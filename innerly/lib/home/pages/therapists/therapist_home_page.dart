import 'package:Innerly/localization/i10n.dart';
import 'package:flutter/material.dart';

class HomeTherapist extends StatelessWidget {
  const HomeTherapist({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.menu, color: Colors.black),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.notifications_none, color: Colors.black),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: L10n.getTranslatedText(context, 'Search'),
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Therapist profile and welcome
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundImage: AssetImage('assets/doctor_avatar.png'),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '${L10n.getTranslatedText(context, 'Hello')}, Dr. Julia',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    L10n.getTranslatedText(context, '"You have 3 active clients today."\nLet\'s make a difference!'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Action Buttons (inlined here)
            _buildTherapistButton(
              context,
              icon: Icons.people,
              text: L10n.getTranslatedText(context, 'Patients'),
              color: Colors.lightBlueAccent,
              onPressed: () {
                // Navigate to patient list screen
              },
            ),
            _buildTherapistButton(
              context,
              icon: Icons.pending_actions,
              text: L10n.getTranslatedText(context, 'View Requests'),
              color: Colors.orangeAccent,
              onPressed: () {
                // Navigate to requests screen
              },
            ),
            _buildTherapistButton(
              context,
              icon: Icons.chat_bubble_outline,
              text: L10n.getTranslatedText(context, 'Go to Chats'),
              color: Colors.lightGreen,
              onPressed: () {
                // Navigate to chat screen
              },
            ),
            _buildTherapistButton(
              context,
              icon: Icons.calendar_today,
              text: L10n.getTranslatedText(context, 'Today\'s Schedule'),
              color: Colors.pinkAccent,
              onPressed: () {
                // Navigate to schedule screen
              },
            ),
          ],
        ),
      ),
    );
  }

  // Therapist button widget inside this file
  Widget _buildTherapistButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 20),
          ],
        ),
      ),
    );
  }
}
