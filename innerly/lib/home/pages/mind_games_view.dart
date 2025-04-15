import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF3E7), // pastel background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 25,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: Text(
          'GAMES',
          style: GoogleFonts.aboreto(
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDAF5FB), // light blue card
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
          Image.asset(image, height: 55, color: Colors.blueGrey),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.amita(
              fontSize: 24,
              color: Colors.black87,
              fontWeight: FontWeight.w600
            ),
          ),
        ],
      ),
    );
  }
}
