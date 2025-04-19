import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test/student/studentDashboard.dart';

class LectureListScreen extends StatefulWidget {
  const LectureListScreen({super.key});

  @override
  _LectureListScreenState createState() => _LectureListScreenState();
}

class _LectureListScreenState extends State<LectureListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> teachersList = [];

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  Future<void> _fetchTeachers() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'lecture')
              .get();

      setState(() {
        teachersList =
            querySnapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();
      });
      print(teachersList);
    } catch (e) {
      print('Error fetching teachers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const StudentDashboard()),
            );
          },
        ),
        title: const Text(
          'Lecturers List',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child:
            teachersList.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                  itemCount: teachersList.length,
                  itemBuilder: (context, index) {
                    var teacher = teachersList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: LecturerCard(
                        name: teacher['lectureName'],
                        title: teacher['lecturePost'] ?? 'No Title',
                        imageUrl:
                            teacher['lectureImage'] ??
                            'https://via.placeholder.com/60x60',
                      ),
                    );
                  },
                ),
      ),
    );
  }
}

class LecturerCard extends StatelessWidget {
  final String name;
  final String title;
  final String imageUrl;

  const LecturerCard({
    super.key,
    required this.name,
    required this.title,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5E6),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.person, size: 30, color: Colors.teal);
                },
              ),
            ),
          ),
          const SizedBox(width: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
