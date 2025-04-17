import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PatientsRequests extends StatelessWidget {
  const PatientsRequests({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Illustration
            Column(
              children: [
                Image.asset(
                  'assets/images/meditation.png', // Replace with your image asset
                  width: 500,
                  height: 300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Take a deep breath',
                  style: GoogleFonts.getFont(
                    'Aclonica',
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"You have 4 new requests from users."',
                  style: GoogleFonts.abyssinicaSil(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6FA57C),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 38,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'View Requests',
                    style: GoogleFonts.aclonica(
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pending Requests
            Text(
              'Pending Requests',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            _sessionCard(
              userId: 'User#A56',
              sessionType: 'Stress Relief',
              priority: 'Low',
              priorityColor: Colors.green,
            ),

            const SizedBox(height: 16),

            // Accepted Sessions
            Text(
              'Pending Requests',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            _sessionCard(
              userId: 'User#A56',
              sessionType: 'Stress Relief',
              priority: 'Low',
              priorityColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  // Card Widget
  Widget _sessionCard({
    required String userId,
    required String sessionType,
    required String priority,
    required Color priorityColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundImage: AssetImage('assets/icons/user.png'),
            radius: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userId,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sessionType,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color.fromARGB(145, 76, 175, 79),
                            width: 1,
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Accept',
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color.fromARGB(145, 76, 175, 79),
                            width: 1,
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Decline',
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
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
