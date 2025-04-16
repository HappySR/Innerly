import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  final Map<String, String> _soundscapes = {
    'Ocean Waves': '🌊',
    'Forest Rain': '🌧️',
    'Mountain Wind': '🍃',
    'Night Insects': '🦗'
  };
  String _selectedSound = 'Ocean Waves';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Soundscape Therapy', style: GoogleFonts.aboreto())),
      body: Column(
        children: [
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children: _soundscapes.entries.map((entry) => GestureDetector(
                onTap: () => setState(() => _selectedSound = entry.key),
                child: Card(
                  color: _selectedSound == entry.key
                      ? Colors.blue[100]
                      : Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(entry.value, style: const TextStyle(fontSize: 40)),
                      Text(entry.key),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Slider(
              value: 0.7,
              onChanged: (value) {},
              activeColor: const Color(0xFF6C9A8B),
            ),
          ),
        ],
      ),
    );
  }
}