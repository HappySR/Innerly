import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Innerly/home/pages/therapist_patients.dart';
import 'package:Innerly/home/pages/therapist_requests.dart';
import 'package:Innerly/home/pages/therapist_schedule.dart';

class HomeTherapist extends StatelessWidget {
  const HomeTherapist({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      drawer: Drawer(), // so the filter button works
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 35.0, 16.0, 16.0),
          child: ListView(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.filter_list_sharp,
                        color: Colors.black87,
                      ),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 40,
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
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              // Profile
              Column(
                children: [
                  const CircleAvatar(
                    radius: 75,
                    backgroundImage: AssetImage('assets/user/user.png'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Hello, Dr.Julia',
                    style: GoogleFonts.aclonica(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '"You have 3 active clients today."',
                        style: GoogleFonts.aboreto(
                          fontSize: 20,
                          color: const Color.fromARGB(255, 40, 39, 39),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Let's make a difference!",
                        style: GoogleFonts.aboreto(
                          fontSize: 20,
                          color: const Color.fromARGB(255, 17, 17, 17),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15.0,
                ), // <-- adjust here
                child: Column(
                  children: [
                    _buildHomeButton(
                      imagePath: 'assets/icons/patients.png',
                      text: 'Patients',
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PatientsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildHomeButton(
                      imagePath: 'assets/icons/requests.png',
                      text: 'View Requests',
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PatientsRequests(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildHomeButton(
                      imagePath: 'assets/icons/chat.png',
                      text: 'Go to Chats',
                      onTap: () {},
                    ),
                    const SizedBox(height: 20),
                    _buildHomeButton(
                      imagePath: 'assets/icons/schedule.png',
                      text: 'Today\'s Schedule',
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScheduleScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton({
    required String imagePath,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(imagePath, width: 32, height: 32),
            const SizedBox(width: 22),
            Text(text, style: const TextStyle(fontSize: 22)),
          ],
        ),
      ),
    );
  }
}
