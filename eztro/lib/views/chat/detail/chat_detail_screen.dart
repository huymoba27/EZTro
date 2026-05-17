import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/chat_model.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../services/chat_service.dart';
import '../providers/chat_notifier.dart';
import 'dart:async';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final int receiverId;
  final String receiverName;
  final int? postId;

  const ChatDetailScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.postId,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int? _currentUserId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _markRead();
  }

  Future<void> _markRead() async {
    final user = await AuthService.getCurrentUser();
    if (user != null) {
      await ChatService.markAsRead(widget.receiverId, user.id);
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() => _currentUserId = user?.id);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _msgController.text.trim();
    if (content.isEmpty) return;
    if (_isSending) return;

    setState(() => _isSending = true);
    final success = await ref
        .read(chatHistoryProvider(widget.receiverId).notifier)
        .sendMessage(content);

    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        _msgController.clear();
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 70);
    if (images.isNotEmpty) {
      for (var image in images) {
        await _sendImage(image.path);
      }
    }
  }

  Future<void> _sendImage(String path) async {
    setState(() => _isSending = true);
    final success = await ref
        .read(chatHistoryProvider(widget.receiverId).notifier)
        .sendMessage("", imagePath: path);
    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatHistoryProvider(widget.receiverId));

    // Lắng nghe để tự động cuộn xuống khi có tin nhắn mới
    ref.listen(chatHistoryProvider(widget.receiverId), (prev, next) {
      if (next is AsyncData) {
        Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);
        _markRead(); // Đánh dấu đã đọc khi có tin nhắn mới
      }
    });

    return Scaffold(
      appBar: CustomAppBar(title: widget.receiverName, centerTitle: false),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Lỗi: $err")),
              data: (messages) => ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.senderId == _currentUserId;
                  return _buildMessageBubble(msg, isMe);
                },
              ),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, bool isMe) {
    bool hasImage = msg.imageUrl != null && msg.imageUrl!.isNotEmpty;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(hasImage ? 4 : 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: hasImage && msg.content.isEmpty
                  ? Colors.transparent
                  : (isMe ? AppColors.primary : Colors.grey[200]),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (hasImage)
                  GestureDetector(
                    onTap: () => _showFullScreenImage(
                      "${ApiConstants.serverUrl}/uploads/chat/${msg.imageUrl}",
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(
                          maxWidth: 300,
                          maxHeight: 400,
                        ),
                        child: Image.network(
                          "${ApiConstants.serverUrl}/uploads/chat/${msg.imageUrl}",
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  ),
                if (msg.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Text(
                      msg.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  msg.createdAt.contains(' ')
                      ? msg.createdAt.split(' ')[1].substring(0, 5)
                      : msg.createdAt,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.black54,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _pickImage,
              icon: const Icon(Icons.image, color: AppColors.primary, size: 28),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _msgController,
                  decoration: const InputDecoration(
                    hintText: "Nhập tin nhắn...",
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _isSending
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
