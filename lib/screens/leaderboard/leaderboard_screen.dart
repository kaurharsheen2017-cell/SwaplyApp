// lib/screens/leaderboard/leaderboard_screen.dart
// Pixel-perfect match of LeaderboardScreen.png (both dark + light panels).
// Dark variant: deep dark-navy bg, confetti decorations, gold crown podium.
// Light variant: white bg, same layout, purple accents.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/leaderboard_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';

// ── Category definitions ──────────────────────────────────────────────────────
class _LbCat {
  final String label;
  final IconData icon;
  final String skill; // skill keyword to filter on
  const _LbCat(this.label, this.icon, this.skill);
}

const _kCats = [
  _LbCat('Programming', Icons.code_rounded,          'programming'),
  _LbCat('Design',      Icons.design_services_rounded,'design'),
  _LbCat('Writing',     Icons.edit_rounded,           'writing'),
  _LbCat('Marketing',   Icons.campaign_rounded,       'marketing'),
  _LbCat('More',        Icons.grid_view_rounded,      ''),
];

// ── Colours ───────────────────────────────────────────────────────────────────
const _kGold   = Color(0xFFFFB800);
const _kSilver = Color(0xFFB0BEC5);
const _kBronze = Color(0xFFCD7F32);
const _kPurple = Color(0xFF5B4FE8);
const _kCoinYellow = Color(0xFFFFB800);

// ═════════════════════════════════════════════════════════════════════════════
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _period   = 0;   // 0=This Month, 1=This Semester, 2=All Time
  int _catIndex = 0;   // By Category tab selected category
  bool _howVisible = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaderboardService>().fetch(period: _period);
    });
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  void _setPeriod(int p) {
    if (_period == p) return;
    setState(() => _period = p);
    HapticFeedback.selectionClick();
    context.read<LeaderboardService>().fetch(period: p);
  }

  void _setCat(int i) {
    setState(() => _catIndex = i);
    HapticFeedback.selectionClick();
    final svc = context.read<LeaderboardService>();
    svc.setSkill(i < _kCats.length ? _kCats[i].skill : '');
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? const Color(0xFF0E0E1C) : Colors.white;
    final tPri    = isDark ? Colors.white            : AppColors.textPrimary;
    final tSec    = isDark ? Colors.white70          : AppColors.textSecondary;
    final primary = isDark ? AppColors.darkPrimary   : _kPurple;
    final border  = isDark ? const Color(0xFF2A2A40) : AppColors.divider;
    final cardBg  = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8F8FF);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          // ── Top bar ────────────────────────────────────────────────────
          _TopBar(isDark: isDark, tPri: tPri, primary: primary),

          // ── Overall / By Category tabs ─────────────────────────────────
          _TabRow(
            ctrl: _tabCtrl,
            isDark: isDark,
            primary: primary,
            bg: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F0F6),
          ),

          // ── Tab body ───────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // ── OVERALL TAB ──
                _OverallTab(
                  period: _period,
                  onPeriod: _setPeriod,
                  isDark: isDark, bg: bg, cardBg: cardBg,
                  tPri: tPri, tSec: tSec,
                  primary: primary, border: border,
                  howVisible: _howVisible,
                  onDismissHow: () => setState(() => _howVisible = false),
                ),
                // ── BY CATEGORY TAB ──
                _ByCategoryTab(
                  catIndex: _catIndex,
                  onCat: _setCat,
                  period: _period,
                  onPeriod: _setPeriod,
                  isDark: isDark, bg: bg, cardBg: cardBg,
                  tPri: tPri, tSec: tSec,
                  primary: primary, border: border,
                  howVisible: _howVisible,
                  onDismissHow: () => setState(() => _howVisible = false),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Top bar: back arrow + "Leaderboard" + trophy icon
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool isDark; final Color tPri, primary;
  const _TopBar({required this.isDark, required this.tPri, required this.primary});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Row(children: [
        IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: tPri, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Text('Leaderboard',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: tPri, letterSpacing: -0.3)),
        ),
        // Trophy icon badge
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: primary.withOpacity(isDark ? 0.22 : 0.10),
            borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.emoji_events_rounded, color: primary, size: 20),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Overall / By Category tab row
// ─────────────────────────────────────────────────────────────────────────────
class _TabRow extends StatelessWidget {
  final TabController ctrl;
  final bool isDark; final Color primary, bg;
  const _TabRow({required this.ctrl, required this.isDark,
    required this.primary, required this.bg});
  @override
  Widget build(BuildContext context) {
    final on  = isDark ? Colors.white : Colors.white;
    final off = isDark ? Colors.white60 : AppColors.textSecondary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      height: 44,
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(12)),
      child: TabBar(
        controller: ctrl,
        indicator: BoxDecoration(
          color: primary, borderRadius: BorderRadius.circular(10)),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: on,
        unselectedLabelColor: off,
        labelStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
        tabs: const [Tab(text: 'Overall'), Tab(text: 'By Category')],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Period selector  (This Month / This Semester / All Time)
// ─────────────────────────────────────────────────────────────────────────────
class _PeriodRow extends StatelessWidget {
  final int active; final ValueChanged<int> onTap;
  final bool isDark; final Color primary;
  const _PeriodRow({required this.active, required this.onTap,
    required this.isDark, required this.primary});

  static const _labels = ['This Month', 'This Semester', 'All Time'];

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F0F6);
    final off = isDark ? Colors.white60 : AppColors.textSecondary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      height: 40,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: List.generate(3, (i) {
          final on = i == active;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: on ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: Text(_labels[i],
                  style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: on ? Colors.white : off)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  OVERALL TAB
// ─────────────────────────────────────────────────────────────────────────────
class _OverallTab extends StatelessWidget {
  final int period; final ValueChanged<int> onPeriod;
  final bool isDark, howVisible;
  final Color bg, cardBg, tPri, tSec, primary, border;
  final VoidCallback onDismissHow;

  const _OverallTab({
    required this.period, required this.onPeriod,
    required this.isDark, required this.howVisible,
    required this.bg, required this.cardBg,
    required this.tPri, required this.tSec,
    required this.primary, required this.border,
    required this.onDismissHow,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaderboardService>(
      builder: (_, svc, __) {
        final all = svc.overall;
        final top3 = all.take(3).toList();
        final rest = all.length > 3 ? all.sublist(3) : <LeaderboardEntry>[];

        return ListView(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          children: [
            // Dark header with confetti (dark) or plain (light)
            _HeaderBanner(isDark: isDark, primary: primary, tPri: tPri, tSec: tSec),

            // Period row
            _PeriodRow(active: period, onTap: onPeriod, isDark: isDark, primary: primary),
            const SizedBox(height: 16),

            // Podium
            if (svc.isLoading)
              const _LoadingPodium()
            else if (top3.isNotEmpty)
              _Podium(top3: top3, isDark: isDark, primary: primary, tPri: tPri, tSec: tSec),

            const SizedBox(height: 20),

            // Top Contributors list (rank 4+)
            if (rest.isNotEmpty) ...[
              _ListHeader(
                tPri: tPri, primary: primary,
                onViewAll: () {},
              ),
              const SizedBox(height: 8),
              ...rest.asMap().entries.map((e) => _ContributorRow(
                entry: e.value, rank: e.key + 4,
                isDark: isDark, cardBg: cardBg,
                tPri: tPri, tSec: tSec, border: border, primary: primary,
              ).animate().fadeIn(delay: Duration(milliseconds: e.key * 40))),
            ],

            // "Consistency is key" banner
            if (howVisible)
              _MotivationBanner(
                isDark: isDark, cardBg: cardBg,
                tPri: tPri, primary: primary,
                onDismiss: onDismissHow,
              ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BY CATEGORY TAB
// ─────────────────────────────────────────────────────────────────────────────
class _ByCategoryTab extends StatelessWidget {
  final int catIndex, period;
  final ValueChanged<int> onCat, onPeriod;
  final bool isDark, howVisible;
  final Color bg, cardBg, tPri, tSec, primary, border;
  final VoidCallback onDismissHow;

  const _ByCategoryTab({
    required this.catIndex, required this.onCat,
    required this.period, required this.onPeriod,
    required this.isDark, required this.howVisible,
    required this.bg, required this.cardBg,
    required this.tPri, required this.tSec,
    required this.primary, required this.border,
    required this.onDismissHow,
  });

  @override
  Widget build(BuildContext context) {
    final cat  = catIndex < _kCats.length ? _kCats[catIndex] : _kCats[0];
    final iconBg = isDark
        ? primary.withOpacity(0.22)
        : primary.withOpacity(0.10);

    return Consumer<LeaderboardService>(
      builder: (_, svc, __) {
        final all  = svc.byCat;
        final top3 = all.take(3).toList();
        final rest = all.length > 3 ? all.sublist(3) : <LeaderboardEntry>[];

        return ListView(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 12),
            // Category icon row
            _CatIconRow(
              selected: catIndex,
              onTap: onCat,
              isDark: isDark,
              primary: primary,
            ),

            // Selected category card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E38) : const Color(0xFFF0EEFF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(cat.icon, color: primary, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cat.label, style: GoogleFonts.dmSans(
                    fontSize: 16, fontWeight: FontWeight.w800, color: tPri)),
                  Text('Top contributors in ${cat.label.toLowerCase()} skills & help',
                    style: GoogleFonts.dmSans(fontSize: 12, color: tSec)),
                ])),
                Icon(cat.icon, color: primary.withOpacity(0.20), size: 38),
              ]),
            ),

            // Period row
            _PeriodRow(active: period, onTap: onPeriod, isDark: isDark, primary: primary),
            const SizedBox(height: 16),

            // Podium
            if (svc.isLoading)
              const _LoadingPodium()
            else if (top3.isNotEmpty)
              _Podium(top3: top3, isDark: isDark, primary: primary, tPri: tPri, tSec: tSec)
            else
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text('No contributors yet for this category.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: tSec),
                  textAlign: TextAlign.center)),
              ),

            const SizedBox(height: 20),

            // Top Contributors
            if (rest.isNotEmpty) ...[
              _ListHeader(tPri: tPri, primary: primary, onViewAll: () {}),
              const SizedBox(height: 8),
              ...rest.asMap().entries.map((e) => _ContributorRow(
                entry: e.value, rank: e.key + 4,
                isDark: isDark, cardBg: cardBg,
                tPri: tPri, tSec: tSec, border: border, primary: primary,
              ).animate().fadeIn(delay: Duration(milliseconds: e.key * 40))),
            ],

            // Motivation banner
            if (howVisible)
              _MotivationBanner(
                isDark: isDark, cardBg: cardBg,
                tPri: tPri, primary: primary,
                onDismiss: onDismissHow,
              ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Header banner (dark = deep bg + confetti; light = plain)
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderBanner extends StatelessWidget {
  final bool isDark; final Color primary, tPri, tSec;
  const _HeaderBanner({required this.isDark, required this.primary,
    required this.tPri, required this.tSec});

  @override
  Widget build(BuildContext context) {
    if (!isDark) return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Text(
        'Recognizing the most active\nand helping hands on campus! ⭐',
        textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(fontSize: 14, color: tSec, height: 1.5)),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Stack(children: [
        // Confetti dots
        ..._confettiDots(),
        Center(
          child: Text(
            'Recognizing the most active\nand helping hands on campus! ⭐',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 15, color: Colors.white70, height: 1.5)),
        ),
      ]),
    );
  }

  List<Widget> _confettiDots() {
    const colors = [Color(0xFFFF6B9D), Color(0xFF5B4FE8), Color(0xFFFFB800), Color(0xFF00E5FF)];
    const positions = [
      Offset(10, 5), Offset(50, 20), Offset(80, 5),
      Offset(200, 10), Offset(240, 20), Offset(280, 8),
      Offset(30, 35), Offset(260, 35),
    ];
    return positions.asMap().entries.map((e) => Positioned(
      left:  e.value.dx,
      top:   e.value.dy,
      child: Container(
        width: 6, height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors[e.key % colors.length].withOpacity(0.8)),
      ),
    )).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Category icon row (By Category tab)
// ─────────────────────────────────────────────────────────────────────────────
class _CatIconRow extends StatelessWidget {
  final int selected; final ValueChanged<int> onTap;
  final bool isDark; final Color primary;
  const _CatIconRow({required this.selected, required this.onTap,
    required this.isDark, required this.primary});

  @override
  Widget build(BuildContext context) {
    final inactiveBg = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5FB);
    final inactiveTxt = isDark ? Colors.white60 : AppColors.textSecondary;
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _kCats.length,
        itemBuilder: (_, i) {
          final cat = _kCats[i];
          final on  = i == selected;
          return GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                AnimatedContainer(
                  duration: 200.ms,
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: on ? primary : inactiveBg,
                    borderRadius: BorderRadius.circular(12)),
                  child: Icon(cat.icon, color: on ? Colors.white : inactiveTxt, size: 20)),
                const SizedBox(height: 4),
                Text(cat.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: on ? primary : inactiveTxt),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Podium: 3-person medal stand  (2nd left, 1st centre tall, 3rd right)
// ─────────────────────────────────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> top3;
  final bool isDark; final Color primary, tPri, tSec;
  const _Podium({required this.top3, required this.isDark,
    required this.primary, required this.tPri, required this.tSec});

  @override
  Widget build(BuildContext context) {
    final e1 = top3.isNotEmpty ? top3[0] : null;
    final e2 = top3.length > 1 ? top3[1] : null;
    final e3 = top3.length > 2 ? top3[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Rank 2 — left
          if (e2 != null) Expanded(child: _PodiumSlot(
            entry: e2, rank: 2,
            avatarR: 38, medalColor: _kSilver,
            isDark: isDark, primary: primary,
            tPri: tPri, tSec: tSec)),
          const SizedBox(width: 8),
          // Rank 1 — centre, taller
          if (e1 != null) Expanded(child: _PodiumSlot(
            entry: e1, rank: 1,
            avatarR: 48, medalColor: _kGold,
            isDark: isDark, primary: primary,
            tPri: tPri, tSec: tSec,
            crown: true)),
          const SizedBox(width: 8),
          // Rank 3 — right
          if (e3 != null) Expanded(child: _PodiumSlot(
            entry: e3, rank: 3,
            avatarR: 34, medalColor: _kBronze,
            isDark: isDark, primary: primary,
            tPri: tPri, tSec: tSec)),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double avatarR;
  final Color medalColor;
  final bool isDark, crown;
  final Color primary, tPri, tSec;

  const _PodiumSlot({
    required this.entry, required this.rank,
    required this.avatarR, required this.medalColor,
    required this.isDark, required this.primary,
    required this.tPri, required this.tSec,
    this.crown = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8F8FF);
    final ptStr  = '${entry.points} pts';

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: rank == 1
            ? Border.all(color: _kGold.withOpacity(0.40), width: 1.5)
            : null,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Crown for rank 1
        if (crown)
          const Text('👑', style: TextStyle(fontSize: 20))
        else
          const SizedBox(height: 4),
        const SizedBox(height: 4),
        // Avatar with rank badge
        Stack(clipBehavior: Clip.none, alignment: Alignment.bottomRight, children: [
          AvatarWidget(
            avatarUrl: entry.avatarUrl,
            username: entry.username,
            radius: avatarR,
            borderColor: medalColor,
          ),
          Positioned(
            bottom: -4, right: -4,
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: medalColor, shape: BoxShape.circle,
                border: Border.all(color: cardBg, width: 2)),
              alignment: Alignment.center,
              child: Text('$rank',
                style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: rank == 1 ? Colors.black87 : Colors.white)),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        // Name
        Text(entry.displayName,
          style: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w700, color: tPri),
          maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        // Campus
        if (entry.campus?.isNotEmpty == true) ...[
          const SizedBox(height: 2),
          Text(entry.campus!,
            style: GoogleFonts.dmSans(fontSize: 10, color: tSec),
            maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 6),
        // Points
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🪙', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(ptStr,
            style: GoogleFonts.dmSans(
              fontSize: 12, fontWeight: FontWeight.w700, color: _kCoinYellow)),
        ]),
        const SizedBox(height: 8),
        // Swaps + Reviews
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.swap_horiz_rounded, size: 12, color: tSec),
          const SizedBox(width: 2),
          Text('${entry.totalSwaps} Swaps',
            style: GoogleFonts.dmSans(fontSize: 10, color: tSec)),
          const SizedBox(width: 6),
          Icon(Icons.rate_review_outlined, size: 12, color: tSec),
          const SizedBox(width: 2),
          Text('${entry.ratingCount} Reviews',
            style: GoogleFonts.dmSans(fontSize: 10, color: tSec)),
        ]),
      ]),
    ).animate().scale(curve: Curves.easeOutBack, duration: 500.ms,
        delay: Duration(milliseconds: (rank - 1) * 80));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Top Contributors list header
// ─────────────────────────────────────────────────────────────────────────────
class _ListHeader extends StatelessWidget {
  final Color tPri, primary; final VoidCallback onViewAll;
  const _ListHeader({required this.tPri, required this.primary, required this.onViewAll});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        Text('Top Contributors',
          style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w800, color: tPri)),
        const SizedBox(width: 6),
        Icon(Icons.info_outline_rounded, size: 16, color: tPri.withOpacity(0.40)),
      ]),
      GestureDetector(
        onTap: onViewAll,
        child: Row(children: [
          Text('View all', style: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w600, color: primary)),
          const SizedBox(width: 2),
          Icon(Icons.chevron_right_rounded, size: 16, color: primary),
        ]),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Contributor row (rank 4+)
// ─────────────────────────────────────────────────────────────────────────────
class _ContributorRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final bool isDark;
  final Color cardBg, tPri, tSec, border, primary;

  const _ContributorRow({
    required this.entry, required this.rank,
    required this.isDark, required this.cardBg,
    required this.tPri, required this.tSec,
    required this.border, required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1)),
      child: Row(children: [
        // Rank number
        SizedBox(
          width: 24,
          child: Text('$rank',
            style: GoogleFonts.dmSans(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: tSec)),
        ),
        const SizedBox(width: 8),
        AvatarWidget(avatarUrl: entry.avatarUrl,
          username: entry.username, radius: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry.displayName,
            style: GoogleFonts.dmSans(
              fontSize: 13.5, fontWeight: FontWeight.w700, color: tPri),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          if (entry.campus?.isNotEmpty == true)
            Text(entry.campus!,
              style: GoogleFonts.dmSans(fontSize: 11, color: tSec)),
        ])),
        // Points
        Row(children: [
          const Text('🪙', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text('${entry.points} pts',
            style: GoogleFonts.dmSans(
              fontSize: 12, fontWeight: FontWeight.w700, color: _kCoinYellow)),
        ]),
        const SizedBox(width: 10),
        // Swaps
        Row(children: [
          Icon(Icons.swap_horiz_rounded, size: 13, color: tSec),
          const SizedBox(width: 2),
          Text('${entry.totalSwaps} Swaps',
            style: GoogleFonts.dmSans(fontSize: 11, color: tSec)),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Motivation banner "Consistency is key" / "Share knowledge."
// ─────────────────────────────────────────────────────────────────────────────
class _MotivationBanner extends StatelessWidget {
  final bool isDark; final Color cardBg, tPri, primary;
  final VoidCallback onDismiss;
  const _MotivationBanner({required this.isDark, required this.cardBg,
    required this.tPri, required this.primary, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8F8FF);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A40) : AppColors.divider, width: 1)),
      child: Row(children: [
        // Flame/star icon
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.12),
            shape: BoxShape.circle),
          child: const Text('⭐', style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isDark ? 'Consistency is key!' : 'Share knowledge. Build solutions.',
            style: GoogleFonts.dmSans(
              fontSize: 13.5, fontWeight: FontWeight.w700, color: primary)),
          Text(isDark ? 'Keep helping, keep growing.' : 'Climb the ranks!',
            style: GoogleFonts.dmSans(fontSize: 12, color: tPri.withOpacity(0.65))),
        ])),
        const SizedBox(width: 8),
        // How points work button
        GestureDetector(
          onTap: () => _showHowPoints(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: primary.withOpacity(0.40), width: 1),
              borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('How points work?',
                style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w600, color: primary)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 14, color: primary),
            ]),
          ),
        ),
      ]),
    );
  }

  void _showHowPoints(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _HowPointsSheet(isDark: isDark, primary: primary),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  "How do you earn points?" bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _HowPointsSheet extends StatelessWidget {
  final bool isDark; final Color primary;
  const _HowPointsSheet({required this.isDark, required this.primary});

  static const _items = [
    (Icons.swap_horiz_rounded,        Color(0xFF16A34A), 'Complete Swaps',    'Earn points for every\nsuccessful swap'),
    (Icons.chat_bubble_outline_rounded,Color(0xFF0284C7), 'Help & Teach',     'Share your skills and\nhelp others learn'),
    (Icons.star_outline_rounded,       Color(0xFFD97706), 'Get Reviews',      'Receive positive reviews\nfrom your peers'),
    (Icons.calendar_today_outlined,    _kPurple,          'Be Consistent',    'Stay active and keep\ncontributing'),
    (Icons.emoji_events_outlined,      Color(0xFFDC2626), 'Unlock Badges',    'Climb ranks and earn\nexclusive badges'),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final tPri = isDark ? Colors.white : AppColors.textPrimary;
    final tSec = isDark ? Colors.white70 : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
          decoration: BoxDecoration(
            color: tSec.withOpacity(0.30),
            borderRadius: BorderRadius.circular(99))),
        const SizedBox(height: 16),
        Text('How do you earn points? 🤔',
          style: GoogleFonts.dmSans(
            fontSize: 18, fontWeight: FontWeight.w800, color: tPri)),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _items.map((item) {
            final (icon, color, title, desc) = item;
            return Expanded(
              child: Column(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 24)),
                const SizedBox(height: 8),
                Text(title,
                  style: GoogleFonts.dmSans(
                    fontSize: 11, fontWeight: FontWeight.w700, color: tPri),
                  textAlign: TextAlign.center),
                const SizedBox(height: 3),
                Text(desc,
                  style: GoogleFonts.dmSans(fontSize: 10, color: tSec, height: 1.4),
                  textAlign: TextAlign.center),
              ]),
            );
          }).toList(),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Loading podium placeholder
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingPodium extends StatelessWidget {
  const _LoadingPodium();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(48),
    child: Center(child: CircularProgressIndicator()));
}