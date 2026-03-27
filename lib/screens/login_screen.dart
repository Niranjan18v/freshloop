import 'package:flutter/material.dart';
import '../../auth_service.dart';
import 'signup_screen.dart';
import '../../core/app_colors.dart';

/// Modern Login Screen for FreshLoop with high-end aesthetic.
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
      await _auth.signIn(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      // MainNavigation will catch the auth change and move forward
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.error, content: Text("Login Failed: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '')}")),
      );
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
                
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text("Forgot Password?", style: TextStyle(color: Color(0xFF5D8064), fontWeight: FontWeight.bold)))),

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
                        ? const CircularProgressIndicator(color: Colors.white)
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
