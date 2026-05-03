import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post_model.dart';
import '../utils/app_theme.dart';
import '../screens/posts/post_detail_screen.dart';
import 'avatar_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PostCard  — theme-aware vertical listing card
//  All colours resolved from Theme.of(context) at build time so it
//  renders correctly in both light and dark modes.
// ─────────────────────────────────────────────────────────────────────────────
class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onBookmarkToggle;

  const PostCard({super.key, required this.post, this.onBookmarkToggle});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 220),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _navigate() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => PostDetailScreen(post: widget.post),
        transitionsBuilder: (_, a1, a2, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a1, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBarter = widget.post.exchangeType == 'barter';

    // ── Theme-resolved colours ────────────────────────────────────────────
    final cardBg       = isDark ? AppColors.darkCardBg    : AppColors.surface;
    final borderColor  = isDark ? AppColors.darkBorder    : AppColors.divider;
    final textPrimary  = isDark ? AppColors.darkTextPrimary  : AppColors.textPrimary;
    final textLight    = isDark ? AppColors.darkTextLight    : AppColors.textLight;
    final primaryColor = isDark ? AppColors.darkPrimary      : AppColors.primary;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.reverse(),
      onTapUp: (_) {
        _pressCtrl.forward();
        _navigate();
      },
      onTapCancel: () => _pressCtrl.forward(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: isDark
                ? null
                : AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: avatar + name + time + bookmark ──────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Row(
                  children: [
                    AvatarWidget(
                      avatarUrl: widget.post.profile?.avatarUrl,
                      username: widget.post.profile?.username ?? '',
                      radius: 19,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.profile?.fullName ??
                                widget.post.profile?.username ??
                                'Unknown',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            timeago.format(widget.post.createdAt),
                            style: GoogleFonts.dmSans(
                              color: textLight,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Open-request badge
                    if (widget.post.isOpenRequest)
                      _Pill(
                        label: 'Request',
                        color: AppColors.warning,
                        bg: AppColors.warning.withOpacity(isDark ? 0.18 : 0.10),
                      ),

                    const SizedBox(width: 6),

                    // Bookmark
                    if (widget.onBookmarkToggle != null)
                      _BookmarkButton(
                        saved: widget.post.isBookmarked,
                        onTap: widget.onBookmarkToggle!,
                        activeColor: primaryColor,
                        inactiveColor: textLight,
                      ),
                  ],
                ),
              ),

              // ── Tags ─────────────────────────────────────────────────────
              if (widget.post.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: widget.post.tags
                        .map((t) => _buildTag(t, isDark))
                        .toList(),
                  ),
                ),

              // ── Title ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: Text(
                  widget.post.title,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: textPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // ── Description ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Text(
                  widget.post.description,
                  style: GoogleFonts.dmSans(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // ── Exchange strip ────────────────────────────────────────────
              _ExchangeStrip(
                post: widget.post,
                isBarter: isBarter,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String tag, bool isDark) {
    Color c;
    Color bg;
    if (isDark) {
      if (tag == 'Urgent') {
        c = const Color(0xFFFCA5A5);
        bg = const Color(0xFF7F1D1D);
      } else if (tag == 'Quick Help') {
        c = AppColors.darkTagTreatsText;
        bg = AppColors.darkTagTreatsBg;
      } else {
        c = AppColors.darkTagSkillText;
        bg = AppColors.darkTagSkillBg;
      }
    } else {
      if (tag == 'Urgent') {
        c = AppColors.error;
        bg = AppColors.error.withOpacity(0.08);
      } else if (tag == 'Quick Help') {
        c = AppColors.warning;
        bg = AppColors.warning.withOpacity(0.08);
      } else {
        c = AppColors.primary;
        bg = AppColors.primary.withOpacity(0.08);
      }
    }
    return _Pill(label: tag, color: c, bg: bg);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Exchange strip — "OFFERING ⇌ WANTS" bottom section of card
// ─────────────────────────────────────────────────────────────────────────────
class _ExchangeStrip extends StatelessWidget {
  final PostModel post;
  final bool isBarter;
  final bool isDark;

  const _ExchangeStrip({
    required this.post,
    required this.isBarter,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final stripBg   = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final leftColor = isDark ? AppColors.darkPrimary         : AppColors.primary;
    final rightColor = isBarter
        ? (isDark ? AppColors.darkTagBarterText : AppColors.secondary)
        : (isDark ? AppColors.darkTagMoneyText  : AppColors.accentTeal);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: stripBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          // Offering
          Expanded(
            child: _SkillChip(
              label: post.skillOffered,
              tag: 'OFFERING',
              color: leftColor,
              icon: Icons.star_rounded,
              align: CrossAxisAlignment.start,
              isDark: isDark,
            ),
          ),

          // Centre swap badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: isBarter
                    ? AppColors.primaryGradient
                    : AppColors.mintGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isBarter ? AppColors.primary : AppColors.accentTeal)
                        .withOpacity(0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isBarter ? '⇌' : '🎁',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),

          // Wanting / custom offer
          Expanded(
            child: _SkillChip(
              label: isBarter
                  ? (post.skillWanted ?? 'Open')
                  : (post.customOffer ?? 'Custom'),
              tag: isBarter ? 'WANTS' : 'OFFERS',
              color: rightColor,
              icon: isBarter
                  ? Icons.sync_alt_rounded
                  : Icons.card_giftcard_rounded,
              align: CrossAxisAlignment.end,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final String tag;
  final Color color;
  final IconData icon;
  final CrossAxisAlignment align;
  final bool isDark;

  const _SkillChip({
    required this.label,
    required this.tag,
    required this.color,
    required this.icon,
    required this.align,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isRight   = align == CrossAxisAlignment.end;
    final labelMeta = isDark ? AppColors.darkTextLight : AppColors.textLight;

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          tag,
          style: GoogleFonts.dmSans(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: labelMeta,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: isRight
              ? [
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(icon, color: color, size: 13),
                ]
              : [
                  Icon(icon, color: color, size: 13),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bookmark button with pop-scale animation
// ─────────────────────────────────────────────────────────────────────────────
class _BookmarkButton extends StatefulWidget {
  final bool saved;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  const _BookmarkButton({
    required this.saved,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  State<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<_BookmarkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _tap() {
    HapticFeedback.lightImpact();
    _ctrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tap,
      child: ScaleTransition(
        scale: _scale,
        child: Icon(
          widget.saved
              ? Icons.bookmark_rounded
              : Icons.bookmark_outline_rounded,
          color: widget.saved ? widget.activeColor : widget.inactiveColor,
          size: 22,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Pill label — reusable tag chip
// ─────────────────────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Pill({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 10.5,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}