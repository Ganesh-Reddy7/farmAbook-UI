import 'package:flutter/material.dart';
import 'dart:async';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;
  final VoidCallback toggleTheme;

  const SplashScreen({
    Key? key,
    required this.isLoggedIn,
    required this.toggleTheme,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _taglineController;
  late Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();

    // Scale animation for icon
    _scaleController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scaleAnimation =
        CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack);

    // Fade animation for splash fade-out
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    // Tagline fade-in
    _taglineController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _taglineFade =
        CurvedAnimation(parent: _taglineController, curve: Curves.easeIn);

    _scaleController.forward().whenComplete(() {
      _taglineController.forward(); // fade tagline after icon scales
    });

    // After 1.8s start fade out, then navigate
    Timer(const Duration(milliseconds: 1800), () {
      _fadeController.forward().whenComplete(() {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, __, ___) => widget.isLoggedIn
                ? DashboardScreen(onToggleTheme: widget.toggleTheme)
                : AuthScreen(toggleTheme: widget.toggleTheme),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeAnimation),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.green.shade900, Colors.black]
                  : [Colors.green.shade400, Colors.green.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Icon with bounce
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Image.asset(
                        "assets/icon/app_icon1.png", // your logo
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Tagline with fade-in
                FadeTransition(
                  opacity: _taglineFade,
                  child: Text(
                    "Smart farming. Smarter profits.",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                      letterSpacing: 0.5,
                    ),
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
