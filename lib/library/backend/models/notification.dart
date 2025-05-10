// Notification Model
// Represents a notification for a user, including message, timestamp, and related booking info.

import 'package:cloud_firestore/cloud_firestore.dart';

class Notification {
  final String id;
  final String userId;
  final String message;
  final DateTime timestamp;
  final String? bookingId; // Reference to the booking
  final DateTime? bookingDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? roomId;
  final bool isRead; // Track if notification has been read

  Notification({
    required this.id,
    required this.userId,
    required this.message,
    required this.timestamp,
    this.bookingId,
    this.bookingDate,
    this.startTime,
    this.endTime,
    this.roomId,
    this.isRead = false,
  });

  factory Notification.fromMap(Map<String, dynamic> map) {
    DateTime? parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is DateTime) return timestamp;
      if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      if (timestamp is String) return DateTime.parse(timestamp);
      return null;
    }

    final timestamp = parseTimestamp(map['timestamp']) ?? DateTime.now();
    final bookingDate = parseTimestamp(map['bookingDate']);
    final startTime = parseTimestamp(map['startTime']);
    final endTime = parseTimestamp(map['endTime']);

    return Notification(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      message: map['message'] as String? ?? '',
      timestamp: timestamp,
      bookingId: map['bookingId'] as String?,
      bookingDate: bookingDate,
      startTime: startTime,
      endTime: endTime,
      roomId: map['roomId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'bookingId': bookingId,
      'bookingDate':
          bookingDate != null ? Timestamp.fromDate(bookingDate!) : null,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'roomId': roomId,
      'isRead': isRead,
    };
  }

  String get formattedDate {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  bool get isExpired {
    return endTime != null && DateTime.now().isAfter(endTime!);
  }
}
