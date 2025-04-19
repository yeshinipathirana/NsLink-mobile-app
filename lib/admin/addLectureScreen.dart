import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test/admin/homeScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class AddLectureScreen extends StatefulWidget {
  const AddLectureScreen({super.key});

  @override
  _AddLectureScreenState createState() => _AddLectureScreenState();
}

class _AddLectureScreenState extends State<AddLectureScreen> {
  final TextEditingController indexController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? selectedFaculty;
  String? selectedDepartment;
  final TextEditingController _postController = TextEditingController();
  String role = "lecture";
  File? _selectedFile;
  bool _isUploading = false;
  String? uid;

  // Sample data
  final List<String> faculties = ['Engineering', 'Science', 'Arts', 'Business'];
  final List<String> departments = [
    'Computer Science',
    'Mathematics',
    'Physics',
    'Economics',
  ];

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
      String uploadPreset =
          "flutter_upload_preset"; // Set in Cloudinary dashboard

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

  Future<void> _sendData() async {
    if (indexController.text.isEmpty ||
        nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        selectedFaculty == null ||
        selectedDepartment == null ||
        _postController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All fields are required!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      uid = userCredential.user!.uid;

      // Upload Image and Get URL
      String? imageUrl = await _uploadFile(uid);
      if (imageUrl == null) throw Exception("Image upload failed");

      await _firestore.collection('users').doc(uid).set({
        "role": role,
        "lectureIndex": indexController.text,
        "lectureName": nameController.text,
        "lectureEmail": emailController.text,
        "lecturePost": _postController.text,
        "lectureFaculty": selectedFaculty,
        "lectureDepartment": selectedDepartment,
        "lectureImage": imageUrl,
      });

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lecture added successfully! 🎉'),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if error occurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add lecture: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    final double horizontalPadding =
        isSmallScreen ? 16.0 : screenSize.width * 0.1;
    final double fieldSpacing = isSmallScreen ? 16.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Lecture"),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1, thickness: 1),
                    SizedBox(height: fieldSpacing),

                    // ID Field
                    _buildTextField(
                      controller: indexController,
                      hintText: 'Index',
                    ),
                    SizedBox(height: fieldSpacing),

                    // Name Field
                    _buildTextField(
                      controller: nameController,
                      hintText: 'name',
                    ),
                    SizedBox(height: fieldSpacing),

                    // Email Field
                    _buildTextField(
                      controller: emailController,
                      hintText: 'Email',
                    ),
                    SizedBox(height: fieldSpacing),

                    // Password Field
                    _buildTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      isPassword: true,
                    ),
                    SizedBox(height: fieldSpacing),

                    // Faculty dropdown
                    _buildDropdown(
                      value: selectedFaculty,
                      hint: 'Faculty drop down',
                      items: faculties,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedFaculty = newValue;
                        });
                      },
                    ),
                    SizedBox(height: fieldSpacing),

                    // Department dropdown
                    _buildDropdown(
                      value: selectedDepartment,
                      hint: 'DEPARTMENT drop down',
                      items: departments,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedDepartment = newValue;
                        });
                      },
                    ),
                    SizedBox(height: fieldSpacing),

                    // Post Field
                    _buildTextField(
                      controller: _postController,
                      hintText: 'post of Lecturers',
                    ),
                    SizedBox(height: fieldSpacing),

                    // Attachment section
                    _buildAttachmentSection(context),
                    SizedBox(height: fieldSpacing * 1.5),

                    // Action Buttons
                    _buildActionButtons(isSmallScreen),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Color.fromARGB(255, 107, 104, 104)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              hint,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          value: value,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
          onChanged: onChanged,
          items:
              items.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(value),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildAttachmentSection(BuildContext context) {
    return Container(
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
              Text('Add Image', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Select and upload the files of your choice',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Drag & Drop Area - Responsive
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
                        onPressed: _pickFile,
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
                          "1 file selected: ${_selectedFile!.path.split('/').last}",
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
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: const [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text("Uploading...", style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isSmallScreen) {
    if (isSmallScreen) {
      // Stack buttons vertically on small screens
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: double.infinity, child: _buildConfirmButton()),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: _buildRejectButton()),
        ],
      );
    } else {
      // Place buttons side by side on larger screens
      return Row(
        children: [
          Expanded(child: _buildConfirmButton()),
          const SizedBox(width: 16),
          Expanded(child: _buildRejectButton()),
        ],
      );
    }
  }

  Widget _buildConfirmButton() {
    return ElevatedButton(
      onPressed: _sendData,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: const Text('Confirm'),
    );
  }

  Widget _buildRejectButton() {
    return ElevatedButton(
      onPressed: () {
        // Clear all fields
        indexController.clear();
        nameController.clear();
        emailController.clear();
        _passwordController.clear();
        _postController.clear();
        setState(() {
          selectedFaculty = null;
          selectedDepartment = null;
          _selectedFile = null;
        });
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
      child: const Text('Reset'),
    );
  }

  @override
  void dispose() {
    indexController.dispose();
    nameController.dispose();
    emailController.dispose();
    _passwordController.dispose();
    _postController.dispose();
    super.dispose();
  }
}
