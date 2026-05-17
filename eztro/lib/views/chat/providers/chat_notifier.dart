import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/chat_service.dart';
import '../../../models/chat_model.dart';
import '../../../services/auth_service.dart';

// Provider cho danh sách hội thoại
final chatListProvider = StateNotifierProvider<ChatNotifier, AsyncValue<List<ChatModel>>>((ref) {
  return ChatNotifier();
});

class ChatNotifier extends StateNotifier<AsyncValue<List<ChatModel>>> {
  ChatNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final chats = await ChatService.getChatList(user.id);
      state = AsyncValue.data(chats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Provider cho lịch sử tin nhắn của một cuộc hội thoại cụ thể
final chatHistoryProvider = StateNotifierProvider.family<ChatMessageNotifier, AsyncValue<List<ChatMessageModel>>, int>((ref, otherUserId) {
  return ChatMessageNotifier(otherUserId);
});

class ChatMessageNotifier extends StateNotifier<AsyncValue<List<ChatMessageModel>>> {
  final int otherUserId;
  Timer? _timer;

  ChatMessageNotifier(this.otherUserId) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    await fetchMessages();
    // Bật polling để cập nhật tin nhắn mới mỗi 3 giây
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) => fetchMessages());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchMessages() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return;

    try {
      final messages = await ChatService.getChatHistory(user.id, otherUserId);
      
      // Chỉ cập nhật state nếu có thay đổi (ví dụ: thêm tin nhắn mới)
      final currentList = state.value ?? [];
      if (messages.length != currentList.length || (messages.isNotEmpty && currentList.isNotEmpty && messages.last.id != currentList.last.id)) {
        state = AsyncValue.data(messages);
      }
    } catch (e, st) {
      // Nếu là lỗi lần đầu thì báo lỗi, nếu đang có data thì giữ data
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<bool> sendMessage(String content, {int? postId, String? imagePath}) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return false;

    try {
      final res = await ChatService.sendMessage(
        senderId: user.id,
        receiverId: otherUserId,
        content: content,
        postId: postId,
        imagePath: imagePath,
      );

      if (res['status'] == 'success') {
        await fetchMessages();
        return true;
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
    return false;
  }
}
