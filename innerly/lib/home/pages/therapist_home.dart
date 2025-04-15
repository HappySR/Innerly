import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'mind_games_view.dart';

class HomeTherapist extends StatelessWidget {
  const HomeTherapist({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6F0EE),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(2, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.search, color: Colors.black87),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search',
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recommended Items
              Text(
                'Recommended Items',
                style: GoogleFonts.abel(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),

              // Replace your Wrap with just this:
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  runSpacing: 16,
                  children: [
                    _buildRecommendedChip('Games', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GamesPage()));
                    }),
                    _buildRecommendedChip('Progress', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GamesPage()));
                    }),
                    _buildRecommendedChip('Music', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GamesPage()));
                    }),
                    _buildRecommendedChip('Consult', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GamesPage()));
                    }),
                    _buildRecommendedChip('Sleep', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GamesPage()));
                    }),
                    _buildRecommendedChip('Relax', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GamesPage()));
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              const Text(
                'Others',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),

              _buildOptionTile('assets/icons/settings.png', 'SETTINGS', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => GamesPage()));
              }),
              const SizedBox(height: 14),
              _buildOptionTile('assets/icons/language.png', 'LANGUAGE', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => GamesPage()));
              }),
              const SizedBox(height: 14),
              _buildOptionTile('assets/icons/leaf1.png', 'LIVELY', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => GamesPage()));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 170,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFD6F0EE),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(2, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.abel(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(String imagePath, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFD6F0EE),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(2, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(
              imagePath,
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 24),
            Text(
              label,
              style: GoogleFonts.aboreto(
                color: const Color(0xFF5F4B8B),
                fontSize: 22,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
