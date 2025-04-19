import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

class SingleLeaveViewScreen extends StatefulWidget {
  final Map<String, dynamic> leaveData;

  const SingleLeaveViewScreen({super.key, required this.leaveData});

  @override
  _SingleLeaveViewScreenState createState() => _SingleLeaveViewScreenState();
}

class _SingleLeaveViewScreenState extends State<SingleLeaveViewScreen> {
  late TextEditingController nameController;
  late TextEditingController facultyController;
  late TextEditingController fromDateController;
  late TextEditingController toDateController;
  late TextEditingController reasonsController;
  late TextEditingController leaveIdController;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? imageUrl;

  Future<void> confirmLeave() async {
    try {
      await firestore
          .collection('requestLeave')
          .doc(widget.leaveData['id'])
          .update({'isAccept': true});

      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Leave request accepted!')));

      // Optionally, navigate back
      Navigator.pop(context);
    } catch (error) {
      print('Error updating leave request: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update leave request')),
      );
    }
  }

  Future<void> rejectLeave() async {
    try {
      await firestore
          .collection('requestLeave')
          .doc(widget.leaveData['id'])
          .update({'isAccept': false});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Leave request reject!')));

      Navigator.pop(context);
    } catch (error) {
      print('Error updating leave request: $error');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to reject leave')));
    }
  }

  @override
  void initState() {
    super.initState();
    print(widget.leaveData);
    leaveIdController = TextEditingController(
      text: widget.leaveData['leaveId'] ?? '',
    );
    nameController = TextEditingController(
      text: widget.leaveData['LeaveName'] ?? '',
    );
    facultyController = TextEditingController(
      text: widget.leaveData['LectureFacultyNam'] ?? '',
    );
    fromDateController = TextEditingController(
      text: widget.leaveData['LeaveFrom'] ?? '',
    );
    toDateController = TextEditingController(
      text: widget.leaveData['LeaveTo'] ?? '',
    );
    reasonsController = TextEditingController(
      text: widget.leaveData['LectureReason'] ?? '',
    );

    // Get the image URL if available
    imageUrl = widget.leaveData['imageUrl'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('view leave', style: TextStyle(fontSize: 16)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: 24),

              // ID Field
              TextField(
                controller: leaveIdController,
                decoration: InputDecoration(
                  hintText: 'id',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Name Field
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Facility Name Field
              TextField(
                controller: facultyController,
                decoration: InputDecoration(
                  hintText: 'Facility name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // From Date Field
              TextField(
                controller: fromDateController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'From',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: const Icon(Icons.calendar_today, size: 20),
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2022),
                    lastDate: DateTime(2030),
                  );
                  // if (picked != null) {
                  //   setState(() {
                  //     fromDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                  //   });
                  // }
                },
              ),
              const SizedBox(height: 16),

              // To Date Field
              TextField(
                controller: toDateController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'To',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: const Icon(Icons.calendar_today, size: 20),
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2022),
                    lastDate: DateTime(2030),
                  );
                  // if (picked != null) {
                  //   setState(() {
                  //     toDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                  //   });
                  // }
                },
              ),
              const SizedBox(height: 16),

              // Reasons Field
              TextField(
                controller: reasonsController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'reasons',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Attachment Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.attachment, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Attachment',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select and upload the files of your choice',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    // Display uploaded image if available
                    if (imageUrl != null && imageUrl!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Uploaded Image:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 200,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Drag & Drop Area
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          // style: BorderStyle.dashed,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cloud_upload_outlined,
                              size: 32,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Choose a file or drag & drop it here',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '(PNG, JPG, GIF up to 10MB)',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 30,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  'Browse File',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        confirmLeave();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        rejectLeave();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.red),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    leaveIdController.dispose();
    facultyController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    reasonsController.dispose();
    super.dispose();
  }
}
