import 'package:flutter/material.dart';
import '../auth_service.dart';
import 'signup_screen.dart';
import '../core/app_colors.dart';
import '../main.dart'; // Import to access MainNavigation explicitly if needed

/// Modern Login Screen for FreshLoop with high-end aesthetic.
/// Fixed navigation logic to ensure instant transition to the dashboard.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  final AuthService _auth = AuthService();
  bool isLoading = false;

  void login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      // 1. Authenticate with Firebase
      final user = await _auth.signIn(email, password);
      
      if (user != null && mounted) {
        // 2. 🚦 INSTANT ACTIVE REDIRECT
        // We go home IMMEDIATELY on success to guarantee no "stuck" logins.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error, 
          content: Text("Login Failed: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '')}")
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: const Color(0xFF5D8064).withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.eco_rounded, size: 80, color: Color(0xFF5D8064)),
                  ),
                ),
                const SizedBox(height: 40),
                const Text("Welcome Back!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF2D3436))),
                const SizedBox(height: 8),
                const Text("Login to manage your inventory smarter.", style: TextStyle(color: Colors.black54, fontSize: 16)),
                const SizedBox(height: 60),

                _buildField(controller: emailController, label: "Email Address", icon: Icons.email_outlined, type: TextInputType.emailAddress),
                const SizedBox(height: 20),
                _buildField(controller: passwordController, label: "Password", icon: Icons.lock_outline, obscure: true),
                
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D8064),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Log In", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 40),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: RichText(
                      text: const TextSpan(
                        text: "New here? ",
                        style: TextStyle(color: Colors.black54, fontSize: 15),
                        children: [
                          TextSpan(
                            text: "Create Account",
                            style: TextStyle(color: Color(0xFF5D8064), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, bool obscure = false, TextInputType? type}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        validator: (v) => v!.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: Icon(icon, color: Colors.grey, size: 22),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        ),
      ),
    );
  }
}
