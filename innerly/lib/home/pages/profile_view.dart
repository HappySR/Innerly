import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../started/welcome_page.dart';
import '../../widget/profile_button.dart';
import 'edit_profile_view.dart';
import 'mind_games_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F1EA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      // Exit the app if there's no previous screen
                      if (Platform.isAndroid) {
                        SystemNavigator.pop(); // Works on Android
                      } else {
                        exit(0); // For iOS or general fallback
                      }
                    }
                  },
                  padding: const EdgeInsets.only(right: 8),
                  constraints: const BoxConstraints(),
                ),
                Text(
                  'Profile',
                  style: GoogleFonts.abel(
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black87, size: 25),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Opacity(
              opacity: 0.1, // Optional: to make background image subtle
              child: Image.asset(
                'assets/logo/app_logo.png',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 140,
                              height: 120,
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: AssetImage('assets/user/user.png'),
                                    fit: BoxFit.cover,
                                    alignment: Alignment(0.0, 0.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          right: 15,
                          child: GestureDetector(
                            onTap: () {
                              // Your onTap functionality here
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfileScreen(),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.edit,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Julia', style: GoogleFonts.aclonica(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      'abc@example.com',
                      style: GoogleFonts.abyssinicaSil(fontSize: 20),
                    ),
                    const SizedBox(height: 90),
                    const SizedBox(height: 24),
                    const ProfileButton(icon: Icons.settings, text: 'Settings'),
                    const SizedBox(height: 18),
                    const ProfileButton(icon: Icons.language, text: 'Language'),
                    const SizedBox(height: 18),
                    const ProfileButton(
                      icon: Icons.info_outline,
                      text: 'About',
                    ),
                    const SizedBox(height: 18),
                    const ProfileButton(icon: Icons.logout, text: 'Logout'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
