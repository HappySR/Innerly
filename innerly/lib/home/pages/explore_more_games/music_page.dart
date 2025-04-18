import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Map<String, dynamic>> _moodPlaylists = [
    {'name': 'Calm', 'emoji': '😌', 'color': const Color(0xFF6C9A8B)},
    {'name': 'Happy', 'emoji': '😊', 'color': const Color(0xFFEDD4B2)},
    {'name': 'Focus', 'emoji': '🎯', 'color': const Color(0xFF8A9EA7)},
    {'name': 'Energize', 'emoji': '⚡', 'color': const Color(0xFFE8998D)},
  ];

  bool _isPlaying = false;
  bool _isLooping = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  String? _currentTrack;
  String? _currentMood;

  @override
  void initState() {
    super.initState();
    _setupAudioListeners();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  void _setupAudioListeners() {
    _audioPlayer.onPlayerComplete.listen((_) async {
      if (_isLooping && mounted) {
        await _audioPlayer.seek(Duration.zero);
        await _audioPlayer.resume();
      } else if (mounted) {
        setState(() {
          _isPlaying = false;
          _audioPosition = Duration.zero;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _audioDuration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _audioPosition = position);
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  Future<void> _playMood(String mood) async {
    try {
      if (_currentMood == mood && _isPlaying) {
        await _audioPlayer.pause();
      } else {
        final path = 'audio/mood_audio/${mood.toLowerCase()}.mp3';
        await _audioPlayer.play(AssetSource(path));
        setState(() {
          _currentMood = mood;
          _currentTrack = mood;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isPlaying = false);
      debugPrint('Audio Error: $e');
    }
  }

  void _resetPlayer() {
    _audioPlayer.stop();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _audioPosition = Duration.zero;
        _currentTrack = null;
      });
    }
  }

  void _toggleLoop() async {
    if (mounted) {
      setState(() => _isLooping = !_isLooping);
      await _audioPlayer.setReleaseMode(
        _isLooping ? ReleaseMode.loop : ReleaseMode.stop,
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Music Therapy', style: GoogleFonts.aboreto(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3A4F), Color(0xFF0E1E2B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.3,
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  children: _moodPlaylists.map((mood) => GestureDetector(
                    onTap: () => _playMood(mood['name']),
                    child: Card(
                      color: mood['color'].withOpacity(0.2),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _currentMood == mood['name']
                              ? mood['color'].withOpacity(0.8)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(mood['emoji'], style: const TextStyle(fontSize: 40)),
                          const SizedBox(height: 10),
                          Text(mood['name'],
                              style: GoogleFonts.amita(
                                  fontSize: isSmallScreen ? 18 : 22,
                                  color: Colors.white
                              )),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
              ),

              // Player controls
              if (_currentTrack != null) _buildPlayerControls(isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerControls(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Track info
          Text(
            _currentTrack!,
            style: GoogleFonts.amita(
              fontSize: isSmallScreen ? 20 : 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _moodPlaylists.firstWhere((m) => m['name'] == _currentTrack)['emoji'],
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 16),

          // Progress bar
          Column(
            children: [
              Slider(
                value: _audioDuration.inSeconds > 0
                    ? _audioPosition.inSeconds.clamp(0, _audioDuration.inSeconds).toDouble()
                    : 0.0,
                min: 0,
                max: _audioDuration.inSeconds > 0
                    ? _audioDuration.inSeconds.toDouble()
                    : 1.0,
                onChanged: (value) async {
                  await _audioPlayer.seek(Duration(seconds: value.toInt()));
                },
                activeColor: Colors.tealAccent,
                inactiveColor: Colors.white24,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_audioPosition),
                      style: GoogleFonts.abel(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      _formatDuration(_audioDuration),
                      style: GoogleFonts.abel(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Loop button
              IconButton(
                icon: Icon(
                  Icons.loop,
                  color: _isLooping ? Colors.tealAccent : Colors.white70,
                  size: isSmallScreen ? 28 : 32,
                ),
                onPressed: _toggleLoop,
              ),
              const SizedBox(width: 20),

              // Play/Pause button
              IconButton(
                iconSize: isSmallScreen ? 50 : 60,
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: Colors.white,
                ),
                onPressed: () => _isPlaying ? _audioPlayer.pause() : _audioPlayer.resume(),
              ),
              const SizedBox(width: 20),

              // Stop button
              IconButton(
                icon: const Icon(Icons.stop_circle),
                color: Colors.white70,
                iconSize: isSmallScreen ? 32 : 40,
                onPressed: _resetPlayer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}