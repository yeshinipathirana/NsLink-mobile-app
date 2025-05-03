import 'package:flutter/material.dart';
import '../../../../backend/services/database_service.dart';
import '../../../../backend/models/booking.dart';

class ReportsTab extends StatelessWidget {
  final DatabaseService _databaseService = DatabaseService();

  ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Statistics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Real-time statistics tiles
          StreamBuilder<List<Booking>>(
            stream: _databaseService.allBookings,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading statistics: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final bookings = snapshot.data ?? [];
              final totalBookings = bookings.length;
              final approvedBookings =
                  bookings.where((b) => b.status == 'approved').length;
              final pendingBookings =
                  bookings.where((b) => b.status == 'pending').length;
              final rejectedBookings =
                  bookings.where((b) => b.status == 'rejected').length;

              return Column(
                children: [
                  _StatisticTile(
                    title: 'Total Bookings',
                    value: totalBookings.toString(),
                    color: Colors.blue,
                    icon: Icons.book,
                  ),
                  const SizedBox(height: 16),
                  _StatisticTile(
                    title: 'Approved Bookings',
                    value: approvedBookings.toString(),
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                  const SizedBox(height: 16),
                  _StatisticTile(
                    title: 'Pending Bookings',
                    value: pendingBookings.toString(),
                    color: Colors.orange,
                    icon: Icons.pending,
                  ),
                  const SizedBox(height: 16),
                  _StatisticTile(
                    title: 'Rejected Bookings',
                    value: rejectedBookings.toString(),
                    color: Colors.red,
                    icon: Icons.cancel,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),
          const Text(
            'Room Utilization',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Room utilization statistics
          StreamBuilder<List<Booking>>(
            stream: _databaseService.allBookings,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading room statistics: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final bookings = snapshot.data ?? [];
              if (bookings.isEmpty) {
                return const Center(
                  child: Text(
                    'No booking data available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              // Calculate room statistics
              final roomStats = <String, int>{};
              for (var booking
                  in bookings.where((b) => b.status == 'approved')) {
                roomStats[booking.roomId] =
                    (roomStats[booking.roomId] ?? 0) + 1;
              }

              final sortedRooms = roomStats.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return Column(
                children: [
                  for (var entry in sortedRooms.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _RoomUtilizationTile(
                        roomId: entry.key,
                        bookingCount: entry.value,
                        totalBookings: bookings
                            .where((b) => b.status == 'approved')
                            .length,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatisticTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatisticTile({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomUtilizationTile extends StatelessWidget {
  final String roomId;
  final int bookingCount;
  final int totalBookings;

  const _RoomUtilizationTile({
    required this.roomId,
    required this.bookingCount,
    required this.totalBookings,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (bookingCount / totalBookings * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Room $roomId',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: bookingCount / totalBookings,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      HSLColor.fromAHSL(
                              1, (bookingCount / totalBookings * 120), 0.7, 0.5)
                          .toColor(),
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$bookingCount bookings',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
