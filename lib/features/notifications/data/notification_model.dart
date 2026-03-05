import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/data_utils.dart';

enum NotificationType { message, asset, achievement, alert }

class NotificationModel {
  final String id;
  final String title;
  final String subtitle;
  final String body;
  final DateTime date;
  final NotificationType type;
  final bool isRead;
  final String? routeName;
  final Map<String, dynamic>? routeArgs;
  final double? progress;

  NotificationModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.date,
    required this.type,
    this.isRead = false,
    this.routeName,
    this.routeArgs,
    this.progress,
  });

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    Map<String, dynamic>? args;
    try {
      if (map['routeArgs'] is Map) {
        args = Map<String, dynamic>.from(map['routeArgs'] as Map);
      }
    } catch (e) {
      debugPrint('Error parsing routeArgs for notification $id: $e');
    }

    return NotificationModel(
      id: id,
      title: DataUtils.asString(map['title']),
      subtitle: DataUtils.asString(map['subtitle']),
      body: DataUtils.asString(map['body']),
      date: DataUtils.asDateTime(map['date']),
      type: _parseType(DataUtils.asString(map['type'])),
      isRead: DataUtils.asBool(map['isRead']),
      routeName: DataUtils.asStringNullable(map['routeName']),
      routeArgs: args,
      progress: DataUtils.asDoubleNullable(map['progress']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'body': body,
      'date': Timestamp.fromDate(date),
      'type': type.name,
      'isRead': isRead,
      'routeName': routeName,
      'routeArgs': routeArgs,
      'progress': progress,
    };
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'message':
        return NotificationType.message;
      case 'asset':
        return NotificationType.asset;
      case 'achievement':
        return NotificationType.achievement;
      case 'alert':
        return NotificationType.alert;
      default:
        return NotificationType.alert;
    }
  }

  Color getIconColor() {
    switch (type) {
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.asset:
        return Colors.orange;
      case NotificationType.achievement:
        return Colors.green;
      case NotificationType.alert:
        return Colors.red;
    }
  }

  IconData getIcon() {
    switch (type) {
      case NotificationType.message:
        return Icons.chat_outlined;
      case NotificationType.asset:
        return Icons.directions_car_rounded;
      case NotificationType.achievement:
        return Icons.emoji_events_outlined;
      case NotificationType.alert:
        return Icons.warning_amber_rounded;
    }
  }
}
