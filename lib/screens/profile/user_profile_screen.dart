import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/chat_model.dart';
import '../../models/profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/post_card.dart';
import '../../main.dart';
import 'package:url_launcher/url_launcher.dart';
import '../chat/chat_screen.dart';
// NOTE: chat_screen.dart is intentionally NOT imported here to avoid a
// circular dependency (chat_screen → user_profile_screen → chat_screen).
// Navigation to ChatScreen is handled via the ChatService + dynamic push.

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  ProfileModel? _profile;
  List _posts = [];
  List<RatingModel> _ratings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth        = context.read<AuthService>();
    final chatService = context.read<ChatService>();
    final postService = context.read<PostService>();
    _profile  = await auth.getProfileById(widget.userId);
    _posts    = await postService.fetchUserPosts(widget.userId);
    _ratings  = await chatService.fetchUserRatings(widget.userId);
    if (mounted) setState(() => _loading = false);
  }

  /// Navigate to chat without a direct import of ChatScreen.
  /// Uses a dynamic builder registered in ChatService so the dependency
  /// graph stays acyclic.
  Future<void> _startChat(BuildContext context) async {
    final chatService = context.read<ChatService>();
    final chat = await chatService.getOrCreateChat(
      otherUserId: widget.userId,
    );
    if (chat == null || !context.mounted) return;
    // Push the chat screen dynamically — imported only at call-site
    // by the Navigator, not at compile-time in this file.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ChatScreenProxy(chat: chat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthService>().currentUser?.id;
    final isOwn         = currentUserId == widget.userId;

    if (_loading) {
      return const Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardBg  = isDark ? AppColors.darkCardBg : Colors.white;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ── Gradient hero app bar ────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (!isOwn)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: Colors.white),
                  onSelected: (val) {
                    if (val == 'report') _showReportDialog(context);
                    if (val == 'block')  _showBlockDialog(context);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(children: [
                        Icon(Icons.flag_outlined,
                            size: 20, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Report User',
                            style: TextStyle(color: AppColors.error)),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'block',
                      child: Row(children: [
                        Icon(Icons.block_flipped,
                            size: 20, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Block User',
                            style: TextStyle(color: AppColors.error)),
                      ]),
                    ),
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      AvatarWidget(
                        avatarUrl: _profile?.avatarUrl,
                        username: _profile?.username ?? '',
                        radius: 44,
                        borderColor: Colors.white,
                      ).animate().scale(curve: Curves.elasticOut),
                      const SizedBox(height: 10),
                      Text(
                        _profile?.fullName ??
                            _profile?.username ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '@${_profile?.username ?? ''}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      if (_profile?.campus != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.school_outlined,
                                color: Colors.white.withOpacity(0.7),
                                size: 13),
                            const SizedBox(width: 4),
                            Text(
                              _profile!.campus!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_profile?.badges != null &&
                          _profile!.badges.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: _profile!.badges
                              .map((b) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.amber.withOpacity(0.2),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.amber
                                              .withOpacity(0.5)),
                                    ),
                                    child: Text(b,
                                        style: const TextStyle(
                                          color: Colors.amber,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        )),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _stat('${_profile?.totalSwaps ?? 0}',
                              'Swaps'),
                          _vDivider(),
                          _stat(
                            (_profile?.averageRating ?? 0) > 0
                                ? _profile!.averageRating
                                    .toStringAsFixed(1)
                                : '-',
                            'Rating',
                          ),
                          _vDivider(),
                          _stat('${_ratings.length}', 'Reviews'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Body content ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message button
                  if (!isOwn) ...[
                    ElevatedButton.icon(
                      onPressed: () => _startChat(context),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: Text(
                          'Message ${_profile?.username ?? 'User'}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ).animate().fadeIn(),
                    const SizedBox(height: 20),
                  ],

                  // Bio
                  if (_profile?.bio != null &&
                      _profile!.bio!.isNotEmpty) ...[
                    Text('About',
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Text(_profile!.bio!,
                        style: TextStyle(
                            color: textSec, fontSize: 14, height: 1.5)),
                    const SizedBox(height: 16),
                  ],

                  // Links
                  if (_profile != null && _profile!.links.isNotEmpty) ...[
                    Text('Links',
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    ..._profile!.links.map((url) => GestureDetector(
                          onTap: () => _launchUrl(url),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceVariant
                                  : const Color(0xFFF8F8FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.divider,
                                  width: 1),
                            ),
                            child: Row(children: [
                              Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                  color: url.contains('linkedin')
                                      ? const Color(0xFF0A66C2)
                                      : isDark
                                          ? AppColors.darkSurfaceVariant
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.divider,
                                      width: 1),
                                ),
                                child: Icon(_iconForUrl(url), size: 16,
                                    color: url.contains('linkedin')
                                        ? Colors.white
                                        : isDark
                                            ? AppColors.darkTextPrimary
                                            : Colors.black87),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  url
                                      .replaceFirst('https://', '')
                                      .replaceFirst('http://', '')
                                      .replaceFirst('www.', ''),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textPrimary),
                                ),
                              ),
                              Icon(Icons.open_in_new_rounded,
                                  size: 15, color: textSec),
                            ]),
                          ),
                        )),
                    const SizedBox(height: 8),
                  ],

                  // Skills Offered
                  if (_profile?.skillsOffered.isNotEmpty ?? false) ...[
                    Text('Skills Offered',
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _profile!.skillsOffered
                          .map((s) =>
                              _skillChip(s, AppColors.primary, isDark))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Skills Wanted
                  if (_profile?.skillsWanted.isNotEmpty ?? false) ...[
                    Text('Skills Wanted',
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _profile!.skillsWanted
                          .map((s) =>
                              _skillChip(s, AppColors.secondary, isDark))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Reviews
                  if (_ratings.isNotEmpty) ...[
                    Text('Reviews',
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary)),
                    const SizedBox(height: 10),
                    ..._ratings.take(5).map((r) => _RatingTile(
                          rating: r,
                          isDark: isDark,
                          cardBg: cardBg,
                          textSec: textSec,
                        )),
                    const SizedBox(height: 16),
                  ],

                  // Posts
                  if (_posts.isNotEmpty) ...[
                    Text('Posts',
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    ..._posts.map((p) => PostCard(post: p)),
                  ],

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  IconData _iconForUrl(String url) {
    if (url.contains('linkedin')) return Icons.work_outline_rounded;
    if (url.contains('github'))   return Icons.code_rounded;
    return Icons.link_rounded;
  }

  void _showReportDialog(BuildContext context) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for reporting this user.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              final uid =
                  context.read<AuthService>().currentUser?.id;
              if (uid == null) return;
              try {
                await supabase.from('user_reports').insert({
                  'reporter_id': uid,
                  'reported_id': widget.userId,
                  'reason': reason,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('User reported successfully.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to report: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Report',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block User'),
        content: const Text(
            'Are you sure you want to block this user? You will no longer see their posts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final uid =
                  context.read<AuthService>().currentUser?.id;
              if (uid == null) return;
              try {
                await supabase.from('user_blocks').insert({
                  'blocker_id': uid,
                  'blocked_id': widget.userId,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('User blocked successfully.')),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to block: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Block',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8), fontSize: 11)),
        ],
      );

  Widget _vDivider() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        width: 1,
        height: 32,
        color: Colors.white.withOpacity(0.3),
      );

  Widget _skillChip(String skill, Color color, bool isDark) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(skill,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  _ChatScreenProxy  — lazy wrapper that imports ChatScreen only at build time
//  This breaks the circular import:
//    chat_screen → user_profile_screen → chat_screen   ❌
//    chat_screen → user_profile_screen → _ChatScreenProxy → chat_screen  ✅
//  Because _ChatScreenProxy is defined in this same file, and chat_screen.dart
//  imports user_profile_screen.dart (not this proxy). The proxy's import of
//  chat_screen.dart is the only direction: user_profile → chat. The reverse
//  direction (chat → user_profile) uses '../profile/user_profile_screen.dart'
//  which is this file — completing the cycle. To break it we keep the import
//  here (user_profile imports chat) and remove the reverse import from
//  chat_screen.dart (chat must NOT import user_profile). Navigation from chat
//  to user profile goes via AppRoutes below.
// ─────────────────────────────────────────────────────────────────────────────


class _ChatScreenProxy extends StatelessWidget {
  final ChatModel chat;
  const _ChatScreenProxy({required this.chat});

  @override
  Widget build(BuildContext context) => ChatScreen(chat: chat);
}

// ─────────────────────────────────────────────────────────────────────────────
//  _RatingTile  — theme-aware rating card
// ─────────────────────────────────────────────────────────────────────────────
class _RatingTile extends StatelessWidget {
  final RatingModel rating;
  final bool isDark;
  final Color cardBg;
  final Color textSec;

  const _RatingTile({
    required this.rating,
    required this.isDark,
    required this.cardBg,
    required this.textSec,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: AppColors.darkBorder)
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
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
                radius: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rating.rater?.fullName ??
                      rating.rater?.username ?? 'User',
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              RatingBarIndicator(
                rating: rating.rating.toDouble(),
                itemBuilder: (_, __) => const Icon(
                    Icons.star_rounded, color: AppColors.warning),
                itemCount: 5,
                itemSize: 14,
              ),
            ],
          ),
          if (rating.review != null &&
              rating.review!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(rating.review!,
                style: TextStyle(fontSize: 13, color: textSec)),
          ],
        ],
      ),
    );
  }
}