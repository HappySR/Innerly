import 'package:Innerly/localization/i10n.dart';
import 'package:Innerly/widget/innerly_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'games/breathing_game.dart';
import 'games/memory_game.dart';
import 'games/sudoku_screen.dart';
import 'games/web_game.dart';

class GamesHub extends StatelessWidget {
  const GamesHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: InnerlyTheme.appBackground,
        title: Text(L10n.getTranslatedText(context, 'Therapeutic Games'), style: GoogleFonts.lora(
            fontSize: 22
        )),
      ),
      backgroundColor: InnerlyTheme.appBackground,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          mainAxisSpacing: 16.0,
          crossAxisSpacing: 16.0,
          children: [
            buildGameCard(
              context,
              L10n.getTranslatedText(context, 'Breathing\nExercise'),
              Icons.self_improvement,
              Colors.blue,
              const BreathingGameScreen(),
            ),
            buildGameCard(
              context,
              L10n.getTranslatedText(context, 'Stress Relief'),
              Icons.sports_esports,
              Colors.green,
              const WebGameScreen(gameUrl: 'https://poki.com/embed/...'),
            ),
            buildGameCard(
              context,
              L10n.getTranslatedText(context, 'Cognitive\nTraining'),
              Icons.grid_4x4,
              Colors.orange,
              const SudokuScreen(),
            ),
            buildGameCard(
              context,
              L10n.getTranslatedText(context, 'Memory Boost'),
              Icons.memory,
              Colors.purple,
              const MemoryGameScreen(),
            ),
          ],
        ),
      ),
    );
  }


  Widget buildGameCard(BuildContext context, String title, IconData icon,
      Color color, Widget screen) {
    return Card(
      color: Colors.white, // Set card background to white
      elevation: 4,
      // Removed individual card margins
      child: InkWell(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => screen)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(title, style: GoogleFonts.lora(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}