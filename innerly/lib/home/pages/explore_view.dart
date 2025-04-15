import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6), // Creamy light background
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Opacity(
                opacity: 0.5, // Optional: to make background image subtle
                child: Image.asset(
                  'assets/logo/app_logo.png',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // First Button: Know Your Mood
                _HomeButton(
                  iconPath: 'assets/images/brain.png',
                  label: 'KNOW YOUR\nMOOD',
                ),
                const SizedBox(height: 20),

                // Second Button: Track Progress
                _HomeButton(
                  iconPath: 'assets/images/progress.png',
                  label: 'TRACK YOUR\nPROGRESS',
                ),

                const SizedBox(height: 60),

                // Innerly Logo + Text
              ],
            ),

            // Bottom Right Leaf Decoration
            Positioned(
              bottom: 4,
              right: 5,
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  'assets/chat/leaf.png',
                  height: 50,
                  width: 50,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final String iconPath;
  final String label;

  const _HomeButton({required this.iconPath, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset(iconPath, height: 60),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.aboreto(
                fontSize: 23,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.0,
                color: Color(0xFF5F4B8B), // Purple-ish color
              ),
            ),
          ),
        ],
      ),
    );
  }
}
