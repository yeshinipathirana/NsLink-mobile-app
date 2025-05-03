import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../backend/services/database_service.dart';
import '../../backend/models/notification.dart' as app_notification;
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final Logger _logger = Logger();
  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isLoading = true;
    });
    await _loadUserId();
  }

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? studentId = prefs.getString('studentId');
      debugPrint('Loaded studentId for notifications: $studentId');
      setState(() {
        _currentUserId = studentId;
        _isLoading = false;
      });
    } catch (e) {
      _logger.w('SharedPreferences not available: $e');
      setState(() {
        _currentUserId = null;
        _isLoading = false;
      });
    }
  }

  void _showBookingDetails(app_notification.Notification notification) async {
    // Mark notification as read when viewed
    if (!notification.isRead) {
      await _databaseService.markNotificationAsRead(notification.id);
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Booking Time Slot',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.teal),
              title: const Text(
                'Date',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                notification.bookingDate != null
                    ? DateFormat('EEEE, MMMM d, y')
                        .format(notification.bookingDate!)
                    : 'Not specified',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.teal),
              title: const Text(
                'Time',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                (notification.startTime != null && notification.endTime != null)
                    ? '${DateFormat('h:mm a').format(notification.startTime!)} - ${DateFormat('h:mm a').format(notification.endTime!)}'
                    : 'Not specified',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room, color: Colors.teal),
              title: const Text(
                'Room',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                notification.roomId != null
                    ? 'Room ${notification.roomId}'
                    : 'Not specified',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.teal,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _currentUserId == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Student ID Found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please make a booking first to see notifications',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : StreamBuilder<List<app_notification.Notification>>(
                  stream:
                      _databaseService.getNotificationsForUser(_currentUserId!),
                  builder: (context, snapshot) {
                    debugPrint(
                        'Notifications snapshot for $_currentUserId: ${snapshot.data}');
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      _logger
                          .e('Error fetching notifications: ${snapshot.error}');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final notifications = snapshot.data ?? [];

                    if (notifications.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _showBookingDetails(notification),
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    _getStatusColor(notification.message),
                                child: Icon(
                                  _getStatusIcon(notification.message),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                notification.message,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('yyyy-MM-dd HH:mm')
                                        .format(notification.timestamp),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (notification.bookingDate != null &&
                                      notification.startTime != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Scheduled: ${DateFormat('MMM d').format(notification.bookingDate!)} at ${DateFormat('h:mm a').format(notification.startTime!)}',
                                      style: const TextStyle(
                                        color: Colors.teal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }

  Color _getStatusColor(String message) {
    if (message.contains('approved')) {
      return Colors.green;
    } else if (message.contains('rejected')) {
      return Colors.red;
    }
    return Colors.orange;
  }

  IconData _getStatusIcon(String message) {
    if (message.contains('approved')) {
      return Icons.check_circle;
    } else if (message.contains('rejected')) {
      return Icons.cancel;
    }
    return Icons.pending;
  }
}
