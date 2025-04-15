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
      width: double.infinity, // 🔹 Full width
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFAED9D3).withAlpha(150),
          foregroundColor: Colors.black87,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20  ), // 🔹 Adjusted padding
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: () async {
          if (text == 'Logout') {
            // Proper logout sequence
            try {
              // Sign out from Supabase
              await Supabase.instance.client.auth.signOut();

              // Clear any local storage
              const storage = FlutterSecureStorage();
              await storage.delete(key: 'anonymous_user_id');

              // Navigate to welcome page and clear stack
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
            // Handle other actions
          }
        },
        icon: Icon(icon, size: 20, color: Colors.black,),
        label: Text(
          text,
          style: GoogleFonts.aclonica(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}