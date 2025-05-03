import 'package:flutter/material.dart';
import 'package:test/library/frontend/screens/home_screen.dart';
import 'package:test/student/lectureListScreen.dart';
import 'package:test/student/profileScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
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

    int crossAxisCount = screenWidth < 600 ? 2 : 4;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Profile Header Section
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
                        // Profile Text
                        Container(
                          child: Image(
                            image: AssetImage('./assets/images/NSBM.png'),
                            width: screenWidth * 0.1,
                            height: 30,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(),
                              ),
                            );
                          },
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
                            image: AssetImage('assets/images/NSBM_home.jpg'),
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
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.2,
                    mainAxisSpacing: 30,
                    crossAxisSpacing: 24,
                    children: [
                      ActionButton(
                        title: 'Computing Faculty',
                        imageAsset: 'assets/images/01.png',
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LecturerSelectionPage(),
                            ),
                          );
                        },
                      ),
                      ActionButton(
                        title: 'Science Faculty',
                        imageAsset: 'assets/images/02.png',
                        onPressed: () {},
                      ),
                      ActionButton(
                        title: 'Engineering Faculty',
                        imageAsset: 'assets/images/05.png',
                        onPressed: () {},
                      ),
                      ActionButton(
                        title: 'Business Faculty',
                        imageAsset: 'assets/images/03.png',
                        onPressed: () {},
                      ),
                      ActionButton(
                        title: 'Assignment Groups',
                        imageAsset: 'assets/images/06.png',
                        onPressed: () {},
                      ),
                      ActionButton(
                        title: 'Library Rooms',
                        imageAsset: 'assets/images/04.png',
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LibraryHomeScreen(),
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
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String title;
  final String imageAsset;
  final VoidCallback? onPressed;

  const ActionButton({
    required this.title,
    required this.imageAsset,
    this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: onPressed ?? () {},
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(imageAsset, width: 48, height: 48, fit: BoxFit.contain),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
