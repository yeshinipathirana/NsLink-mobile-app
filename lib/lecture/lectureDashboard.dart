import 'package:flutter/material.dart';
import 'package:test/lecture/meetingListScreen.dart';
import 'package:test/lecture/requestLeaveScreen.dart';
import 'package:test/lecture/lecture-student MeetingDashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LectureDashboard extends StatefulWidget {
  const LectureDashboard({super.key});

  @override
  State<LectureDashboard> createState() => _LectureDashboardState();
}

class _LectureDashboardState extends State<LectureDashboard> {
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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

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
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 0,
                          top: 8.0,
                          left: 8.0,
                          right: 8.0,
                        ),
                        child: Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                child: Image(
                                  image: AssetImage('./assets/images/NSBM.png'),
                                  width: screenWidth * 0.1,
                                  height: 30,
                                ),
                              ),
                              InkWell(
                                onTap: () {},
                                child: const Icon(
                                  Icons.account_circle,
                                  size: 30,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
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

                      // Action buttons grid
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
                              title: 'Lecturer Meetings',
                              imagePath:
                                  'assets/images/07.png', // Path to the image
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const MeetingListScreen(),
                                  ),
                                );
                              },
                            ),
                            ActionButton(
                              title: 'Student Meetings',
                              imagePath:
                                  'assets/images/07.png', // Path to the image
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const LecturerMeetingDashboard(
                                              lecturerId: '',
                                            ),
                                  ),
                                );
                              },
                            ),
                            ActionButton(
                              title: 'Add Leave',
                              imagePath:
                                  'assets/images/07.png', // Path to the image
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const RequestLeaveScreen(),
                                  ),
                                );
                              },
                            ),
                            ActionButton(
                              title: 'My Schedule',
                              imagePath:
                                  'assets/images/07.png', // Path to the image
                              onPressed: () {},
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
  final VoidCallback? onPressed;
  final String imagePath; // Add a new parameter for the image path

  const ActionButton({
    required this.title,
    this.onPressed,
    required this.imagePath, // Required parameter for image path
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
          mainAxisAlignment:
              MainAxisAlignment.center, // Center the content vertically
          children: [
            Image.asset(
              imagePath, // Use the provided image path
              width: 50, // Adjust size of the image
              height: 50,
            ),
            const SizedBox(height: 10), // Add spacing between image and text
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
