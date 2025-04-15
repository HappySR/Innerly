import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFD7F3F6),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo and App Name with vertical bar
                  Row(
                    children: [
                      Image.asset(
                        'assets/logo/app_logo.png',
                        height: 65, // Slightly smaller so it aligns better
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 30,
                        width: 1.5,
                        color: Colors.black54, // Vertical bar
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'INNERLY',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24, // Adjusted for better visual balance
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // Back Button
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black54, width: 2),
                      color: Colors.transparent,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.black,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Menu Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  _DrawerItem(icon: Icons.person, label: 'PROFILE'),
                  _DrawerItem(icon: Icons.refresh, label: 'RESUME GAME N'),
                  _DrawerItem(icon: Icons.local_hospital, label: 'CONSULT'),
                  _DrawerItem(icon: Icons.spa, label: 'LIVELY'),
                  _DrawerItem(icon: Icons.bar_chart, label: 'MY PROGRESS'),
                  _DrawerItem(icon: Icons.settings, label: 'SETTINGS'),
                  _DrawerItem(icon: Icons.book, label: 'YOUR JOURNAL'),
                  _DrawerItem(icon: Icons.help_outline, label: 'GET HELP'),
                ],
              ),
            ),

            // Bottom Profile
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: AssetImage('assets/images/avatar.png'),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'JULIA',
                        style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const Icon(Icons.logout, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DrawerItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 24, color: Colors.black),
      title: Text(
        label,
        style: GoogleFonts.roboto(
          fontSize: 14,
          color: Colors.black87,
          letterSpacing: 0.5,
        ),
      ),
      onTap: () {
        // You can navigate to the respective screen here
        Navigator.pop(context);
      },
    );
  }
}
