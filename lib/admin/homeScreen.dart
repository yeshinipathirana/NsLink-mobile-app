import 'package:flutter/material.dart';
import 'package:test/admin/addLectureScreen.dart';
import 'package:test/admin/addStudentScreen.dart';
import 'package:test/admin/sheduleMeetings.dart';
import 'package:test/admin/viewLeaves.dart';
import 'package:test/auth/loginScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _email = prefs.getString('user_email') ?? 'No email';
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Admin Home Image
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 0,
                          top: 0,
                          left: 8.0,
                          right: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.end, // Align to the right
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.logout,
                                color: Colors.red,
                              ), // Logout icon
                              label: const Text(
                                "Logout",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 32.0,
                          top: 8.0,
                          left: 8.0,
                          right: 8.0,
                        ),
                        child: Stack(
                          children: [
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: const DecorationImage(
                                  image: AssetImage(
                                    'assets/images/NSBM_home.jpg',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Text(
                                _email ?? '',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black.withOpacity(0.7),
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          mainAxisSpacing: 30,
                          crossAxisSpacing: 24,
                          children: [
                            ActionButton(
                              title: 'Add Lecturer',
                              image: 'assets/images/08.png',
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const AddLectureScreen(),
                                  ),
                                );
                              },
                            ),
                            ActionButton(
                              title: 'Add Student',
                              image: 'assets/images/08.png',
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const AddStudentScreen(),
                                  ),
                                );
                              },
                            ),
                            ActionButton(
                              title: 'View Leave',
                              image: 'assets/images/09.png',
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const ViewLeaveScreen(),
                                  ),
                                );
                              },
                            ),
                            ActionButton(
                              title: 'Schedule Meeting',
                              image: 'assets/images/10.png',
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const ScheduleMeetings(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
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
}

class ActionButton extends StatelessWidget {
  final String title;
  final String image; // Added image parameter
  final VoidCallback? onPressed;

  const ActionButton({
    required this.title,
    required this.image, // Required image parameter
    this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 160,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          foregroundColor: const Color.fromARGB(255, 0, 0, 0),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: onPressed ?? () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              image, // Display image here
              height: 50, // You can adjust the size of the image
              width: 50,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
