// Library Booking System - Database Service
// Handles all database operations for the library booking system.
// Includes room management, booking operations, statistics, and time slot management.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room.dart';
import '../models/booking.dart';
import '../models/notification.dart';
import 'package:logger/logger.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection references for our main data entities
  final CollectionReference roomsCollection =
      FirebaseFirestore.instance.collection('rooms');
  final CollectionReference bookingsCollection =
      FirebaseFirestore.instance.collection('bookings');
  final CollectionReference blockedSlotsCollection =
      FirebaseFirestore.instance.collection('blocked_slots');

  // Get a real-time stream of all available rooms
  // This helps us maintain an up-to-date view of room availability
  Stream<List<Room>> get rooms {
    return _db.collection('rooms').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Room.fromMap(data);
      }).toList();
    });
  }

  // Add a new room to our system
  // This is typically used by administrators to expand library capacity
  Future<void> addRoom({
    required String name,
    required int capacity,
    bool isAvailable = true,
  }) async {
    try {
      // Create a unique room ID
      final String roomId = 'room${DateTime.now().millisecondsSinceEpoch}';

      final Room room = Room(
        id: roomId,
        name: name,
        capacity: capacity,
        isAvailable: isAvailable,
      );

      await _db.collection('rooms').doc(roomId).set(room.toMap());
      Logger().i('Room added successfully: $roomId');
    } catch (e) {
      Logger().e('Error adding room: $e');
      throw Exception('Failed to add room: $e');
    }
  }

  // Delete a room from our system
  // This is typically used by administrators to remove a room from the system
  Future<void> deleteRoom(String roomId) {
    return _db.collection('rooms').doc(roomId).delete();
  }

  // Update the availability of a room
  // This is typically used by administrators to manage room availability
  Future<void> updateRoomAvailability(String roomId, bool isAvailable) {
    return _db.collection('rooms').doc(roomId).update({
      'isAvailable': isAvailable,
    });
  }

  // Create a new booking request
  // This is used when students want to reserve a room
  Future<void> addBooking(Booking booking) async {
    try {
      // Check for overlapping bookings
      final existingBookings = await _db
          .collection('bookings')
          .where('roomId', isEqualTo: booking.roomId)
          .where('date',
              isEqualTo: Timestamp.fromDate(DateTime(
                booking.date.year,
                booking.date.month,
                booking.date.day,
              )))
          .where('status', whereIn: ['pending', 'approved']).get();

      // Check for time slot conflicts
      for (var doc in existingBookings.docs) {
        final existingBooking = Booking.fromMap({
          ...doc.data(),
          'id': doc.id,
        });
        if (booking.overlaps(existingBooking)) {
          throw Exception('This time slot is already booked');
        }
      }

      // Add booking to Firestore
      final docRef = await _db.collection('bookings').add({
        'id': booking.id,
        'roomId': booking.roomId,
        'studentId': booking.studentId,
        'date': Timestamp.fromDate(DateTime(
          booking.date.year,
          booking.date.month,
          booking.date.day,
        )),
        'startTime': Timestamp.fromDate(booking.startTime),
        'endTime': Timestamp.fromDate(booking.endTime),
        'status': booking.status,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create notification for admin
      await _createNotification(
        roomName: 'Room ${booking.roomId}',
        status: 'pending',
        userId: booking.studentId,
      );

      Logger().i('Booking added successfully: ${docRef.id}');
    } catch (e) {
      Logger().e('Error adding booking: $e');
      throw Exception('Failed to create booking: $e');
    }
  }

  // Get a stream of all pending bookings
  // This helps administrators manage new requests in real-time
  Stream<List<Booking>> get pendingBookings {
    try {
      return _db
          .collection('bookings')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                final data = doc.data();
                data['id'] = doc.id;
                return Booking.fromMap(data);
              } catch (e) {
                Logger().e('Error converting booking document: $e');
                return null;
              }
            })
            .where((booking) => booking != null)
            .cast<Booking>()
            .toList();
      });
    } catch (e) {
      Logger().e('Error fetching pending bookings: $e');
      return Stream.value([]);
    }
  }

  // Get a stream of all bookings
  // This helps in managing all bookings
  Stream<List<Booking>> get allBookings {
    try {
      return _db
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                final data = doc.data();
                data['id'] = doc.id;
                return Booking.fromMap(data);
              } catch (e) {
                Logger().e('Error converting booking document: $e');
                return null;
              }
            })
            .where((booking) => booking != null)
            .cast<Booking>()
            .toList();
      });
    } catch (e) {
      Logger().e('Error fetching all bookings: $e');
      return Stream.value([]);
    }
  }

  // Update the status of a booking (approve/reject)
  Future<void> updateBookingStatus(String bookingId, String status) async {
    Logger().i(
        'updateBookingStatus called for booking $bookingId, status: $status');
    try {
      // Get the booking details first
      final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) {
        Logger().e('Booking not found for id $bookingId');
        throw Exception('Booking not found');
      }

      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      final String roomId = bookingData['roomId'].toString();
      final String studentId = bookingData['studentId'].toString();

      Logger().i(
          'Updating booking $bookingId for student $studentId, status: $status');

      // Update the booking status
      await _db.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Logger().i('Attempting to create notification for student $studentId');
      // Create notification for the student
      try {
        await _createNotification(
          roomName: 'Room $roomId',
          status: status,
          userId: studentId,
        );
        Logger().i('Notification created for student $studentId');
      } catch (e) {
        Logger().e('Failed to create notification for $studentId: $e');
        rethrow;
      }

      Logger().i('Booking $bookingId status updated to $status');
    } catch (e) {
      Logger().e('Error updating booking status: $e');
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Get all approved bookings for a specific room and date
  // This helps prevent double bookings and manage room availability
  Future<List<Booking>> getApprovedBookingsForRoomAndDate(
    String roomId,
    DateTime date,
  ) async {
    final snapshot = await bookingsCollection
        .where('roomId', isEqualTo: roomId)
        .where('date', isEqualTo: date.millisecondsSinceEpoch)
        .where('status', isEqualTo: 'approved')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Booking.fromMap(data);
    }).toList();
  }

  // Block a time slot for maintenance or special events
  // This allows administrators to manage room availability
  Future<void> blockTimeSlot(
    String roomId,
    DateTime date,
    DateTime startTime,
    DateTime endTime,
  ) async {
    await blockedSlotsCollection.add({
      'roomId': roomId,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
    });
  }

  // Get the total number of approved reservations
  Stream<int> get totalReservations {
    try {
      return _db
          .collection('bookings')
          .where('status', isEqualTo: 'approved')
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      Logger().e('Error fetching total reservations: $e');
      return Stream.value(0);
    }
  }

  // Get the number of pending approvals
  Stream<int> get pendingApprovals {
    try {
      return _db
          .collection('bookings')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      Logger().e('Error fetching pending approvals: $e');
      return Stream.value(0);
    }
  }

  // Get the number of available rooms for today
  // This provides a quick overview of library capacity
  Stream<int> get availableRooms {
    try {
      return _db
          .collection('rooms')
          .where('isAvailable', isEqualTo: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      Logger().e('Error fetching available rooms: $e');
      return Stream.value(0);
    }
  }

  // Get the most popular booking time slots
  // This helps in understanding peak usage patterns
  Stream<List<Map<String, dynamic>>> get popularTimeSlots {
    return bookingsCollection
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
      Map<int, int> hourCount = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        final booking = Booking.fromMap(data);
        int hour = booking.startTime.hour;
        hourCount[hour] = (hourCount[hour] ?? 0) + 1;
      }

      List<Map<String, dynamic>> sorted = hourCount.entries
          .map((e) => {'hour': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (b['count'] as num).compareTo(a['count'] as num));

      return sorted
          .take(3)
          .map(
            (slot) => {
              'time': '${slot['hour']}:00 - ${(slot['hour'] + 2) % 24}:00',
              'percentage':
                  '${((slot['count'] as num) / (snapshot.docs.isEmpty ? 1 : snapshot.docs.length) * 100).toStringAsFixed(0)}%',
            },
          )
          .toList();
    });
  }

  /// Send a simple notification to a student by their studentId
  Future<void> sendNotificationToStudent({
    required String studentId,
    required String message,
  }) async {
    await _db.collection('notifications').add({
      'userId': studentId,
      'message': message,
      'timestamp': Timestamp.fromDate(DateTime.now()),
      'isRead': false,
    });
  }

  // Cleaned up _createNotification to only store essential fields
  Future<void> _createNotification({
    required String roomName,
    required String status,
    required String userId,
  }) async {
    try {
      String message;
      switch (status.toLowerCase()) {
        case 'approved':
          message = 'Admin Accept your Request';
          break;
        case 'rejected':
          message =
              'Admin Reject your Request. Use different date or time slot and try again';
          break;
        case 'pending':
          message =
              'Your booking request for $roomName is pending admin approval';
          break;
        default:
          throw Exception('Unknown status for notification: $status');
      }
      Logger().i(
          'Creating notification in Firestore for userId: $userId, message: $message');
      await _db.collection('notifications').add({
        'userId': userId,
        'message': message,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'isRead': false,
      });
      Logger()
          .i('Notification document added to Firestore for userId: $userId');
    } catch (e) {
      Logger().e('Error in _createNotification: $e');
      throw Exception('Failed to create notification: $e');
    }
  }

  // Get notifications for a specific user
  Stream<List<Notification>> getNotificationsForUser(String userId) {
    try {
      return _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
        final notifications = <Notification>[];

        for (var doc in snapshot.docs) {
          try {
            final data = doc.data();
            data['id'] = doc.id;
            final notification = Notification.fromMap(data);

            // Check if notification is expired
            if (notification.isExpired) {
              // Delete expired notification
              await doc.reference.delete();
              continue;
            }

            notifications.add(notification);
          } catch (e) {
            Logger().e('Error converting notification: $e');
          }
        }

        return notifications;
      });
    } catch (e) {
      Logger().e('Error fetching notifications: $e');
      return Stream.value([]);
    }
  }

  // Get unread notification count for a user
  Stream<int> getUnreadNotificationCount(String userId) {
    try {
      return _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      Logger().e('Error fetching unread notification count: $e');
      return Stream.value(0);
    }
  }

  // Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
      Logger().i('Notification $notificationId marked as read');
    } catch (e) {
      Logger().e('Error marking notification as read: $e');
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Initialize sample rooms for testing
  Future<void> initializeSampleRooms() async {
    final sampleRooms = [
      {'name': '01', 'capacity': 4},
      {'name': '02', 'capacity': 4},
      {'name': '03', 'capacity': 4},
      {'name': '04', 'capacity': 4},
    ];

    for (var room in sampleRooms) {
      await addRoom(
        name: room['name'] as String,
        capacity: room['capacity'] as int,
        isAvailable: true,
      );
    }
  }
}
