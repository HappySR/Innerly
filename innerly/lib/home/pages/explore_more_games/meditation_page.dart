import 'dart:async';
import 'dart:io';
import 'package:Innerly/localization/i10n.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class MeditationPage extends StatefulWidget {
  const MeditationPage({super.key});

  @override
  State<MeditationPage> createState() => _MeditationPageState();
}

class _MeditationPageState extends State<MeditationPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final CountDownController _timerController = CountDownController();
  final Dio _dio = Dio();
  final _prefsKey = 'downloaded_tracks';
  late final CacheManager _cacheManager;

  bool _isPlaying = false;
  bool _showTimer = false;
  bool _isLooping = false;
  int _selectedDuration = -1;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  List<Map<String, dynamic>> _meditationTracks = [];
  int _selectedTrackIndex = 0;
  Map<String, double> _downloadProgress = {};
  Map<String, bool> _isDownloading = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestStoragePermission();
    });
    _cacheManager = CacheManager(Config('audio_cache',
        stalePeriod: const Duration(days: 30), maxNrOfCacheObjects: 100));
    _setupAudioListeners();
    _initializeTracks();
    _loadDownloadedTracks();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> _initializeTracks() async {
    final cloudName = dotenv.get('CLOUDINARY_CLOUD_NAME');

    setState(() {
      _meditationTracks = [
        {
          'title': L10n.getTranslatedText(context, 'Morning Calm'),
          'remoteUrl': _buildCloudinaryUrl(
              cloudName: cloudName,
              version: 'v1746185897', // Add this from Cloudinary
              publicId: 'morning_calm_pcs2ul'
          ),
          'localPath': '',
          'duration': '10 min',
          'description': L10n.getTranslatedText(context, 'Gentle guidance for starting your day'),
          'isDownloaded': false,
        },
        {
          'title': L10n.getTranslatedText(context, 'Deep Relaxation'),
          'remoteUrl': _buildCloudinaryUrl(
              cloudName: cloudName,
              version: 'v1746185930', // Add this from Cloudinary
              publicId: 'deep_relaxation_pkyohg'
          ),
          'localPath': '',
          'duration': '20 min',
          'description': L10n.getTranslatedText(context, 'Release tension and find peace'),
          'isDownloaded': false,
        },
      ];
    });
  }

  String _buildCloudinaryUrl({
    required String cloudName,
    required String version,
    required String publicId,
  }) {
    return 'https://res.cloudinary.com/$cloudName/video/upload/$version/$publicId.mp3';
  }

  Future<void> _loadDownloadedTracks() async {
    final prefs = await SharedPreferences.getInstance();
    final downloaded = prefs.getStringList(_prefsKey) ?? [];

    for (var track in _meditationTracks) {
      final fileName = track['remoteUrl'].split('/').last;
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDir.path}/$fileName';

      if (downloaded.contains(fileName)) {
        if (await File(localPath).exists()) {
          track['localPath'] = localPath;
          track['isDownloaded'] = true;
        } else {
          prefs.remove(fileName);
        }
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _downloadTrack(int index) async {
    final track = _meditationTracks[index];
    final url = track['remoteUrl'];
    final fileName = url.split('/').last;
    final appDir = await getApplicationDocumentsDirectory();
    final savePath = '${appDir.path}/$fileName';

    if (!await _requestStoragePermission()) return;

    setState(() {
      _isDownloading[url] = true;
      _downloadProgress[url] = 0.0;
    });

    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() => _downloadProgress[url] = received / total);
          }
        },
      );

      // Add to cache
      await _cacheManager.putFile(
        url,
        File(savePath).readAsBytesSync(),
        key: url,
      );

      // Update track state
      final prefs = await SharedPreferences.getInstance();
      final downloaded = prefs.getStringList(_prefsKey) ?? [];
      downloaded.add(fileName);
      await prefs.setStringList(_prefsKey, downloaded);

      setState(() {
        track['localPath'] = savePath;
        track['isDownloaded'] = true;
      });

    } catch (e) {
      _showErrorSnackbar('Download failed: ${e.toString()}');
    } finally {
      setState(() {
        _isDownloading.remove(url);
        _downloadProgress.remove(url);
      });
    }
  }

  Future<bool> _requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 33) { // Android 13+
          final status = await Permission.audio.request();
          if (!status.isGranted) {
            _showErrorSnackbar(L10n.getTranslatedText(context, 'Audio access required for downloads'));
            return false;
          }
        } else { // Android <13
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            _showErrorSnackbar(L10n.getTranslatedText(context, 'Storage permission required for downloads'));
            return false;
          }
        }
      }
      // iOS doesn't need storage permission for app directories
      return true;
    } catch (e) {
      debugPrint('Permission error: $e');
      return false;
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
        final url = track['remoteUrl'];

        FileInfo? fileInfo = await _cacheManager.getFileFromCache(url);
        if (fileInfo == null) {
          fileInfo = await _cacheManager.downloadFile(url);
        }

        await _audioPlayer.play(DeviceFileSource(fileInfo.file.path));

        if (_selectedDuration != -1 && !_showTimer && mounted) {
          setState(() => _showTimer = true);
          _timerController.start();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isPlaying = false);
      debugPrint('Audio Error: $e');
      _showErrorSnackbar('Playback error: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
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
    _dio.close();
    _cacheManager.emptyCache();
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  L10n.getTranslatedText(context, 'Peaceful Mind'),
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
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 15 : 30),

                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _meditationTracks.isEmpty
                                      ? L10n.getTranslatedText(context, 'Loading...')                                      : _meditationTracks[_selectedTrackIndex]['title'],
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

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.loop,
                                  color: _isLooping ? Colors.tealAccent : Colors.white70,
                                  size: isSmallScreen ? 28 : 32,
                                ),
                                onPressed: _toggleLoop,
                              ),
                              SizedBox(width: isSmallScreen ? 10 : 20),

                              IconButton(
                                iconSize: isSmallScreen ? 50 : 60,
                                icon: Icon(
                                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                  color: Colors.white,
                                ),
                                onPressed: _meditationTracks.isEmpty ? null : _playPauseMeditation,
                              ),
                              SizedBox(width: isSmallScreen ? 10 : 20),

                              IconButton(
                                icon: const Icon(Icons.stop_circle),
                                color: Colors.white70,
                                iconSize: isSmallScreen ? 32 : 40,
                                onPressed: _meditationTracks.isEmpty ? null : _resetMeditation,
                              ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 15 : 30),

                          SizedBox(
                            height: isSmallScreen ? 80 : 100,
                            child: _meditationTracks.isEmpty
                                ? const Center(child: CircularProgressIndicator())
                                : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _meditationTracks.length,
                              itemBuilder: (context, index) {
                                final track = _meditationTracks[index];
                                final isDownloading = _isDownloading[track['remoteUrl']] ?? false;
                                final progress = _downloadProgress[track['remoteUrl']] ?? 0.0;

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
                                    child: Stack(
                                      children: [
                                        Column(
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
                                        if (!track['isDownloaded'])
                                          Positioned(
                                            right: 5,
                                            top: 5,
                                            child: IconButton(
                                              icon: isDownloading
                                                  ? CircularProgressIndicator(
                                                value: progress,
                                                backgroundColor: Colors.white24,
                                                valueColor: AlwaysStoppedAnimation(
                                                  Colors.tealAccent,
                                                ),
                                              )
                                                  : Icon(
                                                Icons.cloud_download,
                                                color: Colors.white70,
                                              ),
                                              iconSize: 20,
                                              onPressed: () => _downloadTrack(index),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          Flexible(
                            child: Column(
                              children: [
                                SizedBox(height: isSmallScreen ? 10 : 20),
                                Text(
                                  '${L10n.getTranslatedText(context, 'Duration')}: ${_selectedDuration == -1 ? L10n.getTranslatedText(context, 'Infinite') : '$_selectedDuration min'}',
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
                                    label: _selectedDuration == -1 ? L10n.getTranslatedText(context, 'Infinite') : '$_selectedDuration min',
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