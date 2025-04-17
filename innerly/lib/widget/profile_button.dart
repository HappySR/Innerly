import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../started/welcome_page.dart';

class ProfileButton extends StatelessWidget {
  final IconData? icon;
  final String text;

  const ProfileButton({super.key, this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // Full width button
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFAED9D3).withAlpha(150),
          foregroundColor: Colors.black87,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () async {
          if (text == 'Logout') {
            try {
              await Supabase.instance.client.auth.signOut();
              const storage = FlutterSecureStorage();
              await storage.delete(key: 'anonymous_user_id');
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomePage()),
                (route) => false,
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Logout failed: ${e.toString()}')),
              );
            }
          } else {
            // Other button actions
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start, // Align to left
          children: [
            Icon(icon, size: 28, color: Colors.black),
            const SizedBox(width: 36), // Space between icon and text
            Text(
              text,
              style: GoogleFonts.aclonica(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
