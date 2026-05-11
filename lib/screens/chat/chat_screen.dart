
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/chat_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import 'rate_swap_screen.dart';
import '../../screens/profile/user_profile_screen.dart' as profile_screen;

class ChatScreen extends StatefulWidget {
  final ChatModel chat;
  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final cs = context.read<ChatService>();
    cs.fetchMessages(widget.chat.id).then((_) => _scrollToBottom());
    cs.subscribeToChat(widget.chat.id);
  }

  @override
  void dispose() {
    context.read<ChatService>().unsubscribeFromChat();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    _msgCtrl.clear();

    setState(() => _isSending = true);

    final success = await context.read<ChatService>().sendMessage(
          chatId: widget.chat.id,
          content: text,
        );

    if (success) {
      await context.read<ChatService>().fetchMessages(widget.chat.id);
      _scrollToBottom();
    }

    if (mounted) {
      setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    setState(() => _isSending = true);

    final cs = context.read<ChatService>();

    final url = await cs.uploadChatImage(File(picked.path));

    if (url != null) {
      final success = await cs.sendMessage(
        chatId: widget.chat.id,
        imageUrl: url,
        messageType: 'image',
      );

      if (success) {
        await cs.fetchMessages(widget.chat.id);
        _scrollToBottom();
      }
    }

    if (mounted) {
      setState(() => _isSending = false);
    }
  }

  Future<void> _confirmSwap() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCardBg : Colors.white;
    final textPri =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSec =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Confirm Swap 🤝',
          style: TextStyle(color: textPri),
        ),
        content: Text(
          'Confirm a skill swap with '
          '${widget.chat.otherUser?.fullName ?? widget.chat.otherUser?.username}?\n\n'
          'This will mark the swap as pending until both parties complete it.',
          style: TextStyle(color: textSec),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: textSec),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final swap = await context.read<ChatService>().confirmSwap(
            chatId: widget.chat.id,
            otherUserId: widget.chat.otherUser?.id ?? '',
            postId: widget.chat.postId,
          );

      if (swap != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Swap confirmed! 🎉'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        setState(() {});
      }
    }
  }

  Future<void> _showCompleteSwapDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCardBg : Colors.white;
    final textPri =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSec =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final swaps = await context.read<ChatService>().fetchUserSwaps();

    final swap = swaps.firstWhere(
      (s) => s.chatId == widget.chat.id && s.status == 'pending',
      orElse: () => SwapModel(
        id: '',
        chatId: '',
        initiatorId: '',
        receiverId: '',
        status: 'pending',
        createdAt: DateTime.now(),
      ),
    );

    if (swap.id.isEmpty || !mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Mark Swap as Complete?',
          style: TextStyle(color: textPri),
        ),
        content: Text(
          'Confirm that the skill swap has been completed successfully.',
          style: TextStyle(color: textSec),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: textSec),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text(
              'Complete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context
          .read<ChatService>()
          .markSwapCompleted(swap.id, widget.chat.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Swap marked as complete! 🎉 Please rate your experience.',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        setState(() {});
      }
    }
  }

  void _navigateToProfile() {
    final otherId = widget.chat.otherUser?.id ?? '';

    if (otherId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _UserProfileRoute(userId: otherId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor =
        isDark ? AppColors.darkBackground : AppColors.background;

    final inputBarBg =
        isDark ? AppColors.darkCardBg : AppColors.surface;

    final inputFieldBg =
        isDark ? AppColors.darkSearchBg : AppColors.background;

    final textPri =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    final textLt =
        isDark ? AppColors.darkTextLight : AppColors.textLight;

    final textSec =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final bubbleBg =
        isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

    final borderTop =
        isDark ? AppColors.darkBorder : AppColors.divider;

    final primaryColor =
        isDark ? AppColors.darkPrimary : AppColors.primary;

    final auth = context.watch<AuthService>();

    final currentUserId = auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),

                    GestureDetector(
                      onTap: _navigateToProfile,
                      child: Row(
                        children: [
                          AvatarWidget(
                            avatarUrl:
                                widget.chat.otherUser?.avatarUrl,
                            username:
                                widget.chat.otherUser?.username ?? '',
                            radius: 20,
                          ),

                          const SizedBox(width: 10),

                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.chat.otherUser?.fullName ??
                                    widget.chat.otherUser?.username ??
                                    'User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),

                              Text(
                                '@${widget.chat.otherUser?.username ?? ''}',
                                style: TextStyle(
                                  color:
                                      Colors.white.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    if (widget.chat.swapStatus == 'none' ||
                        widget.chat.swapStatus == '')
                      TextButton.icon(
                        onPressed: _confirmSwap,
                        icon: const Icon(
                          Icons.handshake_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Confirm Swap',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor:
                              Colors.white.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                      ),

                    if (widget.chat.swapStatus == 'pending')
                      TextButton.icon(
                        onPressed: _showCompleteSwapDialog,
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Mark Done',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor:
                              AppColors.success.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: Consumer<ChatService>(
              builder: (_, cs, __) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );

                if (cs.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.waving_hand_rounded,
                          size: 48,
                          color: textLt,
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Say hi to start swapping skills!',
                          style: TextStyle(
                            color: textSec,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  itemCount: cs.messages.length,
                  itemBuilder: (_, i) {
                    final msg = cs.messages[i];
                    final isMe =
                        msg.senderId == currentUserId;

                    if (msg.messageType == 'system') {
                      return _buildSystemMsg(
                        msg.content ?? '',
                        isDark,
                      );
                    }

                    return _buildBubble(
                      msg,
                      isMe,
                      textPri,
                      textLt,
                      bubbleBg,
                      isDark,
                    ).animate().fadeIn(duration: 200.ms);
                  },
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: inputBarBg,
              border: Border(
                top: BorderSide(
                  color: borderTop,
                  width: 1,
                ),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    onPressed:
                        _isSending ? null : _pickAndSendImage,
                    icon: Icon(
                      Icons.image_outlined,
                      color: primaryColor,
                    ),
                    tooltip: 'Send Image',
                  ),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: inputFieldBg,
                        borderRadius:
                            BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization:
                            TextCapitalization.sentences,
                        style: TextStyle(
                          color: textPri,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: textLt,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  GestureDetector(
                    onTap:
                        _isSending ? null : _sendMessage,
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient:
                            AppColors.primaryGradient,
                        borderRadius:
                            BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary
                                .withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: _isSending
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(
    MessageModel msg,
    bool isMe,
    Color textPri,
    Color textLt,
    Color bubbleBg,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 50 : 0,
        right: isMe ? 0 : 50,
        bottom: 6,
      ),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: msg.messageType == 'image'
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
            decoration: BoxDecoration(
              gradient:
                  isMe ? AppColors.primaryGradient : null,
              color: isMe ? null : bubbleBg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft:
                    Radius.circular(isMe ? 18 : 4),
                bottomRight:
                    Radius.circular(isMe ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    isDark ? 0.2 : 0.05,
                  ),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: msg.messageType == 'image' &&
                    msg.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft:
                          const Radius.circular(18),
                      topRight:
                          const Radius.circular(18),
                      bottomLeft:
                          Radius.circular(isMe ? 18 : 4),
                      bottomRight:
                          Radius.circular(isMe ? 4 : 18),
                    ),
                    child: Image.network(
                      msg.imageUrl!,
                      width: 200,
                      fit: BoxFit.cover,
                      loadingBuilder:
                          (_, child, progress) {
                        if (progress == null) {
                          return child;
                        }

                        return const SizedBox(
                          width: 200,
                          height: 150,
                          child: Center(
                            child:
                                CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                  )
                : Text(
                    msg.content ?? '',
                    style: TextStyle(
                      color:
                          isMe ? Colors.white : textPri,
                      fontSize: 14,
                    ),
                  ),
          ),

          const SizedBox(height: 2),

          Text(
            timeago.format(msg.createdAt),
            style: TextStyle(
              fontSize: 10,
              color: textLt,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMsg(
    String content,
    bool isDark,
  ) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(
            isDark ? 0.18 : 0.10,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          content,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.success,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _UserProfileRoute extends StatelessWidget {
  final String userId;

  const _UserProfileRoute({
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return profile_screen.UserProfileScreen(
      userId: userId,
    );
  }
}
