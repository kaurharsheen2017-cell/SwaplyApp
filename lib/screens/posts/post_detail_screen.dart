import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../main.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../chat/chat_screen.dart';
import '../chat/rate_swap_screen.dart';
import '../../screens/profile/user_profile_screen.dart' as profile_screen;

// ─────────────────────────────────────────────────────────────────────────────
//  PostDetailScreen — real-time swap status tied to THIS specific post
// ─────────────────────────────────────────────────────────────────────────────
class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  // ── Swap state ─────────────────────────────────────────────────────────────
  // 'none' | 'pending' | 'confirmed' | 'completed' | 'cancelled'
  String _swapStatus = 'none';
  String? _swapId;
  String? _chatId;

  bool _isLoading   = true;   // initial fetch
  bool _isConfirming = false;
  bool _isMarkingDone = false;

  // All channels stored together for clean disposal
  final List<RealtimeChannel> _channels = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSwapStatus());
  }

  @override
  void dispose() {
    _removeAllChannels();
    super.dispose();
  }

  void _removeAllChannels() {
    for (final ch in _channels) {
      supabase.removeChannel(ch);
    }
    _channels.clear();
  }

  // ── Load initial swap state for THIS post ─────────────────────────────────
  // Strategy: look for a swap row where post_id = widget.post.id
  // and the current user is initiator OR receiver.
  Future<void> _loadSwapStatus() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // Query swaps directly by post_id — most reliable anchor
      final swapRows = await supabase
          .from('swaps')
          .select('id, status, chat_id')
          .eq('post_id', widget.post.id)
          .or('initiator_id.eq.$userId,receiver_id.eq.$userId')
          .order('created_at', ascending: false)
          .limit(1);

      if ((swapRows as List).isNotEmpty) {
        final row    = swapRows.first as Map<String, dynamic>;
        final swapId = row['id']      as String;
        final status = row['status']  as String? ?? 'none';
        final chatId = row['chat_id'] as String;

        if (mounted) {
          setState(() {
            _swapId     = swapId;
            _swapStatus = status;
            _chatId     = chatId;
            _isLoading  = false;
          });
        }
        _subscribeRealtime(chatId, swapId);
        return;
      }

      // No swap yet — check if there's already a chat for this post
      // (chat may exist from "Start Chat" without confirming swap)
      final chatRows = await supabase
          .from('chats')
          .select('id, swap_status')
          .or(
            'and(participant_1.eq.$userId,participant_2.eq.${widget.post.userId}),'
            'and(participant_1.eq.${widget.post.userId},participant_2.eq.$userId)',
          )
          .limit(1);

      if ((chatRows as List).isNotEmpty) {
        final chatRow = chatRows.first as Map<String, dynamic>;
        final chatId  = chatRow['id'] as String;
        if (mounted) {
          setState(() {
            _chatId    = chatId;
            _isLoading = false;
          });
        }
        // Subscribe so we catch if the other party confirms from their side
        _subscribeRealtime(chatId, null);
        return;
      }
    } catch (e) {
      debugPrint('PostDetail _loadSwapStatus error: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ── Real-time subscriptions ───────────────────────────────────────────────
  // One channel per table, both scoped to the chatId.
  void _subscribeRealtime(String chatId, String? swapId) {
    _removeAllChannels();

    // 1. Watch chats row for swap_status changes (UPDATE)
    final chatCh = supabase
        .channel('pds_chat_${chatId}_${widget.post.id}')
        ..onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chats',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: chatId,
          ),
          callback: (payload) {
            final s = payload.newRecord['swap_status'] as String? ?? 'none';
            if (mounted) setState(() => _swapStatus = s);
          },
        )
        ..subscribe();
    _channels.add(chatCh);

    // 2. Watch swaps rows for INSERT (other party confirms) + UPDATE (completed)
    final swapCh = supabase
        .channel('pds_swaps_${chatId}_${widget.post.id}')
        ..onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'swaps',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            // Only react if this swap belongs to our post
            final pid = payload.newRecord['post_id'] as String?;
            if (pid != null && pid != widget.post.id) return;
            final s  = payload.newRecord['status']  as String? ?? 'pending';
            final id = payload.newRecord['id']       as String?;
            if (mounted) {
              setState(() {
                _swapStatus = s;
                if (id != null) _swapId = id;
                _chatId = chatId;
              });
            }
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'swaps',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            final pid = payload.newRecord['post_id'] as String?;
            if (pid != null && pid != widget.post.id) return;
            final s  = payload.newRecord['status'] as String? ?? _swapStatus;
            final id = payload.newRecord['id']      as String?;
            if (mounted) {
              setState(() {
                _swapStatus = s;
                if (id != null) _swapId = id;
              });
            }
          },
        )
        ..subscribe();
    _channels.add(swapCh);
  }

  // ── Confirm Swap ──────────────────────────────────────────────────────────
  Future<void> _onConfirmSwap() async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);

    try {
      final cs = context.read<ChatService>();

      // 1. Get or create a chat with the post owner
      final chat = await cs.getOrCreateChat(
        otherUserId: widget.post.userId,
        postId: widget.post.id,
      );
      if (chat == null || !mounted) return;

      // 2. Confirm dialog
      final isDark  = Theme.of(context).brightness == Brightness.dark;
      final cardBg  = isDark ? AppColors.darkCardBg  : Colors.white;
      final textPri = isDark ? AppColors.darkTextPrimary   : AppColors.textPrimary;
      final textSec = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
      final partner = widget.post.profile?.fullName
          ?? widget.post.profile?.username
          ?? 'this person';

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: cardBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Confirm Swap 🤝', style: TextStyle(color: textPri)),
          content: Text(
            'Confirm a skill swap with $partner?\n\n'
            'Both parties will be able to mark it done once the exchange is complete.',
            style: TextStyle(color: textSec),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: textSec)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success),
              child: const Text('Confirm',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      // 3. Create swap record
      final swap = await cs.confirmSwap(
        chatId: chat.id,
        otherUserId: widget.post.userId,
        postId: widget.post.id,
      );

      if (!mounted) return;

      if (swap != null) {
        setState(() {
          _swapStatus = 'pending';
          _swapId     = swap.id;
          _chatId     = chat.id;
        });
        // Subscribe now that we have a concrete chatId
        _subscribeRealtime(chat.id, swap.id);
        _showSnack('Swap confirmed! 🎉', AppColors.success);
      } else {
        _showSnack('Could not confirm swap. Please try again.',
            AppColors.error);
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  // ── Mark Done ─────────────────────────────────────────────────────────────
  Future<void> _onMarkDone() async {
    if (_isMarkingDone) return;
    setState(() => _isMarkingDone = true);

    try {
      // Re-fetch swap id from DB — handles the case where we came in fresh
      // without a cached _swapId (e.g. other party confirmed from their app)
      String? swapId = _swapId;
      final chatId   = _chatId;

      if (chatId == null) {
        _showSnack('No active swap found for this post.', AppColors.error);
        return;
      }

      if (swapId == null || swapId.isEmpty) {
        final rows = await supabase
            .from('swaps')
            .select('id')
            .eq('chat_id', chatId)
            .eq('post_id', widget.post.id)
            .inFilter('status', ['pending', 'confirmed'])
            .order('created_at', ascending: false)
            .limit(1);

        swapId = (rows as List).isNotEmpty
            ? (rows.first as Map<String, dynamic>)['id'] as String?
            : null;
      }

      if (swapId == null || swapId.isEmpty || !mounted) {
        _showSnack(
            'No active swap to mark done. Confirm the swap first.',
            AppColors.error);
        return;
      }

      // Confirm dialog
      final isDark  = Theme.of(context).brightness == Brightness.dark;
      final cardBg  = isDark ? AppColors.darkCardBg  : Colors.white;
      final textPri = isDark ? AppColors.darkTextPrimary   : AppColors.textPrimary;
      final textSec = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: cardBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Mark Swap as Done?',
              style: TextStyle(color: textPri)),
          content: Text(
              'Confirm that the skill swap has been completed successfully.',
              style: TextStyle(color: textSec)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: textSec)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success),
              child: const Text('Complete',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      final success = await context
          .read<ChatService>()
          .markSwapCompleted(swapId, chatId);

      if (!mounted) return;

      if (success) {
        setState(() => _swapStatus = 'completed');
        _showSnack('Swap marked as complete! 🎉', AppColors.success);

        // Navigate to rating screen
        final chat = await context
            .read<ChatService>()
            .getOrCreateChat(otherUserId: widget.post.userId);
        if (chat != null && mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RateSwapScreen(
                chatId: chatId,
                otherUser: chat.otherUser,
              ),
            ),
          );
        }
      } else {
        _showSnack('Could not mark swap as done. Please try again.',
            AppColors.error);
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isMarkingDone = false);
    }
  }

  // ── Open Chat ─────────────────────────────────────────────────────────────
  Future<void> _openChat() async {
    final chat = await context.read<ChatService>().getOrCreateChat(
          otherUserId: widget.post.userId,
          postId: widget.post.id,
        );
    if (chat != null && mounted) {
      // Subscribe to this chat now so swap changes update us on return
      if (_chatId == null) {
        setState(() => _chatId = chat.id);
        _subscribeRealtime(chat.id, _swapId);
      }
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
      );
      // Refresh status after returning from chat (user may have confirmed there)
      if (mounted) _loadSwapStatus();
    }
  }

  // ── Snackbar helper ───────────────────────────────────────────────────────
  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
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
    final isOwn    = auth.currentUser?.id == widget.post.userId;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ── Gradient app bar ─────────────────────────────────────────────
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
                    widget.post.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => context
                      .read<PostService>()
                      .toggleBookmark(widget.post.id),
                ),
              if (isOwn)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: isDark ? AppColors.darkCardBg : Colors.white,
                  onSelected: (val) async {
                    if (val == 'delete') {
                      final ok = await showDialog<bool>(
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
                                  style:
                                      TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        await context
                            .read<PostService>()
                            .deletePost(widget.post.id);
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
                  if (widget.post.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      children: widget.post.tags
                          .map((t) => _buildTag(t, isDark))
                          .toList(),
                    ).animate().fadeIn(),
                    const SizedBox(height: 12),
                  ],

                  // Title
                  Text(
                    widget.post.title,
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
                          builder: (_) => _UserProfileRoute(
                              userId: widget.post.userId)),
                    ),
                    child: Row(
                      children: [
                        AvatarWidget(
                          avatarUrl: widget.post.profile?.avatarUrl,
                          username: widget.post.profile?.username ?? '',
                          radius: 20,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.profile?.fullName ??
                                  widget.post.profile?.username ??
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
                              Text(timeago.format(widget.post.createdAt),
                                  style: GoogleFonts.dmSans(
                                      fontSize: 11, color: textLt)),
                            ]),
                          ],
                        ),
                        const Spacer(),
                        if ((widget.post.profile?.averageRating ?? 0) > 0)
                          Row(children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFACC15), size: 15),
                            const SizedBox(width: 3),
                            Text(
                              (widget.post.profile?.averageRating ?? 0.0)
                                  .toStringAsFixed(1),
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
                    widget.post.description,
                    style: GoogleFonts.dmSans(
                        fontSize: 14, height: 1.6, color: textSec),
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 20),

                  // Exchange card
                  _ExchangeCard(post: widget.post, isDark: isDark)
                      .animate()
                      .fadeIn(delay: 200.ms),

                  // Open request banner
                  if (widget.post.isOpenRequest) ...[
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

                  // Swap status banner — visible to both parties once active
                  if (!isOwn &&
                      _swapStatus != 'none' &&
                      _swapStatus.isNotEmpty)
                    _SwapStatusBanner(
                      status: _swapStatus,
                      isDark: isDark,
                    ).animate().fadeIn(delay: 250.ms),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom action bar (non-owner only) ────────────────────────────────
      bottomNavigationBar: isOwn
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          height: 44,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _BottomActionBar(
                        swapStatus: _swapStatus,
                        isConfirming: _isConfirming,
                        isMarkingDone: _isMarkingDone,
                        onConfirmSwap: _onConfirmSwap,
                        onMarkDone: _onMarkDone,
                        onOpenChat: _openChat,
                        primary: primary,
                        isDark: isDark,
                      ),
              ),
            ),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Swap status banner (inline, below exchange card)
// ─────────────────────────────────────────────────────────────────────────────
class _SwapStatusBanner extends StatelessWidget {
  final String status;
  final bool isDark;
  const _SwapStatusBanner({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late IconData icon;
    late String label;
    late String sub;

    switch (status) {
      case 'pending':
      case 'confirmed':
        color = AppColors.warning;
        icon  = Icons.hourglass_top_rounded;
        label = 'Swap In Progress';
        sub   = 'Swap confirmed — mark it done once you\'ve exchanged skills.';
        break;
      case 'completed':
        color = AppColors.success;
        icon  = Icons.check_circle_rounded;
        label = 'Swap Completed ✅';
        sub   = 'This skill swap was successfully completed!';
        break;
      case 'cancelled':
        color = AppColors.error;
        icon  = Icons.cancel_rounded;
        label = 'Swap Cancelled';
        sub   = 'This swap was cancelled.';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: color.withOpacity(isDark ? 0.35 : 0.25)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: color)),
              const SizedBox(height: 2),
              Text(sub,
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bottom action bar — 3 states driven by swapStatus
// ─────────────────────────────────────────────────────────────────────────────
class _BottomActionBar extends StatelessWidget {
  final String swapStatus;
  final bool isConfirming;
  final bool isMarkingDone;
  final VoidCallback onConfirmSwap;
  final VoidCallback onMarkDone;
  final VoidCallback onOpenChat;
  final Color primary;
  final bool isDark;

  const _BottomActionBar({
    required this.swapStatus,
    required this.isConfirming,
    required this.isMarkingDone,
    required this.onConfirmSwap,
    required this.onMarkDone,
    required this.onOpenChat,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // ── Completed ─────────────────────────────────────────────────────────
    if (swapStatus == 'completed') {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color:
                  AppColors.success.withOpacity(isDark ? 0.35 : 0.25)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 20),
          const SizedBox(width: 8),
          Text('Swap Completed',
              style: GoogleFonts.dmSans(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        ]),
      );
    }

    // ── Pending / Confirmed — show Mark Done + Open Chat ─────────────────
    if (swapStatus == 'pending' || swapStatus == 'confirmed') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isMarkingDone ? null : onMarkDone,
              icon: isMarkingDone
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                isMarkingDone ? 'Completing…' : 'Mark Swap as Done',
                style:
                    GoogleFonts.dmSans(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenChat,
              icon: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 18),
              label: Text('Open Chat',
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                foregroundColor: primary,
                side:
                    BorderSide(color: primary.withOpacity(0.5)),
              ),
            ),
          ),
        ],
      );
    }

    // ── Default — Confirm Swap + Start Chat ───────────────────────────────
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isConfirming ? null : onConfirmSwap,
            icon: isConfirming
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.handshake_outlined),
            label: Text(
              isConfirming ? 'Confirming…' : 'Confirm Swap',
              style:
                  GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onOpenChat,
            icon: const Icon(Icons.chat_bubble_outline_rounded,
                size: 18),
            label: Text('Start Chat',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              foregroundColor: primary,
              side: BorderSide(color: primary.withOpacity(0.5)),
            ),
          ),
        ),
      ],
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
    final isBarter  = post.exchangeType == 'barter';
    final primary   = isDark ? AppColors.darkPrimary : AppColors.primary;
    final secondary =
        isDark ? AppColors.darkTagBarterText : AppColors.secondary;
    final accent =
        isDark ? AppColors.darkTagMoneyText : AppColors.accent;
    final cardBg = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.cardGradient.colors.first;
    final borderCol = primary.withOpacity(isDark ? 0.25 : 0.15);
    final textLt =
        isDark ? AppColors.darkTextLight : AppColors.textLight;

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
          Expanded(
              child: _ExchangeItem(
            icon: Icons.star_rounded,
            color: primary,
            label: 'Offering',
            value: post.skillOffered,
            isRight: false,
            textLt: textLt,
          )),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withOpacity(isDark ? 0.20 : 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.swap_horiz_rounded,
                color: primary, size: 20),
          ),
          Expanded(
              child: _ExchangeItem(
            icon: isBarter
                ? Icons.sync_alt_rounded
                : Icons.card_giftcard_rounded,
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
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
  const _ExchangeItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.isRight,
    required this.textLt,
  });

  @override
  Widget build(BuildContext context) {
    final textPri = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    return Column(
      crossAxisAlignment:
          isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: textLt)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: isRight
              ? [
                  Flexible(
                      child: Text(value,
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
                  Flexible(
                      child: Text(value,
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

// Navigation proxy
class _UserProfileRoute extends StatelessWidget {
  final String userId;
  const _UserProfileRoute({required this.userId});
  @override
  Widget build(BuildContext context) =>
      profile_screen.UserProfileScreen(userId: userId);
}