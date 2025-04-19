import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/admin/homeScreen.dart';
import 'package:test/lecture/lectureDashboard.dart';
import 'package:test/student/studentDashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _formKey = GlobalKey<FormState>();

  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;

  final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  bool _validateEmail(String email) {
    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      return false;
    } else if (!_emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Enter a valid email address');
      return false;
    }
    setState(() => _emailError = null);
    return true;
  }

  bool _validatePassword(String password) {
    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      return false;
    } else if (password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      return false;
    }
    setState(() => _passwordError = null);
    return true;
  }

  Future<void> _sendData() async {
    final isEmailValid = _validateEmail(_usernameController.text);
    final isPasswordValid = _validatePassword(_passwordController.text);

    if (!isEmailValid || !isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in the form'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _usernameController.text,
        password: _passwordController.text,
      );

      String uid = userCredential.user!.uid;

      // Store the user ID in local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', uid);

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        String role = userDoc['role'];

        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminHomeScreen()),
          );
        } else if (role == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => StudentDashboard()),
          );
        } else if (role == 'lecture') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LectureDashboard()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unknown role!'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', _usernameController.text);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User data not found!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed login attempts. Try again later';
          break;
        default:
          errorMessage = 'Login failed. Please try again';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 0),
                    const Center(
                      child: Image(
                        image: AssetImage('./assets/images/NSBM.png'),
                        width: 100,
                        height: 100,
                      ),
                    ),
                    const SizedBox(height: 0),
                    const Text(
                      'Welcome back!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF494949),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Email TextField with error message
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[200],
                        hintText: 'Enter Email',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        // Show error message if exists
                        errorText: _emailError,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        // Clear error on typing
                        if (_emailError != null) {
                          setState(() => _emailError = null);
                        }
                      },
                      onSubmitted: (value) {
                        _validateEmail(value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password TextField with error message
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[200],
                        hintText: 'Password',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        errorText: _passwordError,
                      ),
                      onChanged: (value) {
                        if (_passwordError != null) {
                          setState(() => _passwordError = null);
                        }
                      },
                      onSubmitted: (value) {
                        _validatePassword(value);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Sign in button with loading state
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B6B6A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(48),
                          ),
                          // Disable button during loading
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  ),
                                )
                                : const Text(
                                  'Sign in',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
