import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test/student/studentDashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _intakeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _facultyController = TextEditingController();
  final TextEditingController _degreeController = TextEditingController();

  File? _selectedFile;
  String? _profileImageUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getData();
  }

  Future<void> _getData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        setState(() {
          _studentIdController.text = userDoc['studentIndex'] ?? '';
          _intakeController.text = userDoc['studentIntake'] ?? '';
          _nameController.text = userDoc['studentName'] ?? '';
          _emailController.text = userDoc['studentEmail'] ?? '';
          _facultyController.text = userDoc['studentFaculty'] ?? '';
          _degreeController.text = userDoc['studentDegree'] ?? '';
          _profileImageUrl = userDoc['profileImage'] ?? '';
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _pickFile() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadAndSaveFile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      String cloudName = "dadzrhcik";
      String uploadPreset = "flutter_upload_preset";
      Uri url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      var request = http.MultipartRequest("POST", url);
      request.fields["upload_preset"] = uploadPreset;
      request.fields["public_id"] =
          "users/$userId/${DateTime.now().millisecondsSinceEpoch}";
      request.files.add(
        await http.MultipartFile.fromPath("file", _selectedFile!.path),
      );
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = jsonDecode(await response.stream.bytesToString());
        String downloadUrl = responseData["secure_url"];

        FirebaseFirestore.instance.collection('users').doc(userId).update({
          'profileImage': downloadUrl,
        });

        setState(() {
          _profileImageUrl = downloadUrl;
          _isUploading = false;
        });
      } else {
        throw Exception("Cloudinary upload failed");
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      print("Upload error: $e");
    }
  }

  Future<void> _sendData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    _uploadAndSaveFile();

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      FirebaseFirestore.instance.collection('users').doc(userId).update({
        'studentIndex': _studentIdController.text,
        'studentIntake': _intakeController.text,
        'studentName': _nameController.text,
        'studentEmail': _emailController.text,
        'studentFaculty': _facultyController.text,
        'studentDegree': _degreeController.text,
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('profile update successfully! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(Duration(seconds: 2));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => StudentDashboard()),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _intakeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _facultyController.dispose();
    _degreeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const StudentDashboard()),
            );
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [Image.asset("assets/images/NSBM.png", height: 50)],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'PROFILE',
              style: TextStyle(
                color: Colors.green,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                      image:
                          _selectedFile != null
                              ? DecorationImage(
                                image: FileImage(_selectedFile!),
                                fit: BoxFit.cover,
                              )
                              : (_profileImageUrl != null
                                  ? DecorationImage(
                                    image: NetworkImage(_profileImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                  : null),
                    ),
                    child:
                        _selectedFile == null
                            ? IconButton(
                              icon: const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              ),
                              onPressed: _pickFile,
                            )
                            : null,
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: 100,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF26A69A),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Center(
                      child: Text(
                        'Enrolled',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildInfoInputRow(
                    leftLabel: 'Student ID',
                    leftController: _studentIdController,
                    rightLabel: 'Intake',
                    rightController: _intakeController,
                  ),
                  const SizedBox(height: 15),
                  _buildInputField(label: 'Name', controller: _nameController),
                  const SizedBox(height: 15),
                  _buildInputField(
                    label: 'NSBM Email',
                    controller: _emailController,
                  ),
                  const SizedBox(height: 15),
                  _buildInputField(
                    label: 'Faculty',
                    controller: _facultyController,
                  ),
                  const SizedBox(height: 15),
                  _buildInputField(
                    label: 'Degree',
                    controller: _degreeController,
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: () {
                      _sendData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoInputRow({
    required String leftLabel,
    required TextEditingController leftController,
    required String rightLabel,
    required TextEditingController rightController,
  }) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leftLabel,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                TextFormField(
                  controller: leftController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rightLabel,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                TextFormField(
                  controller: rightController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
