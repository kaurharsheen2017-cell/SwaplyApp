import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/chat_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/post_card.dart';
import '../../widgets/shimmer_card.dart';
import '../auth/login_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ProfileScreen  — user profile with tabs + Settings entry point
//  All colours resolved from Theme.of(context) — light + dark aware.
// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SwapModel> _swaps = [];
  List<RatingModel> _ratings = [];
  bool _loadingExtra = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthService>();
      if (auth.currentUser != null) {
        context.read<PostService>().fetchBookmarkedPosts();
        _loadExtra(auth.currentUser!.id);
      }
    });
  }

  Future<void> _loadExtra(String userId) async {
    setState(() => _loadingExtra = true);
    final chatService = context.read<ChatService>();
    _swaps = await chatService.fetchUserSwaps();
    _ratings = await chatService.fetchUserRatings(userId);
    if (mounted) setState(() => _loadingExtra = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final auth     = context.watch<AuthService>();
    final profile  = auth.currentProfile;

    // Theme-resolved colours used across the whole screen
    final tabBg    = isDark ? AppColors.darkSurface    : AppColors.background;
    final tabLabel = isDark ? AppColors.darkPrimary    : AppColors.primaryLight;
    final tabUnsel = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 310,
            // Actions: leaderboard + edit + settings + logout
            actions: [
              IconButton(
                icon: const Icon(Icons.leaderboard_rounded, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ).then((_) => auth.fetchProfile()),
              ),
              // ── Settings button (new) ────────────────────────────────
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () async {
                  await auth.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (r) => false,
                    );
                  }
                },
              ),
            ],
            // ── Hero header (gradient — unchanged from original) ─────────
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 52),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AvatarWidget(
                          avatarUrl: profile?.avatarUrl,
                          username: profile?.username ?? '',
                          radius: 44,
                          borderColor: Colors.white,
                        ).animate().scale(curve: Curves.elasticOut),
                        const SizedBox(height: 12),
                        Text(
                          profile?.fullName ?? profile?.username ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '@${profile?.username ?? ''}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                        if (profile?.campus != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: Colors.white.withOpacity(0.7),
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                profile!.campus!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (profile?.badges != null &&
                            profile!.badges.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: profile.badges
                                .map(
                                  (b) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color:
                                              Colors.amber.withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      b,
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _statItem(
                                '${profile?.totalSwaps ?? 0}', 'Swaps'),
                            _divider(),
                            _ratingStatItem(
                              profile?.averageRating ?? 0.0,
                              profile?.ratingCount ?? 0,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // ── Tab bar ──────────────────────────────────────────────────
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: tabBg,
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Posts'),
                    Tab(text: 'Bookmarks'),
                    Tab(text: 'History'),
                    Tab(text: 'Analytics'),
                  ],
                  labelColor: tabLabel,
                  unselectedLabelColor: tabUnsel,
                  indicatorColor: tabLabel,
                  labelStyle: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _PostsTab(userId: auth.currentUser?.id ?? ''),
            _BookmarksTab(),
            _HistoryTab(
              swaps: _swaps,
              ratings: _ratings,
              isLoading: _loadingExtra,
            ),
            _AnalyticsTab(
              swaps: _swaps,
              ratings: _ratings,
              isLoading: _loadingExtra,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _ratingStatItem(double rating, int count) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
            const SizedBox(width: 3),
            Text(
              rating > 0 ? rating.toStringAsFixed(1) : '-',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          '$count ratings',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      width: 1,
      height: 36,
      color: Colors.white.withOpacity(0.3),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Posts Tab
// ─────────────────────────────────────────────────────────────────────────────
class _PostsTab extends StatefulWidget {
  final String userId;
  const _PostsTab({required this.userId});

  @override
  State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> {
  List _posts = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    _posts = await context.read<PostService>().fetchUserPosts(widget.userId);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final textSec  = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textLt   = isDark ? AppColors.darkTextLight     : AppColors.textLight;

    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: 4,
        itemBuilder: (_, __) => const ShimmerCard(),
      );
    }
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add_rounded, size: 60, color: textLt),
            const SizedBox(height: 12),
            Text(
              'No posts yet',
              style: GoogleFonts.dmSans(color: textSec, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: _posts.length,
      itemBuilder: (_, i) => PostCard(post: _posts[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bookmarks Tab
// ─────────────────────────────────────────────────────────────────────────────
class _BookmarksTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textLt  = isDark ? AppColors.darkTextLight     : AppColors.textLight;

    return Consumer<PostService>(
      builder: (_, ps, __) {
        if (ps.bookmarkedPosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_outline_rounded, size: 60, color: textLt),
                const SizedBox(height: 12),
                Text(
                  'No bookmarks yet',
                  style: GoogleFonts.dmSans(color: textSec, fontSize: 14),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: ps.bookmarkedPosts.length,
          itemBuilder: (_, i) => PostCard(post: ps.bookmarkedPosts[i]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  History Tab
// ─────────────────────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  final List<SwapModel> swaps;
  final List<RatingModel> ratings;
  final bool isLoading;

  const _HistoryTab({
    required this.swaps,
    required this.ratings,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final textPri = isDark ? AppColors.darkTextPrimary   : AppColors.textPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textLt  = isDark ? AppColors.darkTextLight     : AppColors.textLight;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (swaps.isEmpty && ratings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 60, color: textLt),
            const SizedBox(height: 12),
            Text(
              'No swap history yet',
              style: GoogleFonts.dmSans(color: textSec, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        if (swaps.isNotEmpty) ...[
          Text(
            'Swaps',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: textPri,
            ),
          ),
          const SizedBox(height: 10),
          ...swaps.map((s) => _SwapHistoryCard(swap: s, isDark: isDark)),
          const SizedBox(height: 20),
        ],
        if (ratings.isNotEmpty) ...[
          Text(
            'Ratings Received',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: textPri,
            ),
          ),
          const SizedBox(height: 10),
          ...ratings.map((r) => _RatingCard(rating: r, isDark: isDark)),
        ],
      ],
    );
  }
}

class _SwapHistoryCard extends StatelessWidget {
  final SwapModel swap;
  final bool isDark;
  const _SwapHistoryCard({required this.swap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg  = isDark ? AppColors.darkCardBg        : Colors.white;
    final border  = isDark ? AppColors.darkBorder        : Colors.transparent;
    final textPri = isDark ? AppColors.darkTextPrimary   : AppColors.textPrimary;
    final textLt  = isDark ? AppColors.darkTextLight     : AppColors.textLight;

    Color statusColor = AppColors.warning;
    if (swap.status == 'completed') statusColor = AppColors.success;
    if (swap.status == 'cancelled') statusColor = AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(isDark ? 0.18 : 0.10),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.swap_horiz_rounded, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Swap ${swap.id.substring(0, 8)}...',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w500,
                    color: textPri,
                  ),
                ),
                Text(
                  swap.createdAt.toString().substring(0, 10),
                  style: GoogleFonts.dmSans(
                    color: textLt,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              swap.status.toUpperCase(),
              style: GoogleFonts.dmSans(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  final RatingModel rating;
  final bool isDark;
  const _RatingCard({required this.rating, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg  = isDark ? AppColors.darkCardBg        : Colors.white;
    final border  = isDark ? AppColors.darkBorder        : Colors.transparent;
    final textPri = isDark ? AppColors.darkTextPrimary   : AppColors.textPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textLt  = isDark ? AppColors.darkTextLight     : AppColors.textLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(
                avatarUrl: rating.rater?.avatarUrl,
                username: rating.rater?.username ?? '',
                radius: 16,
              ),
              const SizedBox(width: 8),
              Text(
                rating.rater?.fullName ?? rating.rater?.username ?? 'User',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: textPri,
                ),
              ),
              const Spacer(),
              RatingBarIndicator(
                rating: rating.rating.toDouble(),
                itemBuilder: (_, __) =>
                    const Icon(Icons.star_rounded, color: AppColors.warning),
                itemCount: 5,
                itemSize: 16,
              ),
            ],
          ),
          if (rating.review != null && rating.review!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rating.review!,
              style: GoogleFonts.dmSans(
                color: textSec,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            rating.createdAt.toString().substring(0, 10),
            style: GoogleFonts.dmSans(color: textLt, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Analytics Tab
// ─────────────────────────────────────────────────────────────────────────────
class _AnalyticsTab extends StatelessWidget {
  final List<SwapModel> swaps;
  final List<RatingModel> ratings;
  final bool isLoading;

  const _AnalyticsTab({
    required this.swaps,
    required this.ratings,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final textPri = isDark ? AppColors.darkTextPrimary   : AppColors.textPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardBg  = isDark ? AppColors.darkCardBg        : Colors.white;
    final border  = isDark ? AppColors.darkBorder        : Colors.transparent;

    if (isLoading) return const Center(child: CircularProgressIndicator());

    final completedSwaps =
        swaps.where((s) => s.status == 'completed').length;
    double avgRating = 0;
    if (ratings.isNotEmpty) {
      avgRating =
          ratings.fold(0.0, (sum, r) => sum + r.rating) / ratings.length;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPri,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Completed Swaps',
                  value: completedSwaps.toString(),
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                  cardBg: cardBg,
                  border: border,
                  textPri: textPri,
                  textSec: textSec,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Avg Rating',
                  value: avgRating > 0
                      ? avgRating.toStringAsFixed(1)
                      : '-',
                  icon: Icons.star_outline,
                  color: AppColors.warning,
                  cardBg: cardBg,
                  border: border,
                  textPri: textPri,
                  textSec: textSec,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Recent Ratings Trend',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPri,
            ),
          ),
          const SizedBox(height: 12),
          _TrendChart(
            ratings: ratings,
            cardBg: cardBg,
            border: border,
            textPri: textPri,
            textSec: textSec,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color, cardBg, border, textPri, textSec;
  final bool isDark;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.cardBg,
    required this.border,
    required this.textPri,
    required this.textSec,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textPri,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.dmSans(
              color: textSec,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<RatingModel> ratings;
  final Color cardBg, border, textPri, textSec;
  final bool isDark;

  const _TrendChart({
    required this.ratings,
    required this.cardBg,
    required this.border,
    required this.textPri,
    required this.textSec,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (ratings.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1),
        ),
        child: Text(
          'No ratings yet for trend data',
          style: GoogleFonts.dmSans(color: textSec),
        ),
      );
    }

    final recentRatings = ratings.take(5).toList().reversed.toList();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: recentRatings.map((r) {
          final heightFactor = r.rating / 5.0;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                r.rating.toStringAsFixed(1),
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: textPri,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 30,
                height: 100 * heightFactor,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}