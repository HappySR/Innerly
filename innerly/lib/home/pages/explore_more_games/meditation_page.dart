import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

class MeditationPage extends StatefulWidget {
  const MeditationPage({super.key});

  @override
  State<MeditationPage> createState() => _MeditationPageState();
}

class _MeditationPageState extends State<MeditationPage> with TickerProviderStateMixin {
  late AnimationController _controller;
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Breathing Exercise', style: GoogleFonts.aboreto())),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF6C9A8B).withOpacity(_controller.value),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(_isPlaying ? 'Breathe Out' : 'Breathe In',
              style: GoogleFonts.amita(fontSize: 24)),
          const SizedBox(height: 20),
          IconButton(
            iconSize: 50,
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () async {
              if (_isPlaying) {
                await _player.pause();
                _controller.stop();
              } else {
                await _player.play(AssetSource('sounds/breathing.mp3'));
                _controller.repeat(reverse: true);
              }
              setState(() => _isPlaying = !_isPlaying);
            },
          ),
        ],
      ),
    );
  }
}