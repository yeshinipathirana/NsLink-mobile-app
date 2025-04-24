import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test/lecture/add_slot.dart';

class LecturerMeetingDashboard extends StatefulWidget {
  const LecturerMeetingDashboard({super.key});

  @override
  State<LecturerMeetingDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerMeetingDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _bookedMeetings = [];
  List<Map<String, dynamic>> _availableSlots = [];
  // Add Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _lecturerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Get current user and fetch data
    _getCurrentUserAndFetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUserAndFetchData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _lecturerId = user.uid;
      });
      await _fetchLecturerData();
    } else {
      setState(() {
        _isLoading = false;
      });
      // Handle the case when no user is logged in
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No user logged in')));
    }
  }

  Future<void> _fetchLecturerData() async {
    if (_lecturerId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch booked meetings from the bookings collection where lecturerId matches
      final bookingsQuery =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('lecturerId', isEqualTo: _lecturerId)
              .get();

      // Fetch available slots from the lecturer's slots subcollection
      final slotsQuery =
          await FirebaseFirestore.instance
              .collection('lecturers')
              .doc(_lecturerId)
              .collection('slots')
              .where('booked', isEqualTo: false)
              .get();

      setState(() {
        _bookedMeetings =
            bookingsQuery.docs
                .map((doc) => {...doc.data(), 'id': doc.id})
                .toList();

        _availableSlots =
            slotsQuery.docs
                .map((doc) => {...doc.data(), 'id': doc.id})
                .toList();

        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching lecturer data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addNewSlot(String date, String time) async {
    if (_lecturerId == null) return;

    try {
      // Add a new slot to the Firestore database
      await FirebaseFirestore.instance
          .collection('lecturers')
          .doc(_lecturerId)
          .collection('slots')
          .add({
            'date': date,
            'time': time,
            'booked': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Refresh the data
      _fetchLecturerData();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Slot added successfully')));
    } catch (e) {
      print('Error adding slot: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add slot: $e')));
    }
  }

  Future<void> _showRemoveConfirmation(
    String slotId,
    String date,
    String time,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Removal'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to remove this slot?'),
                const SizedBox(height: 8),
                Text(
                  'Date: $date',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Time: $time',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _removeSlot(slotId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeSlot(String slotId) async {
    if (_lecturerId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('lecturers')
          .doc(_lecturerId)
          .collection('slots')
          .doc(slotId)
          .delete();

      _fetchLecturerData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot removed successfully')),
      );
    } catch (e) {
      print('Error removing slot: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove slot: $e')));
    }
  }

  void _viewMeetingDetails(Map<String, dynamic> meeting) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Meeting Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Date', meeting['date']),
                _detailRow('Time', meeting['time']),
                _detailRow('Student', meeting['studentName']),
                _detailRow('Message', meeting['message'] ?? 'No message'),
                _detailRow(
                  'Has Attachment',
                  meeting['hasAttachment'] ? 'Yes' : 'No',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(value, style: const TextStyle(fontSize: 16)),
          const Divider(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecturer Dashboard'),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Booked Meetings'),
            Tab(text: 'Available Slots'),
          ],
          labelColor: Colors.white,
          indicatorColor: Colors.white,
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  // Booked Meetings Tab
                  _bookedMeetings.isEmpty
                      ? const Center(child: Text('No booked meetings yet'))
                      : ListView.builder(
                        itemCount: _bookedMeetings.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final meeting = _bookedMeetings[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                meeting['studentName'] ?? 'Unnamed Student',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '${meeting['date']} • ${meeting['time']}',
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    meeting['message'] ?? 'No message',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              trailing:
                                  meeting['hasAttachment'] == true
                                      ? const Icon(Icons.attach_file)
                                      : null,
                              onTap: () => _viewMeetingDetails(meeting),
                            ),
                          );
                        },
                      ),

                  // Available Slots Tab
                  Column(
                    children: [
                      Expanded(
                        child:
                            _availableSlots.isEmpty
                                ? const Center(
                                  child: Text('No available slots'),
                                )
                                : GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 15,
                                        mainAxisSpacing: 15,
                                        childAspectRatio: 0.8,
                                      ),
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _availableSlots.length,
                                  itemBuilder: (context, index) {
                                    final slot = _availableSlots[index];
                                    return Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 3,
                                      child: Stack(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  slot['date'],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  slot['time'],
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  'Available',
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: 5,
                                            right: 5,
                                            child: GestureDetector(
                                              onTap:
                                                  () => _showRemoveConfirmation(
                                                    slot['id'],
                                                    slot['date'],
                                                    slot['time'],
                                                  ),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(
                                                    0.2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        AddSlot(onSlotAdded: _addNewSlot),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'Add New Slot',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
    );
  }
}
