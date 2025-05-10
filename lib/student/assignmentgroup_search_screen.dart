import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:test/student/assignmentgroup_form_screen.dart';

class SearchScreen extends StatefulWidget {
  final String facultyName;
  final ModuleData? newModule;

  const SearchScreen({super.key, required this.facultyName, this.newModule});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ModuleData> filteredModules = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get the faculty name without "Faculty of " prefix
      final String facultyNameOnly = widget.facultyName.split(' ').last;

      // Query modules by faculty
      final QuerySnapshot snapshot =
          await _firestore
              .collection('modules')
              .where('faculty', isEqualTo: facultyNameOnly)
              .orderBy('createdAt', descending: true)
              .get();

      final modules =
          snapshot.docs.map((doc) {
            return ModuleData.fromFirestore(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();

      if (mounted) {
        setState(() {
          filteredModules = modules;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading modules: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _filterModules(String query) async {
    if (query.isEmpty) {
      // If query is empty, just reload all modules for the faculty
      _loadModules();
    } else {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get the faculty name without "Faculty of " prefix
        final String facultyNameOnly = widget.facultyName.split(' ').last;

        // Query modules by faculty and name (starting with the query)
        final QuerySnapshot snapshot =
            await _firestore
                .collection('modules')
                .where('faculty', isEqualTo: facultyNameOnly)
                .get();

        // We need to filter client-side since Firestore doesn't support
        // case-insensitive queries natively
        final modules =
            snapshot.docs
                .map(
                  (doc) => ModuleData.fromFirestore(
                    doc.id,
                    doc.data() as Map<String, dynamic>,
                  ),
                )
                .where(
                  (module) =>
                      module.name.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();

        if (mounted) {
          setState(() {
            filteredModules = modules;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Error searching modules: ${e.toString()}';
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _enrollStudent(ModuleData module) async {
    try {
      // Start a batch write to update both the module and add the student
      WriteBatch batch = _firestore.batch();

      // Reference to the module document
      DocumentReference moduleRef = _firestore
          .collection('modules')
          .doc(module.id);

      // Update available spaces
      batch.update(moduleRef, {'availableSpaces': FieldValue.increment(-1)});

      // Add student to enrolledStudents subcollection
      // In a real app, you would get this info from authentication or user input
      String studentId = DateTime.now().millisecondsSinceEpoch.toString();
      String studentName = "Student User"; // In a real app, get this from user
      String studentBatch = "24.1"; // In a real app, get this from user

      DocumentReference studentRef = moduleRef
          .collection('enrolledStudents')
          .doc(studentId);

      batch.set(studentRef, {
        'studentName': studentName,
        'batch': studentBatch,
        'enrollmentDate': FieldValue.serverTimestamp(),
      });

      // Commit the batch
      await batch.commit();

      // Update the UI
      setState(() {
        module.availableSpaces--;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have successfully enrolled!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enrolling: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showModuleDetails(BuildContext context, ModuleData module) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(module.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Faculty: ${module.faculty}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Group: ${module.group}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Available Spaces: ${module.availableSpaces}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (module.leaderName.isNotEmpty)
                  Text(
                    'Group Leader: ${module.leaderName}',
                    style: const TextStyle(fontSize: 16),
                  ),
                if (module.leaderName.isNotEmpty) const SizedBox(height: 8),
                if (module.phoneNumber.isNotEmpty)
                  Text(
                    'Phone Number: +94 ${module.phoneNumber}',
                    style: const TextStyle(fontSize: 16),
                  ),
                if (module.phoneNumber.isNotEmpty) const SizedBox(height: 8),
                if (module.batch.isNotEmpty)
                  Text(
                    'Batch: ${module.batch}',
                    style: const TextStyle(fontSize: 16),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back', style: TextStyle(color: Colors.green)),
            ),
            ElevatedButton(
              onPressed:
                  module.availableSpaces > 0
                      ? () {
                        _enrollStudent(module);
                        Navigator.pop(context);
                      }
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
              ),
              child: const Text('Enroll'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.facultyName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadModules,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                  hintText: 'Search modules...',
                ),
                onChanged: _filterModules,
              ),
              const SizedBox(height: 20),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // Loading indicator or module grid
              Expanded(
                child:
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(color: Colors.green),
                        )
                        : filteredModules.isEmpty
                        ? const Center(
                          child: Text(
                            'No modules found. Try adding some!',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                        : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.85,
                              ),
                          itemCount: filteredModules.length,
                          itemBuilder: (context, index) {
                            return _buildModuleCard(
                              context,
                              filteredModules[index],
                            );
                          },
                        ),
              ),

              // Add Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FormScreen(),
                      ),
                    ).then((_) => _loadModules()); // Refresh when returning
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Add New Group',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, ModuleData module) {
    return GestureDetector(
      onTap: () => _showModuleDetails(context, module),
      child: Card(
        elevation: 2,
        color: Colors.green[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.green.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                module.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              const Divider(color: Colors.green),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Available:'),
                  Text(
                    '${module.availableSpaces}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Group:'),
                  Text(
                    module.group,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModuleData {
  final String id;
  final String name;
  final String faculty;
  int availableSpaces;
  final String group;
  final String leaderName;
  final String phoneNumber;
  final String batch;
  final Timestamp? createdAt;

  ModuleData({
    required this.id,
    required this.name,
    required this.faculty,
    required this.availableSpaces,
    required this.group,
    this.leaderName = '',
    this.phoneNumber = '',
    this.batch = '',
    this.createdAt,
  });

  // Factory constructor to create ModuleData from Firestore document
  factory ModuleData.fromFirestore(String id, Map<String, dynamic> data) {
    return ModuleData(
      id: id,
      name: data['name'] ?? '',
      faculty: data['faculty'] ?? '',
      availableSpaces: data['availableSpaces'] ?? 0,
      group: data['group'] ?? '',
      leaderName: data['leaderName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      batch: data['batch'] ?? '',
      createdAt: data['createdAt'],
    );
  }
}
