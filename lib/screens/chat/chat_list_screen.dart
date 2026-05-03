import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/chat_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatService>().fetchChats();
    });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':   return AppColors.warning;
      case 'completed': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default:          return AppColors.textLight;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending':   return 'Pending';
      case 'completed': return 'Done';
      case 'cancelled': return 'Cancelled';
      default:          return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground    : AppColors.background;
    final navBg   = isDark ? AppColors.darkBackground    : AppColors.surface;
    final divider = isDark ? AppColors.darkDivider       : AppColors.divider;
    final textPri = isDark ? AppColors.darkTextPrimary   : AppColors.textPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final primary = isDark ? AppColors.darkPrimary       : AppColors.primary;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: navBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'Messages',
              style: GoogleFonts.dmSans(
                color: textPri,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            centerTitle: false,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: divider),
            ),
          ),

          // ── Chat list ────────────────────────────────────────────────────
          Consumer<ChatService>(
            builder: (_, cs, __) {
              if (cs.isLoading && cs.chats.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (cs.chats.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(isDark ? 0.15 : 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 44,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'No conversations yet',
                          style: GoogleFonts.dmSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textPri,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Find a skill post and start chatting!',
                          style: GoogleFonts.dmSans(
                            color: textSec,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ).animate().fadeIn().scale(
                          begin: const Offset(0.92, 0.92)),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final chat   = cs.chats[i];
                    final other  = chat.otherUser;
                    final hasSt  = chat.swapStatus != 'none' &&
                        chat.swapStatus.isNotEmpty;

                    return _ChatTile(
                      key: ValueKey(chat.id),
                      avatarUrl: other?.avatarUrl,
                      username: other?.username ?? '',
                      displayName:
                          other?.fullName ?? other?.username ?? 'Unknown',
                      lastMessage:
                          chat.lastMessage ?? 'Start the conversation...',
                      hasMessage: chat.lastMessage != null,
                      time: timeago.format(chat.lastMessageAt),
                      statusColor:
                          hasSt ? _statusColor(chat.swapStatus) : null,
                      statusLabel:
                          hasSt ? _statusLabel(chat.swapStatus) : null,
                      index: i,
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, a1, __) =>
                              ChatScreen(chat: chat),
                          transitionsBuilder: (_, a1, __, child) =>
                              SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                                parent: a1,
                                curve: Curves.easeOutCubic)),
                            child: child,
                          ),
                        ),
                      ).then((_) => cs.fetchChats()),
                    );
                  },
                  childCount: cs.chats.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _ChatTile  — single conversation row, theme-aware
// ─────────────────────────────────────────────────────────────────────────────
class _ChatTile extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final String displayName;
  final String lastMessage;
  final bool hasMessage;
  final String time;
  final Color? statusColor;
  final String? statusLabel;
  final int index;
  final bool isDark;
  final VoidCallback onTap;

  const _ChatTile({
    super.key,
    required this.avatarUrl,
    required this.username,
    required this.displayName,
    required this.lastMessage,
    required this.hasMessage,
    required this.time,
    required this.onTap,
    required this.index,
    required this.isDark,
    this.statusColor,
    this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg  = isDark ? AppColors.darkCardBg        : AppColors.surface;
    final border  = isDark ? AppColors.darkDivider        : AppColors.divider;
    final textPri = isDark ? AppColors.darkTextPrimary   : AppColors.textPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textLt  = isDark ? AppColors.darkTextLight     : AppColors.textLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(
            bottom: BorderSide(color: border, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Avatar + optional status dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                AvatarWidget(
                  avatarUrl: avatarUrl,
                  username: username,
                  radius: 26,
                ),
                if (statusColor != null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cardBg,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: textPri,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        time,
                        style: GoogleFonts.dmSans(
                          fontSize: 11.5,
                          color: textLt,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: hasMessage ? textSec : textLt,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (statusLabel != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor!
                                .withOpacity(isDark ? 0.20 : 0.10),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            statusLabel!,
                            style: GoogleFonts.dmSans(
                              fontSize: 10.5,
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 40))
        .slideX(begin: 0.04, curve: Curves.easeOutCubic);
  }
}