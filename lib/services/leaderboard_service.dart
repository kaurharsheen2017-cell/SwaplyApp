// lib/services/leaderboard_service.dart
// Queries Supabase profiles table for ranking.
// Points formula: totalSwaps * 100 (matches profile_screen display).
// filterBySkill filters "By Category" tab by skills_offered.

import 'package:flutter/material.dart';
import '../main.dart';

// ── Data model ────────────────────────────────────────────────────────────────
class LeaderboardEntry {
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? campus;
  final int totalSwaps;
  final double averageRating;
  final int ratingCount;
  final List<String> skillsOffered;
  final int points;   // totalSwaps * 100

  LeaderboardEntry({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.campus,
    required this.totalSwaps,
    required this.averageRating,
    required this.ratingCount,
    required this.skillsOffered,
    required this.points,
  });

  String get displayName => fullName?.isNotEmpty == true ? fullName! : username;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final swaps = (json['total_swaps'] ?? 0) as int;
    return LeaderboardEntry(
      id:            json['id']       ?? '',
      username:      json['username'] ?? '',
      fullName:      json['full_name'],
      avatarUrl:     json['avatar_url'],
      campus:        json['campus'],
      totalSwaps:    swaps,
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      ratingCount:   (json['rating_count']   ?? 0) as int,
      skillsOffered: List<String>.from(json['skills_offered'] ?? []),
      points:        swaps * 100,
    );
  }
}

// ── Service ───────────────────────────────────────────────────────────────────
class LeaderboardService extends ChangeNotifier {
  // Overall
  List<LeaderboardEntry> _overall = [];
  // Category (By Category tab, filtered by selected skill)
  List<LeaderboardEntry> _byCat   = [];

  bool   _loading = false;
  String? _error;

  // Period selector: 0 = This Month, 1 = This Semester, 2 = All Time
  int _period = 0;
  // Category filter index (for By Category tab)
  String _selectedSkill = '';

  List<LeaderboardEntry> get overall => _overall;
  List<LeaderboardEntry> get byCat   => _byCat;
  bool   get isLoading => _loading;
  String? get error   => _error;
  int    get period   => _period;
  String get selectedSkill => _selectedSkill;

  Future<void> fetch({int period = 0}) async {
    _period  = period;
    _loading = true;
    _error   = null;
    notifyListeners();

    try {
      // Build date filter based on period
      DateTime? since;
      final now = DateTime.now();
      if (period == 0) {
        since = DateTime(now.year, now.month, 1);
      } else if (period == 1) {
        // Semester ≈ 6 months
        since = now.subtract(const Duration(days: 180));
      }
      // period == 2 → All Time, no date filter

      var query = supabase
          .from('profiles')
          .select(
            'id, username, full_name, avatar_url, campus, '
            'total_swaps, average_rating, rating_count, skills_offered',
          )
          .order('total_swaps', ascending: false)
          .limit(50);

      final data = await query;

      final entries = (data as List)
          .map((j) => LeaderboardEntry.fromJson(j))
          .where((e) => e.totalSwaps > 0 || e.ratingCount > 0)
          .toList()
        ..sort((a, b) => b.points.compareTo(a.points));

      _overall = entries;
      _applySkillFilter();
    } catch (e) {
      _error = e.toString();
      debugPrint('LeaderboardService error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setSkill(String skill) {
    _selectedSkill = skill;
    _applySkillFilter();
    notifyListeners();
  }

  void _applySkillFilter() {
    if (_selectedSkill.isEmpty) {
      _byCat = List.from(_overall);
      return;
    }
    _byCat = _overall.where((e) => e.skillsOffered.any(
      (s) => s.toLowerCase().contains(_selectedSkill.toLowerCase()),
    )).toList();
  }

  /// All unique skills from all entries (for category tab icons row)
  List<String> get allSkills {
    final seen = <String>{};
    for (final e in _overall) {
      for (final s in e.skillsOffered) {
        seen.add(s);
      }
    }
    return seen.toList()..sort();
  }

  // Kept for backward-compat with any existing callers
  Future<void> fetchLeaderboard() => fetch();
  void filterBySkill(String? s) => setSkill(s ?? '');
  List<LeaderboardEntry> get entries         => _overall;
  List<LeaderboardEntry> get filteredEntries => _byCat;
}