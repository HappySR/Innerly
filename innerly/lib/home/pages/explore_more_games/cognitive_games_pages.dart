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
        title: Text('Therapeutic Games', style: GoogleFonts.aboreto()),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        children: [
          _buildGameCard(
            context,
            'Breathing Exercise',
            Icons.self_improvement,
            Colors.blue,
            const BreathingGameScreen(),
          ),
          _buildGameCard(
            context,
            'Stress Relief',
            Icons.sports_esports,
            Colors.green,
            const WebGameScreen(gameUrl: 'https://poki.com/embed/...'),
          ),
          _buildGameCard(
            context,
            'Cognitive Training',
            Icons.grid_4x4,
            Colors.orange,
            const SudokuScreen(),
          ),
          _buildGameCard(
            context,
            'Memory Boost',
            Icons.memory,
            Colors.purple,
            const MemoryGameScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, String title, IconData icon,
      Color color, Widget screen) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(12),
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
              Text(title, style: GoogleFonts.amita(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}