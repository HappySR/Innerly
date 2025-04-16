import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class InitiatePage extends StatelessWidget {
  const InitiatePage({super.key});

  Future<void> _launchContact(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Immediate Support', style: GoogleFonts.aboreto()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _buildEmergencyCard(
              context,
              'Emergency Hotline',
              '24/7 Suicide & Crisis Lifeline',
              '988',
              Icons.emergency,
              Colors.red,
              'tel:988',
            ),
            const SizedBox(height: 20),
            _buildEmergencyCard(
              context,
              'Crisis Text Line',
              'Text HOME to 741741',
              'Free 24/7 Support',
              Icons.sms,
              Colors.green,
              'sms:741741',
            ),
            const SizedBox(height: 20),
            _buildEmergencyCard(
              context,
              'Therapist Connect',
              'Schedule Urgent Session',
              'Next available slot',
              Icons.people_alt,
              Colors.blue,
              'https://therapy.example.com',
            ),
            const SizedBox(height: 20),
            _buildEmergencyCard(
              context,
              'Safety Planning',
              'Create Personal Safety Plan',
              'Step-by-step guide',
              Icons.security,
              Colors.purple,
              'https://safetyplan.example.com',
            ),
            const SizedBox(height: 30),
            Text(
              'Additional Resources:',
              style: GoogleFonts.amita(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                _buildResourceChip('Self-Help Guides', Icons.article,
                    const Color(0xFF6C9A8B)),
                _buildResourceChip('Breathing Exercises', Icons.self_improvement,
                    Colors.orange),
                _buildResourceChip('Support Groups', Icons.group,
                    Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(
      BuildContext context,
      String title,
      String subtitle,
      String actionText,
      IconData icon,
      Color color,
      String url,
      ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: color.withOpacity(0.2), width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _launchContact(url),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.amita(
                          fontSize: 18,
                          fontWeight: FontWeight.w600
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  actionText,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceChip(String label, IconData icon, Color color) {
    return ActionChip(
      avatar: Icon(icon, color: color),
      label: Text(label),
      labelStyle: TextStyle(color: color),
      backgroundColor: color.withOpacity(0.1),
      shape: StadiumBorder(
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      onPressed: () {},
    );
  }
}