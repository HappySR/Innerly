import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Dio _dio = Dio();
  final _prefsKey = 'downloaded_mood_tracks';
  late final CacheManager _cacheManager;
  late AnimationController _animationController;

  bool _isPlaying = false;
  bool _isLooping = false;
  bool _isLoadingAudio = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  String? _currentTrack;
  String? _currentMood;

  List<Map<String, dynamic>> _moodPlaylists = [];
  Map<String, double> _downloadProgress = {};
  Map<String, bool> _isDownloading = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _cacheManager = CacheManager(Config('mood_audio_cache',
        stalePeriod: const Duration(days: 30), maxNrOfCacheObjects: 100));
    _setupAudioListeners();
    _initializeMoods();
    _loadDownloadedTracks();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> _initializeMoods() async {
    final cloudName = dotenv.get('CLOUDINARY_CLOUD_NAME');

    setState(() {
      _moodPlaylists = [
        {
          'name': 'Calm',
          'emoji': '😌',
          'color': const Color(0xFF6C9A8B),
          'remoteUrl': _buildCloudinaryUrl(
              cloudName: cloudName,
              version: 'v1746186043',
              publicId: 'calm_oqh5n7'),
          'localPath': '',
          'isDownloaded': false,
          'description': 'Soothing melodies to help you relax',
        },
        {
          'name': 'Happy',
          'emoji': '😊',
          'color': const Color(0xFFEDD4B2),
          'remoteUrl': _buildCloudinaryUrl(
              cloudName: cloudName,
              version: 'v1746186045',
              publicId: 'happy_fbtfxf'),
          'localPath': '',
          'isDownloaded': false,
          'description': 'Uplifting tunes to brighten your day',
        },
        {
          'name': 'Focus',
          'emoji': '🎯',
          'color': const Color(0xFF8A9EA7),
          'remoteUrl': _buildCloudinaryUrl(
              cloudName: cloudName,
              version: 'v1746186089',
              publicId: 'focus_c2s9yb'),
          'localPath': '',
          'isDownloaded': false,
          'description': 'Ambient sounds for concentration',
        },
        {
          'name': 'Energize',
          'emoji': '⚡',
          'color': const Color(0xFFE8998D),
          'remoteUrl': _buildCloudinaryUrl(
              cloudName: cloudName,
              version: 'v1746186100',
              publicId: 'energize_ybs0kz'),
          'localPath': '',
          'isDownloaded': false,
          'description': 'Dynamic rhythms to boost your energy',
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

    for (var mood in _moodPlaylists) {
      final fileName = mood['remoteUrl'].split('/').last;
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDir.path}/$fileName';

      if (downloaded.contains(fileName)) {
        if (await File(localPath).exists()) {
          mood['localPath'] = localPath;
          mood['isDownloaded'] = true;
        } else {
          prefs.remove(fileName);
        }
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _downloadMoodTrack(String moodName) async {
    final mood = _moodPlaylists.firstWhere((m) => m['name'] == moodName);
    final url = mood['remoteUrl'];
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

      await _cacheManager.putFile(
        url,
        File(savePath).readAsBytesSync(),
        key: url,
      );

      final prefs = await SharedPreferences.getInstance();
      final downloaded = prefs.getStringList(_prefsKey) ?? [];
      downloaded.add(fileName);
      await prefs.setStringList(_prefsKey, downloaded);

      setState(() {
        mood['localPath'] = savePath;
        mood['isDownloaded'] = true;
      });

      _showSuccessSnackbar('${mood['name']} track downloaded successfully');
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

        if (sdkInt >= 33) {
          final status = await Permission.audio.request();
          if (!status.isGranted) {
            _showErrorSnackbar('Audio access required for downloads');
            return false;
          }
        } else {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            _showErrorSnackbar('Storage permission required for downloads');
            return false;
          }
        }
      }
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
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          // This is where we had the error with PlayerState.loading
          // In current AudioPlayers versions, we need to handle this differently
          if (_isLoadingAudio && (state == PlayerState.playing || state == PlayerState.paused)) {
            _isLoadingAudio = false;
          }
        });
      }
    });
  }

  Future<void> _playMood(String moodName) async {
    try {
      if (_currentMood == moodName && _isPlaying) {
        await _audioPlayer.pause();
      } else {
        setState(() {
          _isLoadingAudio = true;
          _currentMood = moodName;
          _currentTrack = moodName;
        });

        final mood = _moodPlaylists.firstWhere((m) => m['name'] == moodName);
        final url = mood['remoteUrl'];

        FileInfo? fileInfo = await _cacheManager.getFileFromCache(url);
        if (fileInfo == null) {
          fileInfo = await _cacheManager.downloadFile(url);
        }

        await _audioPlayer.play(DeviceFileSource(fileInfo.file.path));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isLoadingAudio = false;
        });
      }
      debugPrint('Audio Error: $e');
      _showErrorSnackbar('Playback error: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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
    _animationController.dispose();
    _audioPlayer.dispose();
    _dio.close();
    _cacheManager.emptyCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.dark(
          primary: Colors.tealAccent,
          secondary: Colors.tealAccent.shade700,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.music_note, color: Colors.tealAccent),
              const SizedBox(width: 10),
              Text(
                'Mood Therapy',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.black26,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white70),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF0E1E2B).withOpacity(0.95),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'About Mood Therapy',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Enhance your mood with carefully curated sound tracks. Download tracks for offline listening or stream them directly.',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: Text(
                            'Close',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A192F),
                const Color(0xFF0E1E2B),
                Colors.black.withBlue(30),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(24, isSmallScreen ? 8 : 16, 24, 8),
                  child: Text(
                    'Select a mood to enhance your wellbeing',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                    itemCount: _moodPlaylists.length,
                    itemBuilder: (context, index) {
                      final mood = _moodPlaylists[index];
                      final isActive = _currentMood == mood['name'];

                      return GestureDetector(
                        onTap: () => _playMood(mood['name']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                mood['color'].withOpacity(isActive ? 0.7 : 0.2),
                                mood['color'].withOpacity(isActive ? 0.5 : 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: isActive
                                ? [
                              BoxShadow(
                                color: mood['color'].withOpacity(0.5),
                                blurRadius: 15,
                                spreadRadius: -5,
                              )
                            ]
                                : null,
                            border: Border.all(
                              color: isActive
                                  ? mood['color']
                                  : Colors.white.withOpacity(0.1),
                              width: isActive ? 2 : 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isLoadingAudio && isActive)
                                    SizedBox(
                                      height: 60,
                                      width: 60,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white.withOpacity(0.8),
                                        ),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      height: 60,
                                      width: 60,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? mood['color'].withOpacity(0.3)
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          mood['emoji'],
                                          style: TextStyle(fontSize: isActive ? 44 : 40),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  Text(
                                    mood['name'],
                                    style: GoogleFonts.poppins(
                                      fontSize: isActive ? 20 : 18,
                                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      mood['description'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (isActive && _isPlaying)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.tealAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              if (!mood['isDownloaded'])
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(30),
                                      onTap: () => _downloadMoodTrack(mood['name']),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        child: _isDownloading[mood['remoteUrl']] ?? false
                                            ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            value: _downloadProgress[mood['remoteUrl']] ?? 0.0,
                                            backgroundColor: Colors.white24,
                                            valueColor: const AlwaysStoppedAnimation(Colors.tealAccent),
                                            strokeWidth: 2,
                                          ),
                                        )
                                            : const Icon(
                                          Icons.download_rounded,
                                          color: Colors.white70,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_currentTrack != null) _buildPlayerControls(isSmallScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerControls(bool isSmallScreen) {
    final currentMood = _moodPlaylists.firstWhere((m) => m['name'] == _currentTrack);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isSmallScreen ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: currentMood['color'].withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    currentMood['emoji'],
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentTrack!,
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      currentMood['description'],
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 12 : 13,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                    elevation: 2,
                  ),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
                  trackShape: CustomTrackShape(),
                ),
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
                  activeColor: currentMood['color'],
                  inactiveColor: Colors.white12,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_audioPosition),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      _formatDuration(_audioDuration),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  Icons.loop,
                  color: _isLooping ? currentMood['color'] : Colors.white70,
                  size: 24,
                ),
                onPressed: _toggleLoop,
                tooltip: 'Repeat',
              ),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap: () => _isPlaying ? _audioPlayer.pause() : _audioPlayer.resume(),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: currentMood['color'].withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: currentMood['color'].withOpacity(_isPlaying ? 1.0 : 0.5),
                        width: 2,
                      ),
                    ),
                    child: _isLoadingAudio
                        ? Center(
                      child: SizedBox(
                        height: 32,
                        width: 32,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(currentMood['color']),
                          strokeWidth: 2,
                        ),
                      ),
                    )
                        : Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),

              IconButton(
                icon: const Icon(Icons.stop_rounded),
                color: Colors.white70,
                iconSize: 24,
                onPressed: _resetPlayer,
                tooltip: 'Stop',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4.0;
    final double trackLeft = offset.dx + 10;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - 20;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}