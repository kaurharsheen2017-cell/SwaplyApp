import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../main.dart';
import '../models/chat_model.dart';
import '../models/profile_model.dart';

class ChatService extends ChangeNotifier {
  List<ChatModel> _chats = [];
  List<MessageModel> _messages = [];
  List<SwapModel> _userSwaps = [];
  bool _isLoading = false;

  RealtimeChannel? _messageChannel;

  List<ChatModel> get chats => _chats;
  List<MessageModel> get messages => _messages;
  List<SwapModel> get userSwaps => _userSwaps;
  bool get isLoading => _isLoading;

  // ═════════════════════════════════════════════
  // GET OR CREATE CHAT
  // ═════════════════════════════════════════════
  Future<ChatModel?> getOrCreateChat({
    required String otherUserId,
    String? postId,
  }) async {
    final currentUserId = supabase.auth.currentUser?.id;

    if (currentUserId == null) return null;

    try {
      final existing = await supabase
          .from('chats')
          .select()
          .or(
            'and(participant_1.eq.$currentUserId,participant_2.eq.$otherUserId),and(participant_1.eq.$otherUserId,participant_2.eq.$currentUserId)',
          )
          .maybeSingle();

      if (existing != null) {
        final otherProfile = await supabase
            .from('profiles')
            .select()
            .eq('id', otherUserId)
            .single();

        return ChatModel.fromJson(
          existing,
          otherUser: ProfileModel.fromJson(otherProfile),
        );
      }

      final data = await supabase
          .from('chats')
          .insert({
            'participant_1': currentUserId,
            'participant_2': otherUserId,
          })
          .select()
          .single();

      final otherProfile = await supabase
          .from('profiles')
          .select()
          .eq('id', otherUserId)
          .single();

      return ChatModel.fromJson(
        data,
        otherUser: ProfileModel.fromJson(otherProfile),
      );
    } catch (e) {
      debugPrint('Error getting/creating chat: $e');
      return null;
    }
  }

  // ═════════════════════════════════════════════
  // FETCH CHATS
  // ═════════════════════════════════════════════
  Future<void> fetchChats() async {
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final data = await supabase
          .from('chats')
          .select()
          .or('participant_1.eq.$userId,participant_2.eq.$userId')
          .order('last_message_at', ascending: false);

      List<ChatModel> chats = [];

      for (final chatJson in data as List) {
        final otherUserId = chatJson['participant_1'] == userId
            ? chatJson['participant_2']
            : chatJson['participant_1'];

        final profileData = await supabase
            .from('profiles')
            .select()
            .eq('id', otherUserId)
            .single();

        chats.add(
          ChatModel.fromJson(
            chatJson,
            otherUser: ProfileModel.fromJson(profileData),
          ),
        );
      }

      _chats = chats;
    } catch (e) {
      debugPrint('Error fetching chats: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ═════════════════════════════════════════════
  // FETCH MESSAGES
  // ═════════════════════════════════════════════
  Future<void> fetchMessages(String chatId) async {
    try {
      final data = await supabase
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);

      _messages = (data as List)
          .map((m) => MessageModel.fromJson(m))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
  }

  // ═════════════════════════════════════════════
  // REALTIME SUBSCRIPTION
  // ═════════════════════════════════════════════
  void subscribeToChat(String chatId) {
    unsubscribeFromChat();

    _messageChannel = supabase.channel('chat_$chatId');

    _messageChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) async {
            await fetchMessages(chatId);
          },
        )
        .subscribe();
  }

  // ═════════════════════════════════════════════
  // UNSUBSCRIBE
  // ═════════════════════════════════════════════
  void unsubscribeFromChat() {
    if (_messageChannel != null) {
      supabase.removeChannel(_messageChannel!);
      _messageChannel = null;
    }

    _messages = [];
  }

  // ═════════════════════════════════════════════
  // SEND MESSAGE
  // ═════════════════════════════════════════════
  Future<bool> sendMessage({
    required String chatId,
    String? content,
    String? imageUrl,
    String messageType = 'text',
  }) async {
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return false;

    try {
      await supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': userId,
        'content': content ?? '',
        'image_url': imageUrl,
        'message_type': messageType,
      });

      await supabase.from('chats').update({
        'last_message':
            messageType == 'image' ? '📷 Image' : content,
        'last_message_at':
            DateTime.now().toIso8601String(),
      }).eq('id', chatId);

      // Immediate refresh
      await fetchMessages(chatId);

      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  // ═════════════════════════════════════════════
  // IMAGE UPLOAD
  // ═════════════════════════════════════════════
 Future<String?> uploadChatImage(File imageFile) async {
  try {
    final fileName =
        '${const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final bytes = await imageFile.readAsBytes();

    await supabase.storage
        .from('chat-images')
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
          ),
        );

    final publicUrl = supabase.storage
        .from('chat-images')
        .getPublicUrl(fileName);

    debugPrint('UPLOAD SUCCESS: $publicUrl');

    return publicUrl;
  } catch (e) {
    debugPrint('Error uploading image: $e');
    return null;
  }
}
  // ═════════════════════════════════════════════
  // CONFIRM SWAP
  // ═════════════════════════════════════════════
  Future<SwapModel?> confirmSwap({
    required String chatId,
    required String otherUserId,
    String? postId,
  }) async {
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return null;

    try {
      // Check if a swap already exists for this chat to avoid duplicates
      final existing = await supabase
          .from('swaps')
          .select()
          .eq('chat_id', chatId)
          .inFilter('status', ['pending', 'confirmed'])
          .limit(1);

      Map<String, dynamic> data;
      if ((existing as List).isNotEmpty) {
        // Swap already exists — reuse it and just ensure chat is updated
        data = existing.first as Map<String, dynamic>;
      } else {
        final insertData = {
          'chat_id': chatId,
          'initiator_id': userId,
          'receiver_id': otherUserId,
          'status': 'pending',
        };
        if (postId != null && postId.isNotEmpty) {
          insertData['post_id'] = postId;
        }
        data = await supabase
            .from('swaps')
            .insert(insertData)
            .select()
            .single();
      }

      await supabase.from('chats').update({
        'swap_confirmed': true,
        'swap_status': 'pending',
      }).eq('id', chatId);

      await sendMessage(
        chatId: chatId,
        content:
            '🤝 Swap confirmed! Waiting for completion.',
        messageType: 'system',
      );

      final swapModel = SwapModel.fromJson(data);
      // Refresh local swaps so Profile screen shows the new pending swap
      await fetchUserSwaps();
      return swapModel;
    } catch (e) {
      debugPrint('Error confirming swap: $e');
      return null;
    }
  }

  // ═════════════════════════════════════════════
  // COMPLETE SWAP
  // ═════════════════════════════════════════════
  Future<bool> markSwapCompleted(
    String swapId,
    String chatId,
  ) async {
    try {
      await supabase.from('swaps').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', swapId);

      await supabase.from('chats').update({
        'swap_status': 'completed',
      }).eq('id', chatId);

      // System message so both parties see the status change in chat
      await sendMessage(
        chatId: chatId,
        content: '✅ Swap marked as completed! Rate your experience.',
        messageType: 'system',
      );

      // Refresh the local swaps list so Profile screen updates reactively
      await fetchUserSwaps();

      return true;
    } catch (e) {
      debugPrint('Error marking swap completed: $e');
      return false;
    }
  }

  // ═════════════════════════════════════════════
  // FETCH USER SWAPS  (enriched — batched queries)
  // ═════════════════════════════════════════════
  Future<List<SwapModel>> fetchUserSwaps() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // 1. Fetch all swaps for this user
      final swapRows = await supabase
          .from('swaps')
          .select()
          .or('initiator_id.eq.$userId,receiver_id.eq.$userId')
          .order('created_at', ascending: false) as List;

      if (swapRows.isEmpty) return [];

      // 2. Collect unique partner IDs and post IDs in one pass
      final partnerIds = <String>{};
      final postIds    = <String>{};
      final chatIds    = <String>{};

      for (final s in swapRows) {
        final otherId = s['initiator_id'] == userId
            ? s['receiver_id'] as String
            : s['initiator_id'] as String;
        partnerIds.add(otherId);
        final pid = s['post_id'] as String?;
        if (pid != null && pid.isNotEmpty) postIds.add(pid);
        chatIds.add(s['chat_id'] as String);
      }

      // 3. Batch-fetch all partner profiles
      final profileRows = await supabase
          .from('profiles')
          .select()
          .inFilter('id', partnerIds.toList()) as List;
      final profileMap = {
        for (final p in profileRows) p['id'] as String: ProfileModel.fromJson(p as Map<String, dynamic>)
      };

      // 4. Batch-fetch post_id from chats (for swaps without a direct post_id)
      final chatRows = await supabase
          .from('chats')
          .select('id, post_id')
          .inFilter('id', chatIds.toList()) as List;
      final chatPostMap = {
        for (final c in chatRows)
          if (c['post_id'] != null) c['id'] as String: c['post_id'] as String
      };

      // Merge all known post IDs
      for (final chatPostId in chatPostMap.values) {
        postIds.add(chatPostId);
      }

      // 5. Batch-fetch post details
      Map<String, Map<String, dynamic>> postMap = {};
      if (postIds.isNotEmpty) {
        final postRows = await supabase
            .from('posts')
            .select('id, skill_offered, skill_wanted, exchange_type')
            .inFilter('id', postIds.toList()) as List;
        postMap = {
          for (final p in postRows) p['id'] as String: p as Map<String, dynamic>
        };
      }

      // 6. Assemble enriched SwapModel list
      final List<SwapModel> result = [];
      for (final s in swapRows) {
        final otherId = s['initiator_id'] == userId
            ? s['receiver_id'] as String
            : s['initiator_id'] as String;

        final partnerProfile = profileMap[otherId];

        final postId = (s['post_id'] as String?)?.isNotEmpty == true
            ? s['post_id'] as String
            : chatPostMap[s['chat_id'] as String];
        final postData = postId != null ? postMap[postId] : null;

        result.add(SwapModel.fromJson(
          s as Map<String, dynamic>,
          otherUserProfile: partnerProfile,
          skillOffered: postData?['skill_offered'] as String?,
          skillWanted:  postData?['skill_wanted']  as String?,
          exchangeType: postData?['exchange_type'] as String?,
        ));
      }

      _userSwaps = result;
      notifyListeners();
      return result;
    } catch (e) {
      debugPrint('Error fetching swaps: $e');
      return [];
    }
  }

  // ═════════════════════════════════════════════
  // SUBMIT RATING
  // ═════════════════════════════════════════════
  Future<bool> submitRating({
    required String swapId,
    required String rateeId,
    required int rating,
    String? review,
  }) async {
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return false;

    try {
      await supabase.from('ratings').insert({
        'swap_id': swapId,
        'rater_id': userId,
        'ratee_id': rateeId,
        'rating': rating,
        'review': review,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // ═════════════════════════════════════════════
  // FETCH USER RATINGS
  // ═════════════════════════════════════════════
  Future<List<RatingModel>> fetchUserRatings(
    String userId,
  ) async {
    try {
      final data = await supabase
          .from('ratings')
          .select()
          .eq('ratee_id', userId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((r) => RatingModel.fromJson(r))
          .toList();
    } catch (e) {
      return [];
    }
  }
}