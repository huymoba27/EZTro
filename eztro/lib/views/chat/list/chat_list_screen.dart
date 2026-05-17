import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../detail/chat_detail_screen.dart';
import '../providers/chat_notifier.dart';
import 'package:eztro/core/widgets/widgets.dart';
import 'dart:async';

class ChatListScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const ChatListScreen({super.key, this.onBack});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  int? _currentUserId;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) ref.read(chatListProvider.notifier).refresh();
    });
  }

  Future<void> _loadUserId() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() => _currentUserId = user?.id);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatListAsync = ref.watch(chatListProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: "TIN NHẮN",
        showBackButton: true,
        onBack: widget.onBack,
      ),
      body: chatListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Lỗi: $err")),
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("Chưa có cuộc hội thoại nào", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.read(chatListProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: chats.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final chat = chats[index];
                final otherUserId = chat.senderId == _currentUserId ? chat.receiverId : chat.senderId;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(chat.otherName[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(chat.otherName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    chat.content.isEmpty && chat.imageUrl != null
                        ? "[Hình ảnh]"
                        : chat.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: (chat.isRead == 0 && chat.receiverId == _currentUserId) 
                        ? FontWeight.bold 
                        : FontWeight.normal
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        chat.createdAt.contains(' ')
                            ? chat.createdAt.split(' ')[1].substring(0, 5)
                            : chat.createdAt,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      if (chat.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            chat.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          receiverId: otherUserId,
                          receiverName: chat.otherName,
                        ),
                      ),
                    );
                    ref.read(chatListProvider.notifier).refresh();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
