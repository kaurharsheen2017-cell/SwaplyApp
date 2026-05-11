// lib/screens/posts/open_requests_screen.dart
// Pixel-perfect match of OpenRequestScreen.png
//
// Layout (top→bottom):
//   ← "Open Requests"   🔽 filter icon     ← white bg AppBar
//   "Find requests that match your skills and interests."  (subtitle)
//   Search bar  [🔍 Search by skill, topic or keyword…]  [⚙]
//   Category chips:  [All] </> Programming  ✏ Design  📢 Marketing  💼 Business  More ▾
//   Promo banner:  ✨ Find the perfect match / Explore open requests…  [illustration] [×]
//   "All Open Requests"   Sort by: Newest ▾
//   "78 requests" (grey)
//   Post card rows — each: skill icon (coloured square), title (bold), description,
//     tag chips, avatar + "Name · Posted Xh ago", right: [Active] pill + ⭐ rating + bookmark

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import 'post_detail_screen.dart';
import '../posts/open_requests_screen.dart';

// ── Constants ─────────────────────────────────────────────────────────────────
const _kP = AppColors.primary;

class _Cat {
  final String label;
  final IconData icon;
  final String? filter;
  const _Cat(this.label, this.icon, [this.filter]);
}

const _kCats = [
  _Cat('All',         Icons.apps_rounded,                   null),
  _Cat('Programming', Icons.code_rounded,                   'programming'),
  _Cat('Design',      Icons.design_services_outlined,       'design'),
  _Cat('Marketing',   Icons.campaign_outlined,              'marketing'),
  _Cat('Business',    Icons.business_center_outlined,       'business'),
  _Cat('More',        Icons.expand_more_rounded,            null),
];

// ═════════════════════════════════════════════════════════════════════════════
class OpenRequestsScreen extends StatefulWidget {
  const OpenRequestsScreen({super.key});
  @override
  State<OpenRequestsScreen> createState() => _OpenRequestsScreenState();
}

class _OpenRequestsScreenState extends State<OpenRequestsScreen> {
  int    _selCat    = 0;
  int    _sortIndex = 0;   // 0=Newest, 1=Oldest, 2=Rating
  String _search    = '';
  bool   _bannerVisible = true;
  final  _searchCtrl    = TextEditingController();
  final  _scrollCtrl    = ScrollController();

  static const _sortLabels = ['Newest', 'Oldest', 'Top Rated'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() {
    final ps = context.read<PostService>();
    return ps.fetchPosts(
      openRequestsOnly: true,
      ascending:        _sortIndex == 1,
      searchQuery:      _search.isNotEmpty ? _search : null,
    );
  }

  List<PostModel> _filtered(List<PostModel> raw) {
    var list = raw.where((p) => p.isOpenRequest).toList();
    // Category keyword filter
    if (_selCat > 0 && _selCat < _kCats.length - 1) {
      final kw = _kCats[_selCat].filter ?? '';
      if (kw.isNotEmpty) {
        list = list.where((p) =>
          p.tags.any((t) => t.toLowerCase().contains(kw)) ||
          p.title.toLowerCase().contains(kw) ||
          p.skillOffered.toLowerCase().contains(kw)).toList();
      }
    }
    // Sort
    if (_sortIndex == 2) {
      list.sort((a, b) =>
          (b.profile?.averageRating ?? 0).compareTo(a.profile?.averageRating ?? 0));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? AppColors.darkBackground : Colors.white;
    final tPri    = isDark ? AppColors.darkTextPrimary   : const Color(0xFF111128);
    final tSec    = isDark ? AppColors.darkTextSecondary : const Color(0xFF6B6B80);
    final border  = isDark ? AppColors.darkBorder        : const Color(0xFFE8E8F0);
    final cardBg  = isDark ? AppColors.darkCardBg        : Colors.white;
    final primary = isDark ? AppColors.darkPrimary       : _kP;

    return Scaffold(
      backgroundColor: bg,
      body: Consumer<PostService>(
        builder: (_, ps, __) {
          final posts = _filtered(ps.openRequests.isEmpty ? ps.posts : ps.openRequests);

          return RefreshIndicator(
            color: primary,
            onRefresh: _fetch,
            child: CustomScrollView(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              slivers: [

                // ── AppBar ────────────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  backgroundColor: bg,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: tPri, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text('Open Requests',
                    style: GoogleFonts.dmSans(
                      color: tPri, fontSize: 18, fontWeight: FontWeight.w800,
                      letterSpacing: -0.3)),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.filter_list_rounded, color: primary, size: 24),
                      onPressed: () => _showSortSheet(context, isDark, primary, tPri, tSec),
                    ),
                    const SizedBox(width: 4),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Divider(height: 1, thickness: 1,
                      color: isDark ? AppColors.darkDivider : AppColors.divider)),
                ),

                // ── Subtitle ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Text('Find requests that match your skills and interests.',
                      style: GoogleFonts.dmSans(fontSize: 13.5, color: tSec)),
                  ).animate().fadeIn(delay: 60.ms),
                ),

                // ── Search bar ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _SearchBar(
                    ctrl: _searchCtrl,
                    isDark: isDark, border: border,
                    tSec: tSec, primary: primary,
                    onChanged: (q) {
                      setState(() => _search = q);
                      _fetch();
                    },
                  ).animate().fadeIn(delay: 90.ms),
                ),

                // ── Category chips ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _CatRow(
                    selected: _selCat,
                    isDark: isDark, primary: primary,
                    border: border, tPri: tPri, tSec: tSec,
                    onTap: (i) {
                      HapticFeedback.selectionClick();
                      setState(() => _selCat = i);
                    },
                  ).animate().fadeIn(delay: 110.ms),
                ),

                // ── Promo banner ──────────────────────────────────────────
                if (_bannerVisible)
                  SliverToBoxAdapter(
                    child: _PromoBanner(
                      isDark: isDark, primary: primary,
                      tPri: tPri,
                      onDismiss: () => setState(() => _bannerVisible = false),
                    ).animate().fadeIn(delay: 130.ms),
                  ),

                // ── Section header ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    count: posts.length,
                    sortLabel: _sortLabels[_sortIndex],
                    isDark: isDark, tPri: tPri, tSec: tSec, primary: primary,
                    onSort: () => _showSortSheet(context, isDark, primary, tPri, tSec),
                  ),
                ),

                // ── Post list ─────────────────────────────────────────────
                if (ps.isLoading && posts.isEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _CardShimmer(isDark: isDark, cardBg: cardBg),
                      childCount: 5))
                else if (posts.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyState(isDark: isDark, tPri: tPri, tSec: tSec))
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _RequestCard(
                        post: posts[i],
                        isDark: isDark, cardBg: cardBg,
                        tPri: tPri, tSec: tSec,
                        border: border, primary: primary,
                        onBookmark: () =>
                            ps.toggleBookmark(posts[i].id),
                      ).animate().fadeIn(delay: Duration(milliseconds: i * 55)),
                      childCount: posts.length)),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSortSheet(BuildContext ctx, bool isDark, Color primary,
      Color tPri, Color tSec) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(
        isDark: isDark, primary: primary,
        tPri: tPri, tSec: tSec,
        current: _sortIndex,
        onPick: (i) {
          setState(() => _sortIndex = i);
          _fetch();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Search bar  (matches OpenRequestScreen.png exactly)
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool isDark;
  final Color border, tSec, primary;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.ctrl, required this.isDark,
    required this.border, required this.tSec, required this.primary,
    required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final fill = isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF8F8FF);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: fill, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 1)),
            child: TextField(
              controller: ctrl,
              onChanged: onChanged,
              style: GoogleFonts.dmSans(fontSize: 14,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by skill, topic or keyword…',
                hintStyle: GoogleFonts.dmSans(fontSize: 13.5, color: tSec),
                prefixIcon: Icon(Icons.search_rounded, color: tSec, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Filter/settings icon button
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: fill, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1)),
          child: Icon(Icons.tune_rounded, color: primary, size: 20),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Category chip row
// ─────────────────────────────────────────────────────────────────────────────
class _CatRow extends StatelessWidget {
  final int selected;
  final bool isDark;
  final Color primary, border, tPri, tSec;
  final ValueChanged<int> onTap;
  const _CatRow({required this.selected, required this.isDark,
    required this.primary, required this.border,
    required this.tPri, required this.tSec, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        physics: const BouncingScrollPhysics(),
        itemCount: _kCats.length,
        itemBuilder: (_, i) {
          final cat = _kCats[i];
          final on  = i == selected;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: on ? primary : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: on ? primary : border, width: 1.5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(cat.icon, size: 14,
                    color: on ? Colors.white : tSec),
                if (cat.label != 'All') const SizedBox(width: 5),
                Text(cat.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: on ? Colors.white : tSec)),
                if (i == _kCats.length - 1) ...[
                  const SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 16,
                      color: on ? Colors.white : tSec),
                ],
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Promo banner: lavender bg, sparkle icon, illustration, ×
// ─────────────────────────────────────────────────────────────────────────────
class _PromoBanner extends StatelessWidget {
  final bool isDark;
  final Color primary, tPri;
  final VoidCallback onDismiss;
  const _PromoBanner({required this.isDark, required this.primary,
    required this.tPri, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? primary.withOpacity(0.16)
        : const Color(0xFFF0EEFF);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primary.withOpacity(isDark ? 0.30 : 0.18), width: 1)),
      child: Row(children: [
        // Sparkle circle icon
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: primary, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Find the perfect match',
              style: GoogleFonts.dmSans(
                fontSize: 14, fontWeight: FontWeight.w800, color: tPri)),
            const SizedBox(height: 2),
            Text('Explore open requests and offer your skills.',
              style: GoogleFonts.dmSans(
                fontSize: 12, color: tPri.withOpacity(0.65))),
          ]),
        ),
        const SizedBox(width: 8),
        // Magnifier illustration  (custom paint)
        SizedBox(
          width: 56, height: 48,
          child: CustomPaint(painter: _MagnifierPainter(color: primary))),
        // × dismiss
        GestureDetector(
          onTap: onDismiss,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.close_rounded,
                size: 18, color: tPri.withOpacity(0.45)),
          ),
        ),
      ]),
    );
  }
}

class _MagnifierPainter extends CustomPainter {
  final Color color;
  const _MagnifierPainter({required this.color});
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = color.withOpacity(0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    // circle (lens)
    c.drawCircle(Offset(s.width*0.40, s.height*0.42), s.width*0.28, p);
    // handle
    c.drawLine(Offset(s.width*0.61, s.height*0.62),
               Offset(s.width*0.84, s.height*0.86), p);
    // person silhouette in lens
    final fp = Paint()..color = color.withOpacity(0.30)..style = PaintingStyle.fill;
    c.drawCircle(Offset(s.width*0.34, s.height*0.34), s.width*0.10, fp);
    final rr = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(s.width*0.40, s.height*0.50),
          width: s.width*0.22, height: s.width*0.14),
      const Radius.circular(4));
    c.drawRRect(rr, fp);
    // sparkle dots
    final sp = Paint()..color = color.withOpacity(0.60)..style = PaintingStyle.fill;
    c.drawCircle(Offset(s.width*0.75, s.height*0.16), 2.5, sp);
    c.drawCircle(Offset(s.width*0.86, s.height*0.28), 2.0, sp);
  }
  @override bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Section header: "All Open Requests" + count + sort
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final int count;
  final String sortLabel;
  final bool isDark;
  final Color tPri, tSec, primary;
  final VoidCallback onSort;
  const _SectionHeader({required this.count, required this.sortLabel,
    required this.isDark, required this.tPri, required this.tSec,
    required this.primary, required this.onSort});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('All Open Requests',
              style: GoogleFonts.dmSans(
                fontSize: 17, fontWeight: FontWeight.w800, color: tPri)),
            GestureDetector(
              onTap: onSort,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Sort by: ',
                  style: GoogleFonts.dmSans(fontSize: 12.5, color: tSec)),
                Text(sortLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5, fontWeight: FontWeight.w700, color: primary)),
                const SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: primary),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text('$count requests',
          style: GoogleFonts.dmSans(
            fontSize: 13, color: primary, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Request card  — matches OpenRequestScreen.png rows exactly
//  Left: skill-category coloured square icon
//  Centre: title (bold) + description + tag chips + avatar + "Name · Xh ago"
//  Right: [Active] green pill  +  ⭐ rating + count  +  bookmark icon
// ─────────────────────────────────────────────────────────────────────────────
class _RequestCard extends StatefulWidget {
  final PostModel post;
  final bool isDark;
  final Color cardBg, tPri, tSec, border, primary;
  final VoidCallback onBookmark;
  const _RequestCard({required this.post, required this.isDark,
    required this.cardBg, required this.tPri, required this.tSec,
    required this.border, required this.primary, required this.onBookmark});
  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bkCtrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 200));
  late final Animation<double> _bkScale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 50),
    TweenSequenceItem(tween: Tween(begin: 1.45, end: 1.0), weight: 50),
  ]).animate(CurvedAnimation(parent: _bkCtrl, curve: Curves.easeInOut));

  @override
  void dispose() { _bkCtrl.dispose(); super.dispose(); }

  void _tapBookmark() {
    HapticFeedback.lightImpact();
    _bkCtrl.forward(from: 0);
    widget.onBookmark();
  }

  // Derive a skill icon + bg from tags / exchangeType
  (IconData, Color, Color) _skillIcon() {
    final title = widget.post.title.toLowerCase();
    final tags  = widget.post.tags.map((t) => t.toLowerCase()).join(' ');
    final all   = '$title $tags';

    if (all.contains('react') || all.contains('code') ||
        all.contains('python') || all.contains('sql') ||
        all.contains('javascript') || all.contains('data')) {
      return (Icons.code_rounded,
          const Color(0xFFE0F2FE), const Color(0xFF0284C7));
    }
    if (all.contains('design') || all.contains('canva') ||
        all.contains('figma') || all.contains('instagram')) {
      return (Icons.design_services_rounded,
          const Color(0xFFFCE7F3), const Color(0xFFDB2777));
    }
    if (all.contains('market') || all.contains('social')) {
      return (Icons.campaign_rounded,
          const Color(0xFFFEF3C7), const Color(0xFFD97706));
    }
    if (all.contains('database') || all.contains('sql')) {
      return (Icons.storage_rounded,
          const Color(0xFFEDE9FE), const Color(0xFF7C3AED));
    }
    return (Icons.lightbulb_outline_rounded,
        const Color(0xFFDCFCE7), const Color(0xFF16A34A));
  }

  @override
  Widget build(BuildContext context) {
    final p      = widget;
    final post   = p.post;
    final (icon, iconBg, iconColor) = _skillIcon();
    final rating = post.profile?.averageRating ?? 0.0;
    final rCount = post.profile?.ratingCount   ?? 0;
    final age    = timeago.format(post.createdAt, allowFromNow: true);
    final name   = post.profile?.fullName?.split(' ').first
        ?? post.profile?.username ?? 'User';

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: p.border, width: 1))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Skill icon square
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: p.isDark ? iconColor.withOpacity(0.20) : iconBg,
                borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 26)),
            const SizedBox(width: 12),

            // Title + description
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(post.title,
                style: GoogleFonts.dmSans(
                  fontSize: 15, fontWeight: FontWeight.w800, color: p.tPri,
                  height: 1.2),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(post.skillOffered.isNotEmpty ? post.skillOffered : (post.customOffer ?? ''),
                style: GoogleFonts.dmSans(
                  fontSize: 13, color: p.tSec, height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            ])),
            const SizedBox(width: 8),

            // Right column: Active pill + rating + bookmark
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              // Active pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(99)),
                child: Text('Active',
                  style: GoogleFonts.dmSans(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: const Color(0xFF16A34A)))),
              const SizedBox(height: 6),
              // Star rating
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFF5B4FE8), size: 14),
                const SizedBox(width: 2),
                Text(rating > 0 ? rating.toStringAsFixed(1) : '—',
                  style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w700, color: p.tPri)),
              ]),
              Text('(${rCount > 0 ? rCount : '--'} reviews)',
                style: GoogleFonts.dmSans(fontSize: 10.5, color: p.tSec)),
              const SizedBox(height: 4),
              // Bookmark icon
              GestureDetector(
                onTap: _tapBookmark,
                child: ScaleTransition(
                  scale: _bkScale,
                  child: Icon(
                    post.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 22,
                    color: post.isBookmarked ? p.primary : p.tSec.withOpacity(0.55),
                  ),
                ),
              ),
            ]),
          ]),

          const SizedBox(height: 10),

          // Tag chips
          if (post.tags.isNotEmpty)
            Wrap(spacing: 6, runSpacing: 4,
              children: post.tags.take(3).map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: p.isDark
                      ? p.primary.withOpacity(0.14)
                      : const Color(0xFFF0EEFF),
                  borderRadius: BorderRadius.circular(99)),
                child: Text(tag,
                  style: GoogleFonts.dmSans(
                    fontSize: 11.5, fontWeight: FontWeight.w600,
                    color: p.primary)),
              )).toList()),

          const SizedBox(height: 10),

          // Avatar + name + posted time
          Row(children: [
            AvatarWidget(
              avatarUrl: post.profile?.avatarUrl,
              username: post.profile?.username ?? '',
              radius: 12),
            const SizedBox(width: 7),
            Text(name,
              style: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: FontWeight.w600, color: p.tSec)),
            Text(' · ',
              style: GoogleFonts.dmSans(fontSize: 12, color: p.tSec)),
            Text('Posted $age',
              style: GoogleFonts.dmSans(fontSize: 12, color: p.tSec)),
          ]),

          const SizedBox(height: 14),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sort bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _SortSheet extends StatelessWidget {
  final bool isDark; final Color primary, tPri, tSec;
  final int current; final ValueChanged<int> onPick;
  const _SortSheet({required this.isDark, required this.primary,
    required this.tPri, required this.tSec,
    required this.current, required this.onPick});

  static const _opts = ['Newest', 'Oldest', 'Top Rated'];

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkCardBg : Colors.white;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
          decoration: BoxDecoration(
            color: tSec.withOpacity(0.30),
            borderRadius: BorderRadius.circular(99))),
        const SizedBox(height: 16),
        Text('Sort By', style: GoogleFonts.dmSans(
          fontSize: 16, fontWeight: FontWeight.w800, color: tPri)),
        const SizedBox(height: 14),
        ..._opts.asMap().entries.map((e) {
          final on = e.key == current;
          return GestureDetector(
            onTap: () { Navigator.pop(context); onPick(e.key); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.divider))),
              child: Row(children: [
                Expanded(child: Text(e.value,
                  style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: on ? primary : tPri))),
                if (on) Icon(Icons.check_rounded, color: primary, size: 20),
              ]),
            ),
          );
        }),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shimmer placeholder card
// ─────────────────────────────────────────────────────────────────────────────
class _CardShimmer extends StatelessWidget {
  final bool isDark; final Color cardBg;
  const _CardShimmer({required this.isDark, required this.cardBg});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    height: 140,
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF0F0F0),
      borderRadius: BorderRadius.circular(14)));
}

// ─────────────────────────────────────────────────────────────────────────────
//  Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isDark; final Color tPri, tSec;
  const _EmptyState({required this.isDark, required this.tPri, required this.tSec});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.search_off_rounded, size: 64,
        color: isDark ? AppColors.darkTextLight : AppColors.textLight),
      const SizedBox(height: 16),
      Text('No open requests found',
        style: GoogleFonts.dmSans(
          fontSize: 17, fontWeight: FontWeight.w700, color: tPri)),
      const SizedBox(height: 8),
      Text('Try a different category or search term.',
        style: GoogleFonts.dmSans(fontSize: 13, color: tSec)),
    ]),
  );
}