import 'package:Innerly/home/pages/home_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/pages/bottom_nav.dart';
import '../services/auth_service.dart';
import '../services/role.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F1EA), // soft cream background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Image.asset(
                'assets/logo/app_logo.png',
                height: 250,
              ),
              const SizedBox(height: 20),

              // "Are you a Therapist???" button
              RoundedButton(
                text: 'Are you a Therapist???',
                  onPressed: () async {
                    UserRole.isTherapist = true;
                    UserRole.saveRole(true);
                    final authService = AuthService();
                    await authService.handleAnonymousLogin();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => BottomNav()),
                    );
                  },
                textStyle: GoogleFonts.alegreyaSansSc(
                  fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    fontSize: 26
                )
              ),
              const SizedBox(height: 50),

              // "Continue Anonymously..." button
              RoundedButton(
                text: 'Continue Anonymously...',
                onPressed: () async {
                  try {
                    UserRole.isTherapist = false;
                    UserRole.saveRole(false);
                    final authService = AuthService();
                    await authService.handleAnonymousLogin();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => BottomNav()),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
                textStyle: GoogleFonts.alegreyaSansSc(
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 5,
                ),
              ),

              const Spacer(),
              Padding(
                padding: EdgeInsets.only(bottom: 24.0),
                child: Text(
                  '"Not all battles are visible and neither are the victories." — Brittany Burgunder',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.aboreto(
                    fontStyle: FontStyle.italic,
                    fontSize: 25
                  )
                ),
              ),
              SizedBox(height: 40,)
            ],
          ),
        ),
      ),
    );
  }
}

class RoundedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final TextStyle textStyle;

  const RoundedButton({
    Key? key,
    required this.text,
    required this.onPressed,
    required this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFDDE0E6),
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15), // Removed vertical padding
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Center(
        child: Text(
          text,
          style: textStyle,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
