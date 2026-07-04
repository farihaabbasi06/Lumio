import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Controllers to grab the text data
  final _nameController = TextEditingController();
  final _universityController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? errorMessage = await _authService.signUp(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      university: _universityController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (errorMessage == null) {
      // Success! Move to Login or Home Screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully! Please log in.')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Show error popup if something went wrong
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Matching your exact dark theme color palette
    const backgroundColor = Color(0xFF0D0D18);
    const cardColor = Color(0xFF1A1A2E);
    const inputColor = Color(0xFF1E1E2E);
    const primaryPurple = Color(0xFF534AB7);
    const textPurple = Color(0xFFCECBF6);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Header space
                  const Icon(Icons.auto_stories, size: 64, color: primaryPurple),
                  const SizedBox(height: 16),
                  const Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign up to unlock your AI study assistant',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // 1. Name Field
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Full Name',
                    icon: Icons.person_outline,
                    backgroundColor: inputColor,
                    validator: (val) => val!.isEmpty ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 16),

                  // 2. University Field
                  _buildTextField(
                    controller: _universityController,
                    hint: 'University Name',
                    icon: Icons.school_outlined,
                    backgroundColor: inputColor,
                    validator: (val) => val!.isEmpty ? 'Please enter your university' : null,
                  ),
                  const SizedBox(height: 16),

                  // 3. Email Field
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Email Address',
                    icon: Icons.email_outlined,
                    backgroundColor: inputColor,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Please enter an email';
                      if (!val.contains('@')) return 'Please enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 4. Password Field
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    backgroundColor: inputColor,
                    isObscure: true,
                    validator: (val) => val!.length < 6 ? 'Password must be at least 6 characters' : null,
                  ),
                  const SizedBox(height: 32),

                  // Signup Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      foregroundColor: textPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: textPurple, strokeWidth: 2),
                          )
                        : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),

                  // Redirect to Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: const Text(
                          'Log In',
                          style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // UI Builder helper for inputs matching the prototype style
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color backgroundColor,
    bool isObscure = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        filled: true,
        fillColor: backgroundColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
    );
  }
}