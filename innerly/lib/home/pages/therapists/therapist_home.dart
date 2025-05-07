import 'package:Innerly/localization/i10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemNavigator
import 'package:google_fonts/google_fonts.dart';
import 'package:Innerly/home/pages/therapists/therapist_patients.dart';
import 'package:Innerly/home/pages/therapists/therapist_requests.dart';
import 'package:Innerly/home/pages/therapists/therapist_schedule.dart';
import 'package:provider/provider.dart';
import '../../providers/bottom_nav_provider.dart';

class HomeTherapist extends StatelessWidget {
  final VoidCallback onProfileTap;
  final VoidCallback goToPatients;
  final VoidCallback goToRequest;

  HomeTherapist({super.key, required this.onProfileTap,
    required this.goToPatients, required this.goToRequest});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Handle back button press to exit app directly
      onWillPop: () async {
        // Exit the app immediately without showing confirmation
        SystemNavigator.pop();
        return false; // This line won't actually be reached due to the app exiting
      },
      child: Scaffold(
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
                              hintText: L10n.getTranslatedText(context, 'Search'),
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
                      '${L10n.getTranslatedText(context, 'Hello')}, Dr.Julia',
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
                          L10n.getTranslatedText(context, '"You have 3 active clients today."'),
                          style: GoogleFonts.aboreto(
                            fontSize: 19,
                            color: const Color.fromARGB(255, 40, 39, 39),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          L10n.getTranslatedText(context, 'Let\'s make a difference!'),
                          style: GoogleFonts.actor(
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
                  padding: EdgeInsets.symmetric(
                    horizontal: 15.0,
                  ), // <-- adjust here
                  child: Column(
                    children: [
                      _buildHomeButton(
                        imagePath: 'assets/icons/patients.png',
                        text: L10n.getTranslatedText(context, 'Patients'),
                          onTap: goToPatients
                      ),
                      const SizedBox(height: 20),
                      _buildHomeButton(
                        imagePath: 'assets/icons/requests.png',
                        text: L10n.getTranslatedText(context, 'View Requests'),
                        onTap: goToRequest
                      ),
                      const SizedBox(height: 20),
                      _buildHomeButton(
                        imagePath: 'assets/icons/chat.png',
                        text: L10n.getTranslatedText(context, 'Go to Chats'),
                        onTap: () {
                          // Use the provider to change the selected tab index
                          // This will navigate to the Community screen with bottom nav
                          final bottomNavProvider = Provider.of<BottomNavProvider>(context, listen: false);
                          bottomNavProvider.currentIndex = 3; // Set index to Community tab (index 3 for therapists)
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildHomeButton(
                        imagePath: 'assets/icons/schedule.png',
                        text: L10n.getTranslatedText(context, 'Today\'s Schedule'),
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