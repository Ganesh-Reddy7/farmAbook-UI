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
  late AnimationController _iconScaleController;
  late Animation<double> _iconScaleAnimation;

  late AnimationController _taglineFadeController;
  late Animation<double> _taglineFadeAnimation;

  late AnimationController _backgroundFadeController;
  late Animation<double> _backgroundFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation controllers
    _iconScaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _taglineFadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _backgroundFadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    // Animations
    _iconScaleAnimation = CurvedAnimation(
        parent: _iconScaleController, curve: Curves.easeInOutBack);
    _taglineFadeAnimation = CurvedAnimation(
        parent: _taglineFadeController, curve: Curves.easeIn);
    _backgroundFadeAnimation = CurvedAnimation(
        parent: _backgroundFadeController, curve: Curves.easeOut);

    // Start sequence
    _iconScaleController.forward().whenComplete(() {
      _taglineFadeController.forward();
    });

    // Navigate after splash
    Timer(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      _backgroundFadeController.forward().whenComplete(() {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 600),
              pageBuilder: (_, __, ___) =>
              widget.isLoggedIn
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
    _iconScaleController.dispose();
    _taglineFadeController.dispose();
    _backgroundFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity:
        Tween<double>(begin: 1.0, end: 0.0).animate(_backgroundFadeAnimation),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E2822), Color(0xFF3B574F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with glow & scale animation
                ScaleTransition(
                  scale: _iconScaleAnimation,
                  child: Container(
                    height: 160,
                    width: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.6),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        "assets/icon/Main_Icon.png", // your logo
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Tagline fade in
                FadeTransition(
                  opacity: _taglineFadeAnimation,
                  child: const Text(
                    "Smart farming.\nSmarter profits.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.1,
                      fontFamily: 'RobotoSlab',
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
