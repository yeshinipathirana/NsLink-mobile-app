import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test/lecture/lectureDashboard.dart';
import 'package:test/student/bookingSlots.dart';

class LecturerSelectionPage extends StatelessWidget {
  const LecturerSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Lecturer'),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LectureDashboard()),
            );
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('lecturers').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No lecturers available'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final lecturer = snapshot.data!.docs[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(lecturer['imageUrl']),
                  ),
                  title: Text(lecturer['name']),
                  subtitle: Text(lecturer['email']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => LecturePage(lecturerId: lecturer.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class LecturePage extends StatefulWidget {
  final String lecturerId;

  const LecturePage({super.key, required this.lecturerId});

  @override
  State<LecturePage> createState() => _LecturePageState();
}

class _LecturePageState extends State<LecturePage> {
  bool isLoading = true;
  String lecturerName = '';
  String lecturerEmail = '';
  String lecturerImageUrl = '';
  List<Map<String, dynamic>> lectureSlots = [];

  @override
  void initState() {
    super.initState();
    fetchLecturerData();
  }

  Future<void> fetchLecturerData() async {
    try {
      // Fetch lecturer details from the lecturers collection
      final lecturerDoc =
          await FirebaseFirestore.instance
              .collection('lecturers')
              .doc(widget.lecturerId)
              .get();

      if (lecturerDoc.exists) {
        setState(() {
          lecturerName = lecturerDoc['name'];
          lecturerEmail = lecturerDoc['email'];
          lecturerImageUrl = lecturerDoc['imageUrl'];
        });

        // Fetch slots from the slots subcollection
        final slotsSnapshot =
            await FirebaseFirestore.instance
                .collection('lecturers')
                .doc(widget.lecturerId)
                .collection('slots')
                .get();

        final slots =
            slotsSnapshot.docs.map((doc) {
              return {
                'id': doc.id,
                'date': doc['date'],
                'time': doc['time'],
                'booked': doc['booked'] ?? false,
              };
            }).toList();

        setState(() {
          lectureSlots = slots;
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lecturer not found')));
      }
    } catch (e) {
      print('Error fetching data: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
  }

  Future<void> bookSlot(int index) async {
    try {
      final slotId = lectureSlots[index]['id'];
      final date = lectureSlots[index]['date'];
      final time = lectureSlots[index]['time'];

      // Navigate to booking form page
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => BookingFormPage(
                lecturerId: widget.lecturerId,
                lecturerName: lecturerName,
                slotId: slotId,
                date: date,
                time: time,
              ),
        ),
      );

      // If booking was successful, update local state
      if (result == true) {
        setState(() {
          lectureSlots[index]['booked'] = true;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Appointment reserved!!')));
      }
    } catch (e) {
      print('Error booking slot: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to reserve slot: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.green),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Hero(
              tag: 'profilePic-${widget.lecturerId}',
              child: CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(lecturerImageUrl),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              lecturerName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              lecturerEmail,
              style: const TextStyle(color: Colors.green, fontSize: 16),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child:
                  lectureSlots.isEmpty
                      ? const Center(
                        child: Text(
                          'No slots available for this lecturer',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                      : SizedBox(
                        height: 500,
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                                childAspectRatio: 1.2,
                              ),
                          itemCount: lectureSlots.length,
                          itemBuilder: (context, index) {
                            final bool isSlotBooked =
                                lectureSlots[index]['booked'];
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      lectureSlots[index]['date'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      lectureSlots[index]['time'],
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            isSlotBooked
                                                ? Colors.grey
                                                : Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                      ),
                                      onPressed:
                                          isSlotBooked
                                              ? null
                                              : () => bookSlot(index),
                                      child: Text(
                                        isSlotBooked ? 'Reserved' : 'Book',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
