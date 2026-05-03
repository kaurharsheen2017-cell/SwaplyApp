// File: lib/screens/home/feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/chatbot_widget.dart';
import '../../widgets/filter_sheet.dart';
import '../explore/explore_screen.dart';
import '../notifications/notifications_screen.dart';
import '../posts/post_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int    _selectedCat     = 0;
  final  _searchCtrl      = TextEditingController();
  String _searchQuery     = '';
  final  _scrollCtrl      = ScrollController();
  bool   _headerCollapsed = false;
  PostFilter _filter      = const PostFilter();

  static const _categories = [
    _Category('All',      Icons.apps_rounded,                   null),
    _Category('Skills',   Icons.code_rounded,                   'barter'),
    _Category('Services', Icons.miscellaneous_services_rounded, null),
    _Category('Barter',   Icons.swap_horiz_rounded,             'barter'),
    _Category('Money',    Icons.attach_money_rounded,           'custom'),
    _Category('Treats',   Icons.card_giftcard_rounded,          'custom'),
    _Category('More',     Icons.more_horiz_rounded,             null),
  ];

  static const _catColorsLight = [
    Color(0xFFEDE9FE), Color(0xFFCCFBF1), Color(0xFFFEF3C7),
    Color(0xFFFFEDD5), Color(0xFFD1FAE5), Color(0xFFFCE7F3), Color(0xFFF3F4F6),
  ];
  static const _catColorsDark = [
    Color(0xFF2D1B69), Color(0xFF134E4A), Color(0xFF78350F),
    Color(0xFF7C2D12), Color(0xFF14532D), Color(0xFF831843), Color(0xFF1E1E30),
  ];
  static const _catIconColors = [
    Color(0xFF5B4FE8), Color(0xFF0D9488), Color(0xFFD97706),
    Color(0xFFEA580C), Color(0xFF16A34A), Color(0xFFDB2777), Color(0xFF6B7280),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostService>().fetchPosts();
    });
    _scrollCtrl.addListener(() {
      final collapsed = _scrollCtrl.offset > 8;
      if (collapsed != _headerCollapsed) setState(() => _headerCollapsed = collapsed);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onCategoryTap(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedCat = index);
    final cat = _categories[index];
    context.read<PostService>().fetchPosts(
      exchangeType:     _filter.exchangeType ?? cat.filterValue,
      searchQuery:      _searchQuery.isNotEmpty ? _searchQuery : null,
      openRequestsOnly: _filter.openOnly,
      ascending:        _filter.sortOrder == SortOrder.oldest,
    );
  }

  void _onSearch(String q) {
    setState(() => _searchQuery = q);
    final cat = _categories[_selectedCat];
    context.read<PostService>().fetchPosts(
      searchQuery:      q.isNotEmpty ? q : null,
      exchangeType:     _filter.exchangeType ?? cat.filterValue,
      openRequestsOnly: _filter.openOnly,
      ascending:        _filter.sortOrder == SortOrder.oldest,
    );
  }

  void _onFilterChanged(PostFilter f) {
    setState(() => _filter = f);
    final cat = _categories[_selectedCat];
    context.read<PostService>().fetchPosts(
      searchQuery:      _searchQuery.isNotEmpty ? _searchQuery : null,
      exchangeType:     f.exchangeType ?? cat.filterValue,
      openRequestsOnly: f.openOnly,
      ascending:        f.sortOrder == SortOrder.oldest,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final auth       = context.watch<AuthService>();
    final firstName  = auth.currentProfile?.fullName?.split(' ').first
        ?? auth.currentProfile?.username
        ?? 'there';
    final surfaceBg  = isDark ? AppColors.darkBackground : AppColors.surface;

    return Scaffold(
      backgroundColor: surfaceBg,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(isDark, firstName),

              // ── Search + Filter ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: _FeedSearchBar(
                  controller: _searchCtrl,
                  isDark: isDark,
                  filter: _filter,
                  onChanged: _onSearch,
                  onFilterChanged: _onFilterChanged,
                ).animate().fadeIn(delay: 80.ms),
              ),

              // ── Category pills ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: _CategoryRow(
                  selected: _selectedCat,
                  isDark: isDark,
                  onTap: _onCategoryTap,
                  categories: _categories,
                  catColorsLight: _catColorsLight,
                  catColorsDark: _catColorsDark,
                  catIconColors: _catIconColors,
                ).animate().fadeIn(delay: 130.ms),
              ),

              // ── Active filter chips row ──────────────────────────────────
              if (_filter.isActive)
                SliverToBoxAdapter(
                  child: _ActiveFilterRow(
                    filter: _filter,
                    isDark: isDark,
                    onClear: () => _onFilterChanged(const PostFilter()),
                  ),
                ),

              // ── Popular Listings ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Consumer<PostService>(
                  builder: (_, ps, __) => _SectionHeader(
                    title: 'Popular Listings',
                    onSeeAll: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => PopularSeeAllScreen(
                        title: 'Popular Listings',
                        posts: ps.posts.applyFilter(_filter),
                      ),
                    )),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Consumer<PostService>(
                  builder: (_, ps, __) {
                    final displayPosts = ps.posts.applyFilter(_filter);
                    return _ListingCardRow(
                      posts: displayPosts,
                      isLoading: ps.isLoading,
                      isDark: isDark,
                      onBookmark: (id) => ps.toggleBookmark(id),
                    );
                  },
                ),
              ),

              // ── Nearby Swaps ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Consumer<PostService>(
                  builder: (_, ps, __) => _SectionHeader(
                    title: 'Nearby Swaps',
                    onSeeAll: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => NearbySeeAllScreen(
                        posts: ps.posts.applyFilter(_filter).reversed.toList(),
                      ),
                    )),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Consumer<PostService>(
                  builder: (_, ps, __) {
                    final displayPosts =
                        ps.posts.applyFilter(_filter).reversed.toList();
                    return _NearbySwapRow(
                      posts: displayPosts,
                      isLoading: ps.isLoading,
                      isDark: isDark,
                    );
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 90),
              ),
            ],
          ),

          const Positioned(bottom: 20, right: 20, child: ChatbotFab()),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark, String firstName) {
    final surfaceColor = isDark ? AppColors.darkBackground : AppColors.surface;
    final dividerColor = isDark ? AppColors.darkDivider    : AppColors.divider;
    final textPri      = isDark ? AppColors.darkTextPrimary   : AppColors.textPrimary;
    final textSec      = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final primary      = isDark ? AppColors.darkPrimary       : AppColors.primary;

    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 110,
      backgroundColor: surfaceColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      title: AnimatedOpacity(
        opacity: _headerCollapsed ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 180),
        child: Text('Swaply',
            style: GoogleFonts.dmSans(
                color: textPri, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 1,
          color: _headerCollapsed ? dividerColor : Colors.transparent,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.help_outline_rounded, color: textPri, size: 22),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ExploreScreen())),
        ),
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: textPri, size: 22),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 80, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(children: [
                  Text('Hey, ',
                      style: GoogleFonts.dmSans(
                          color: textPri, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                  Text('$firstName 👋',
                      style: GoogleFonts.dmSans(
                          color: primary, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                ]),
                const SizedBox(height: 2),
                Text('What do you want to exchange today?',
                    style: GoogleFonts.dmSans(color: textSec, fontSize: 13)),
              ],
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Feed Search Bar — includes FilterButton
// ─────────────────────────────────────────────────────────────────────────────
class _FeedSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final PostFilter filter;
  final ValueChanged<String> onChanged;
  final ValueChanged<PostFilter> onFilterChanged;

  const _FeedSearchBar({
    required this.controller,
    required this.isDark,
    required this.filter,
    required this.onChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor  = isDark ? AppColors.darkSearchBg      : const Color(0xFFF0F0F5);
    final hintColor  = isDark ? AppColors.darkTextLight      : AppColors.textLight;
    final iconColor  = isDark ? AppColors.darkTextSecondary  : AppColors.textSecondary;
    final textPri    = isDark ? AppColors.darkTextPrimary    : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
                color: fillColor, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.dmSans(fontSize: 14, color: textPri),
              decoration: InputDecoration(
                hintText: 'Search skills, services or people...',
                hintStyle: GoogleFonts.dmSans(fontSize: 13, color: hintColor),
                prefixIcon: Icon(Icons.search_rounded, color: iconColor, size: 20),
                suffixIcon: controller.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () { controller.clear(); onChanged(''); },
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
        FilterButton(
          filter: filter,
          isDark: isDark,
          onChanged: onFilterChanged,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Active filter chips strip — shown below search when filters are on
// ─────────────────────────────────────────────────────────────────────────────
class _ActiveFilterRow extends StatelessWidget {
  final PostFilter filter;
  final bool isDark;
  final VoidCallback onClear;

  const _ActiveFilterRow({
    required this.filter, required this.isDark, required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final primary  = isDark ? AppColors.darkPrimary       : AppColors.primary;
    final chipBg   = isDark ? AppColors.darkPrimary.withOpacity(0.15)
                            : AppColors.primary.withOpacity(0.08);
    final textCol  = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final chips = <Widget>[];

    if (filter.sortOrder != SortOrder.newest) {
      chips.add(_chip(filter.sortOrder.label, primary, chipBg));
    }
    if (filter.exchangeType != null) {
      chips.add(_chip(
        filter.exchangeType == 'barter' ? 'Barter' : 'Money',
        primary, chipBg,
      ));
    }
    if (filter.skillType != SkillType.all) {
      chips.add(_chip(filter.skillType.label, primary, chipBg));
    }
    if (filter.openOnly) {
      chips.add(_chip('Open Requests', primary, chipBg));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(children: [
        Expanded(
          child: SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: chips,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onClear,
          child: Text('Clear all',
              style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w600, color: primary)),
        ),
      ]),
    );
  }

  Widget _chip(String label, Color color, Color bg) => Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3))),
    child: Text(label,
        style: GoogleFonts.dmSans(
            fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Category data holder
// ─────────────────────────────────────────────────────────────────────────────
class _Category {
  final String label;
  final IconData icon;
  final String? filterValue;
  const _Category(this.label, this.icon, this.filterValue);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Category Row
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryRow extends StatelessWidget {
  final int selected;
  final bool isDark;
  final ValueChanged<int> onTap;
  final List<_Category> categories;
  final List<Color> catColorsLight;
  final List<Color> catColorsDark;
  final List<Color> catIconColors;

  const _CategoryRow({
    required this.selected, required this.isDark, required this.onTap,
    required this.categories, required this.catColorsLight,
    required this.catColorsDark, required this.catIconColors,
  });

  @override
  Widget build(BuildContext context) {
    final labelActive   = isDark ? AppColors.darkPrimary       : AppColors.primary;
    final labelInactive = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final cat      = categories[i];
          final isActive = selected == i;
          final bgColor  = isDark ? catColorsDark[i] : catColorsLight[i];
          final iconColor = isActive ? catIconColors[i]
              : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary);

          return GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              width: 62,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: isActive ? bgColor : bgColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: isActive
                          ? Border.all(color: catIconColors[i].withOpacity(0.4), width: 1.5)
                          : null,
                    ),
                    child: Icon(cat.icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(height: 5),
                  Text(cat.label,
                      style: GoogleFonts.dmSans(
                          fontSize: 10.5,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? labelActive : labelInactive),
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
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  State<_SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<_SectionHeader> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final textPri = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.title,
              style: GoogleFonts.dmSans(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: textPri, letterSpacing: -0.3)),
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
                        color: _hovered ? primary : Colors.transparent,
                        width: 1.5),
                  ),
                ),
                child: Text('See all',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w600, color: primary)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Popular Listings — horizontal cards
// ─────────────────────────────────────────────────────────────────────────────
class _ListingCardRow extends StatelessWidget {
  final List<PostModel> posts;
  final bool isLoading, isDark;
  final ValueChanged<String> onBookmark;

  const _ListingCardRow({
    required this.posts, required this.isLoading,
    required this.isDark, required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && posts.isEmpty) {
      return SizedBox(
        height: 168,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (_, __) => _ListingShimmer(isDark: isDark),
        ),
      );
    }
    if (posts.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text('No listings match the current filters',
              style: GoogleFonts.dmSans(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  fontSize: 13)),
        ),
      );
    }
    return SizedBox(
      height: 168,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: posts.length,
        itemBuilder: (_, i) => _ListingCard(
          post: posts[i], isDark: isDark,
          onBookmark: () => onBookmark(posts[i].id),
        ).animate().fadeIn(delay: Duration(milliseconds: i * 60)).slideX(begin: 0.06),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final PostModel post;
  final bool isDark;
  final VoidCallback onBookmark;

  const _ListingCard({required this.post, required this.isDark, required this.onBookmark});

  _PillColors _pillColors(String type) {
    if (isDark) {
      switch (type) {
        case 'barter': return _PillColors(AppColors.darkTagSkillBg, AppColors.darkTagSkillText);
        case 'custom': return _PillColors(AppColors.darkTagMoneyBg, AppColors.darkTagMoneyText);
        default:       return _PillColors(AppColors.darkTagStudyBg, AppColors.darkTagStudyText);
      }
    } else {
      switch (type) {
        case 'barter': return _PillColors(const Color(0xFFF3F0FF), const Color(0xFF5B4FE8));
        case 'custom': return _PillColors(const Color(0xFFDCFCE7), const Color(0xFF16A34A));
        default:       return _PillColors(const Color(0xFFE0F2FE), const Color(0xFF0284C7));
      }
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'barter': return 'Skill • Barter';
      case 'custom': return 'Design • Money';
      default:       return 'Study • Treats';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg    = isDark ? AppColors.darkCardBg        : AppColors.surface;
    final border    = isDark ? AppColors.darkBorder        : AppColors.divider;
    final textPri   = isDark ? AppColors.darkTextPrimary   : AppColors.textPrimary;
    final textSec   = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final pill      = _pillColors(post.exchangeType);

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
      child: Container(
        width: 148,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1),
          boxShadow: isDark ? null : [BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              post.exchangeType == 'barter'
                  ? post.skillOffered : (post.customOffer ?? post.skillOffered),
              style: GoogleFonts.dmSans(fontSize: 10, color: textSec, fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(post.title,
                style: GoogleFonts.dmSans(
                    fontSize: 13.5, fontWeight: FontWeight.w700, color: textPri, height: 1.25),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              AvatarWidget(avatarUrl: post.profile?.avatarUrl,
                  username: post.profile?.username ?? '', radius: 9),
              const SizedBox(width: 5),
              Expanded(
                child: Text(post.profile?.fullName ?? post.profile?.username ?? 'Unknown',
                    style: GoogleFonts.dmSans(fontSize: 10.5, color: textSec, fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 5),
            Row(children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFACC15), size: 13),
              const SizedBox(width: 2),
              Text((post.profile?.averageRating ?? 0.0).toStringAsFixed(1),
                  style: GoogleFonts.dmSans(
                      fontSize: 11, fontWeight: FontWeight.w600, color: textPri)),
            ]),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: pill.bg, borderRadius: BorderRadius.circular(20)),
              child: Text(_typeLabel(post.exchangeType),
                  style: GoogleFonts.dmSans(
                      fontSize: 9.5, fontWeight: FontWeight.w700, color: pill.text)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Nearby Swaps — horizontal cards
// ─────────────────────────────────────────────────────────────────────────────
class _NearbySwapRow extends StatelessWidget {
  final List<PostModel> posts;
  final bool isLoading, isDark;

  const _NearbySwapRow({required this.posts, required this.isLoading, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (isLoading && posts.isEmpty) {
      return SizedBox(
        height: 152,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 2,
          itemBuilder: (_, __) => _SwapShimmer(isDark: isDark),
        ),
      );
    }
    if (posts.isEmpty) return const SizedBox(height: 80);

    return SizedBox(
      height: 152,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: posts.length,
        itemBuilder: (_, i) => _SwapCard(
          post: posts[i], isDark: isDark, distanceKm: 1.5 + i * 1.2,
        ).animate().fadeIn(delay: Duration(milliseconds: i * 70)).slideX(begin: 0.06),
      ),
    );
  }
}

class _SwapCard extends StatelessWidget {
  final PostModel post;
  final bool isDark;
  final double distanceKm;

  const _SwapCard({required this.post, required this.isDark, required this.distanceKm});

  _PillColors _tagColors() {
    if (isDark) {
      switch (post.exchangeType) {
        case 'barter': return _PillColors(AppColors.darkTagBarterBg, AppColors.darkTagBarterText);
        default:       return _PillColors(AppColors.darkTagMoneyBg,  AppColors.darkTagMoneyText);
      }
    } else {
      switch (post.exchangeType) {
        case 'barter': return _PillColors(const Color(0xFFFFEDD5), const Color(0xFFEA580C));
        default:       return _PillColors(const Color(0xFFD1FAE5), const Color(0xFF059669));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg  = isDark ? AppColors.darkCardBg        : AppColors.surface;
    final border  = isDark ? AppColors.darkBorder        : AppColors.divider;
    final textPri = isDark ? AppColors.darkTextPrimary   : AppColors.textPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final tag     = _tagColors();

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
      child: Container(
        width: 192,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1),
          boxShadow: isDark ? null : [BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(post.skillOffered,
                      style: GoogleFonts.dmSans(fontSize: 10, color: textSec, fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 4),
                Row(children: [
                  Icon(Icons.location_on_rounded, size: 10, color: textSec),
                  Text('${distanceKm.toStringAsFixed(1)} km',
                      style: GoogleFonts.dmSans(fontSize: 10, color: textSec, fontWeight: FontWeight.w500)),
                ]),
              ],
            ),
            const SizedBox(height: 3),
            Text('for', style: GoogleFonts.dmSans(fontSize: 10, color: textSec)),
            Text(post.title,
                style: GoogleFonts.dmSans(
                    fontSize: 13.5, fontWeight: FontWeight.w700, color: textPri, height: 1.25),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              AvatarWidget(avatarUrl: post.profile?.avatarUrl,
                  username: post.profile?.username ?? '', radius: 9),
              const SizedBox(width: 5),
              Expanded(
                child: Text(post.profile?.fullName ?? post.profile?.username ?? 'Unknown',
                    style: GoogleFonts.dmSans(fontSize: 10.5, color: textSec, fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFACC15), size: 13),
                  const SizedBox(width: 2),
                  Text((post.profile?.averageRating ?? 0.0).toStringAsFixed(1),
                      style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: textPri)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: tag.bg, borderRadius: BorderRadius.circular(20)),
                  child: Text(post.exchangeType == 'barter' ? 'Barter' : 'Money',
                      style: GoogleFonts.dmSans(fontSize: 9.5, fontWeight: FontWeight.w700, color: tag.text)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shimmers
// ─────────────────────────────────────────────────────────────────────────────
class _ListingShimmer extends StatelessWidget {
  final bool isDark;
  const _ListingShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? const Color(0xFF252540) : AppColors.shimmerBase;
    final high = isDark ? const Color(0xFF2D2D4E) : AppColors.shimmerHigh;
    return Shimmer.fromColors(
      baseColor: base, highlightColor: high,
      child: Container(
        width: 148, margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _SwapShimmer extends StatelessWidget {
  final bool isDark;
  const _SwapShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? const Color(0xFF252540) : AppColors.shimmerBase;
    final high = isDark ? const Color(0xFF2D2D4E) : AppColors.shimmerHigh;
    return Shimmer.fromColors(
      baseColor: base, highlightColor: high,
      child: Container(
        width: 192, margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Pill colour helper
// ─────────────────────────────────────────────────────────────────────────────
class _PillColors {
  final Color bg, text;
  const _PillColors(this.bg, this.text);
}