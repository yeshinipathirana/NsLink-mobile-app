import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test/admin/homeScreen.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScheduleMeetings extends StatefulWidget {
  const ScheduleMeetings({super.key});

  @override
  State<ScheduleMeetings> createState() => _ScheduleMeetingsState();
}

class _ScheduleMeetingsState extends State<ScheduleMeetings> {
  final TextEditingController _meetingTypeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  File? _selectedFile;
  bool _isUploading = false;

  String? selectedFaculty;
  String? selectedDepartment;

  final List<String> faculties = [
    'Engineering',
    'Business',
    'Arts',
    'Science',
    'Medicine',
  ];

  final List<String> departments = [
    'Computer Science',
    'Mathematics',
    'Physics',
    'Economics',
  ];

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(), // Default time
    );

    if (pickedTime != null) {
      setState(() {
        _timeController.text = pickedTime.format(context); // Format and display
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _uploadToCloudinary(File file) async {
    try {
      setState(() {
        _isUploading = true;
      });

      // Cloudinary credentials
      String cloudName = "dadzrhcik";
      String apiKey = "565432923148985";
      String uploadPreset = "flutter_upload_preset";

      // Prepare the upload request
      Uri url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );
      var request = http.MultipartRequest("POST", url);

      // Add file to upload
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      // Add necessary parameters
      request.fields['upload_preset'] = uploadPreset;
      request.fields['api_key'] = apiKey;

      // Send the request
      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);

      // Parse the response
      var result = jsonDecode(responseString);

      if (response.statusCode == 200) {
        return result['secure_url'];
      } else {
        throw Exception(
          'Failed to upload image: ${result['error']['message']}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _sendData() async {
    if (_meetingTypeController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _timeController.text.isEmpty ||
        selectedFaculty == null ||
        selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isUploading = true;
      });

      // Map to store meeting data
      Map<String, dynamic> meetingData = {
        "meetingType": _meetingTypeController.text,
        'meetingDate': _dateController.text,
        "meetingTime": _timeController.text,
        'meetingNote': _noteController.text,
        "meetingFaculty": selectedFaculty,
        "meetingDepartment": selectedDepartment,
        "createdAt": FieldValue.serverTimestamp(),
      };

      // Upload image if selected
      if (_selectedFile != null) {
        String? imageUrl = await _uploadToCloudinary(_selectedFile!);
        if (imageUrl != null) {
          meetingData["meetingImageUrl"] = imageUrl;
        }
      }

      // Save to Firestore
      await _firestore.collection('scheduleMeetings').add(meetingData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule Meeting successfully! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to Schedule Meeting: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Schedule Meeting',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Colors.grey),
                const SizedBox(height: 24),

                // Meeting type field
                TextField(
                  controller: _meetingTypeController,
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
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2022),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        _dateController.text = DateFormat(
                          'yyyy-MM-dd',
                        ).format(picked);
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _timeController,
                  readOnly: true, // Prevent manual input
                  decoration: const InputDecoration(
                    hintText: 'Select Time',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.access_time), // Clock icon
                  ),
                  onTap: () => _selectTime(context), // Show time picker on tap
                ),

                const SizedBox(height: 16),

                // Faculty Dropdown
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Select Faculty',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      value: selectedFaculty,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      icon: const Icon(Icons.arrow_drop_down),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedFaculty = newValue;
                        });
                      },
                      items:
                          faculties.map<DropdownMenuItem<String>>((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Text(value),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Department Dropdown
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Select Department',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      value: selectedDepartment,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      icon: const Icon(Icons.arrow_drop_down),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedDepartment = newValue;
                        });
                      },
                      items:
                          departments.map<DropdownMenuItem<String>>((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Text(value),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Note text field
                const Text(
                  'Note',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // File upload section
                Container(
                  constraints: const BoxConstraints(minHeight: 120),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
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
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 30,
                            child: ElevatedButton(
                              onPressed: _isUploading ? null : _pickFile,
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
                          if (_selectedFile != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                "File selected: ${_selectedFile!.path.split('/').last}",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _sendData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF26C485),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child:
                        _isUploading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'Submit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
