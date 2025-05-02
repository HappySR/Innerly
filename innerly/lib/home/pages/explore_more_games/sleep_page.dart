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

class _SleepPageState extends State<SleepPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Dio _dio = Dio();
  final _prefsKey = 'downloaded_sleep_tracks';
  late final CacheManager _cacheManager;

  bool _isPlaying = false;
  bool _isLooping = true;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  double _volume = 0.7;
  String? _currentSound;

  List<Map<String, dynamic>> _soundscapes = [];
  Map<String, double> _downloadProgress = {};
  Map<String, bool> _isDownloading = {};

  @override
  void initState() {
    super.initState();
    _cacheManager = CacheManager(Config('sleep_audio_cache',
        stalePeriod: const Duration(days: 30), maxNrOfCacheObjects: 100));
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
              publicId: 'ocean_waves_k5arct'),
          'localPath': '',
          'isDownloaded': false,
        },
        {
          'name': 'Forest Rain',
          'emoji': '🌧️',
          'color': const Color(0xFF4A6572),
          'remoteUrl': _buildCloudinaryUrl(
              cloudName: cloudName,
              version: 'v1746185840',
              publicId: 'forest_rain_r3blwz'),
          'localPath': '',
          'isDownloaded': false,
        },
        {
          'name': 'Mountain Wind',
          'emoji': '🍃',
          'color': const Color(0xFF8A9EA7),
          'remoteUrl': _buildCloudinaryUrl(
              cloudName: cloudName,
              version: 'v1746185807',
              publicId: 'mountain_wind_wozcem'),
          'localPath': '',
          'isDownloaded': false,
        },
        {
          'name': 'Night Insects',
          'emoji': '🦗',
          'color': const Color(0xFF4B3832),
          'remoteUrl': _buildCloudinaryUrl(
              cloudName: cloudName,
              version: 'v1746185813',
              publicId: 'night_insects_ad4f7r'),
          'localPath': '',
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
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  Future<void> _playSound(String soundName) async {
    try {
      if (_currentSound == soundName && _isPlaying) {
        await _audioPlayer.pause();
      } else {
        final sound = _soundscapes.firstWhere((s) => s['name'] == soundName);
        final url = sound['remoteUrl'];

        FileInfo? fileInfo = await _cacheManager.getFileFromCache(url);
        fileInfo ??= await _cacheManager.downloadFile(url);

        await _audioPlayer.play(DeviceFileSource(fileInfo.file.path));
        await _audioPlayer.setVolume(_volume);
        setState(() => _currentSound = soundName);
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
    _dio.close();
    _cacheManager.emptyCache();
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
                  children: _soundscapes.map((sound) => GestureDetector(
                    onTap: () => _playSound(sound['name']),
                    child: Card(
                      color: sound['color'].withOpacity(0.2),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _currentSound == sound['name']
                              ? sound['color'].withOpacity(0.8)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(sound['emoji'], style: const TextStyle(fontSize: 40)),
                              const SizedBox(height: 10),
                              Text(sound['name'],
                                  style: GoogleFonts.amita(
                                      fontSize: isSmallScreen ? 18 : 22,
                                      color: Colors.white
                                  )),
                            ],
                          ),
                          if (!sound['isDownloaded'])
                            Positioned(
                              right: 8,
                              top: 8,
                              child: IconButton(
                                icon: _isDownloading[sound['remoteUrl']] ?? false
                                    ? CircularProgressIndicator(
                                  value: _downloadProgress[sound['remoteUrl']] ?? 0.0,
                                  backgroundColor: Colors.white24,
                                  valueColor: const AlwaysStoppedAnimation(Colors.tealAccent),
                                )
                                    : const Icon(Icons.cloud_download, color: Colors.white70),
                                iconSize: 20,
                                onPressed: () => _downloadSoundscape(sound['name']),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
              ),

              if (_currentSound != null) _buildPlayerControls(isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerControls(bool isSmallScreen) {
    final currentSound = _soundscapes.firstWhere((s) => s['name'] == _currentSound);

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Text(
            _currentSound!,
            style: GoogleFonts.amita(
              fontSize: isSmallScreen ? 20 : 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentSound['emoji'],
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 16),

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
                  activeColor: currentSound['color'],
                  inactiveColor: Colors.white24,
                ),
              ),
              const Icon(Icons.volume_up, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 8),

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
                activeColor: currentSound['color'],
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

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.loop,
                  color: _isLooping ? currentSound['color'] : Colors.white70,
                  size: isSmallScreen ? 28 : 32,
                ),
                onPressed: _toggleLoop,
              ),
              const SizedBox(width: 20),

              IconButton(
                iconSize: isSmallScreen ? 50 : 60,
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: Colors.white,
                ),
                onPressed: () => _isPlaying ? _audioPlayer.pause() : _audioPlayer.resume(),
              ),
              const SizedBox(width: 20),

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