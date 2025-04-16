import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  final List<Map<String, dynamic>> _moodPlaylists = [
    {'name': 'Calm', 'emoji': '😌', 'color': Colors.blue},
    {'name': 'Happy', 'emoji': '😊', 'color': Colors.yellow},
    {'name': 'Focus', 'emoji': '🎯', 'color': Colors.green},
    {'name': 'Energize', 'emoji': '⚡', 'color': Colors.orange},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Music Therapy', style: GoogleFonts.aboreto())),
      body: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        padding: const EdgeInsets.all(20),
        children: _moodPlaylists.map((mood) => Card(
          color: mood['color'].withOpacity(0.2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(mood['emoji'], style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              Text(mood['name'], style: GoogleFonts.amita(fontSize: 20)),
            ],
          ),
        )).toList(),
      ),
    );
  }
}