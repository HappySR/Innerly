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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Immediate Support', style: GoogleFonts.aboreto()),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F7FA), Color(0xFFE4E8F0)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
            child: ListView(
              children: [
                _buildEmergencyCard(
                  context,
                  'Emergency Hotline',
                  '24/7 Suicide & Crisis Lifeline',
                  'Call 988',
                  Icons.emergency,
                  Colors.red,
                  'tel:988',
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                _buildEmergencyCard(
                  context,
                  'Crisis Text Line',
                  'Text HOME to 741741',
                  'Text Now',
                  Icons.sms,
                  Colors.green,
                  'sms:741741?body=HOME',
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                _buildEmergencyCard(
                  context,
                  'Therapist Connect',
                  'Schedule Urgent Session',
                  'Find Help',
                  Icons.people_alt,
                  Colors.blue,
                  'https://www.psychologytoday.com/us/therapists',
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                _buildEmergencyCard(
                  context,
                  'Safety Planning',
                  'Create Personal Safety Plan',
                  'Learn More',
                  Icons.security,
                  Colors.purple,
                  'https://suicidepreventionlifeline.org/wp-content/uploads/2016/08/Brown_StanleySafetyPlanTemplate.pdf',
                ),
                SizedBox(height: isSmallScreen ? 24 : 30),
                Text(
                  'Additional Resources:',
                  style: GoogleFonts.amita(
                    fontSize: isSmallScreen ? 18 : 22,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Wrap(
                  spacing: isSmallScreen ? 8 : 12,
                  runSpacing: isSmallScreen ? 8 : 12,
                  children: [
                    _buildResourceChip(
                      context,
                      'Self-Help Guides',
                      Icons.article,
                      const Color(0xFF6C9A8B),
                      'https://www.mhanational.org/self-help-tools',
                    ),
                    _buildResourceChip(
                      context,
                      'Breathing Exercises',
                      Icons.self_improvement,
                      Colors.orange,
                      'https://www.health.harvard.edu/mind-and-mood/relaxation-techniques-breath-control-helps-quell-errant-stress-response',
                    ),
                    _buildResourceChip(
                      context,
                      'Support Groups',
                      Icons.group,
                      Colors.purple,
                      'https://www.nami.org/Support-Education/Support-Groups',
                    ),
                    _buildResourceChip(
                      context,
                      'Meditation',
                      Icons.health_and_safety,
                      Colors.blue,
                      'https://www.headspace.com/',
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 20 : 30),
                _buildBottomNote(context),
              ],
            ),
          ),
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
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: color.withOpacity(0.2), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _launchContact(url),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: isSmallScreen ? 24 : 28),
              ),
              SizedBox(width: isSmallScreen ? 12 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.amita(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 15,
                  vertical: isSmallScreen ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  actionText,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceChip(
      BuildContext context,
      String label,
      IconData icon,
      Color color,
      String url,
      ) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return ActionChip(
      avatar: Icon(icon, size: isSmallScreen ? 18 : 20, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: isSmallScreen ? 12 : 14,
          color: color,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      shape: StadiumBorder(
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      onPressed: () => _launchContact(url),
    );
  }

  Widget _buildBottomNote(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        const Divider(),
        SizedBox(height: isSmallScreen ? 12 : 16),
        Text(
          'You are not alone. Help is available.',
          style: GoogleFonts.amita(
            fontSize: isSmallScreen ? 16 : 18,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Text(
          'Reach out anytime - your mental health matters.',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}