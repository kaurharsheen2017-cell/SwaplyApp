import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/post_card.dart';
import '../../widgets/shimmer_card.dart';

class OpenRequestsScreen extends StatefulWidget {
  const OpenRequestsScreen({super.key});
  @override
  State<OpenRequestsScreen> createState() => _OpenRequestsScreenState();
}

class _OpenRequestsScreenState extends State<OpenRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostService>().fetchOpenRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground    : AppColors.background;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textLt  = isDark ? AppColors.darkTextLight     : AppColors.textLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ── Gradient app bar ──────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 90,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                  decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient)),
              title: Text('Open Requests',
                  style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 0, 16),
            ),
          ),

          // Info banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning
                      .withOpacity(isDark ? 0.15 : 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.warning
                          .withOpacity(isDark ? 0.35 : 0.30)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Students posting requests for help — respond by starting a chat!',
                      style: GoogleFonts.dmSans(
                          color: textSec, fontSize: 12),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          // List
          Consumer<PostService>(
            builder: (_, ps, __) {
              if (ps.isLoading && ps.openRequests.isEmpty) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const ShimmerCard(),
                    childCount: 4,
                  ),
                );
              }
              if (ps.openRequests.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.help_outline_rounded,
                            size: 60, color: textLt),
                        const SizedBox(height: 12),
                        Text('No open requests yet',
                            style: GoogleFonts.dmSans(
                                fontSize: 16, color: textSec)),
                        const SizedBox(height: 6),
                        Text('Be the first to post a help request!',
                            style: GoogleFonts.dmSans(color: textLt)),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => PostCard(
                      post: ps.openRequests[i],
                      onBookmarkToggle: () =>
                          ps.toggleBookmark(ps.openRequests[i].id),
                    ).animate().fadeIn(
                          delay: Duration(milliseconds: i * 60)),
                    childCount: ps.openRequests.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}