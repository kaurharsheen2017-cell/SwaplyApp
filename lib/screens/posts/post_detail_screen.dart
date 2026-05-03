import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../chat/chat_screen.dart';
import '../../screens/profile/user_profile_screen.dart' as profile_screen;
class PostDetailScreen extends StatelessWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bgColor  = isDark ? AppColors.darkBackground    : AppColors.background;
    final textPri  = isDark ? AppColors.darkTextPrimary   : AppColors.textPrimary;
    final textSec  = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textLt   = isDark ? AppColors.darkTextLight     : AppColors.textLight;
    final divColor = isDark ? AppColors.darkDivider       : AppColors.divider;
    final primary  = isDark ? AppColors.darkPrimary       : AppColors.primary;
    final auth     = context.watch<AuthService>();
    final isOwn    = auth.currentUser?.id == post.userId;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ── Gradient app bar ────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 80,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (!isOwn)
                IconButton(
                  icon: Icon(
                    post.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () =>
                      context.read<PostService>().toggleBookmark(post.id),
                ),
              if (isOwn)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: isDark ? AppColors.darkCardBg : Colors.white,
                  onSelected: (val) async {
                    if (val == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor:
                              isDark ? AppColors.darkCardBg : Colors.white,
                          title: Text('Delete Post',
                              style: TextStyle(color: textPri)),
                          content: Text(
                              'Are you sure you want to delete this post?',
                              style: TextStyle(color: textSec)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel',
                                  style: TextStyle(color: textSec)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete',
                                  style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await context.read<PostService>().deletePost(post.id);
                        if (context.mounted) Navigator.pop(context);
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Post',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                  decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient)),
              title: Text('Skill Post',
                  style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 0, 16),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags
                  if (post.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      children: post.tags
                          .map((t) => _buildTag(t, isDark))
                          .toList(),
                    ).animate().fadeIn(),
                    const SizedBox(height: 12),
                  ],

                  // Title
                  Text(
                    post.title,
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textPri,
                      letterSpacing: -0.4,
                    ),
                  ).animate().fadeIn(delay: 50.ms),

                  const SizedBox(height: 12),

                  // Author row
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              _UserProfileRoute(userId: post.userId)),
                    ),
                    child: Row(
                      children: [
                        AvatarWidget(
                          avatarUrl: post.profile?.avatarUrl,
                          username: post.profile?.username ?? '',
                          radius: 20,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.profile?.fullName ??
                                  post.profile?.username ??
                                  'Unknown',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: textPri,
                              ),
                            ),
                            Row(children: [
                              Icon(Icons.access_time_rounded,
                                  size: 12, color: textLt),
                              const SizedBox(width: 3),
                              Text(timeago.format(post.createdAt),
                                  style: GoogleFonts.dmSans(
                                      fontSize: 11, color: textLt)),
                            ]),
                          ],
                        ),
                        const Spacer(),
                        if ((post.profile?.averageRating ?? 0) > 0)
                          Row(children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFACC15), size: 15),
                            const SizedBox(width: 3),
                            Text(
                              (post.profile?.averageRating ?? 0.0).toStringAsFixed(1),
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                color: textPri,
                              ),
                            ),
                          ]),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 20),
                  Divider(color: divColor),
                  const SizedBox(height: 16),

                  // Description
                  Text('About this swap',
                      style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPri)),
                  const SizedBox(height: 8),
                  Text(
                    post.description,
                    style: GoogleFonts.dmSans(
                        fontSize: 14, height: 1.6, color: textSec),
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 20),

                  // Exchange card
                  _ExchangeCard(post: post, isDark: isDark)
                      .animate()
                      .fadeIn(delay: 200.ms),

                  // Open request banner
                  if (post.isOpenRequest) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning
                            .withOpacity(isDark ? 0.15 : 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.warning
                                .withOpacity(isDark ? 0.40 : 0.30)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.help_outline_rounded,
                            color: AppColors.warning),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Open Request',
                                  style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.warning)),
                              Text(
                                  'This is a help request open to all campus members.',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12, color: textSec)),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Chat CTA ─────────────────────────────────────────────────────────
      bottomNavigationBar: !isOwn
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final chatService = context.read<ChatService>();
                    final chat = await chatService.getOrCreateChat(
                      otherUserId: post.userId,
                      postId: post.id,
                    );
                    if (chat != null && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ChatScreen(chat: chat)),
                      );
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: Text('Start Chat & Swap',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTag(String tag, bool isDark) {
    Color c = isDark ? AppColors.darkPrimary : AppColors.primary;
    if (tag == 'Urgent')     c = AppColors.error;
    if (tag == 'Quick Help') c = AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(isDark ? 0.40 : 0.30)),
      ),
      child: Text(tag,
          style: TextStyle(
              fontSize: 11, color: c, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Exchange details card ──────────────────────────────────────────────────
class _ExchangeCard extends StatelessWidget {
  final PostModel post;
  final bool isDark;
  const _ExchangeCard({required this.post, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isBarter = post.exchangeType == 'barter';
    final primary  = isDark ? AppColors.darkPrimary : AppColors.primary;
    final secondary = isDark ? AppColors.darkTagBarterText : AppColors.secondary;
    final accent    = isDark ? AppColors.darkTagMoneyText  : AppColors.accent;
    final cardBg    = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.cardGradient.colors.first;
    final borderCol = primary.withOpacity(isDark ? 0.25 : 0.15);
    final textLt    = isDark ? AppColors.darkTextLight : AppColors.textLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? cardBg : null,
        gradient: isDark ? null : AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(child: _ExchangeItem(
            icon: Icons.star_rounded, color: primary,
            label: 'Offering', value: post.skillOffered, isRight: false,
            textLt: textLt,
          )),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withOpacity(isDark ? 0.20 : 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.swap_horiz_rounded, color: primary, size: 20),
          ),
          Expanded(child: _ExchangeItem(
            icon: isBarter ? Icons.sync_alt_rounded : Icons.card_giftcard_rounded,
            color: isBarter ? secondary : accent,
            label: isBarter ? 'Wants' : 'Offer',
            value: isBarter
                ? (post.skillWanted ?? 'Open')
                : (post.customOffer ?? 'Custom'),
            isRight: true,
            textLt: textLt,
          )),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (isBarter ? secondary : accent)
                .withOpacity(isDark ? 0.20 : 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isBarter ? '🔄 Barter Exchange' : '🎁 Custom Offer',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isBarter ? secondary : accent,
            ),
          ),
        ),
      ]),
    );
  }
}

class _ExchangeItem extends StatelessWidget {
  final IconData icon;
  final Color color, textLt;
  final String label, value;
  final bool isRight;
  const _ExchangeItem({required this.icon, required this.color,
      required this.label, required this.value,
      required this.isRight, required this.textLt});

  @override
  Widget build(BuildContext context) {
    final textPri = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    return Column(
      crossAxisAlignment:
          isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: textLt)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: isRight
              ? [
                  Flexible(child: Text(value,
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: textPri),
                      textAlign: TextAlign.end)),
                  const SizedBox(width: 4),
                  Icon(icon, color: color, size: 16),
                ]
              : [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 4),
                  Flexible(child: Text(value,
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: textPri))),
                ],
        ),
      ],
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