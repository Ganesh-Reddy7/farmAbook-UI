import 'package:farmabook/screens/main_dashboard_screen.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/api_exception.dart';
import '../models/user.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  const AuthScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();

  bool _loading = false;
  bool isLogin = true;
  bool _passwordVisible = false;
  bool _confirmVisible = false;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0C1914),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: w * 0.08),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.06,
              vertical: h * 0.03,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.eco_outlined, size: 70, color: Colors.white),
                const SizedBox(height: 20),

                _buildField(
                  controller: _phoneController,
                  label: "Phone Number",
                  keyboard: TextInputType.phone,
                ),

                if (!isLogin) ...[
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _userNameController,
                    label: "User Name",
                  ),
                ],

                const SizedBox(height: 16),

                _buildField(
                  controller: _passwordController,
                  label: "Password",
                  obscure: !_passwordVisible,
                  suffix: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() => _passwordVisible = !_passwordVisible);
                    },
                  ),
                ),

                if (!isLogin) ...[
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _confirmController,
                    label: "Confirm Password",
                    obscure: !_confirmVisible,
                    suffix: IconButton(
                      icon: Icon(
                        _confirmVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() => _confirmVisible = !_confirmVisible);
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                _buildActionButton(),

                const SizedBox(height: 18),

                GestureDetector(
                  onTap: () => setState(() => isLogin = !isLogin),
                  child: Text(
                    isLogin
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
          ),
        ),
      ),
    );
  }

  // -------------------- FIELD --------------------
  Widget _buildField({
    required TextEditingController controller,
    required String label,
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
        fillColor: Colors.white.withOpacity(0.05),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.greenAccent, width: 1.4),
        ),
      ),
    );
  }

  // -------------------- BUTTON --------------------
  Widget _buildActionButton() {
    return InkWell(
      onTap: _loading ? null : _validateAndSubmit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.greenAccent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 2,
            ),
          )
              : Text(
            isLogin ? "Login" : "Register",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // -------------------- VALIDATION + API --------------------
  Future<void> _validateAndSubmit() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return _showMessage("Enter valid 10-digit phone number");
    }

    if (password.isEmpty || password.length < 4) {
      return _showMessage("Password must be at least 4 characters");
    }

    if (!isLogin) {
      if (_passwordController.text != _confirmController.text) {
        return _showMessage("Passwords do not match");
      }
      if (_userNameController.text.isEmpty) {
        return _showMessage("Enter a valid username");
      }
    }

    setState(() => _loading = true);

    try {
      if (isLogin) {
        // 👇 login returns **User**
        User user = await _authService.login(phone, password);

        _showMessage("Login successful!");

        await Future.delayed(const Duration(milliseconds: 700));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MainDashboardScreen(onToggleTheme: widget.toggleTheme),
          ),
        );
      } else {
        // REGISTER
        bool success = await _authService.register(
          _userNameController.text.trim(),
          phone,
          password,
        );

        if (success) {
          _showMessage("Account created! Please login.");
        }

        // Switch to login screen
        setState(() {
          isLogin = true;
          _passwordController.clear();
          _confirmController.clear();
        });
      }
    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage("Something went wrong.");
    }

    setState(() => _loading = false);
  }

  // -------------------- SNACKBAR --------------------
  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
