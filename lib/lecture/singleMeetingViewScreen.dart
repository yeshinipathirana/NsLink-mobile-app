import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test/lecture/meetingListScreen.dart';

class SingleMeetingViewScreen extends StatefulWidget {
  final Map<String, dynamic> meeting;

  const SingleMeetingViewScreen({super.key, required this.meeting});

  @override
  _SingleMeetingViewScreenState createState() =>
      _SingleMeetingViewScreenState();
}

class _SingleMeetingViewScreenState extends State<SingleMeetingViewScreen> {
  final TextEditingController _meetingTypeController = TextEditingController();
  final TextEditingController facultyController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController reasonsController = TextEditingController();
  final TextEditingController meetingDepartment = TextEditingController();

  String? uploadedImageUrl;
  bool isImageLoading = false;

  @override
  void initState() {
    super.initState();
    _meetingTypeController.text = widget.meeting['meetingType'] ?? '';
    facultyController.text = widget.meeting['meetingFaculty'] ?? '';
    _dateController.text = widget.meeting['meetingDate'] ?? '';
    _timeController.text = widget.meeting['meetingTime'] ?? '';
    reasonsController.text = widget.meeting['meetingNote'] ?? '';
    meetingDepartment.text = widget.meeting['meetingDepartment'] ?? '';
    uploadedImageUrl = widget.meeting['meetingImageUrl'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Meeting"),
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MeetingListScreen(),
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: 24),

              TextField(
                controller: _meetingTypeController,
                readOnly: true,
                decoration: const InputDecoration(
                  hintText: 'Type of meeting',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Date field
              TextField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: const Icon(Icons.calendar_today, size: 20),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _timeController,
                readOnly: true,
                decoration: const InputDecoration(
                  hintText: 'Select Time',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: facultyController,
                readOnly: true,
                decoration: const InputDecoration(
                  hintText: '',
                  labelText: 'Faculty',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: meetingDepartment,
                readOnly: true,
                decoration: const InputDecoration(
                  hintText: '',
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Note',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonsController,
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              if (uploadedImageUrl != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Uploaded Attachment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                            child: Image.network(
                              uploadedImageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              height: 200,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return SizedBox(
                                  height: 200,
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
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.photo,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    uploadedImageUrl!.split('/').last,
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.open_in_new, size: 20),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          child: Container(
                                            constraints: BoxConstraints(
                                              maxHeight:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.height *
                                                  0.8,
                                              maxWidth:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.9,
                                            ),
                                            child: Image.network(
                                              uploadedImageUrl!,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('OK'),
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
    _meetingTypeController.dispose();
    facultyController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    reasonsController.dispose();
    meetingDepartment.dispose();
    super.dispose();
  }
}
