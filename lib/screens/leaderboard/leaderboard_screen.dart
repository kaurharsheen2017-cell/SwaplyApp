import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/leaderboard_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../../screens/profile/user_profile_screen.dart' as profile_screen;

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedSkill = 'All Skills';
  late LeaderboardService _service;

  @override
  void initState() {
    super.initState();
    _service = LeaderboardService();
    _service.fetchLeaderboard();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  void _goToProfile(BuildContext ctx, String userId) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => _UserProfileRoute(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;

    return ChangeNotifierProvider.value(
      value: _service,
      child: Scaffold(
        backgroundColor: bgColor,
        body: CustomScrollView(
          slivers: [
            // ── Gradient app bar ───────────────────────────────────────
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                      gradient: AppColors.heroGradient),
                  child: Stack(children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                  ]),
                ),
                title: Text(
                  'Leaderboard',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                titlePadding: const EdgeInsets.fromLTRB(56, 0, 0, 16),
              ),
            ),

            // ── Skill filter row ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Consumer<LeaderboardService>(
                builder: (ctx, svc, __) {
                  if (svc.isLoading) return const SizedBox.shrink();

                  final dropBg     = isDark ? AppColors.darkCardBg        : Colors.white;
                  final dropBorder = isDark ? AppColors.darkBorder        : AppColors.border;
                  final dropText   = isDark ? AppColors.darkTextPrimary   : AppColors.textPrimary;
                  final dropSec    = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 2),
                          decoration: BoxDecoration(
                            color: dropBg,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: dropBorder),
                            boxShadow: isDark ? null : AppShadows.card,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSkill,
                              isExpanded: true,
                              dropdownColor: dropBg,
                              icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: dropSec),
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: dropText,
                              ),
                              items: svc.allSkills
                                  .map((skill) => DropdownMenuItem(
                                        value: skill,
                                        child: Text(skill),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                setState(() => _selectedSkill =
                                    val ?? 'All Skills');
                                svc.filterBySkill(val);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: dropBg,
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: dropBorder),
                          boxShadow: isDark ? null : AppShadows.card,
                        ),
                        child: Text(
                          '${svc.filteredEntries.length} users',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: dropSec,
                          ),
                        ),
                      ),
                    ]),
                  );
                },
              ),
            ),

            // ── Podium top-3 ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Consumer<LeaderboardService>(
                builder: (ctx, svc, __) {
                  if (svc.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (svc.filteredEntries.isEmpty) {
                    return _emptyState(isDark);
                  }
                  if (svc.filteredEntries.length >= 3) {
                    return _buildPodium(ctx, svc.filteredEntries);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

            // ── Rank list (#4 onward) ──────────────────────────────────
            Consumer<LeaderboardService>(
              builder: (ctx, svc, __) {
                if (svc.isLoading || svc.filteredEntries.isEmpty) {
                  return const SliverToBoxAdapter(
                      child: SizedBox.shrink());
                }
                final start =
                    svc.filteredEntries.length >= 3 ? 3 : 0;
                final entries =
                    svc.filteredEntries.skip(start).toList();
                if (entries.isEmpty) {
                  return const SliverToBoxAdapter(
                      child: SizedBox.shrink());
                }
                return SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildRankTile(
                              ctx, entries[i], start + i + 1, isDark)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: i * 50)),
                      childCount: entries.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Podium ──────────────────────────────────────────────────────────
  Widget _buildPodium(
      BuildContext context, List<LeaderboardEntry> entries) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.button,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _podiumItem(context, entries[1], 2),
          _podiumItem(context, entries[0], 1),
          _podiumItem(context, entries[2], 3),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _podiumItem(
      BuildContext context, LeaderboardEntry entry, int rank) {
    const crownColors = {
      1: Color(0xFFFFD700),
      2: Color(0xFFC0C0C0),
      3: Color(0xFFCD7F32),
    };
    final cc = crownColors[rank]!;

    return GestureDetector(
      onTap: () => _goToProfile(context, entry.id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          rank == 1
              ? Icon(Icons.emoji_events_rounded, color: cc, size: 28)
              : const SizedBox(height: 28),
          const SizedBox(height: 6),
          Stack(
            clipBehavior: Clip.none,
            children: [
              AvatarWidget(
                avatarUrl: entry.avatarUrl,
                username: entry.username,
                radius: rank == 1 ? 34 : 26,
                borderColor: Colors.white,
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: cc,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.username,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: rank == 1 ? 13 : 11,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_horiz_rounded,
                  color: Colors.white70, size: 12),
              const SizedBox(width: 3),
              Text(
                '${entry.totalSwaps}',
                style: GoogleFonts.dmSans(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.star_rounded,
                  color: Color(0xFFFFD700), size: 12),
              const SizedBox(width: 3),
              Text(
                entry.averageRating > 0
                    ? entry.averageRating.toStringAsFixed(1)
                    : '-',
                style: GoogleFonts.dmSans(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: rank == 1 ? 80 : 65,
            height: rank == 1 ? 48 : rank == 2 ? 36 : 24,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Rank tile ────────────────────────────────────────────────────────
  Widget _buildRankTile(BuildContext context, LeaderboardEntry entry,
      int rank, bool isDark) {
    final cardBg  = isDark ? AppColors.darkCardBg        : Colors.white;
    final border  = isDark ? AppColors.darkBorder        : AppColors.divider;
    final textPri = isDark ? AppColors.darkTextPrimary   : AppColors.textPrimary;
    final textLt  = isDark ? AppColors.darkTextLight     : AppColors.textLight;
    final primary = isDark ? AppColors.darkPrimary       : AppColors.primary;

    return GestureDetector(
      onTap: () => _goToProfile(context, entry.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: border, width: 1),
          boxShadow: isDark ? null : AppShadows.card,
        ),
        child: Row(children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: textLt,
              ),
            ),
          ),
          AvatarWidget(
            avatarUrl: entry.avatarUrl,
            username: entry.username,
            radius: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.fullName ?? entry.username,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPri,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '@${entry.username}',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: textLt,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(children: [
                Icon(Icons.swap_horiz_rounded, size: 13, color: primary),
                const SizedBox(width: 3),
                Text(
                  '${entry.totalSwaps} swaps',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.star_rounded,
                    size: 13, color: AppColors.warning),
                const SizedBox(width: 3),
                Text(
                  entry.averageRating > 0
                      ? entry.averageRating.toStringAsFixed(1)
                      : '-',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ]),
            ],
          ),
        ]),
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────
  Widget _emptyState(bool isDark) {
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textLt  = isDark ? AppColors.darkTextLight     : AppColors.textLight;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(children: [
          Icon(Icons.leaderboard_outlined, size: 56, color: textLt),
          const SizedBox(height: 16),
          Text(
            'No results for this skill',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textSec,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try selecting a different skill category.',
            style: GoogleFonts.dmSans(fontSize: 13, color: textLt),
          ),
        ]),
      ),
    );
  }
}

// Navigation proxy — avoids circular import with user_profile_screen

class _UserProfileRoute extends StatelessWidget {
  final String userId;
  const _UserProfileRoute({required this.userId});
  @override
  Widget build(BuildContext context) =>
      profile_screen.UserProfileScreen(userId: userId);
}