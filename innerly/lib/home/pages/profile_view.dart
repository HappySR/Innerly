import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../started/welcome_page.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F1EA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black87),
            onPressed: () {
              // TODO: Handle edit profile
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/user/user.png'),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.edit,
                    size: 14,
                    color: Colors.grey[700],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Julia',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'abc@example.com',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 30),

          // Background watermark (optional)
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.05,
                  child: Text(
                    'Innerly',
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    ProfileButton(
                      icon: Icons.settings,
                      text: 'Settings',
                    ),
                    SizedBox(height: 12),
                    ProfileButton(
                      icon: Icons.language,
                      text: 'Language',
                    ),
                    SizedBox(height: 12),
                    ProfileButton(
                      icon: Icons.info_outline,
                      text: 'About',
                    ),
                    SizedBox(height: 12),
                    ProfileButton(
                      icon: Icons.logout,
                      text: 'Logout',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileButton extends StatelessWidget {
  final IconData icon;
  final String text;

  const ProfileButton({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFAED9D3),
        foregroundColor: Colors.black87,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        minimumSize: const Size(280, 48),
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
      icon: Icon(icon, size: 20),
      label: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}