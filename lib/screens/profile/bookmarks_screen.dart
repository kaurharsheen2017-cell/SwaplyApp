// lib/screens/profile/bookmarks_screen.dart
// Lists all bookmarked posts. Each PostCard shows live bookmark toggle.
// Unbooking a post removes it from the list instantly (optimistic update).
// Pulls from PostService.bookmarkedPosts — real Supabase "bookmarks" table.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/post_card.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await context.read<PostService>().fetchBookmarkedPosts();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? AppColors.darkBackground    : AppColors.background;
    final tPri    = isDark ? AppColors.darkTextPrimary   : AppColors.textPrimary;
    final tSec    = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final border  = isDark ? AppColors.darkBorder        : AppColors.divider;
    final primary = isDark ? AppColors.darkPrimary       : AppColors.primary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: tPri, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bookmarks',
          style: GoogleFonts.dmSans(
              color: tPri, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: border),
        ),
      ),
      body: RefreshIndicator(
        color: primary,
        onRefresh: _load,
        child: Consumer<PostService>(
          builder: (_, ps, __) {
            final posts = ps.bookmarkedPosts;

            // ── Loading state ─────────────────────────────────────────────
            if (_loading && posts.isEmpty) {
              return Center(
                child: CircularProgressIndicator(color: primary),
              );
            }

            // ── Empty state ───────────────────────────────────────────────
            if (posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border_rounded,
                      size: 64,
                      color: isDark
                          ? AppColors.darkTextLight
                          : AppColors.textLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No bookmarks yet',
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: tPri,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the bookmark icon on any post\nto save it here.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                          fontSize: 14, color: tSec, height: 1.5),
                    ),
                  ],
                ),
              );
            }

            // ── List ──────────────────────────────────────────────────────
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              physics: const BouncingScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (_, i) {
                final post = posts[i];
                return PostCard(
                  post: post,
                  // Wired: toggling removes immediately from bookmarked list
                  onBookmarkToggle: () async {
                    await ps.toggleBookmark(post.id);
                    // fetchBookmarkedPosts re-syncs the list from Supabase
                    await ps.fetchBookmarkedPosts();
                  },
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: i * 50))
                    .slideY(begin: 0.04);
              },
            );
          },
        ),
      ),
    );
  }
}