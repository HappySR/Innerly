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

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Dio _dio = Dio();
  final _prefsKey = 'downloaded_sleep_tracks';
  late final CacheManager _cacheManager;
  late AnimationController _animationController;

  bool _isPlaying = false;
  bool _isLooping = true;
  bool _isLoadingAudio = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  double _volume = 0.7;
  String? _currentSound;
  String? _currentTrack;

  List<Map<String, dynamic>> _soundscapes = [];
  Map<String, double> _downloadProgress = {};
  Map<String, bool> _isDownloading = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _cacheManager = CacheManager(
      Config(
        'sleep_audio_cache',
        stalePeriod: const Duration(days: 30),
        maxNrOfCacheObjects: 100,
      ),
    );
    _setupAudioListeners();
    _initializeSoundscapes();
    _loadDownloadedTracks();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  void _initializeSoundscapes() async {
    final cloudName = dotenv.get('CLOUDINARY_CLOUD_NAME');

    setState(() {
      _soundscapes = [
        {
          'name': 'Ocean Waves',
          'emoji': '🌊',
          'color': const Color(0xFF6C9A8B),
          'remoteUrl': _buildCloudinaryUrl(
            cloudName: cloudName,
            version: 'v1746185812',
            publicId: 'ocean_waves_k5arct',
          ),
          'localPath': '',
          'isDownloaded': false,
          'description': 'Peaceful ocean sounds for deep sleep',
        },
        {
          'name': 'Forest Rain',
          'emoji': '🌧️',
          'color': const Color(0xFF4A6572),
          'remoteUrl': _buildCloudinaryUrl(
            cloudName: cloudName,
            version: 'v1746185840',
            publicId: 'forest_rain_r3blwz',
          ),
          'localPath': '',
          'isDownloaded': false,
          'description': 'Gentle rainfall on forest leaves',
        },
        {
          'name': 'Mountain Wind',
          'emoji': '🍃',
          'color': const Color(0xFF8A9EA7),
          'remoteUrl': _buildCloudinaryUrl(
            cloudName: cloudName,
            version: 'v1746185807',
            publicId: 'mountain_wind_wozcem',
          ),
          'localPath': '',
          'isDownloaded': false,
          'description': 'Calming wind sounds from the mountains',
        },
        {
          'name': 'Night Insects',
          'emoji': '🦗',
          'color': const Color(0xFF4B3832),
          'remoteUrl': _buildCloudinaryUrl(
            cloudName: cloudName,
            version: 'v1746185813',
            publicId: 'night_insects_ad4f7r',
          ),
          'localPath': '',
          'isDownloaded': false,
          'description': 'Soothing night ambience with crickets',
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

    for (var sound in _soundscapes) {
      final fileName = sound['remoteUrl'].split('/').last;
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDir.path}/$fileName';

      if (downloaded.contains(fileName)) {
        if (await File(localPath).exists()) {
          sound['localPath'] = localPath;
          sound['isDownloaded'] = true;
        } else {
          prefs.remove(fileName);
        }
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _downloadSoundscape(String soundName) async {
    final sound = _soundscapes.firstWhere((s) => s['name'] == soundName);
    final url = sound['remoteUrl'];
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
        sound['localPath'] = savePath;
        sound['isDownloaded'] = true;
      });

      _showSuccessSnackbar('${sound['name']} track downloaded successfully');
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
          if (_isLoadingAudio &&
              (state == PlayerState.playing || state == PlayerState.paused)) {
            _isLoadingAudio = false;
          }
        });
      }
    });
  }

  Future<void> _playSound(String soundName) async {
    try {
      if (_currentSound == soundName && _isPlaying) {
        await _audioPlayer.pause();
      } else {
        setState(() {
          _isLoadingAudio = true;
          _currentSound = soundName;
          _currentTrack = soundName;
        });

        final sound = _soundscapes.firstWhere((s) => s['name'] == soundName);
        final url = sound['remoteUrl'];

        FileInfo? fileInfo = await _cacheManager.getFileFromCache(url);
        if (fileInfo == null) {
          fileInfo = await _cacheManager.downloadFile(url);
        }

        await _audioPlayer.play(DeviceFileSource(fileInfo.file.path));
        await _audioPlayer.setVolume(_volume);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        _currentSound = null;
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
              const Icon(Icons.nightlight_round, color: Colors.tealAccent),
              const SizedBox(width: 10),
              Text(
                'Soundscape Therapy',
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder:
                      (context) => Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'About Soundscape Therapy',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Relax and drift into peaceful sleep with our collection of calming nature sounds. Download tracks for offline listening or stream them directly.',
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                'Close',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                ),
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
                  padding: EdgeInsets.fromLTRB(
                    24,
                    isSmallScreen ? 8 : 16,
                    24,
                    8,
                  ),
                  child: Text(
                    'Choose a soundscape for better sleep',
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
                    itemCount: _soundscapes.length,
                    itemBuilder: (context, index) {
                      final sound = _soundscapes[index];
                      final isActive = _currentSound == sound['name'];

                      return GestureDetector(
                        onTap: () => _playSound(sound['name']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                sound['color'].withOpacity(
                                  isActive ? 0.7 : 0.2,
                                ),
                                sound['color'].withOpacity(
                                  isActive ? 0.5 : 0.1,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow:
                                isActive
                                    ? [
                                      BoxShadow(
                                        color: sound['color'].withOpacity(0.5),
                                        blurRadius: 15,
                                        spreadRadius: -5,
                                      ),
                                    ]
                                    : null,
                            border: Border.all(
                              color:
                                  isActive
                                      ? sound['color']
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white.withOpacity(0.8),
                                            ),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      height: 60,
                                      width: 60,
                                      decoration: BoxDecoration(
                                        color:
                                            isActive
                                                ? sound['color'].withOpacity(
                                                  0.3,
                                                )
                                                : Colors.transparent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          sound['emoji'],
                                          style: TextStyle(
                                            fontSize: isActive ? 44 : 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  Text(
                                    sound['name'],
                                    style: GoogleFonts.poppins(
                                      fontSize: isActive ? 20 : 18,
                                      fontWeight:
                                          isActive
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      sound['description'],
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
                              if (!sound['isDownloaded'])
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(30),
                                      onTap:
                                          () => _downloadSoundscape(
                                            sound['name'],
                                          ),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        child:
                                            _isDownloading[sound['remoteUrl']] ??
                                                    false
                                                ? SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    value:
                                                        _downloadProgress[sound['remoteUrl']] ??
                                                        0.0,
                                                    backgroundColor:
                                                        Colors.white24,
                                                    valueColor:
                                                        const AlwaysStoppedAnimation(
                                                          Colors.tealAccent,
                                                        ),
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
    final currentSound = _soundscapes.firstWhere(
      (s) => s['name'] == _currentTrack,
    );

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
                  color: currentSound['color'].withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    currentSound['emoji'],
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
                      currentSound['description'],
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
          const SizedBox(height: 16),

          // Volume slider
          // Row(
          //   children: [
          //     Icon(
          //       Icons.volume_down,
          //       color: Colors.white70,
          //       size: isSmallScreen ? 18 : 20,
          //     ),
          //     Expanded(
          //       child: SliderTheme(
          //         data: SliderThemeData(
          //           trackHeight: 4,
          //           thumbShape: RoundSliderThumbShape(
          //             enabledThumbRadius: 6,
          //             elevation: 2,
          //           ),
          //           overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
          //           trackShape: CustomTrackShape(),
          //         ),
          //         child: Slider(
          //           value: _volume,
          //           min: 0,
          //           max: 1,
          //           onChanged: (value) async {
          //             setState(() => _volume = value);
          //             await _audioPlayer.setVolume(value);
          //           },
          //           activeColor: currentSound['color'],
          //           inactiveColor: Colors.white12,
          //         ),
          //       ),
          //     ),
          //     Icon(
          //       Icons.volume_up,
          //       color: Colors.white70,
          //       size: isSmallScreen ? 18 : 20,
          //     ),
          //   ],
          // ),

          const SizedBox(height: 12),

          // Progress slider
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
                  value:
                      _audioDuration.inSeconds > 0
                          ? _audioPosition.inSeconds
                              .clamp(0, _audioDuration.inSeconds)
                              .toDouble()
                          : 0.0,
                  min: 0,
                  max:
                      _audioDuration.inSeconds > 0
                          ? _audioDuration.inSeconds.toDouble()
                          : 1.0,
                  onChanged: (value) async {
                    await _audioPlayer.seek(Duration(seconds: value.toInt()));
                  },
                  activeColor: currentSound['color'],
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
                  color: _isLooping ? currentSound['color'] : Colors.white70,
                  size: 24,
                ),
                onPressed: _toggleLoop,
                tooltip: 'Repeat',
              ),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap:
                      () =>
                          _isPlaying
                              ? _audioPlayer.pause()
                              : _audioPlayer.resume(),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: currentSound['color'].withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: currentSound['color'].withOpacity(
                          _isPlaying ? 1.0 : 0.5,
                        ),
                        width: 2,
                      ),
                    ),
                    child:
                        _isLoadingAudio
                            ? Center(
                              child: SizedBox(
                                height: 32,
                                width: 32,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    currentSound['color'],
                                  ),
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                            : Icon(
                              _isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
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
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - 20;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
