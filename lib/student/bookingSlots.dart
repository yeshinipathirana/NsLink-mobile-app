import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class BookingFormPage extends StatefulWidget {
  final String slotId;
  final String date;
  final String time;

  const BookingFormPage({
    super.key,
    required this.slotId,
    required this.date,
    required this.time,
    required String lecturerId,
    required String lecturerName,
  });

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  late String _lecturerId;
  String _lecturerName = 'Loading...';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;
  File? _selectedFile;
  String? _selectedFileName;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _lecturerId = user.uid;
      _loadLecturerData();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No user logged in')));
        Navigator.pop(context);
      });
    }

    if (widget.time.contains('-')) {
      final timeParts = widget.time.split('-');
      if (timeParts.length == 2) {
        _fromController.text = timeParts[0].trim();
        _toController.text = timeParts[1].trim();
      }
    }
  }

  Future<void> _loadLecturerData() async {
    try {
      final doc =
          await _firestore.collection('lecturers').doc(_lecturerId).get();
      if (doc.exists) {
        setState(() {
          _lecturerName = doc.data()?['name'] ?? 'Unknown Lecturer';
        });
      }
    } catch (e) {
      print('Error loading lecturer data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load lecturer information')),
      );
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'mp4'],
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to select file: $e')));
    }
  }

  Future<String?> _uploadFile() async {
    if (_selectedFile == null) return null;

    setState(() => _isUploading = true);

    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$_selectedFileName';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('booking_attachments')
          .child(_lecturerId)
          .child(fileName);

      await storageRef.putFile(_selectedFile!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload file: $e')));
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      String? fileUrl = await _uploadFile();

      await _firestore
          .collection('lecturers')
          .doc(_lecturerId)
          .collection('slots')
          .doc(widget.slotId)
          .update({'booked': true});

      await _firestore.collection('bookings').add({
        'lecturerId': _lecturerId,
        'lecturerName': _lecturerName,
        'slotId': widget.slotId,
        'date': widget.date,
        'time': widget.time,
        'studentName': _nameController.text,
        'fromTime': _fromController.text,
        'toTime': _toController.text,
        'message': _messageController.text,
        'hasAttachment': fileUrl != null,
        'attachmentUrl': fileUrl,
        'attachmentName': _selectedFileName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      print('Error submitting booking: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit booking: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request to book'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text(
                'Your First Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter your name';
                  return null;
                },
              ),

              const SizedBox(height: 16),
              const Text('From', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fromController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
              ),

              const SizedBox(height: 16),
              const Text('To', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _toController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
              ),

              const SizedBox(height: 16),
              const Text(
                'Write a message to the host',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: 5,
              ),

              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.attach_file),
                        const SizedBox(width: 8),
                        const Text(
                          'Attachment',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                    Text(
                      'Select and upload the files of your choice',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(minHeight: 90),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          _selectedFile != null
                              ? _buildSelectedFilePreview()
                              : _buildFilePicker(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      (_isSubmitting || _isUploading) ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child:
                      _isSubmitting || _isUploading
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _isUploading ? 'Uploading...' : 'Submitting...',
                              ),
                            ],
                          )
                          : const Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePicker() {
    return InkWell(
      onTap: _pickFile,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_upload, color: Colors.grey),
              const SizedBox(height: 4),
              const Text(
                'Choose a file or drag & drop it here',
                style: TextStyle(fontSize: 12),
              ),
              Text(
                'JPEG, PNG, PDF, and MP4 formats, up to 50MB',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 30,
                child: OutlinedButton(
                  onPressed: _pickFile,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Browse File',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedFilePreview() {
    final extension = _selectedFileName?.split('.').last.toLowerCase();
    final isImage =
        extension == 'jpg' || extension == 'jpeg' || extension == 'png';

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage && _selectedFile != null)
            Container(
              height: 120,
              alignment: Alignment.center,
              child: Image.file(
                _selectedFile!,
                fit: BoxFit.contain,
                height: 120,
              ),
            ),
          if (!isImage)
            Container(
              height: 80,
              alignment: Alignment.center,
              child: Icon(
                extension == 'pdf'
                    ? Icons.picture_as_pdf
                    : extension == 'mp4'
                    ? Icons.video_file
                    : Icons.insert_drive_file,
                size: 48,
                color: Colors.grey[700],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedFileName ?? 'Selected file',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed:
                    () => setState(() {
                      _selectedFile = null;
                      _selectedFileName = null;
                    }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          TextButton(
            onPressed: _pickFile,
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[800],
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Change file',
              style: TextStyle(
                decoration: TextDecoration.underline,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
