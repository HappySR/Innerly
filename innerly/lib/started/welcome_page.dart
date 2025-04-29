import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Innerly/home/pages/therapists/started/signup_view.dart';
import '../home/pages/bottom_nav.dart';
import '../services/auth_service.dart';
import '../services/role.dart';
import 'package:Innerly/started/user_verification.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<OptionCardData> options = [
      OptionCardData(
        imagePath: 'assets/images/therapist_profile_image.png',
        text: 'Are You a therapist?',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TherapistSignUpPage(),
            ),
          );
        },
      ),
      OptionCardData(
        imagePath: 'assets/images/anonymous.png',
        text: 'Continue Anonymously....',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UUIDInputPage()),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Title
              Text(
                '"Innerly: A Safe Space"',
                style: GoogleFonts.lora(
                  fontSize: 26,
                  color: Colors.green[800],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                "Support, connection, and healing. Whether you're guiding or seeking.",
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Dynamic Option Cards
              ...options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: OptionCard(
                    imagePath: option.imagePath,
                    text: option.text,
                    onTap: option.onTap,
                  ),
                ),
              ),

              // Admin Link
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: InkWell(
                  onTap: () {
                    // TODO: navigate to admin login
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Are you an admin? ',
                      style: GoogleFonts.lora(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      children: [
                        TextSpan(
                          text: 'Click here',
                          style: GoogleFonts.lora(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// OptionCardData model
class OptionCardData {
  final String imagePath;
  final String text;
  final VoidCallback onTap;

  OptionCardData({
    required this.imagePath,
    required this.text,
    required this.onTap,
  });
}

class OptionCard extends StatelessWidget {
  final String imagePath;
  final String text;
  final VoidCallback onTap;

  const OptionCard({
    Key? key,
    required this.imagePath,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0x14719E07), // 8% opacity of #719E07
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Image.asset(imagePath, height: 200),
            const SizedBox(height: 10),
            Text(
              text,
              style: GoogleFonts.lora(
                color: Colors.green[800],
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
