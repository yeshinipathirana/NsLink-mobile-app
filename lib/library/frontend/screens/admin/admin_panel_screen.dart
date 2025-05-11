import 'package:flutter/material.dart';
import '../../../backend/services/database_service.dart';
import '../../../backend/models/booking.dart';
import '../../../backend/models/room.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<_RoomsTabState> _roomsTabKey = GlobalKey<_RoomsTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // To update FAB visibility
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.teal,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.teal,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending'),
            Tab(icon: Icon(Icons.meeting_room), text: 'Rooms'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PendingBookingsTab(),
          _RoomsTab(key: _roomsTabKey),
          _ReportsTab(),
        ],
      ),
      floatingActionButton:
          _tabController.index == 1
              ? FloatingActionButton(
                onPressed: () {
                  _roomsTabKey.currentState?.showAddRoomDialog();
                },
                backgroundColor: Colors.teal,
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _PendingBookingsTab extends StatelessWidget {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Booking>>(
      stream: _databaseService.pendingBookings,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return const Center(child: Text('No pending bookings'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return Card(
              child: ListTile(
                title: Text('Room ${booking.roomId}'),
                subtitle: Text(
                  'Student ID: ${booking.studentId}\n'
                  'Date: ${booking.date}\n'
                  'Time: ${booking.startTime.hour}:${booking.startTime.minute} - '
                  '${booking.endTime.hour}:${booking.endTime.minute}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed:
                          () => _databaseService.updateBookingStatus(
                            booking.id,
                            'approved',
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed:
                          () => _databaseService.updateBookingStatus(
                            booking.id,
                            'rejected',
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RoomsTab extends StatefulWidget {
  const _RoomsTab({super.key});
  @override
  State<_RoomsTab> createState() => _RoomsTabState();
}

class _RoomsTabState extends State<_RoomsTab> {
  final DatabaseService _databaseService = DatabaseService();
  Room? _selectedRoom;

  void _blockTimeSlot() async {
    if (!mounted) return;

    final selectedRoom = _selectedRoom;
    if (selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a room first')),
      );
      return;
    }

    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (!mounted || date == null) return;

    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (!mounted || startTime == null) return;

    final TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime.now().add(const Duration(hours: 1)),
      ),
    );

    if (!mounted || endTime == null) return;

    try {
      await _databaseService.blockTimeSlot(
        selectedRoom.id,
        date,
        DateTime(
          date.year,
          date.month,
          date.day,
          startTime.hour,
          startTime.minute,
        ),
        DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Time slot blocked successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error blocking time slot: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showAddRoomDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final capacityController = TextEditingController();
    bool isAvailable = true;
    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Add Room'),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Room Name',
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Enter room name'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: capacityController,
                          decoration: const InputDecoration(
                            labelText: 'Capacity',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final cap = int.tryParse(value ?? '');
                            if (cap == null || cap <= 0) {
                              return 'Enter valid capacity';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Available'),
                          value: isAvailable,
                          onChanged: (value) {
                            setState(() => isAvailable = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          await _databaseService.addRoom(
                            name: nameController.text,
                            capacity: int.parse(capacityController.text),
                            isAvailable: isAvailable,
                          );
                          if (mounted) Navigator.pop(dialogContext);
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Room>>(
      stream: _databaseService.rooms,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final rooms = snapshot.data ?? [];

        if (rooms.isEmpty) {
          return const Center(child: Text('No rooms available'));
        }

        return ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('Room ${room.name}'),
                subtitle: Text('Capacity: ${room.capacity}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'block') {
                      setState(() => _selectedRoom = room);
                      _blockTimeSlot();
                    } else if (value == 'delete') {
                      _databaseService.deleteRoom(room.id);
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'block',
                          child: Text('Block Time Slot'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Room'),
                        ),
                      ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ReportsTab extends StatelessWidget {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Booking>>(
      stream: _databaseService.allBookings,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final bookings = snapshot.data ?? [];

        final totalBookings = bookings.length;
        final approvedBookings =
            bookings.where((b) => b.status == 'approved').length;
        final pendingBookings =
            bookings.where((b) => b.status == 'pending').length;
        final rejectedBookings =
            bookings.where((b) => b.status == 'rejected').length;

        // Calculate room utilization
        final roomBookings = <String, int>{};
        for (final booking in bookings) {
          final roomId = booking.roomId;
          if (roomId.isNotEmpty) {
            roomBookings[roomId] = (roomBookings[roomId] ?? 0) + 1;
          }
        }

        final mostBookedRoom =
            roomBookings.isEmpty
                ? 'None'
                : roomBookings.entries
                    .reduce((a, b) => a.value > b.value ? a : b)
                    .key;
        final leastBookedRoom =
            roomBookings.isEmpty
                ? 'None'
                : roomBookings.entries
                    .reduce((a, b) => a.value < b.value ? a : b)
                    .key;

        // Calculate average booking duration
        final totalDuration = bookings.fold<Duration>(
          Duration.zero,
          (total, booking) =>
              total + (booking.endTime.difference(booking.startTime)),
        );
        final averageDuration =
            bookings.isEmpty ? 0 : totalDuration.inHours / bookings.length;

        if (bookings.isNotEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reports',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildReportCard('Booking Statistics', [
                  'Total Bookings: $totalBookings',
                  'Approved Bookings: $approvedBookings',
                  'Pending Bookings: $pendingBookings',
                  'Rejected Bookings: $rejectedBookings',
                ]),
                const SizedBox(height: 16),
                _buildReportCard('Room Utilization', [
                  'Most Booked Room: $mostBookedRoom',
                  'Least Booked Room: $leastBookedRoom',
                  'Average Booking Duration: ${averageDuration.toStringAsFixed(1)} hours',
                ]),
              ],
            ),
          );
        } else {
          return const Center(child: Text('No bookings found'));
        }
      },
    );
  }

  Widget _buildReportCard(String title, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
