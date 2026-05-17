import 'dart:convert';
import 'package:flutter/material.dart';

enum NotificationType {
  contract,
  payment,
  tenant,
  system,
  utility,
  invoice,
  incident,
  deposit,
  message
}

class NotificationModel {
  final int id;
  final NotificationType type;
  final String title;
  final String description;
  final DateTime createdAt;
  bool isRead;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
    this.isRead = false,
    this.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: int.parse(json['id'].toString()),
      type: _parseType(json['type']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      isRead: (json['is_read'] ?? 0).toString() == '1',
      metadata: json['metadata'] != null 
          ? (json['metadata'] is String 
              ? (jsonDecode(json['metadata']) as Map<String, dynamic>?)
              : Map<String, dynamic>.from(json['metadata']))
          : null,
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'contract': return NotificationType.contract;
      case 'payment': return NotificationType.payment;
      case 'tenant': return NotificationType.tenant;
      case 'utility': return NotificationType.utility;
      case 'invoice': return NotificationType.invoice;
      case 'incident': return NotificationType.incident;
      case 'deposit': return NotificationType.deposit;
      case 'message': return NotificationType.message;
      default: return NotificationType.system;
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.contract: return Icons.assignment_turned_in_outlined;
      case NotificationType.payment: return Icons.account_balance_wallet_outlined;
      case NotificationType.tenant: return Icons.people_outline;
      case NotificationType.utility: return Icons.water_drop_outlined;
      case NotificationType.invoice: return Icons.receipt_long_outlined;
      case NotificationType.incident: return Icons.report_problem_outlined;
      case NotificationType.deposit: return Icons.price_check_outlined;
      case NotificationType.message: return Icons.chat_bubble_outline_rounded;
      case NotificationType.system: return Icons.campaign_outlined;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.contract: return Colors.green;
      case NotificationType.payment: return Colors.orange;
      case NotificationType.tenant: return Colors.blue;
      case NotificationType.utility: return Colors.teal;
      case NotificationType.invoice: return Colors.redAccent;
      case NotificationType.incident: return Colors.amber;
      case NotificationType.deposit: return Colors.pink;
      case NotificationType.message: return Colors.indigo;
      case NotificationType.system: return Colors.purple;
    }
  }
}
