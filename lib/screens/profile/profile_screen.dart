// lib/screens/profile/profile_screen.dart
// Changes from previous version:
//   • Stats card is INSIDE the purple header (Stack), elevated above the bg
//   • Bio shown directly below name (plain text, 300-char limit, no campus row)
//   • Campus field completely removed
//   • Icons:  Points   → Icons.stars_rounded        (amber)
//             Swaps    → Icons.swap_horiz_rounded    (purple)
//             Rating   → Icons.star_rounded          (amber — kept, distinct bg)
//             Completed→ Icons.check_circle_rounded  (green)
//   • ThemeMode.system default (via ThemeProvider)
//   • Real-time Supabase: fetchUserSwaps + fetchUserPosts

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/chat_model.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../posts/post_detail_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

const _kP  = AppColors.primary;
const _kG1 = Color(0xFF2A22B8);
const _kG2 = Color(0xFF4A3FD4);
const _kG3 = Color(0xFF5B4FE8);

// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _swapTab = 0;
  List<SwapModel> _swaps   = [];
  List<PostModel> _myPosts = [];
  bool _loadingSwaps = false;
  bool _loadingPosts = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    final auth = context.read<AuthService>();
    if (auth.currentUser == null) return;
    setState(() { _loadingSwaps = true; _loadingPosts = true; });
    final res = await Future.wait([
      context.read<ChatService>().fetchUserSwaps(),
      context.read<PostService>().fetchUserPosts(auth.currentUser!.id),
    ]);
    if (!mounted) return;
    setState(() {
      _swaps        = res[0] as List<SwapModel>;
      _myPosts      = res[1] as List<PostModel>;
      _loadingSwaps = false;
      _loadingPosts = false;
    });
  }

  List<SwapModel> get _filteredSwaps {
    if (_swapTab == 0) {
      return _swaps
          .where((s) => s.status == 'pending' || s.status == 'confirmed')
          .toList();
    }
    if (_swapTab == 1) return _swaps.where((s) => s.status == 'completed').toList();
    return _swaps.where((s) => s.status == 'cancelled').toList();
  }

  int get _completedCount => _swaps.where((s) => s.status == 'completed').length;
  int _points(int ts) => ts * 100;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final auth    = context.watch<AuthService>();
    final profile = auth.currentProfile;

    final bg     = isDark ? AppColors.darkBackground : const Color(0xFFF5F5FB);
    final cardBg = isDark ? AppColors.darkCardBg     : Colors.white;
    final tPri   = isDark ? AppColors.darkTextPrimary   : AppColors.textPrimary;
    final tSec   = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final border = isDark ? AppColors.darkBorder        : const Color(0xFFEEEEF5);

    final name       = profile?.fullName ?? profile?.username ?? 'User';
    final bio        = (profile?.bio ?? '').length > 300
        ? '${(profile?.bio ?? '').substring(0, 300)}…'
        : (profile?.bio ?? '');
    final rating     = profile?.averageRating ?? 0.0;
    final totalSwaps = profile?.totalSwaps    ?? 0;
    final skills      = profile?.skillsOffered ?? [];
    final skillsWanted = profile?.skillsWanted  ?? [];

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        color: _kP,
        onRefresh: () async {
          await auth.fetchProfile();
          await _loadAll();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ══════════════════════════════════════════════════════════════
            //  PURPLE HEADER  — gradient bg, avatar, name, bio
            //  Stats card INSIDE the header (Stack, bottom of gradient)
            // ══════════════════════════════════════════════════════════════
            SliverToBoxAdapter(
              child: _ProfileHeader(
                profile: profile,
                name: name,
                bio: bio,
                isDark: isDark,
                points: _points(totalSwaps),
                totalSwaps: totalSwaps,
                rating: rating,
                completed: _completedCount,
                cardBg: cardBg,
                tPri: tPri,
                tSec: tSec,
                onSettings: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
                onEdit: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()))
                  .then((_) => auth.fetchProfile()),
              ),
            ),

            // ══════════════════════════════════════════════════════════════
            //  MY LINKS
            // ══════════════════════════════════════════════════════════════
            SliverToBoxAdapter(
              child: _LinksSection(
                links: profile?.links ?? [],   // no links field in model yet
                isDark: isDark, cardBg: cardBg, tPri: tPri,
                tSec: tSec, border: border,
                onManage: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()))
                  .then((_) => auth.fetchProfile()),
                onLaunch: _launchUrl,
              ).animate().fadeIn(delay: 100.ms),
            ),

            // ══════════════════════════════════════════════════════════════
            //  MY SKILLS
            // ══════════════════════════════════════════════════════════════
            SliverToBoxAdapter(
              child: _SkillsSection(
                skills: skills,
                isDark: isDark, cardBg: cardBg, tPri: tPri,
                tSec: tSec, border: border,
                onEdit: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()))
                  .then((_) => auth.fetchProfile()),
              ).animate().fadeIn(delay: 150.ms),
            ),

            // ══════════════════════════════════════════════════════════════
            //  SKILLS I WANT
            // ══════════════════════════════════════════════════════════════
            SliverToBoxAdapter(
              child: _SkillsWantedSection(
                skills: skillsWanted,
                isDark: isDark, cardBg: cardBg, tPri: tPri,
                tSec: tSec, border: border,
                onEdit: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()))
                  .then((_) => auth.fetchProfile()),
              ).animate().fadeIn(delay: 175.ms),
            ),

            // ══════════════════════════════════════════════════════════════
            //  I OFFER
            // ══════════════════════════════════════════════════════════════
            SliverToBoxAdapter(
              child: _OfferSection(
                posts: _myPosts,
                isLoading: _loadingPosts,
                isDark: isDark, cardBg: cardBg, tPri: tPri,
                tSec: tSec, border: border,
              ).animate().fadeIn(delay: 200.ms),
            ),

            // ══════════════════════════════════════════════════════════════
            //  MY SWAPS
            // ══════════════════════════════════════════════════════════════
            SliverToBoxAdapter(
              child: _SwapsSection(
                swaps: _filteredSwaps,
                isLoading: _loadingSwaps,
                activeTab: _swapTab,
                onTab: (i) => setState(() => _swapTab = i),
                isDark: isDark, cardBg: cardBg, tPri: tPri,
                tSec: tSec, border: border,
              ).animate().fadeIn(delay: 250.ms),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  PROFILE HEADER  — gradient, avatar, name, bio, stats card INSIDE gradient
// ═════════════════════════════════════════════════════════════════════════════
class _ProfileHeader extends StatelessWidget {
  final dynamic profile;
  final String name, bio;
  final bool isDark;
  final int points, totalSwaps, completed;
  final double rating;
  final Color cardBg, tPri, tSec;
  final VoidCallback onSettings, onEdit;

  const _ProfileHeader({
    required this.profile, required this.name, required this.bio,
    required this.isDark, required this.points, required this.totalSwaps,
    required this.rating, required this.completed,
    required this.cardBg, required this.tPri, required this.tSec,
    required this.onSettings, required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // gradient extends downward enough to hold the card
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kG1, _kG2, _kG3],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top action row: Settings top-right ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _HeaderBtn(icon: Icons.settings_outlined, onTap: onSettings),
                ],
              ),
            ),

            // ── Avatar + name + bio ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Stack(children: [
                    AvatarWidget(
                      avatarUrl: profile?.avatarUrl,
                      username: profile?.username ?? '',
                      radius: 44,
                      borderColor: Colors.white,
                      showOnline: true,
                    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                    // Edit pencil badge
                    Positioned(
                      right: 0, bottom: 0,
                      child: GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.4), width: 1.5)),
                          child: const Icon(Icons.edit_rounded,
                              size: 14, color: _kP),
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(width: 16),

                  // Name + verified + bio
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        // Name row
                        Row(children: [
                          Flexible(
                            child: Text(name,
                              style: GoogleFonts.dmSans(
                                color: Colors.white, fontSize: 20,
                                fontWeight: FontWeight.w800, letterSpacing: -0.3),
                              overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade400,
                              shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 13)),
                        ]),
                        // Bio — plain text below name, max 300 chars
                        if (bio.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(bio,
                            style: GoogleFonts.dmSans(
                              color: Colors.white.withOpacity(0.82),
                              fontSize: 13, height: 1.45),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ══════════════════════════════════════════════════════════════
            //  STATS CARD — elevated white card INSIDE gradient
            //  Positioned at the bottom of the gradient with padding
            // ══════════════════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.30 : 0.12),
                      blurRadius: 24, offset: const Offset(0, 8)),
                    BoxShadow(
                      color: _kG1.withOpacity(0.18),
                      blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(children: [
                  // Points — star icon (amber-gold)
                  _StatCol(
                    icon: Icons.stars_rounded,
                    iconBg: const Color(0xFFFFF3DC),
                    iconColor: const Color(0xFFD97706),
                    value: '$points',
                    label: 'Points',
                    tPri: tPri, tSec: tSec),
                  _StatDivider(isDark: isDark),
                  // Total Swaps — swap icon (indigo)
                  _StatCol(
                    icon: Icons.swap_horiz_rounded,
                    iconBg: const Color(0xFFEDE9FF),
                    iconColor: _kP,
                    value: '$totalSwaps',
                    label: 'Total Swaps',
                    tPri: tPri, tSec: tSec),
                  _StatDivider(isDark: isDark),
                  // Rating — star (amber, same icon family but different bg shade)
                  _StatCol(
                    icon: Icons.star_rounded,
                    iconBg: const Color(0xFFFEF9E7),
                    iconColor: const Color(0xFFF59E0B),
                    value: rating > 0 ? rating.toStringAsFixed(1) : '—',
                    label: 'Rating',
                    tPri: tPri, tSec: tSec),
                  _StatDivider(isDark: isDark),
                  // Completed Swaps — check circle (green)
                  _StatCol(
                    icon: Icons.check_circle_rounded,
                    iconBg: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF16A34A),
                    value: '$completed',
                    label: 'Completed',
                    tPri: tPri, tSec: tSec),
                ]),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Header icon button (frosted white) ───────────────────────────────────────
class _HeaderBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1)),
      child: Icon(icon, color: Colors.white, size: 20)));
}

// ── Stat column ───────────────────────────────────────────────────────────────
class _StatCol extends StatelessWidget {
  final IconData icon; final Color iconBg, iconColor;
  final String value, label; final Color tPri, tSec;
  const _StatCol({required this.icon, required this.iconBg,
    required this.iconColor, required this.value, required this.label,
    required this.tPri, required this.tSec});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
        child: Icon(icon, color: iconColor, size: 22)),
      const SizedBox(height: 8),
      Text(value,
        style: GoogleFonts.dmSans(
          fontSize: 17, fontWeight: FontWeight.w800, color: tPri)),
      const SizedBox(height: 2),
      Text(label,
        textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(
          fontSize: 10.5, color: tSec, fontWeight: FontWeight.w500)),
    ]),
  );
}

class _StatDivider extends StatelessWidget {
  final bool isDark;
  const _StatDivider({required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 50,
    color: isDark ? AppColors.darkBorder : const Color(0xFFEEEEF5));
}

// ═════════════════════════════════════════════════════════════════════════════
//  MY LINKS
// ═════════════════════════════════════════════════════════════════════════════
class _LinksSection extends StatelessWidget {
  final List<String> links;
  final bool isDark;
  final Color cardBg, tPri, tSec, border;
  final VoidCallback onManage;
  final Future<void> Function(String) onLaunch;

  const _LinksSection({required this.links, required this.isDark,
    required this.cardBg, required this.tPri, required this.tSec,
    required this.border, required this.onManage, required this.onLaunch});

  IconData _iconFor(String url) {
    if (url.contains('linkedin')) return Icons.work_outline_rounded;
    if (url.contains('github'))   return Icons.code_rounded;
    return Icons.link_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : _kP;
    return _SectionCard(isDark: isDark, cardBg: cardBg, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.link_rounded, label: 'My Links',
          actionLabel: 'Manage', isDark: isDark,
          tPri: tPri, primary: primary, onAction: onManage),
        const SizedBox(height: 14),
        if (links.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('No links added yet.',
              style: GoogleFonts.dmSans(fontSize: 13, color: tSec)))
        else
          ...links.map((url) => _LinkRow(
            url: url, icon: _iconFor(url), isDark: isDark,
            border: border, tPri: tPri, onTap: () => onLaunch(url))),
        const SizedBox(height: 4),
        // + Add another link dashed button
        GestureDetector(
          onTap: onManage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFD0C8FF),
                width: 1.4)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_rounded, size: 16, color: primary),
              const SizedBox(width: 6),
              Text('Add another link',
                style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w600, color: primary)),
            ]),
          ),
        ),
      ],
    ));
  }
}

class _LinkRow extends StatelessWidget {
  final String url; final IconData icon;
  final bool isDark; final Color border, tPri;
  final VoidCallback onTap;
  const _LinkRow({required this.url, required this.icon, required this.isDark,
    required this.border, required this.tPri, required this.onTap});
  String _display(String u) {
    final d = u.replaceFirst('https://','').replaceFirst('http://','').replaceFirst('www.','');
    return d.length > 38 ? '${d.substring(0,38)}…' : d;
  }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF8F8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1)),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(
            color: url.contains('linkedin') ? const Color(0xFF0A66C2)
                : isDark ? AppColors.darkSurfaceVariant : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border, width: 1)),
          child: Icon(icon, size: 18,
            color: url.contains('linkedin') ? Colors.white
                : isDark ? AppColors.darkTextPrimary : Colors.black87)),
        const SizedBox(width: 12),
        Expanded(child: Text(_display(url),
          style: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w500, color: tPri))),
        Icon(Icons.open_in_new_rounded, size: 16,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
      ]),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
//  MY SKILLS
// ═════════════════════════════════════════════════════════════════════════════
class _SkillsSection extends StatelessWidget {
  final List<String> skills;
  final bool isDark;
  final Color cardBg, tPri, tSec, border;
  final VoidCallback onEdit;
  const _SkillsSection({required this.skills, required this.isDark,
    required this.cardBg, required this.tPri, required this.tSec,
    required this.border, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final primary  = isDark ? AppColors.darkPrimary : _kP;
    final chipBg   = isDark ? _kP.withOpacity(0.14) : const Color(0xFFEDE9FF);
    final chipBord = isDark ? _kP.withOpacity(0.32) : const Color(0xFFCFC8FF);

    return _SectionCard(isDark: isDark, cardBg: cardBg, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.star_rounded, label: 'My Skills',
          actionLabel: 'Edit', isDark: isDark,
          tPri: tPri, primary: primary, onAction: onEdit),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ...skills.map((s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: chipBg, borderRadius: BorderRadius.circular(99),
              border: Border.all(color: chipBord, width: 1)),
            child: Text(s, style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w600, color: primary)))),
          // + Add Skill
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: border, width: 1.4)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, size: 15, color: tSec),
                const SizedBox(width: 4),
                Text('Add Skill', style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w600, color: tSec)),
              ]),
            ),
          ),
        ]),
      ],
    ));
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SKILLS I WANT  — same visual style as My Skills but amber/orange palette
// ═════════════════════════════════════════════════════════════════════════════
class _SkillsWantedSection extends StatelessWidget {
  final List<String> skills;
  final bool isDark;
  final Color cardBg, tPri, tSec, border;
  final VoidCallback onEdit;
  const _SkillsWantedSection({required this.skills, required this.isDark,
    required this.cardBg, required this.tPri, required this.tSec,
    required this.border, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    // Amber-tinted palette to visually distinguish from "I Offer" (purple)
    final chipColor  = isDark ? const Color(0xFFD97706) : const Color(0xFFD97706);
    final chipBg     = isDark ? const Color(0xFF78350F).withOpacity(0.35)
                               : const Color(0xFFFEF3C7);
    final chipBorder = isDark ? const Color(0xFFD97706).withOpacity(0.40)
                               : const Color(0xFFFDE68A);
    final primary    = isDark ? AppColors.darkPrimary : _kP;

    return _SectionCard(isDark: isDark, cardBg: cardBg, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header — lightbulb icon to contrast with star on My Skills
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(Icons.lightbulb_outline_rounded,
                color: const Color(0xFFD97706), size: 20),
            const SizedBox(width: 8),
            Text('Skills I Want',
                style: GoogleFonts.dmSans(
                    fontSize: 16, fontWeight: FontWeight.w800, color: tPri)),
          ]),
          GestureDetector(
            onTap: onEdit,
            child: Text('Edit',
                style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w700, color: primary)),
          ),
        ]),
        const SizedBox(height: 14),

        if (skills.isEmpty)
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: border, width: 1.4)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, size: 15, color: tSec),
                const SizedBox(width: 4),
                Text('Add skills you want to learn',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w600, color: tSec)),
              ]),
            ),
          )
        else
          Wrap(spacing: 8, runSpacing: 8, children: [
            ...skills.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: chipBorder, width: 1)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.lightbulb_rounded,
                    size: 13, color: chipColor),
                const SizedBox(width: 5),
                Text(s, style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: chipColor)),
              ]),
            )),
            // + Add more
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: border, width: 1.4)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, size: 15, color: tSec),
                  const SizedBox(width: 4),
                  Text('Add more', style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w600, color: tSec)),
                ]),
              ),
            ),
          ]),
      ],
    ));
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ═════════════════════════════════════════════════════════════════════════════
class _OfferSection extends StatelessWidget {
  final List<PostModel> posts;
  final bool isLoading, isDark;
  final Color cardBg, tPri, tSec, border;
  const _OfferSection({required this.posts, required this.isLoading,
    required this.isDark, required this.cardBg, required this.tPri,
    required this.tSec, required this.border});

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : _kP;
    final bg = isDark ? AppColors.darkBackground : const Color(0xFFF5F5FB);

    return Container(
      color: bg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.card_giftcard_rounded, color: primary, size: 20),
                const SizedBox(width: 8),
                Text('I Offer',
                  style: GoogleFonts.dmSans(
                    fontSize: 16, fontWeight: FontWeight.w800, color: tPri)),
              ]),
              Text('See all',
                style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w700, color: primary)),
            ],
          ),
        ),
        if (isLoading)
          SizedBox(height: 165,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              itemBuilder: (_, __) => _OfferShimmer(isDark: isDark)))
        else if (posts.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text('No posts yet.',
              style: GoogleFonts.dmSans(fontSize: 13, color: tSec)))
        else
          SizedBox(height: 165,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              itemCount: posts.length,
              itemBuilder: (_, i) => _OfferCard(
                post: posts[i], isDark: isDark,
                cardBg: cardBg, tPri: tPri, tSec: tSec, border: border)
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: i * 55))
                  .slideX(begin: 0.05))),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final PostModel post; final bool isDark;
  final Color cardBg, tPri, tSec, border;
  const _OfferCard({required this.post, required this.isDark,
    required this.cardBg, required this.tPri, required this.tSec,
    required this.border});

  @override
  Widget build(BuildContext context) {
    final isBarter = post.exchangeType == 'barter';
    final pillBg   = isBarter
        ? (isDark ? AppColors.darkTagBarterBg : const Color(0xFFDCFCE7))
        : (isDark ? AppColors.darkTagMoneyBg  : const Color(0xFFDCFCE7));
    final pillText = isBarter
        ? (isDark ? AppColors.darkTagBarterText : const Color(0xFF16A34A))
        : (isDark ? AppColors.darkTagMoneyText  : const Color(0xFF16A34A));

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
      child: Container(
        width: 158,
        margin: const EdgeInsets.only(right: 12, bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1),
          boxShadow: isDark ? null : [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10, offset: const Offset(0, 3))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFEDE9FF),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.star_outline_rounded, size: 20,
              color: isDark ? AppColors.darkPrimary : _kP)),
          const SizedBox(height: 8),
          Text(post.title,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 13.5, fontWeight: FontWeight.w700, color: tPri)),
          const SizedBox(height: 3),
          Expanded(child: Text(post.skillOffered,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(fontSize: 11.5, color: tSec, height: 1.4))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: pillBg,
                borderRadius: BorderRadius.circular(99)),
            child: Text('Barter',
              style: GoogleFonts.dmSans(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: pillText))),
        ]),
      ),
    );
  }
}

class _OfferShimmer extends StatelessWidget {
  final bool isDark;
  const _OfferShimmer({required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    width: 158,
    margin: const EdgeInsets.only(right: 12, bottom: 12),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(16)));
}

// ═════════════════════════════════════════════════════════════════════════════
//  MY SWAPS
// ═════════════════════════════════════════════════════════════════════════════
class _SwapsSection extends StatelessWidget {
  final List<SwapModel> swaps; final bool isLoading, isDark;
  final int activeTab; final ValueChanged<int> onTab;
  final Color cardBg, tPri, tSec, border;
  const _SwapsSection({required this.swaps, required this.isLoading,
    required this.isDark, required this.activeTab, required this.onTab,
    required this.cardBg, required this.tPri, required this.tSec,
    required this.border});

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : _kP;
    final bg = isDark ? AppColors.darkBackground : const Color(0xFFF5F5FB);

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(Icons.swap_horiz_rounded, color: primary, size: 20),
            const SizedBox(width: 8),
            Text('My Swaps',
              style: GoogleFonts.dmSans(
                fontSize: 16, fontWeight: FontWeight.w800, color: tPri)),
          ]),
          Text('See all',
            style: GoogleFonts.dmSans(
              fontSize: 13, fontWeight: FontWeight.w700, color: primary)),
        ]),
        const SizedBox(height: 14),
        // Tabs
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1)),
          child: Row(children: [
            _SwapTab(label: 'Active',    i: 0, active: activeTab, onTap: onTab, isDark: isDark),
            _SwapTab(label: 'Completed', i: 1, active: activeTab, onTap: onTab, isDark: isDark),
            _SwapTab(label: 'Cancelled', i: 2, active: activeTab, onTap: onTab, isDark: isDark),
          ]),
        ),
        const SizedBox(height: 14),
        if (isLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(28),
            child: CircularProgressIndicator()))
        else if (swaps.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Text('No swaps here yet.',
              style: GoogleFonts.dmSans(fontSize: 13, color: tSec))))
        else
          ...swaps.asMap().entries.map((e) => _SwapRow(
            swap: e.value, isDark: isDark, cardBg: cardBg,
            tPri: tPri, tSec: tSec, border: border)
              .animate().fadeIn(delay: Duration(milliseconds: e.key * 55))),
      ]),
    );
  }
}

class _SwapTab extends StatelessWidget {
  final String label; final int i, active;
  final ValueChanged<int> onTap; final bool isDark;
  const _SwapTab({required this.label, required this.i, required this.active,
    required this.onTap, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final on = i == active;
    return Expanded(child: GestureDetector(
      onTap: () => onTap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 210),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: on ? _kP : Colors.transparent,
          borderRadius: BorderRadius.circular(9)),
        alignment: Alignment.center,
        child: Text(label,
          style: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: on ? Colors.white
                : isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
      ),
    ));
  }
}

class _SwapRow extends StatelessWidget {
  final SwapModel swap; final bool isDark;
  final Color cardBg, tPri, tSec, border;
  const _SwapRow({required this.swap, required this.isDark,
    required this.cardBg, required this.tPri, required this.tSec,
    required this.border});
  @override
  Widget build(BuildContext context) {
    Color sc; String sl;
    switch (swap.status) {
      case 'completed': sc = const Color(0xFF16A34A); sl = 'Completed';  break;
      case 'cancelled': sc = AppColors.error;         sl = 'Cancelled';  break;
      case 'confirmed': sc = _kP;                     sl = 'Confirmed';  break;
      default:          sc = const Color(0xFFF59E0B); sl = 'In Progress';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: cardBg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1),
        boxShadow: isDark ? null : [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(width: 46, height: 46,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFEDE9FF),
            shape: BoxShape.circle),
          child: Icon(Icons.person_rounded,
            color: isDark ? AppColors.darkPrimary : _kP, size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Swap Request',
            style: GoogleFonts.dmSans(
              fontSize: 14, fontWeight: FontWeight.w700, color: tPri)),
          const SizedBox(height: 2),
          Text('with partner',
            style: GoogleFonts.dmSans(fontSize: 12, color: tSec)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Barter',
            style: GoogleFonts.dmSans(
              fontSize: 12, fontWeight: FontWeight.w600, color: tSec)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: sc.withOpacity(isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(99)),
            child: Text(sl,
              style: GoogleFonts.dmSans(
                fontSize: 11, fontWeight: FontWeight.w700, color: sc))),
        ]),
        const SizedBox(width: 6),
        Icon(Icons.chevron_right_rounded, size: 18,
          color: isDark ? AppColors.darkTextLight : AppColors.textLight),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═════════════════════════════════════════════════════════════════════════════
class _SectionCard extends StatelessWidget {
  final bool isDark; final Color cardBg; final Widget child;
  const _SectionCard({required this.isDark, required this.cardBg,
    required this.child});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: cardBg, borderRadius: BorderRadius.circular(18),
      boxShadow: isDark ? null : [BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 14, offset: const Offset(0, 4))]),
    child: child);
}

class _SectionHeader extends StatelessWidget {
  final IconData icon; final String label, actionLabel;
  final bool isDark; final Color tPri, primary;
  final VoidCallback onAction;
  const _SectionHeader({required this.icon, required this.label,
    required this.actionLabel, required this.isDark,
    required this.tPri, required this.primary, required this.onAction});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(children: [
        Icon(icon, color: primary, size: 20),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.dmSans(
            fontSize: 16, fontWeight: FontWeight.w800, color: tPri)),
      ]),
      GestureDetector(
        onTap: onAction,
        child: Text(actionLabel,
          style: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w700, color: primary))),
    ],
  );
}