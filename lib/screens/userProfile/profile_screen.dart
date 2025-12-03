import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/session_service.dart';
import '../auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  final User? user;
  final VoidCallback onToggleTheme;

  const ProfileScreen({
    Key? key,
    required this.user,
    required this.onToggleTheme,
  }) : super(key: key);

  // ------------------------------
  // LOGOUT HANDLER
  // ------------------------------
  void _logout(BuildContext context) async {
    await SessionService().logout();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => AuthScreen(toggleTheme: onToggleTheme),
      ),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness != Brightness.dark;
    final colors = _AppColors(isDark);
    final accentColor = isDark ? Colors.greenAccent.shade200 : Colors.green.shade700;

    final username = user?.username ?? "Guest User";
    final phone = user?.phone ?? "N/A";

    return Scaffold(
      backgroundColor: colors.card,
      appBar: AppBar(
        backgroundColor: colors.card,
        elevation: 0,
        title: Text(
          "Profile",
          style: TextStyle(
            color: colors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: colors.text),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6, color: colors.text),
            onPressed: onToggleTheme,
          )
        ],
      ),

      // ------------------------------
      // BODY
      // ------------------------------
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // PROFILE CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.divider.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: accentColor.withOpacity(0.25),
                    child: Icon(Icons.person, size: 55, color: accentColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    username,
                    style: TextStyle(
                      fontSize: 24,
                      color: colors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    phone,
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.text.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // DETAILS SECTION
            _buildDetailTile(
              context,
              icon: Icons.person_outline,
              title: "Username",
              value: username,
              colors: colors,
            ),

            _buildDetailTile(
              context,
              icon: Icons.phone_android,
              title: "Phone Number",
              value: phone,
              colors: colors,
            ),

            const Spacer(),

            // LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ------------------------------
  // REUSABLE DETAIL TILE
  // ------------------------------
  Widget _buildDetailTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String value,
        required _AppColors colors,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.text.withOpacity(0.8), size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.text.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// ------------------------
// THEME CLASS (Same as other screens)
// ------------------------
class _AppColors {
  final Color background;
  final Color card;
  final Color text;
  final Color divider;

  _AppColors(bool isDark)
      : background = isDark ? const Color(0xFF121212) : Colors.white,
        card = isDark ? const Color(0xFF081712) : Colors.grey.shade100,
        text = isDark ? Colors.white : Colors.black87,
        divider = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
}
