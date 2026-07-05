import 'package:flutter/material.dart';
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8FD), // Light background color from image_1a98e7.png
      appBar: AppBar(
        backgroundColor: const Color(0xFFB4E3DB), // Mint green color from image_1a98e7.png
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Back button functional agar yeh kisi pehle screen se call ho rahi ho
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Profile Screen',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // Profile Image Circle
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFF009688), // Teal color from image_1a98e7.png
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Name
            const Text(
              'Zamzam Ali',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            
            // Email
            const Text(
              'zamzam.ali@student.comsats.edu.pk',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            
            // Divider Line
            const Divider(
              color: Colors.grey,
              thickness: 0.5,
              indent: 20,
              endIndent: 20,
            ),
            const SizedBox(height: 10),
            
            // 1st Clickable Button: Academic Performance Check
            _buildProfileButton(
              context: context,
              icon: Icons.bar_chart,
              title: 'Academic Performance Check',
              targetScreen: const AcademicScreen(), // Niche majood Academic class ko call kiya
            ),
            
            // 2nd Clickable Button: Application Preferences
            _buildProfileButton(
              context: context,
              icon: Icons.settings,
              title: 'Application Preferences',
              targetScreen: const PreferencesScreen(), // Niche majood Preferences class ko call kiya
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildProfileButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget targetScreen,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF00897B),
          size: 28,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        onTap: () {
          // Asal navigation call jo agla page kholegi
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetScreen),
          );
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
class AcademicScreen extends StatelessWidget {
  const AcademicScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8FD),
      appBar: AppBar(
        title: const Text('Academic Performance Check', style: TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFFB4E3DB),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Academic Performance Details Screen',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8FD),
      appBar: AppBar(
        title: const Text('Application Preferences', style: TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFFB4E3DB),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Application Preferences Screen',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}