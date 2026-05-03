// File: lib/screens/explore/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../../models/post_model.dart';
import '../../services/notification_service.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/shimmer_card.dart';
import '../notifications/notifications_screen.dart';
import '../posts/post_detail_screen.dart';
import '../../widgets/filter_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ExploreScreen
// ─────────────────────────────────────────────────────────────────────────────
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchCtrl  = TextEditingController();
  final _scrollCtrl  = ScrollController();
  int  _selectedCat  = 0;
  bool _isSearching  = false;
  bool _searchActive = false;

  static const _categories = [
    _Cat('All',      Icons.apps_rounded,                   null),
    _Cat('Skills',   Icons.code_rounded,                   'barter'),
    _Cat('Services', Icons.miscellaneous_services_rounded, null),
    _Cat('Barter',   Icons.swap_horiz_rounded,             'barter'),
    _Cat('Money',    Icons.attach_money_rounded,           'custom'),
    _Cat('Treats',   Icons.card_giftcard_rounded,          'custom'),
  ];

  static const _trendingSkills = [
    _Skill('UI/UX Design',    Icons.design_services_rounded),
    _Skill('Video Editing',   Icons.video_camera_back_rounded),
    _Skill('Photography',     Icons.camera_alt_rounded),
    _Skill('Public Speaking', Icons.mic_rounded),
    _Skill('Excel',           Icons.table_chart_rounded),
    _Skill('Python',          Icons.code_rounded),
    _Skill('Music',           Icons.music_note_rounded),
    _Skill('Writing',         Icons.edit_rounded),
  ];

  List<PostModel> _popularPosts  = [];
  List<PostModel> _nearbyPosts   = [];
  List<PostModel> _filteredPosts = [];
  bool _loadingPopular = false;
  bool _loadingNearby  = false;
  PostFilter _filter = const PostFilter(skillType: SkillType.all);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    _loadPopular();
    _loadNearby();
  }

  Future<void> _loadPopular() async {
    setState(() => _loadingPopular = true);
    final ps = context.read<PostService>();
    await ps.fetchPosts();
    if (mounted) {
      setState(() {
        _popularPosts   = ps.posts.applyFilter(_filter).take(6).toList();
        _loadingPopular = false;
      });
    }
  }

  Future<void> _loadNearby() async {
    setState(() => _loadingNearby = true);
    final ps = context.read<PostService>();
    await ps.fetchPosts();
    if (mounted) {
      setState(() {
        _nearbyPosts   = ps.posts.applyFilter(_filter).reversed.take(8).toList();
        _loadingNearby = false;
      });
    }
  }

  void _onCategoryTap(int idx) {
    HapticFeedback.selectionClick();
    setState(() => _selectedCat = idx);
    final cat = _categories[idx];
    if (_searchActive) {
      _runSearch(_searchCtrl.text, exchangeType: cat.filterValue);
    } else {
      context.read<PostService>().fetchPosts(exchangeType: cat.filterValue).then((_) {
        if (mounted) {
          setState(() {
            _popularPosts = List.from(context.read<PostService>().posts.take(6));
          });
        }
      });
    }
  }

  void _onSearchChanged(String q) {
    setState(() => _searchActive = q.isNotEmpty);
    if (q.isEmpty) { setState(() => _filteredPosts = []); return; }
    _runSearch(q, exchangeType: _categories[_selectedCat].filterValue);
  }

  Future<void> _runSearch(String q, {String? exchangeType}) async {
    setState(() => _isSearching = true);
    final ps = context.read<PostService>();
    await ps.fetchPosts(
      searchQuery: q.isEmpty ? null : q,
      exchangeType: exchangeType,
    );
    if (mounted) {
      setState(() {
        _filteredPosts = List.from(ps.posts);
        _isSearching   = false;
      });
    }
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() { _searchActive = false; _filteredPosts = []; });
  }

  void _onTrendingTap(_Skill skill) {
    _searchCtrl.text = skill.label;
    setState(() => _searchActive = true);
    _runSearch(skill.label);
  }

  void _onFilterChanged(PostFilter f) {
    setState(() => _filter = f);
    // Re-fetch with Supabase params then apply client-side
    final cat = _categories[_selectedCat];
    context.read<PostService>().fetchPosts(
      searchQuery: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
      exchangeType: f.exchangeType ?? cat.filterValue,
      openRequestsOnly: f.openOnly,
      ascending: f.sortOrder == SortOrder.oldest,
    ).then((_) {
      if (!mounted) return;
      final ps = context.read<PostService>();
      final filtered = ps.posts.applyFilter(f);
      setState(() {
        _popularPosts  = filtered.take(6).toList();
        _nearbyPosts   = filtered.reversed.take(8).toList();
        if (_searchActive) _filteredPosts = filtered;
      });
    });
  }

  void _goToPopularAll() => Navigator.push(context, MaterialPageRoute(
    builder: (_) => _SeeAllScreen(title: 'Popular This Week 🔥', posts: _popularPosts),
  ));

  void _goToNearbyAll() => Navigator.push(context, MaterialPageRoute(
    builder: (_) => _NearbyAllScreen(posts: _nearbyPosts),
  ));

  void _goToTrendingAll() => Navigator.push(context, MaterialPageRoute(
    builder: (_) => _TrendingAllScreen(
      skills: _trendingSkills.toList(),
      onSkillTap: (skill) { Navigator.pop(context); _onTrendingTap(skill); },
    ),
  ));

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Color _bg(bool d)         => d ? AppColors.darkBackground    : AppColors.surface;
  Color _cardBg(bool d)     => d ? AppColors.darkCardBg        : Colors.white;
  Color _border(bool d)     => d ? AppColors.darkBorder        : const Color(0xFFF0F0F0);
  Color _searchBg(bool d)   => d ? AppColors.darkSearchBg      : const Color(0xFFF3F3F3);
  Color _textPri(bool d)    => d ? AppColors.darkTextPrimary   : const Color(0xFF1A1A1A);
  Color _textSec(bool d)    => d ? AppColors.darkTextSecondary : const Color(0xFF6B7280);
  Color _textLt(bool d)     => d ? AppColors.darkTextLight     : const Color(0xFF9CA3AF);
  Color _primary(bool d)    => d ? AppColors.darkPrimary       : AppColors.primary;
  Color _chipBg(bool d)     => d ? AppColors.darkSurfaceVariant: const Color(0xFFF3F4F6);
  Color _chipBorder(bool d) => d ? AppColors.darkBorder        : const Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: CustomScrollView(
        controller: _scrollCtrl,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(isDark),

          SliverToBoxAdapter(
            child: _SearchBar(
              controller: _searchCtrl,
              isDark: isDark,
              searchBg: _searchBg(isDark),
              textPri: _textPri(isDark),
              hintColor: _textLt(isDark),
              iconColor: _textSec(isDark),
              isSearching: _isSearching,
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
              filterButton: FilterButton(
                filter: _filter,
                isDark: isDark,
                onChanged: _onFilterChanged,
              ),
            ).animate().fadeIn(delay: 60.ms),
          ),

          SliverToBoxAdapter(
            child: _CategoryRow(
              selected: _selectedCat,
              isDark: isDark,
              categories: _categories,
              primary: _primary(isDark),
              textSec: _textSec(isDark),
              chipBg: _chipBg(isDark),
              onTap: _onCategoryTap,
            ).animate().fadeIn(delay: 100.ms),
          ),

          if (_searchActive) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                child: Text(
                  _isSearching ? 'Searching...' : '${_filteredPosts.length} results',
                  style: GoogleFonts.dmSans(color: _textSec(isDark), fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            if (_isSearching)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ShimmerCard(),
                  ),
                  childCount: 3,
                ),
              )
            else if (_filteredPosts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 56, color: _textLt(isDark)),
                      const SizedBox(height: 12),
                      Text('No results found',
                          style: GoogleFonts.dmSans(color: _textSec(isDark), fontSize: 15)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _SearchResultTile(
                      post: _filteredPosts[i],
                      isDark: isDark,
                      cardBg: _cardBg(isDark),
                      border: _border(isDark),
                      textPri: _textPri(isDark),
                      textSec: _textSec(isDark),
                      textLt: _textLt(isDark),
                      primary: _primary(isDark),
                    ).animate().fadeIn(delay: Duration(milliseconds: i * 40)),
                    childCount: _filteredPosts.length,
                  ),
                ),
              ),
          ] else ...[
            // ── Popular This Week ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Popular This Week 🔥',
                isDark: isDark,
                textPri: _textPri(isDark),
                primary: _primary(isDark),
                onSeeAll: _goToPopularAll,
              ),
            ),
            SliverToBoxAdapter(
              child: _loadingPopular
                  ? _shimmerRow(isDark)
                  : _PopularCardRow(
                      posts: _popularPosts,
                      isDark: isDark,
                      cardBg: _cardBg(isDark),
                      border: _border(isDark),
                      textPri: _textPri(isDark),
                      textSec: _textSec(isDark),
                      textLt: _textLt(isDark),
                    ),
            ),

            // ── Trending Skills ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Trending Skills',
                isDark: isDark,
                textPri: _textPri(isDark),
                primary: _primary(isDark),
                onSeeAll: _goToTrendingAll,
              ),
            ),
            SliverToBoxAdapter(
              child: _TrendingSkillsRow(
                skills: _trendingSkills,
                isDark: isDark,
                chipBg: _chipBg(isDark),
                chipBorder: _chipBorder(isDark),
                textPri: _textPri(isDark),
                textSec: _textSec(isDark),
                primary: _primary(isDark),
                onTap: _onTrendingTap,
              ).animate().fadeIn(delay: 180.ms),
            ),

            // ── Nearby Swaps ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Nearby Swaps',
                isDark: isDark,
                textPri: _textPri(isDark),
                primary: _primary(isDark),
                onSeeAll: _goToNearbyAll,
              ),
            ),

            if (_loadingNearby)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: _NearbySwapTileShimmer(isDark: isDark),
                  ),
                  childCount: 3,
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _NearbySwapTile(
                    post: _nearbyPosts[i],
                    isDark: isDark,
                    cardBg: _cardBg(isDark),
                    border: _border(isDark),
                    textPri: _textPri(isDark),
                    textSec: _textSec(isDark),
                    textLt: _textLt(isDark),
                    primary: _primary(isDark),
                    distanceKm: 0.5 + i * 0.7,
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: i * 50))
                      .slideX(begin: 0.03),
                  childCount: _nearbyPosts.length,
                ),
              ),

            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.bottom + 90),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    final appBarBg = isDark ? AppColors.darkBackground : Colors.white;
    final textPri  = _textPri(isDark);
    final textSec  = _textSec(isDark);
    final divColor = isDark ? AppColors.darkBorder : const Color(0xFFF0F0F0);
    final primary  = _primary(isDark);

    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 90,
      backgroundColor: appBarBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: divColor),
      ),
      actions: [
        Consumer<NotificationService>(
          builder: (_, ns, __) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: badges.Badge(
              showBadge: ns.unreadCount > 0,
              badgeContent: Text(
                ns.unreadCount > 9 ? '9+' : '${ns.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
              ),
              badgeStyle: badges.BadgeStyle(badgeColor: primary, padding: const EdgeInsets.all(4)),
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                child: Icon(Icons.notifications_outlined, color: textPri, size: 24),
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          color: appBarBg,
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Explore',
                  style: GoogleFonts.dmSans(
                      color: textPri, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text('Find skills, services or anything of value ✨',
                  style: GoogleFonts.dmSans(color: textSec, fontSize: 12, fontWeight: FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerRow(bool isDark) {
    return SizedBox(
      height: 168,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          width: 148,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(color: _chipBg(isDark), borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Public See-All screens (reusable from Home page)
// ─────────────────────────────────────────────────────────────────────────────

class PopularSeeAllScreen extends StatelessWidget {
  final String title;
  final List<PostModel> posts;
  const PopularSeeAllScreen({super.key, this.title = 'Popular This Week 🔥', required this.posts});

  @override
  Widget build(BuildContext context) => _SeeAllScreen(title: title, posts: posts);
}

class NearbySeeAllScreen extends StatelessWidget {
  final List<PostModel> posts;
  const NearbySeeAllScreen({super.key, required this.posts});

  @override
  Widget build(BuildContext context) => _NearbyAllScreen(posts: posts);
}

// ─────────────────────────────────────────────────────────────────────────────
//  _SeeAllScreen — Popular grid, fixed spacing, responsive layout
// ─────────────────────────────────────────────────────────────────────────────
class _SeeAllScreen extends StatefulWidget {
  final String title;
  final List<PostModel> posts;
  const _SeeAllScreen({required this.title, required this.posts});

  @override
  State<_SeeAllScreen> createState() => _SeeAllScreenState();
}

class _SeeAllScreenState extends State<_SeeAllScreen> {
  PostFilter _filter = const PostFilter();

  static _PillStyle _ps(String type, bool isDark) {
    if (isDark) {
      switch (type) {
        case 'barter': return _PillStyle(AppColors.darkTagSkillBg,  AppColors.darkTagSkillText,  'Barter');
        case 'custom': return _PillStyle(AppColors.darkTagMoneyBg,  AppColors.darkTagMoneyText,  'Money');
        default:       return _PillStyle(AppColors.darkTagStudyBg,  AppColors.darkTagStudyText,  'Treats');
      }
    } else {
      switch (type) {
        case 'barter': return _PillStyle(const Color(0xFFEDE9FE), const Color(0xFF5B4FE8), 'Barter');
        case 'custom': return _PillStyle(const Color(0xFFD1FAE5), const Color(0xFF059669), 'Money');
        default:       return _PillStyle(const Color(0xFFFEF3C7), const Color(0xFFD97706), 'Treats');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? AppColors.darkBackground    : const Color(0xFFF8F8F8);
    final appBg   = isDark ? AppColors.darkBackground    : Colors.white;
    final textPri = isDark ? AppColors.darkTextPrimary   : const Color(0xFF1A1A1A);
    final textSec = isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280);
    final textLt  = isDark ? AppColors.darkTextLight     : const Color(0xFF9CA3AF);
    final cardBg  = isDark ? AppColors.darkCardBg        : Colors.white;
    final border  = isDark ? AppColors.darkBorder        : const Color(0xFFF0F0F0);
    final divider = isDark ? AppColors.darkBorder        : const Color(0xFFF0F0F0);
    final primary = isDark ? AppColors.darkPrimary       : AppColors.primary;
    final displayPosts = widget.posts.applyFilter(_filter);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: appBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPri, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title,
            style: GoogleFonts.dmSans(color: textPri, fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterButton(
              filter: _filter,
              isDark: isDark,
              onChanged: (f) => setState(() => _filter = f),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: divider),
        ),
      ),
      body: displayPosts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 56, color: textLt),
                  const SizedBox(height: 12),
                  Text('No posts yet', style: GoogleFonts.dmSans(color: textSec, fontSize: 15)),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (_, constraints) {
                // Responsive: use screen width to compute exact card size
                // so there's NEVER empty vertical space inside cards.
                final screenW = constraints.maxWidth;
                final cols    = screenW > 900 ? 3 : 2;
                final spacing = 12.0;
                final padding = 16.0;
                final cardW   = (screenW - padding * 2 - spacing * (cols - 1)) / cols;
                // Card height = fixed content: offer(14) + for(14) + title(40) +
                //   gap(6) + avatar row(20) + gap(5) + rating(16) + gap(8) + pill(22) + padding(24)
                // ≈ 169px — use a tight fixed height, no Spacer()
                const cardH = 172.0;

                return GridView.builder(
                  padding: EdgeInsets.all(padding),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: cardW / cardH,
                  ),
                  itemCount: displayPosts.length,
                  itemBuilder: (_, i) {
                    final post  = displayPosts[i];
                    final pill  = _SeeAllScreenState._ps(post.exchangeType, isDark);
                    final offer = post.exchangeType == 'barter'
                        ? post.skillOffered
                        : (post.customOffer ?? post.skillOffered);

                    return GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border, width: 1),
                          boxShadow: isDark
                              ? null
                              : [BoxShadow(color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // offer label
                            Text(offer,
                                style: GoogleFonts.dmSans(
                                    fontSize: 10, color: textSec, fontWeight: FontWeight.w500),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('for', style: GoogleFonts.dmSans(fontSize: 10, color: textLt)),
                            const SizedBox(height: 2),
                            // title
                            Text(post.title,
                                style: GoogleFonts.dmSans(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: textPri, height: 1.3),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            // avatar + username
                            Row(children: [
                              AvatarWidget(
                                  avatarUrl: post.profile?.avatarUrl,
                                  username: post.profile?.username ?? '',
                                  radius: 9),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(post.profile?.username ?? 'User',
                                    style: GoogleFonts.dmSans(fontSize: 10, color: textSec),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            // rating
                            Row(children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFACC15), size: 12),
                              const SizedBox(width: 2),
                              Text(
                                (post.profile?.averageRating ?? 0.0).toStringAsFixed(1),
                                style: GoogleFonts.dmSans(
                                    fontSize: 11, fontWeight: FontWeight.w600, color: textPri),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            // pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: pill.bg, borderRadius: BorderRadius.circular(20)),
                              child: Text(pill.label,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 9.5, fontWeight: FontWeight.w700, color: pill.text)),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: Duration(milliseconds: i * 35));
                  },
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _NearbyAllScreen — compact list, no wasted space
// ─────────────────────────────────────────────────────────────────────────────
class _NearbyAllScreen extends StatelessWidget {
  final List<PostModel> posts;
  const _NearbyAllScreen({required this.posts});

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? AppColors.darkBackground    : const Color(0xFFF8F8F8);
    final appBg   = isDark ? AppColors.darkBackground    : Colors.white;
    final textPri = isDark ? AppColors.darkTextPrimary   : const Color(0xFF1A1A1A);
    final textSec = isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280);
    final textLt  = isDark ? AppColors.darkTextLight     : const Color(0xFF9CA3AF);
    final cardBg  = isDark ? AppColors.darkCardBg        : Colors.white;
    final border  = isDark ? AppColors.darkBorder        : const Color(0xFFF0F0F0);
    final divider = isDark ? AppColors.darkBorder        : const Color(0xFFF0F0F0);
    final primary = isDark ? AppColors.darkPrimary       : AppColors.primary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: appBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPri, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Nearby Swaps',
            style: GoogleFonts.dmSans(color: textPri, fontSize: 17, fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: divider),
        ),
      ),
      body: posts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_rounded, size: 56, color: textLt),
                  const SizedBox(height: 12),
                  Text('No nearby swaps yet',
                      style: GoogleFonts.dmSans(color: textSec, fontSize: 15)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              physics: const BouncingScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (_, i) => _NearbySwapTile(
                post: posts[i],
                isDark: isDark,
                cardBg: cardBg,
                border: border,
                textPri: textPri,
                textSec: textSec,
                textLt: textLt,
                primary: primary,
                distanceKm: 0.5 + i * 0.7,
              ).animate().fadeIn(delay: Duration(milliseconds: i * 40)),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _TrendingAllScreen — compact list rows, fixed height, no wasted space
// ─────────────────────────────────────────────────────────────────────────────
class _TrendingAllScreen extends StatelessWidget {
  final List<_Skill> skills;
  final ValueChanged<_Skill> onSkillTap;
  const _TrendingAllScreen({required this.skills, required this.onSkillTap});

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? AppColors.darkBackground    : const Color(0xFFF8F8F8);
    final appBg   = isDark ? AppColors.darkBackground    : Colors.white;
    final textPri = isDark ? AppColors.darkTextPrimary   : const Color(0xFF1A1A1A);
    final textSec = isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280);
    final chipBg  = isDark ? AppColors.darkSurfaceVariant: Colors.white;
    final chipBd  = isDark ? AppColors.darkBorder        : const Color(0xFFE5E7EB);
    final primary = isDark ? AppColors.darkPrimary       : AppColors.primary;
    final divider = isDark ? AppColors.darkBorder        : const Color(0xFFF0F0F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: appBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPri, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Trending Skills',
            style: GoogleFonts.dmSans(color: textPri, fontSize: 17, fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: divider),
        ),
      ),
      // ── Use ListView of 2-per-row instead of GridView ──────────────────
      body: LayoutBuilder(
        builder: (_, constraints) {
          final isWide = constraints.maxWidth > 600;
          // Wrap skills into rows of 2
          final rows = <List<_Skill>>[];
          for (var i = 0; i < skills.length; i += 2) {
            rows.add([
              skills[i],
              if (i + 1 < skills.length) skills[i + 1],
            ]);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            physics: const BouncingScrollPhysics(),
            itemCount: rows.length,
            itemBuilder: (_, ri) {
              final row = rows[ri];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: row.asMap().entries.map((e) {
                    final i     = ri * 2 + e.key;
                    final skill = e.value;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: e.key == 0 && row.length > 1 ? 5 : 0),
                        child: GestureDetector(
                          onTap: () => onSkillTap(skill),
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: chipBd, width: 1),
                              boxShadow: isDark
                                  ? null
                                  : [BoxShadow(color: Colors.black.withOpacity(0.04),
                                        blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: Row(children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(isDark ? 0.2 : 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(skill.icon, size: 17, color: primary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(skill.label,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 13, fontWeight: FontWeight.w600, color: textPri),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: textSec),
                            ]),
                          ),
                        ).animate().fadeIn(delay: Duration(milliseconds: i * 40)),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Data classes
// ─────────────────────────────────────────────────────────────────────────────
class _Cat {
  final String label;
  final IconData icon;
  final String? filterValue;
  const _Cat(this.label, this.icon, this.filterValue);
}

class _Skill {
  final String label;
  final IconData icon;
  const _Skill(this.label, this.icon);
}

class _PillStyle {
  final Color bg, text;
  final String label;
  const _PillStyle(this.bg, this.text, this.label);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Search Bar
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark, isSearching;
  final Color searchBg, textPri, hintColor, iconColor;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final Widget filterButton;

  const _SearchBar({
    required this.controller,   required this.isDark,
    required this.searchBg,     required this.textPri,
    required this.hintColor,    required this.iconColor,
    required this.isSearching,  required this.onChanged,
    required this.onClear,      required this.filterButton,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(color: searchBg, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.dmSans(color: textPri, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search skills, services or people...',
                hintStyle: GoogleFonts.dmSans(color: hintColor, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: iconColor, size: 20),
                suffixIcon: controller.text.isNotEmpty
                    ? GestureDetector(
                        onTap: onClear,
                        child: Icon(Icons.close_rounded, color: iconColor, size: 18))
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        filterButton,
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Category Row
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryRow extends StatelessWidget {
  final int selected;
  final bool isDark;
  final List<_Cat> categories;
  final Color primary, textSec, chipBg;
  final ValueChanged<int> onTap;

  const _CategoryRow({
    required this.selected, required this.isDark, required this.categories,
    required this.primary,  required this.textSec, required this.chipBg,
    required this.onTap,
  });

  static const _bgLight = [
    Color(0xFFEEF2FF), Color(0xFFEEF2FF), Color(0xFFE8FFF5),
    Color(0xFFFFF8E6), Color(0xFFE8F5E9), Color(0xFFFCE4EC),
  ];
  static const _bgDark = [
    Color(0xFF2D1B69), Color(0xFF2D1B69), Color(0xFF134E4A),
    Color(0xFF78350F), Color(0xFF14532D), Color(0xFF831843),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final cat      = categories[i];
          final isActive = selected == i;
          final bg       = isDark ? _bgDark[i] : _bgLight[i];
          return GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              width: 58,
              margin: const EdgeInsets.only(right: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: isActive ? bg : chipBg,
                      borderRadius: BorderRadius.circular(14),
                      border: isActive
                          ? Border.all(color: primary.withOpacity(0.4), width: 1.5)
                          : null,
                    ),
                    child: Icon(cat.icon, size: 20, color: isActive ? primary : textSec),
                  ),
                  const SizedBox(height: 4),
                  Text(cat.label,
                      style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? primary : textSec),
                      textAlign: TextAlign.center,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Section Header — hover underline on "See all"
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatefulWidget {
  final String title;
  final bool isDark;
  final Color textPri, primary;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,   required this.isDark,
    required this.textPri, required this.primary, required this.onSeeAll,
  });

  @override
  State<_SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<_SectionHeader> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.title,
              style: GoogleFonts.dmSans(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: widget.textPri, letterSpacing: -0.3)),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit:  (_) => setState(() => _hovered = false),
            child: GestureDetector(
              onTap: widget.onSeeAll,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _hovered ? widget.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Text('See all',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w600, color: widget.primary)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Popular This Week — horizontal card row (Explore main screen)
// ─────────────────────────────────────────────────────────────────────────────
class _PopularCardRow extends StatelessWidget {
  final List<PostModel> posts;
  final bool isDark;
  final Color cardBg, border, textPri, textSec, textLt;

  const _PopularCardRow({
    required this.posts,   required this.isDark,
    required this.cardBg,  required this.border,
    required this.textPri, required this.textSec, required this.textLt,
  });

  _PillStyle _pill(String type) {
    if (isDark) {
      switch (type) {
        case 'barter': return _PillStyle(AppColors.darkTagSkillBg, AppColors.darkTagSkillText, 'Barter');
        case 'custom': return _PillStyle(AppColors.darkTagMoneyBg, AppColors.darkTagMoneyText, 'Money');
        default:       return _PillStyle(AppColors.darkTagStudyBg, AppColors.darkTagStudyText, 'Treats');
      }
    } else {
      switch (type) {
        case 'barter': return _PillStyle(const Color(0xFFEDE9FE), const Color(0xFF5B4FE8), 'Barter');
        case 'custom': return _PillStyle(const Color(0xFFD1FAE5), const Color(0xFF059669), 'Money');
        default:       return _PillStyle(const Color(0xFFFEF3C7), const Color(0xFFD97706), 'Treats');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return const SizedBox(height: 168);
    return SizedBox(
      height: 168,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        itemCount: posts.length,
        itemBuilder: (_, i) {
          final post  = posts[i];
          final pill  = _pill(post.exchangeType);
          final offer = post.exchangeType == 'barter'
              ? post.skillOffered
              : (post.customOffer ?? post.skillOffered);

          return GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
            child: Container(
              width: 148,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border, width: 1),
                boxShadow: isDark
                    ? null
                    : [BoxShadow(color: Colors.black.withOpacity(0.05),
                          blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(offer,
                      style: GoogleFonts.dmSans(fontSize: 10, color: textSec, fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('for', style: GoogleFonts.dmSans(fontSize: 10, color: textLt)),
                  const SizedBox(height: 2),
                  Text(post.title,
                      style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700,
                          color: textPri, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    AvatarWidget(avatarUrl: post.profile?.avatarUrl,
                        username: post.profile?.username ?? '', radius: 9),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(post.profile?.username ?? 'User',
                          style: GoogleFonts.dmSans(fontSize: 10, color: textSec),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const SizedBox(height: 5),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFACC15), size: 12),
                    const SizedBox(width: 2),
                    Text((post.profile?.averageRating ?? 0.0).toStringAsFixed(1),
                        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: textPri)),
                  ]),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: pill.bg, borderRadius: BorderRadius.circular(20)),
                    child: Text(pill.label,
                        style: GoogleFonts.dmSans(fontSize: 9.5, fontWeight: FontWeight.w700, color: pill.text)),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: i * 55)),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Trending Skills Row (Explore main screen)
// ─────────────────────────────────────────────────────────────────────────────
class _TrendingSkillsRow extends StatelessWidget {
  final List<_Skill> skills;
  final bool isDark;
  final Color chipBg, chipBorder, textPri, textSec, primary;
  final ValueChanged<_Skill> onTap;

  const _TrendingSkillsRow({
    required this.skills,     required this.isDark,
    required this.chipBg,     required this.chipBorder,
    required this.textPri,    required this.textSec,
    required this.primary,    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        itemCount: skills.length,
        itemBuilder: (_, i) {
          final skill = skills[i];
          return GestureDetector(
            onTap: () => onTap(skill),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: chipBorder, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(skill.icon, size: 15, color: primary),
                  const SizedBox(width: 6),
                  Text(skill.label,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, fontWeight: FontWeight.w600, color: textPri)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Nearby Swap Tile
// ─────────────────────────────────────────────────────────────────────────────
class _NearbySwapTile extends StatelessWidget {
  final PostModel post;
  final bool isDark;
  final Color cardBg, border, textPri, textSec, textLt, primary;
  final double distanceKm;

  const _NearbySwapTile({
    required this.post,    required this.isDark,
    required this.cardBg,  required this.border,
    required this.textPri, required this.textSec,
    required this.textLt,  required this.primary,
    required this.distanceKm,
  });

  _PillStyle _pill() {
    if (isDark) {
      switch (post.exchangeType) {
        case 'barter': return _PillStyle(AppColors.darkTagSkillBg,   AppColors.darkTagSkillText,   'Barter');
        case 'custom': return _PillStyle(AppColors.darkTagMoneyBg,   AppColors.darkTagMoneyText,   'Money');
        default:       return _PillStyle(AppColors.darkTagTreatsBg,  AppColors.darkTagTreatsText,  'Treats');
      }
    } else {
      switch (post.exchangeType) {
        case 'barter': return _PillStyle(const Color(0xFFEDE9FE), const Color(0xFF5B4FE8), 'Barter');
        case 'custom': return _PillStyle(const Color(0xFFD1FAE5), const Color(0xFF059669), 'Money');
        default:       return _PillStyle(const Color(0xFFFEF3C7), const Color(0xFFD97706), 'Treats');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pill = _pill();
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1),
          boxShadow: isDark
              ? null
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          AvatarWidget(avatarUrl: post.profile?.avatarUrl, username: post.profile?.username ?? '', radius: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title,
                    style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: textPri),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [
                  Text(post.profile?.username ?? 'User',
                      style: GoogleFonts.dmSans(fontSize: 11, color: textSec)),
                  Text(' · ', style: TextStyle(color: textLt, fontSize: 11)),
                  Icon(Icons.location_on_rounded, size: 10, color: textLt),
                  Text('${distanceKm.toStringAsFixed(1)} km',
                      style: GoogleFonts.dmSans(fontSize: 11, color: textLt)),
                ]),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: pill.bg, borderRadius: BorderRadius.circular(20)),
                child: Text(pill.label,
                    style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: pill.text)),
              ),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFACC15), size: 12),
                const SizedBox(width: 2),
                Text((post.profile?.averageRating ?? 0.0).toStringAsFixed(1),
                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: textPri)),
              ]),
            ],
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Nearby Swap Shimmer
// ─────────────────────────────────────────────────────────────────────────────
class _NearbySwapTileShimmer extends StatelessWidget {
  final bool isDark;
  const _NearbySwapTileShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? const Color(0xFF252540) : const Color(0xFFEEEEEE);
    return Container(
      height: 60,
      decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(12)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Search Result Tile
// ─────────────────────────────────────────────────────────────────────────────
class _SearchResultTile extends StatelessWidget {
  final PostModel post;
  final bool isDark;
  final Color cardBg, border, textPri, textSec, textLt, primary;

  const _SearchResultTile({
    required this.post,    required this.isDark,
    required this.cardBg,  required this.border,
    required this.textPri, required this.textSec,
    required this.textLt,  required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1),
          boxShadow: isDark
              ? null
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          AvatarWidget(avatarUrl: post.profile?.avatarUrl, username: post.profile?.username ?? '', radius: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title,
                    style: GoogleFonts.dmSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: textPri),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(post.profile?.username ?? 'User',
                    style: GoogleFonts.dmSans(fontSize: 11, color: textSec)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded, size: 13, color: textLt),
        ]),
      ),
    );
  }
}