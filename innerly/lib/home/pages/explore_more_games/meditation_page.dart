import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/services.dart';

class MeditationPage extends StatefulWidget {
  const MeditationPage({super.key});

  @override
  State<MeditationPage> createState() => _MeditationPageState();
}

class _MeditationPageState extends State<MeditationPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final CountDownController _timerController = CountDownController();

  bool _isPlaying = false;
  bool _showTimer = false;
  bool _isLooping = false;
  int _selectedDuration = -1; // -1 represents infinite duration
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  List<Map<String, dynamic>> _meditationTracks = [];
  int _selectedTrackIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupAudioListeners();
    _loadAudioFiles();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> _loadAudioFiles() async {
    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      final audioPaths = json.decode(manifest).keys
          .where((path) => path.startsWith('assets/audio/meditation_audio/'))
          .toList();

      _meditationTracks = audioPaths.map((fullPath) {
        final cleanPath = fullPath.replaceFirst('assets/', '');
        final filename = cleanPath.split('/').last.replaceAll('.mp3', '');

        return {
          'title': filename.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '),
          'path': cleanPath,
          'duration': '10 min',
          'description': _getDescription(filename),
        };
      }).toList();

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _meditationTracks = [
            {
              'title': 'Morning Calm',
              'path': 'audio/meditation_audio/morning_calm.mp3',
              'duration': '10 min',
              'description': 'Gentle guidance for starting your day'
            },
            {
              'title': 'Deep Relaxation',
              'path': 'audio/meditation_audio/deep_relaxation.mp3',
              'duration': '20 min',
              'description': 'Release tension and find peace'
            },
          ];
        });
      }
    }
  }

  String _getDescription(String filename) {
    switch (filename) {
      case 'deep_relaxation':
        return 'Release tension and find peace';
      case 'morning_calm':
        return 'Gentle guidance for starting your day';
      default:
        return 'Meditation track';
    }
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

  Future<void> _playPauseMeditation() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        _timerController.pause();
      } else {
        if (_meditationTracks.isEmpty) return;

        final track = _meditationTracks[_selectedTrackIndex];
        await _audioPlayer.play(AssetSource(track['path']));

        if (_selectedDuration != -1 && !_showTimer && mounted) {
          setState(() => _showTimer = true);
          _timerController.start();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isPlaying = false);
      debugPrint('Audio Error: $e');
    }
  }

  void _resetMeditation() {
    _audioPlayer.stop();
    _timerController.reset();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _showTimer = false;
        _audioPosition = Duration.zero;
      });
    }
  }

  void _completeMeditation() {
    _audioPlayer.stop();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _showTimer = false;
        _audioPosition = Duration.zero;
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

    return '${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;
    final isSmallScreen = screenSize.height < 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3A4F), Color(0xFF0E1E2B)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header with timer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Peaceful Mind',
                                  style: GoogleFonts.aboreto(
                                    fontSize: isSmallScreen ? 20 : 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_showTimer && _selectedDuration != -1)
                                SizedBox(
                                  width: isSmallScreen ? 50 : 60,
                                  height: isSmallScreen ? 50 : 60,
                                  child: CircularCountDownTimer(
                                    duration: _selectedDuration * 60,
                                    initialDuration: 0,
                                    controller: _timerController,
                                    width: isSmallScreen ? 40 : 60,
                                    height: isSmallScreen ? 40 : 60,
                                    ringColor: Colors.white24,
                                    fillColor: Colors.tealAccent.withOpacity(0.3),
                                    backgroundColor: Colors.transparent,
                                    strokeWidth: 4,
                                    strokeCap: StrokeCap.round,
                                    textStyle: GoogleFonts.abel(
                                      fontSize: isSmallScreen ? 12 : 14,
                                      color: Colors.white,
                                    ),
                                    textFormat: CountdownTextFormat.MM_SS,
                                    isReverse: true,
                                    onComplete: _completeMeditation,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 15 : 30),

                          // Meditation track artwork
                          Container(
                            width: isPortrait ? screenSize.width * 0.7 : screenSize.height * 0.7,
                            height: isPortrait ? screenSize.width * 0.7 : screenSize.height * 0.7,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: const DecorationImage(
                                image: AssetImage('assets/images/meditation_artwork.jpg'),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                )
                              ],
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 15 : 30),

                          // Track info
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _meditationTracks.isEmpty
                                      ? 'Loading...'
                                      : _meditationTracks[_selectedTrackIndex]['title'],
                                  style: GoogleFonts.amita(
                                    fontSize: isSmallScreen ? 20 : 24,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isSmallScreen ? 4 : 8),
                                Text(
                                  _meditationTracks.isEmpty
                                      ? ''
                                      : _meditationTracks[_selectedTrackIndex]['description'],
                                  style: GoogleFonts.abel(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    color: Colors.white70,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 15 : 20),

                          // Audio progress bar
                          Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 20),
                                child: Slider(
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
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(_audioPosition),
                                      style: GoogleFonts.abel(
                                        fontSize: isSmallScreen ? 10 : 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(_audioDuration),
                                      style: GoogleFonts.abel(
                                        fontSize: isSmallScreen ? 10 : 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 10 : 20),

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
                              SizedBox(width: isSmallScreen ? 10 : 20),

                              // Main play/pause button
                              IconButton(
                                iconSize: isSmallScreen ? 50 : 60,
                                icon: Icon(
                                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                  color: Colors.white,
                                ),
                                onPressed: _meditationTracks.isEmpty ? null : _playPauseMeditation,
                              ),
                              SizedBox(width: isSmallScreen ? 10 : 20),

                              // Reset button
                              IconButton(
                                icon: const Icon(Icons.stop_circle),
                                color: Colors.white70,
                                iconSize: isSmallScreen ? 32 : 40,
                                onPressed: _meditationTracks.isEmpty ? null : _resetMeditation,
                              ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 15 : 30),

                          // Track selection
                          SizedBox(
                            height: isSmallScreen ? 80 : 100,
                            child: _meditationTracks.isEmpty
                                ? const Center(child: CircularProgressIndicator())
                                : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _meditationTracks.length,
                              itemBuilder: (context, index) {
                                final track = _meditationTracks[index];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedTrackIndex = index);
                                    _resetMeditation();
                                  },
                                  child: Container(
                                    width: isSmallScreen ? 120 : 150,
                                    margin: EdgeInsets.only(right: isSmallScreen ? 8 : 15),
                                    padding: EdgeInsets.all(isSmallScreen ? 10 : 15),
                                    decoration: BoxDecoration(
                                      color: _selectedTrackIndex == index
                                          ? Colors.teal.withOpacity(0.2)
                                          : Colors.white10,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: _selectedTrackIndex == index
                                            ? Colors.tealAccent
                                            : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            track['title'],
                                            style: GoogleFonts.abel(
                                              fontSize: isSmallScreen ? 14 : 16,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(height: isSmallScreen ? 2 : 5),
                                        Flexible(
                                          child: Text(
                                            track['duration'],
                                            style: GoogleFonts.abel(
                                              fontSize: isSmallScreen ? 10 : 12,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                        if (!isSmallScreen) SizedBox(height: 5),
                                        if (!isSmallScreen)
                                          Flexible(
                                            child: Text(
                                              track['description'],
                                              style: GoogleFonts.abel(
                                                fontSize: 10,
                                                color: Colors.white54,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Duration selection
                          Flexible(
                            child: Column(
                              children: [
                                SizedBox(height: isSmallScreen ? 10 : 20),
                                Text(
                                  'Duration: ${_selectedDuration == -1 ? 'Infinite' : '$_selectedDuration min'}',
                                  style: GoogleFonts.abel(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 40),
                                  child: Slider(
                                    value: _selectedDuration == -1 ? 65 : _selectedDuration.toDouble(),
                                    min: 5,
                                    max: 65,
                                    divisions: 12,
                                    label: _selectedDuration == -1 ? 'Infinite' : '$_selectedDuration min',
                                    activeColor: Colors.tealAccent,
                                    inactiveColor: Colors.white24,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedDuration = value == 65 ? -1 : value.toInt();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}