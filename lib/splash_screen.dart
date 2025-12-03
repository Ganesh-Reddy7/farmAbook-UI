import 'dart:async';
import 'package:farmabook/screens/auth_screen.dart';
import 'package:farmabook/screens/main_dashboard_screen.dart';
import 'package:flutter/material.dart';
import '../utils/token_manager.dart';


class SplashScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const SplashScreen({
    Key? key,
    required this.toggleTheme,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Animation Controllers and Animations (no changes needed)
  late final AnimationController _iconScaleController;
  late final Animation<double> _iconScaleAnimation;
  late final AnimationController _taglineFadeController;
  late final Animation<double> _taglineFadeAnimation;
  late final AnimationController _backgroundFadeController;
  late final Animation<double> _backgroundFadeAnimation;

  Widget? _nextScreen;

  @override
  void initState() {
    super.initState();

    _initAnimations();
    _runSplashFlow();
  }

  void _initAnimations() {
    _iconScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _taglineFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _backgroundFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _iconScaleAnimation = CurvedAnimation(
      parent: _iconScaleController,
      curve: Curves.easeInOutBack,
    );
    _taglineFadeAnimation = CurvedAnimation(
      parent: _taglineFadeController,
      curve: Curves.easeIn,
    );
    _backgroundFadeAnimation = CurvedAnimation(
      parent: _backgroundFadeController,
      curve: Curves.easeOut,
    );

    _iconScaleController.forward().whenComplete(() {
      _taglineFadeController.forward();
    });
  }

  // 💡 FIX: Replaced manual token check with the TokenManager utility
  Future<bool> checkTokenValidity() async {
    return await TokenManager.isLoggedIn();
  }

  void _runSplashFlow() async {
    bool isValid = await checkTokenValidity();
    _nextScreen = isValid
        ? MainDashboardScreen(onToggleTheme: widget.toggleTheme)
        : AuthScreen(toggleTheme: widget.toggleTheme);

    Timer(const Duration(milliseconds: 3000), () {
      if (!mounted) return;

      _backgroundFadeController.forward().whenComplete(() {
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (_, __, ___) => _nextScreen!,
            transitionsBuilder: (_, animation, __, child) {
              final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeIn),
              );
              final scale = Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              );
              return FadeTransition(
                opacity: fade,
                child: ScaleTransition(scale: scale, child: child),
              );
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
      backgroundColor: const Color(0xFF1E2822),
      body: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0)
            .animate(_backgroundFadeAnimation),
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
                        "assets/icon/Main_Icon.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
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