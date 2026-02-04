import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { info, warning, success, error, aiInsight }

class BizNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? actionUrl;
  final Map<String, dynamic>? payload;

  const BizNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.actionUrl,
    this.payload,
  });

  factory BizNotification.fromMap(Map<String, dynamic> map, String id) {
    return BizNotification(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'info'),
        orElse: () => NotificationType.info,
      ),
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      actionUrl: map['actionUrl'],
      payload: map['payload'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'actionUrl': actionUrl,
      'payload': payload,
    };
  }

  BizNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
    String? actionUrl,
    Map<String, dynamic>? payload,
  }) {
    return BizNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      actionUrl: actionUrl ?? this.actionUrl,
      payload: payload ?? this.payload,
    );
  }
}
