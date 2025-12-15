import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/api_exception.dart';
import '../models/user.dart';
import 'package:farmabook/screens/main_dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const AuthScreen({super.key, required this.toggleTheme});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();

  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  final nameCtrl = TextEditingController();

  final ValueNotifier<bool> isLogin = ValueNotifier(true);
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<bool> passVisible = ValueNotifier(false);
  final ValueNotifier<bool> confirmVisible = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0C1914),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: w * 0.08),
          child: ValueListenableBuilder(
            valueListenable: isLogin,
            builder: (_, bool login, __) {
              return _buildCard(login);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCard(bool login) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco_outlined, size: 64, color: Colors.white),
          const SizedBox(height: 20),

          _buildInput(phoneCtrl, "Phone Number", keyboard: TextInputType.phone),

          if (!login) ...[
            const SizedBox(height: 16),
            _buildInput(nameCtrl, "User Name"),
          ],

          const SizedBox(height: 16),

          ValueListenableBuilder(
            valueListenable: passVisible,
            builder: (_, visible, __) {
              return _buildInput(
                passCtrl,
                "Password",
                obscure: !visible,
                suffix: IconButton(
                  icon: Icon(
                      visible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white70),
                  onPressed: () => passVisible.value = !visible,
                ),
              );
            },
          ),

          if (!login)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ValueListenableBuilder(
                valueListenable: confirmVisible,
                builder: (_, visible, __) {
                  return _buildInput(
                    confirmCtrl,
                    "Confirm Password",
                    obscure: !visible,
                    suffix: IconButton(
                      icon: Icon(
                          visible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white70),
                      onPressed: () => confirmVisible.value = !visible,
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 28),

          _buildActionButton(login),
          const SizedBox(height: 18),

          GestureDetector(
            onTap: () => isLogin.value = !isLogin.value,
            child: Text(
              login
                  ? "Don't have an account? Register"
                  : "Already have an account? Login",
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInput(
      TextEditingController controller,
      String label, {
        TextInputType keyboard = TextInputType.text,
        bool obscure = false,
        Widget? suffix,
      }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white38),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.greenAccent, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildActionButton(bool login) {
    return ValueListenableBuilder(
      valueListenable: loading,
      builder: (_, bool busy, __) {
        return GestureDetector(
          onTap: busy ? null : () => _submit(login),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: busy
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.black, strokeWidth: 2),
              )
                  : Text(
                login ? "Login" : "Register",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit(bool login) async {
    loading.value = true;

    final phone = phoneCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (phone.length != 10) {
      return _err("Enter valid phone number");
    }
    if (pass.length < 4) {
      return _err("Password must be at least 4 characters");
    }

    try {
      if (login) {
        final user = await _authService.login(phone, pass);
        await Future.delayed(const Duration(milliseconds: 600));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainDashboardScreen(
              onToggleTheme: widget.toggleTheme,
            ),
          ),
        );
      } else {
        if (pass != confirmCtrl.text.trim()) {
          return _err("Passwords do not match");
        }
        if (nameCtrl.text.trim().isEmpty) {
          return _err("Enter a valid username");
        }

        final ok = await _authService.register(
          nameCtrl.text.trim(),
          phone,
          pass,
        );

        if (ok) _err("Account created! Please login");
        isLogin.value = true;
      }
    } catch (e) {
      _err("Something went wrong");
    }

    loading.value = false;
  }

  void _err(String msg) {
    loading.value = false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green.shade800,
      ),
    );
  }
}
