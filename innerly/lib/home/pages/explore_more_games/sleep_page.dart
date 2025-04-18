import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<String, String> _soundscapes = {
    'Ocean Waves': '🌊',
    'Forest Rain': '🌧️',
    'Mountain Wind': '🍃',
    'Night Insects': '🦗'
  };

  bool _isPlaying = false;
  bool _isLooping = true; // Default to looping for sleep sounds
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  String? _currentSound;
  double _volume = 0.7;

  @override
  void initState() {
    super.initState();
    _setupAudioListeners();
    _audioPlayer.setReleaseMode(ReleaseMode.loop); // Default to loop for sleep
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

  Future<void> _playSound(String sound) async {
    try {
      if (_currentSound == sound && _isPlaying) {
        await _audioPlayer.pause();
      } else {
        final path = 'audio/sleep_audio/${sound.toLowerCase().replaceAll(' ', '_')}.mp3';
        await _audioPlayer.play(AssetSource(path));
        await _audioPlayer.setVolume(_volume);
        setState(() => _currentSound = sound);
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
        _currentSound = null;
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
        title: Text('Soundscape Therapy', style: GoogleFonts.aboreto(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A192F), Color(0xFF172A45)],
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
                  children: _soundscapes.entries.map((entry) => GestureDetector(
                    onTap: () => _playSound(entry.key),
                    child: Card(
                      color: _currentSound == entry.key
                          ? const Color(0xFF6C9A8B).withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _currentSound == entry.key
                              ? const Color(0xFF6C9A8B)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(entry.value, style: const TextStyle(fontSize: 40)),
                          const SizedBox(height: 10),
                          Text(entry.key,
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
              if (_currentSound != null) _buildPlayerControls(isSmallScreen),
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
          // Sound info
          Text(
            _currentSound!,
            style: GoogleFonts.amita(
              fontSize: isSmallScreen ? 20 : 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _soundscapes[_currentSound]!,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 16),

          // Volume control
          Row(
            children: [
              const Icon(Icons.volume_down, color: Colors.white70),
              Expanded(
                child: Slider(
                  value: _volume,
                  min: 0,
                  max: 1,
                  onChanged: (value) async {
                    setState(() => _volume = value);
                    await _audioPlayer.setVolume(value);
                  },
                  activeColor: const Color(0xFF6C9A8B),
                  inactiveColor: Colors.white24,
                ),
              ),
              const Icon(Icons.volume_up, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 8),

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
                activeColor: const Color(0xFF6C9A8B),
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
                  color: _isLooping ? const Color(0xFF6C9A8B) : Colors.white70,
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