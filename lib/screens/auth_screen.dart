import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'dashboard_screen.dart';
import '../services/auth_service.dart';


class AuthScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  const AuthScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  bool _loading = false;

  bool isLogin = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dark background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A1F13), Color(0xFF112A1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Floating neon shapes
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              double angle = _animationController.value * 2 * pi;
              return Stack(
                children: [
                  _buildGlowCircle(angle, 80, 100, 220),
                  _buildGlowCircle(angle * 1.3, 200, 350, 150),
                  _buildGlowCircle(angle * 0.7, 300, 250, 180),
                ],
              );
            },
          ),
          // Frosted glass card
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: Colors.greenAccent.withOpacity(0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade900.withOpacity(0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.eco_outlined,
                          size: 80,
                          color: Colors.white, // leaf icon in white
                        ),

                        const SizedBox(height: 30),
                        _buildTextField("Phone Number", false, controller: _phoneController),
                        if (!isLogin) ...[
                          const SizedBox(height: 20),
                          _buildTextField("User Name", false, controller: _userNameController),
                        ],
                        const SizedBox(height: 20),
                        _buildTextField("Password", true, controller: _passwordController),
                        if (!isLogin) ...[
                          const SizedBox(height: 20),
                          _buildTextField("Confirm Password", true, controller: _confirmController),
                        ],
                        const SizedBox(height: 36),
                        _buildNeonButton(isLogin ? "Login" : "Register"),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isLogin = !isLogin;
                            });
                          },
                          child: Text(
                            isLogin
                                ? "Don't have an account? Register"
                                : "Already have an account? Login",
                            style: TextStyle(
                                color: Colors.greenAccent.shade200,
                                fontSize: 14,
                                decoration: TextDecoration.underline),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  // Neon glowing circle helper
  Widget _buildGlowCircle(double angle, double x, double y, double size) {
    return Positioned(
      top: y + 50 * sin(angle),
      left: x + 50 * cos(angle),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.greenAccent.withOpacity(0.1),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.3),
              blurRadius: 50,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, bool obscure, {TextEditingController? controller}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white, width: 1.2),
        ),
      ),
    );
  }





  Widget _buildNeonButton(String text) {
    return InkWell(
      onTap: _loading ? null : () async {
        setState(() => _loading = true);

        bool success = false;
        if (isLogin) {
          success = await _authService.login(
            _phoneController.text,
            _passwordController.text,
          );
        } else {
          if (_passwordController.text != _confirmController.text) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Passwords do not match")),
            );
            setState(() => _loading = false);
            return;
          }
          success = await _authService.register(
            _userNameController.text,
            _phoneController.text,
            _passwordController.text,
          );
        }

        setState(() => _loading = false);

        if (success) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DashboardScreen(onToggleTheme: widget.toggleTheme),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Authentication Failed")),
          );
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 3,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _loading
              ? const CircularProgressIndicator(color: Colors.black)
              : Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }




}
