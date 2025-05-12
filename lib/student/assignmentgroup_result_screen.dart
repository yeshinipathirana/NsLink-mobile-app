import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:test/student/assignmentgroup_search_screen.dart';
import 'package:test/student/studentDashboard.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  Map<String, int> _facultyCounts = {};

  @override
  void initState() {
    super.initState();
    _loadFacultyCounts();
  }

  Future<void> _loadFacultyCounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all the faculties we have modules for
      final QuerySnapshot snapshot =
          await _firestore.collection('modules').get();

      // Count modules per faculty
      final Map<String, int> counts = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final faculty = data['faculty'] as String? ?? 'Unknown';
        counts[faculty] = (counts[faculty] ?? 0) + 1;
      }

      if (mounted) {
        setState(() {
          _facultyCounts = counts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading faculties: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Faculty Selection',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const StudentDashboard()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadFacultyCounts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                )
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assignment Group',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadFacultyCounts,
                          color: Colors.teal,
                          child: ListView(
                            children: [
                              _buildFacultyItem(
                                context,
                                'Faculty of Computing',
                                'Faculty of Computing',
                                _facultyCounts['Computing'] ?? 0,
                              ),
                              _buildFacultyItem(
                                context,
                                'Faculty of Engineering',
                                'Faculty of Engineering',
                                _facultyCounts['Engineering'] ?? 0,
                              ),
                              _buildFacultyItem(
                                context,
                                'Faculty of Science',
                                'Faculty of Science',
                                _facultyCounts['Science'] ?? 0,
                              ),
                              _buildFacultyItem(
                                context,
                                'Faculty of Business',
                                'Faculty of Business',
                                _facultyCounts['Business'] ?? 0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildFacultyItem(
    BuildContext context,
    String title,
    String facultyName,
    int moduleCount,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to SearchScreen when the faculty is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchScreen(facultyName: facultyName),
          ),
        ).then((_) => _loadFacultyCounts()); // Refresh counts when returning
      },
      child: Card(
        elevation: 2,
        color: Colors.green[100],
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: const Icon(Icons.school, color: Colors.teal),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('$moduleCount groups available'),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.teal),
        ),
      ),
    );
  }
}
