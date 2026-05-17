class ChatModel {
  final int senderId;
  final int receiverId;
  final String otherName;
  final String content;
  final String? imageUrl;
  final int isRead;
  final int unreadCount;
  final String createdAt;

  ChatModel({
    required this.senderId,
    required this.receiverId,
    required this.otherName,
    required this.content,
    this.imageUrl,
    required this.isRead,
    required this.unreadCount,
    required this.createdAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      senderId: int.tryParse(json['sender_id']?.toString() ?? "0") ?? 0,
      receiverId: int.tryParse(json['receiver_id']?.toString() ?? "0") ?? 0,
      otherName: json['other_name']?.toString() ?? "N/A",
      content: json['content']?.toString() ?? "",
      imageUrl: json['image_url']?.toString(),
      isRead: int.tryParse(json['is_read']?.toString() ?? "0") ?? 0,
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? "0") ?? 0,
      createdAt: json['created_at']?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'other_name': otherName,
      'content': content,
      'image_url': imageUrl,
      'is_read': isRead,
      'unread_count': unreadCount,
      'created_at': createdAt,
    };
  }
}

class ChatMessageModel {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final int? postId;
  final String? postTitle;
  final String? postImage;
  final String? postPrice;
  final String? houseName;
  final String? imageUrl;
  final String createdAt;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.postId,
    this.postTitle,
    this.postImage,
    this.postPrice,
    this.houseName,
    this.imageUrl,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: int.tryParse(json['id']?.toString() ?? "0") ?? 0,
      senderId: int.tryParse(json['sender_id']?.toString() ?? "0") ?? 0,
      receiverId: int.tryParse(json['receiver_id']?.toString() ?? "0") ?? 0,
      content: json['content']?.toString() ?? "",
      postId: int.tryParse(json['post_id']?.toString() ?? ""),
      postTitle: json['post_title']?.toString(),
      postImage: json['post_image']?.toString(),
      postPrice: json['post_price']?.toString(),
      houseName: json['house_name']?.toString(),
      imageUrl: json['image_url']?.toString(),
      createdAt: json['created_at']?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'post_id': postId,
      'post_title': postTitle,
      'post_image': postImage,
      'post_price': postPrice,
      'house_name': houseName,
      'image_url': imageUrl,
      'created_at': createdAt,
    };
  }
}
