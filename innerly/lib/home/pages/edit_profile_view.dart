import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widget/profile_button.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6), // Light cream background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: 0.1,
                    child: Image.asset(
                      'assets/logo/app_logo.png',
                      width: 300,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  // Back button and title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back_ios_new, size: 20),
                        const SizedBox(width: 20),
                        Center(
                          child: Text(
                              'Edit Profile',
                              style: GoogleFonts.abel(
                                  fontSize: 30
                              )
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Avatar
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

                  const SizedBox(height: 4),

                  // Name
                  Text(
                    "Julia",
                    style: GoogleFonts.aclonica(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Email
                  Text(
                    "abc@example.com",
                    style: GoogleFonts.abyssinicaSil(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 110),

                  // Opacity(
                  //   opacity: 0.05,
                  //   child: Image.asset(
                  //     'assets/logo/app_logo.png', // Faded inner leaf
                  //     height: 100,
                  //     fit: BoxFit.cover,
                  //   ),
                  // ),

                  // Input Fields
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildRoundedTextField("GENDER"),
                        const SizedBox(height: 20),
                        _buildRoundedTextField("AGE"),
                        const SizedBox(height: 20),
                        _buildRoundedTextField("LANGUAGE"),
                        const SizedBox(height:50),

                        // Save Changes Button
                        ProfileButton(text: "Save Changes",),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundedTextField(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(letterSpacing: 1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(20),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.teal),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
