import 'package:Innerly/home/pages/home_view.dart';
import 'package:flutter/material.dart';

import '../home/pages/bottom_nav.dart';
import '../services/auth_service.dart';

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
                height: 100,
              ),
              const SizedBox(height: 16),
              Text(
                'Innerly',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  fontFamily: 'Serif', // You can use GoogleFonts if desired
                ),
              ),
              const SizedBox(height: 48),

              // "Are you a Therapist???" button
              RoundedButton(
                text: 'Are you a Therapist???',
                onPressed: () {
                  // TODO: navigate or handle action
                },
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),

              // "Continue Anonymously..." button
              RoundedButton(
                text: 'Continue Anonymously...',
                onPressed: () async {
                  try {
                    final authService = AuthService();
                    await authService.handleAnonymousLogin();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const BottomNav()),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),

              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(bottom: 24.0),
                child: Text(
                  '"Not all battles are visible and neither are the victories." — Brittany Burgunder',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Text(text, style: textStyle),
    );
  }
}
