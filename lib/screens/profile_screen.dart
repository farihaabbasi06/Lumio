import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  int _totalSubjects = 0;
  int _totalFlashcards = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final subjectsSnap = await FirebaseFirestore.instance
          .collection('subjects')
          .where('userId', isEqualTo: uid)
          .get();

      final flashcardsSnap = await FirebaseFirestore.instance.collection('flashcards').get();

      if (mounted) {
        setState(() {
          _userData = userDoc.data();
          _totalSubjects = subjectsSnap.docs.length;
          _totalFlashcards = flashcardsSnap.docs.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut(AppColors colors) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to logout?', style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: Text('Logout', style: TextStyle(color: colors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final themeProvider = context.watch<ThemeProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final String name = _userData?['name'] ?? user?.displayName ?? 'Student';
    final String email = _userData?['email'] ?? user?.email ?? '';
    final String university = _userData?['university'] ?? 'University';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: colors.primary,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                      style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    university,
                    style: TextStyle(color: colors.accent, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(child: _buildStatCard('$_totalSubjects', 'Subjects', colors.primary, colors)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('$_totalFlashcards', 'Flashcards', colors.accent, colors)),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'APPEARANCE',
                      style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14)),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(
                        themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: colors.primary,
                      ),
                      title: Text('Dark Mode', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                      value: themeProvider.isDarkMode,
                      activeColor: colors.primary,
                      onChanged: (_) => themeProvider.toggleTheme(),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ACCOUNT INFO',
                      style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoTile(Icons.person_outline_rounded, 'Full Name', name, colors),
                  const SizedBox(height: 8),
                  _buildInfoTile(Icons.school_outlined, 'University', university, colors),
                  const SizedBox(height: 8),
                  _buildInfoTile(Icons.email_outlined, 'Email', email, colors),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.danger.withAlpha(25),
                        foregroundColor: colors.danger,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: colors.danger, width: 0.5),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      onPressed: () => _signOut(colors),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text('Lumio v1.0.0', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color, AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, AppColors colors) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(                                   // ✅ gives Column a bounded width
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              Text(
                value,
                style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 2,                         // ✅ optional: cap at 2 lines
                overflow: TextOverflow.ellipsis,      // ✅ adds "..." if still too long
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}