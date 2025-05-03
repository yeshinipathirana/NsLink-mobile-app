// Booking Model
// Represents a room booking in the library system.
// Handles booking identification, room and student info, time slot management, status tracking, and database conversions.

import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  // Unique identifier for the booking
  final String id;

  // Reference to the room being booked
  final String roomId;

  // ID of the student making the booking
  final String studentId;

  // The date of the booking
  final DateTime date;

  // Start time of the booking slot
  final DateTime startTime;

  // End time of the booking slot
  final DateTime endTime;

  // Current status of the booking (pending/approved/rejected)
  final String status;

  // Constructor requiring all essential booking information
  Booking({
    required this.id,
    required this.roomId,
    required this.studentId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  // Creates a Booking object from Firestore data
  // This makes our database operations more intuitive and maintainable
  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as String,
      roomId: map['roomId'] as String,
      studentId: map['studentId'] as String,
      date: (map['date'] as Timestamp).toDate(),
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      status: map['status'] as String,
    );
  }

  // Converts Booking object to Firestore-compatible format
  // This ensures consistent data structure in our database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'studentId': studentId,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status,
    };
  }

  // String representation of the booking for debugging and logging
  @override
  String toString() {
    return 'Booking: Room $roomId, Date: ${date.toString().split(' ')[0]}, Time: ${startTime.hour}:${startTime.minute}-${endTime.hour}:${endTime.minute}';
  }

  // Checks if this booking overlaps with another booking
  bool overlaps(Booking other) {
    return roomId == other.roomId &&
        date.year == other.date.year &&
        date.month == other.date.month &&
        date.day == other.date.day &&
        startTime.isBefore(other.endTime) &&
        endTime.isAfter(other.startTime);
  }
}
