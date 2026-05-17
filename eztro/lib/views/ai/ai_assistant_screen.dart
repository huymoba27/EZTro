import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../core/constants/app_colors.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../services/ai_service.dart';
import '../../services/chat_storage_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const Map<String, dynamic> _welcomeMessage = {
    'role': 'ai',
    'text':
        'Xin chào! Tôi là **Trợ lý AI EZTro**.\n\n'
        'Tôi có thể giúp bạn:\n\n'
        '- Xem thống kê & doanh thu\n\n'
        '- Kiểm tra nhà & phòng trọ\n\n'
        '- Tra cứu khách thuê\n\n'
        '- Xem hóa đơn & hợp đồng\n\n'
        '- Theo dõi sự cố\n\n'
        'Hãy hỏi tôi bất cứ điều gì!',
  };

  List<Map<String, dynamic>> _messages = [Map.from(_welcomeMessage)];
  List<dynamic> _history = [];
  bool _isTyping = false;
  bool _isLoading = true;

  // Gợi ý nhanh cho chủ trọ
  final List<Map<String, dynamic>> _suggestions = [
    {'text': 'Thống kê tổng quan'},
    {'text': 'Có bao nhiêu phòng trống?'},
    {'text': 'Danh sách khách thuê'},
    {'text': 'Hóa đơn chưa thanh toán'},
    {'text': 'Danh sách nhà trọ'},
    {'text': 'Sự cố cần xử lý'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedChat();
  }

  /// Tải lịch sử chat đã lưu
  Future<void> _loadSavedChat() async {
    final savedMessages = await ChatStorageService.loadMessages();
    final savedHistory = await ChatStorageService.loadHistory();

    if (mounted) {
      setState(() {
        if (savedMessages.isNotEmpty) {
          _messages = savedMessages;
        }
        _history = savedHistory;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  /// Lưu chat hiện tại
  Future<void> _saveChat() async {
    await ChatStorageService.saveMessages(_messages);
    await ChatStorageService.saveHistory(_history);
  }

  /// Xóa toàn bộ lịch sử và bắt đầu cuộc hội thoại mới
  void _clearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Xóa lịch sử chat"),
        content: const Text(
          "Bạn có chắc muốn xóa toàn bộ lịch sử trò chuyện với AI?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ChatStorageService.clearAll();
              if (mounted) {
                setState(() {
                  _messages = [Map.from(_welcomeMessage)];
                  _history = [];
                });
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  void _sendMessage([String? preset]) async {
    final text = preset ?? _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _controller.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    final response = await AiAssistantService.getResponse(
      text,
      history: _history,
    );

    // Lưu lịch sử chat đơn giản (chỉ text, không lưu function call)
    _history.add({
      "role": "user",
      "parts": [
        {"text": text},
      ],
    });
    _history.add({
      "role": "model",
      "parts": [
        {"text": response},
      ],
    });

    // Giới hạn lịch sử API để tránh quá tải token
    if (_history.length > 20) {
      _history.removeRange(0, 2);
    }

    if (mounted) {
      setState(() {
        _messages.add({'role': 'ai', 'text': response});
        _isTyping = false;
      });
      _scrollToBottom();

      // Tự động lưu sau mỗi lần nhắn tin
      _saveChat();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "TRỢ LÝ AI",
        onBack: () => Navigator.pop(context),
        actions: [
          // Nút xóa lịch sử chat
          if (_messages.length > 1)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: "Cuộc trò chuyện mới",
              onPressed: _clearChat,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildChatBubble(msg['role'], msg['text']);
                    },
                  ),
                ),
                // Gợi ý nhanh (chỉ hiện khi chưa có tin nhắn user)
                if (_messages.length <= 1 && !_isTyping)
                  _buildSuggestionChips(),
                if (_isTyping)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Row(
                      children: [
                        const Text(
                          "AI đang truy vấn dữ liệu",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 4),
                        const JumpingDots(radius: 2, spacing: 2),
                      ],
                    ),
                  ),
                _buildInputArea(),
              ],
            ),
    );
  }

  Widget _buildSuggestionChips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _suggestions.map((s) {
          return GestureDetector(
            onTap: () => _sendMessage(s['text']),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text(
                s['text'],
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChatBubble(String role, String text) {
    final isAi = role == 'ai';
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isAi ? const Color(0xFFF2F2F7) : AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAi ? 0 : 16),
            bottomRight: Radius.circular(isAi ? 16 : 0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: text,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: isAi ? Colors.black87 : Colors.white,
                  fontSize: 14,
                ),
                strong: TextStyle(
                  color: isAi ? AppColors.primary : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                listBullet: TextStyle(
                  color: isAi ? Colors.black87 : Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: "Hỏi về phòng, hóa đơn, thống kê...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(),
            child: const Icon(
              Icons.send_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
