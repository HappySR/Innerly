import 'package:flutter/material.dart';
import 'package:Innerly/home/pages/therapist_patient_details.dart';

class PatientsPage extends StatelessWidget {
  const PatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top illustration
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/patients.png', // Replace with your actual asset path
                    height: 300,
                  ),
                ),

                // Search bar
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                  child: TextField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Search',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFCED4DA), // light grey border
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFCED4DA),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF4CAF50), // green when focused
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // User Cards
                _buildPatientCard(context),
                const SizedBox(height: 12),
                _buildPatientCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Patient card builder
  Widget _buildPatientCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to PatientDetails page on card tap
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PatientDetails()),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: const CircleAvatar(
                radius: 28,
                backgroundImage: AssetImage('assets/icons/user.png'),
              ),
            ),

            // User Info & Buttons
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User#A56',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Issue: Anxiety',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        'Status: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                      ),
                      const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Buttons — wrapped individually with GestureDetector to stop tap propagation
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Prevent parent tap — do message action here
                            print("Message pressed");
                          },
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Same message action
                              print("Message pressed");
                            },
                            icon: const Icon(
                              Icons.message,
                              size: 18,
                              color: Colors.black,
                            ),
                            label: const Text(
                              'Message',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFCED4DA),
                                width: 1,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Prevent parent tap — do schedule action here
                            print("Schedule pressed");
                          },
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Same schedule action
                              print("Schedule pressed");
                            },
                            icon: const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Colors.black,
                            ),
                            label: const Text(
                              'Schedule',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFCED4DA),
                                width: 1,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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
      ),
    );
  }
}
