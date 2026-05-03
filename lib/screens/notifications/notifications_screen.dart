import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().markAllRead();
    });
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'message':  return Icons.chat_bubble_outline_rounded;
      case 'swap':     return Icons.swap_horiz_rounded;
      case 'rating':   return Icons.star_outline_rounded;
      case 'bookmark': return Icons.bookmark_outline_rounded;
      default:         return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'message': return AppColors.primary;
      case 'swap':    return AppColors.success;
      case 'rating':  return AppColors.warning;
      default:        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground    : AppColors.background;
    final textLt  = isDark ? AppColors.darkTextLight     : AppColors.textLight;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textPri = isDark ? AppColors.darkTextPrimary   : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ── Gradient app bar ─────────────────────────────────────────────
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
                    gradient: AppColors.primaryGradient),
              ),
              title: Text(
                'Notifications',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 0, 16),
            ),
          ),

          // ── Notification list ─────────────────────────────────────────────
          Consumer<NotificationService>(
            builder: (_, ns, __) {
              if (ns.notifications.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_rounded,
                            size: 64, color: textLt),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: GoogleFonts.dmSans(
                              fontSize: 16, color: textSec),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final notif = ns.notifications[i];
                    final color = _colorForType(notif.type);
                    final cardBg = notif.isRead
                        ? (isDark ? AppColors.darkCardBg : Colors.white)
                        : (isDark
                            ? AppColors.darkPrimary.withOpacity(0.10)
                            : AppColors.primary.withOpacity(0.05));
                    final borderColor = notif.isRead
                        ? (isDark ? AppColors.darkBorder : AppColors.divider)
                        : (isDark
                            ? AppColors.darkPrimary.withOpacity(0.30)
                            : AppColors.primary.withOpacity(0.20));

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(isDark ? 0.20 : 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_iconForType(notif.type),
                              color: color, size: 20),
                        ),
                        title: Text(
                          notif.title,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: textPri,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (notif.body != null)
                              Text(
                                notif.body!,
                                style: GoogleFonts.dmSans(
                                    fontSize: 12, color: textSec),
                              ),
                            Text(
                              timeago.format(notif.createdAt),
                              style: GoogleFonts.dmSans(
                                  fontSize: 11, color: textLt),
                            ),
                          ],
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ).animate().fadeIn(
                          delay: Duration(milliseconds: i * 40));
                  },
                  childCount: ns.notifications.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}