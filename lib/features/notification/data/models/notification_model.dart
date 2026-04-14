import 'package:flutter/material.dart';

enum NotificationType { session, message, update, achievement, reminder }

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String description;
  final String time;
  bool isRead;
  final IconData icon;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.time,
    required this.isRead,
    required this.icon,
  });

  static NotificationType _parseType(String? typeStr) {
    switch (typeStr) {
      case 'session': return NotificationType.session;
      case 'message': return NotificationType.message;
      case 'achievement': return NotificationType.achievement;
      case 'reminder': return NotificationType.reminder;
      default: return NotificationType.update;
    }
  }

  static IconData _parseIcon(String? iconName) {
    switch (iconName) {
      case 'event': return Icons.event;
      case 'chat': return Icons.chat;
      case 'system_update': return Icons.system_update;
      case 'emoji_events': return Icons.emoji_events;
      case 'assessment': return Icons.assessment;
      case 'check_circle': return Icons.check_circle;
      case 'person_add': return Icons.person_add;
      case 'lightbulb': return Icons.lightbulb;
      case 'rocket_launch': return Icons.rocket_launch;
      default: return Icons.notifications;
    }
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] ?? '').toString(),
      type: _parseType(json['type']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      time: json['created_at'] ?? json['time'] ?? '',
      isRead: (json['is_read'] ?? 0) == 1,
      icon: _parseIcon(json['icon_name']),
    );
  }
}
