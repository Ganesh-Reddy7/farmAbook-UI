import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  AuthScreen({required this.toggleTheme});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool isLogin = true;
  late AnimationController _leafController;

  @override
  void initState() {
    super.initState();
    _leafController =
    AnimationController(vsync: this, duration: Duration(seconds: 8))
      ..repeat();
  }

  @override
  void dispose() {
    _leafController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // 🌞 Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.green.shade900, Colors.brown.shade900]
                    : [Colors.green.shade300, Colors.lightGreen.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🌞 Sun glow (top right)
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.yellow.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 🌱 Animated floating leaves
          AnimatedBuilder(
            animation: _leafController,
            builder: (context, child) {
              final angle = _leafController.value * 2 * pi;
              return Stack(
                children: [
                  _buildLeaf(angle, 50, 100),
                  _buildLeaf(angle + pi / 2, 200, 250),
                  _buildLeaf(angle + pi, 100, 400),
                ],
              );
            },
          ),

          // 🌾 Curved hills at bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: CustomPaint(
              size: Size(double.infinity, 120),
              painter: HillPainter(isDark: isDark),
            ),
          ),

          // 🌿 Frosted glass form
          // 🌿 Frosted glass form
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: EdgeInsets.symmetric(vertical: 36, horizontal: 28),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.4)
                            : Colors.green.withOpacity(0.3),
                        blurRadius: 25,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  // 🔹 Added SingleChildScrollView here
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLogin ? "Welcome Back" : "Create an Account",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.green.shade900,
                          ),
                        ),
                        SizedBox(height: 28),
                        // Fields
                        AnimatedSize(
                          duration: Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: Column(
                            children: [
                              _buildTextField(
                                  hint: "User Name",
                                  obscure: false,
                                  icon: Icons.person_outline),
                              if (!isLogin) ...[
                                SizedBox(height: 16),
                                _buildTextField(
                                    hint: "Phone Number",
                                    obscure: false,
                                    icon: Icons.phone),
                              ],
                              SizedBox(height: 16),
                              _buildTextField(
                                  hint: "Password",
                                  obscure: true,
                                  icon: Icons.lock_outline),
                              if (!isLogin) ...[
                                SizedBox(height: 16),
                                _buildTextField(
                                    hint: "Confirm Password",
                                    obscure: true,
                                    icon: Icons.lock_outline),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 28),
                        _buildGradientButton(isLogin ? "Login" : "Register"),
                        SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => setState(() => isLogin = !isLogin),
                          child: AnimatedSwitcher(
                            duration: Duration(milliseconds: 400),
                            child: Text(
                              isLogin
                                  ? "Don't have an account? Register"
                                  : "Already have an account? Login",
                              key: ValueKey<bool>(isLogin),
                              style: TextStyle(
                                color: isDark
                                    ? Colors.lightGreen.shade300
                                    : Colors.green.shade800,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
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
        ],
      ),
    );
  }

  // 🌱 Floating leaf widget
  Widget _buildLeaf(double angle, double x, double y) {
    return Positioned(
      top: y + 20 * sin(angle),
      left: x + 30 * cos(angle),
      child: Transform.rotate(
        angle: angle,
        child: Icon(
          Icons.eco,
          color: Colors.green.shade200.withOpacity(0.6),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required String hint, required bool obscure, required IconData icon}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      obscureText: obscure,
      style: TextStyle(color: isDark ? Colors.white : Colors.green.shade900),
      decoration: InputDecoration(
        prefixIcon: Icon(icon,
            color: isDark ? Colors.green.shade200 : Colors.green.shade800),
        labelText: hint,
        labelStyle: TextStyle(
          color: isDark ? Colors.green.shade200 : Colors.green.shade800,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.green.withOpacity(0.05),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildGradientButton(String text) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DashboardScreen(onToggleTheme: widget.toggleTheme),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.greenAccent.shade700, Colors.green.shade600]
                : [Colors.green.shade600, Colors.lightGreen.shade400],
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.green.withOpacity(0.4),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// 🌾 Painter for hills
class HillPainter extends CustomPainter {
  final bool isDark;
  HillPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [Colors.green.shade800, Colors.green.shade900]
            : [Colors.green.shade400, Colors.green.shade700],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..lineTo(0, size.height - 40)
      ..quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5,
          size.height - 30)
      ..quadraticBezierTo(size.width * 0.75, size.height - 60, size.width,
          size.height - 20)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
