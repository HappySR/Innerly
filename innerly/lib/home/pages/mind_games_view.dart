import 'package:Innerly/widget/innerly_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'explore_more_games/cognitive_games_pages.dart';
import 'explore_more_games/initiate_page.dart';
import 'explore_more_games/meditation_page.dart';
import 'explore_more_games/music_page.dart';
import 'explore_more_games/relax_page.dart';
import 'explore_more_games/sleep_page.dart';

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF3E7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 25),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'ACTIVITY',
          style: GoogleFonts.lora(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: const [
            GameCard(image: 'assets/icons/meditation.png', label: 'Meditate'),
            GameCard(image: 'assets/icons/sleep.png', label: 'Sleep'),
            GameCard(image: 'assets/icons/music.png', label: 'Music'),
            GameCard(image: 'assets/icons/game.png', label: 'Games'),
            GameCard(image: 'assets/icons/relax.png', label: 'Relax'),
            GameCard(image: 'assets/icons/initiate.png', label: 'Initiate'),
          ],
        ),
      ),
    );
  }
}

class GameCard extends StatelessWidget {
  final String image;
  final String label;

  const GameCard({super.key, required this.image, required this.label});

  void _handleNavigation(BuildContext context) {
    switch (label) {
      case 'Meditate':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MeditationPage()),
        );
        break;
      case 'Sleep':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SleepPage()),
        );
        break;
      case 'Music':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MusicPage()),
        );
        break;
      case 'Games':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GamesHub()),
        );
        break;
      case 'Relax':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RelaxPage()),
        );
        break;
      case 'Initiate':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const InitiatePage()),
        );
        break;
      default:
        debugPrint('No page defined for $label');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleNavigation(context),
      child: Container(
        decoration: BoxDecoration(
          color: InnerlyTheme.pink,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(image, height: 55, color: Colors.black),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.amita(
                fontSize: 24,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
