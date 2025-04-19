import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test/lecture/lectureDashboard.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class RequestLeaveScreen extends StatefulWidget {
  const RequestLeaveScreen({super.key});

  @override
  _RequestLeaveScreenState createState() => _RequestLeaveScreenState();
}

class _RequestLeaveScreenState extends State<RequestLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController indexController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController facultyController = TextEditingController();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final TextEditingController reasonsController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  File? _selectedFile;
  bool _isUploading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<String?> _uploadFile(uid) async {
    if (_selectedFile == null) return null;

    setState(() {
      _isUploading = true;
    });

    try {
      String cloudName = "dadzrhcik";
      String apiKey = "565432923148985";
      String uploadPreset = "flutter_upload_preset";

      Uri url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      var request = http.MultipartRequest("POST", url);
      request.fields["upload_preset"] = uploadPreset;
      request.fields["public_id"] =
          "users/$uid/${DateTime.now().millisecondsSinceEpoch}";

      request.files.add(
        await http.MultipartFile.fromPath("file", _selectedFile!.path),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = jsonDecode(await response.stream.bytesToString());
        String downloadUrl = responseData["secure_url"];

        setState(() {
          _isUploading = false;
        });

        return downloadUrl;
      } else {
        throw Exception("Cloudinary upload failed");
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      print("Upload error: $e");
      return null;
    }
  }

  bool _validateDates() {
    if (fromDateController.text.isEmpty || toDateController.text.isEmpty) {
      return false;
    }

    try {
      DateTime fromDate = DateFormat(
        'yyyy-MM-dd',
      ).parse(fromDateController.text);
      DateTime toDate = DateFormat('yyyy-MM-dd').parse(toDateController.text);

      return !toDate.isBefore(fromDate);
    } catch (e) {
      return false;
    }
  }

  Future<void> _sendData() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if an image is selected
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image attachment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      String? imageUrl = await _uploadFile(
        "leave_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (imageUrl == null) throw Exception("Image upload failed");

      await _firestore.collection('requestLeave').add({
        "leaveId": indexController.text.trim(),
        'LeaveName': nameController.text.trim(),
        "LectureFacultyName": facultyController.text.trim(),
        'LeaveFrom': fromDateController.text.trim(),
        "LeaveTo": toDateController.text.trim(),
        "LectureReason": reasonsController.text.trim(),
        "timestamp": FieldValue.serverTimestamp(),
        "imageUrl": imageUrl,
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave added successfully! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LectureDashboard()),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add Leave: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Leave"),
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 800),
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth > 600 ? 32.0 : 16.0,
                    vertical: 16.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 24),

                        // Form Fields
                        buildFormField(
                          controller: indexController,
                          hintText: 'ID',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'ID is required';
                            }
                            return null;
                          },
                        ),

                        buildFormField(
                          controller: nameController,
                          hintText: 'Name',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),

                        buildFormField(
                          controller: facultyController,
                          hintText: 'Faculty name',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Faculty name is required';
                            }
                            return null;
                          },
                        ),

                        if (isSmallScreen)
                          Column(
                            children: [
                              buildDateField(
                                controller: fromDateController,
                                hintText: 'From',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'From date is required';
                                  }
                                  return null;
                                },
                              ),
                              buildDateField(
                                controller: toDateController,
                                hintText: 'To',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'To date is required';
                                  }
                                  if (!_validateDates()) {
                                    return 'To date must be after From date';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: buildDateField(
                                  controller: fromDateController,
                                  hintText: 'From',
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'From date is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: buildDateField(
                                  controller: toDateController,
                                  hintText: 'To',
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'To date is required';
                                    }
                                    if (!_validateDates()) {
                                      return 'To date must be after From date';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                        buildFormField(
                          controller: reasonsController,
                          hintText: 'Reasons',
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Reason is required';
                            }
                            if (value.trim().length < 10) {
                              return 'Please provide a more detailed reason (minimum 10 characters)';
                            }
                            return null;
                          },
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
                          padding: EdgeInsets.all(
                            constraints.maxWidth > 600 ? 24.0 : 16.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.attachment, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Attachment',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Select and upload the files of your choice',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),

                              Container(
                                constraints: const BoxConstraints(
                                  minHeight: 120,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (_selectedFile != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8.0,
                                            ),
                                            child: Text(
                                              'Selected: ${_selectedFile!.path.split('/').last}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.teal,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          )
                                        else
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
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 30,
                                          child: ElevatedButton(
                                            onPressed: _pickFile,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: Colors.black,
                                              side: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
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
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (isSmallScreen)
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _sendData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text('Confirm'),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const LectureDashboard(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _sendData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text('Confirm'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const LectureDashboard(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildFormField({
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget buildDateField({
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
          if (picked != null) {
            setState(() {
              controller.text = DateFormat('yyyy-MM-dd').format(picked);
            });
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    indexController.dispose();
    nameController.dispose();
    facultyController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    reasonsController.dispose();
    super.dispose();
  }
}
