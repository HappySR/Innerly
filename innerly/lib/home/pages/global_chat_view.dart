import 'dart:io';
import 'package:Innerly/localization/i10n.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:open_file/open_file.dart';
import '../../services/global_chat_service.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class GlobalChatScreen extends StatefulWidget {
  const GlobalChatScreen({super.key});

  @override
  State<GlobalChatScreen> createState() => _GlobalChatScreenState();
}

class _GlobalChatScreenState extends State<GlobalChatScreen> {
  final _messageController = TextEditingController();
  final DateFormat _timeFormat = DateFormat('HH:mm');
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _imagePicker = ImagePicker();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  String? _audioPath;
  File? _selectedFile;
  String? _fileType;
  bool _isSending = false;
  bool _isPlaying = false;
  Duration? _audioDuration;
  Duration? _audioPosition;
  String? _currentUserId;
  String? _currentlyPlayingAudioUrl;

  @override
  void initState() {
    super.initState();
    _ensureAuth();
    _setupAudioPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _chatService.unsubscribe();
    _messageController.dispose();
    _audioPlayer.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final tempDir = await getTemporaryDirectory();
        _audioPath = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        setState(() {
          _isRecording = true;
        });

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _audioPath!,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null && mounted) {
        setState(() {
          _isRecording = false;
          _selectedFile = File(path);
          _fileType = 'audio';
        });
        _sendMessage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stop recording failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _setupAudioPlayer() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.stopped || state == PlayerState.completed) {
            _currentlyPlayingAudioUrl = null;
          }
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) async {
      if (mounted) {
        setState(() {
          _currentlyPlayingAudioUrl = null;
          _isPlaying = false;
        });
      }
      await _audioPlayer.release();
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _audioDuration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _audioPosition = position;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _currentlyPlayingAudioUrl = null;
          _isPlaying = false;
        });
      }
    });
  }

  Future<void> _ensureAuth() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      await Supabase.instance.client.auth.signInAnonymously();
    }
    if (mounted) {
      setState(() {
        _currentUserId = Supabase.instance.client.auth.currentUser?.id;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty && _selectedFile == null) return;

    setState(() => _isSending = true);

    try {
      String? fileUrl;
      if (_selectedFile != null) {
        fileUrl = await _chatService.uploadFile(_selectedFile!);
      }

      await _chatService.sendMessage(
        _messageController.text,
        fileUrl: fileUrl,
        fileType: _fileType,
      );

      _messageController.clear();
      if (mounted) {
        setState(() {
          _selectedFile = null;
          _fileType = null;
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _showAttachmentOptions() async {
    final result = await showModalBottomSheet<AttachmentType>(
      context: context,
      builder:
          (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Image'),
              onTap: () => Navigator.pop(context, AttachmentType.image),
            ),
            ListTile(
              leading: const Icon(Icons.audiotrack),
              title: const Text('Audio'),
              onTap: () => Navigator.pop(context, AttachmentType.audio),
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Document'),
              onTap: () => Navigator.pop(context, AttachmentType.document),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video'),
              onTap: () => Navigator.pop(context, AttachmentType.video),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      switch (result) {
        case AttachmentType.image:
          await _pickImage();
          break;
        case AttachmentType.audio:
          await _pickAudio();
          break;
        case AttachmentType.document:
          await _pickDocument();
          break;
        case AttachmentType.video:
          await _pickVideo();
          break;
      }
    }
  }

  Future<void> _pickImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final image = await _imagePicker.pickImage(source: source);
    if (image != null && mounted) {
      setState(() {
        _selectedFile = File(image.path);
        _fileType = 'image';
      });
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null && mounted) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileType = 'audio';
      });
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null && mounted) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileType = 'document';
      });
    }
  }

  Future<void> _pickVideo() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final video = await _imagePicker.pickVideo(source: source);
    if (video != null && mounted) {
      setState(() {
        _selectedFile = File(video.path);
        _fileType = 'video';
      });
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder:
          (context) => AlertDialog(
        title: const Text('Select source'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Support Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _showAttachmentOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getGlobalChatStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final message = snapshot.data![index];
                    return _buildMessageItem(message);
                  },
                );
              },
            ),
          ),
          if (_selectedFile != null) _buildFilePreview(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  onPressed: () async {
                    if (_isRecording) {
                      await _stopRecording();
                    } else {
                      await _startRecording();
                    }
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: L10n.getTranslatedText(context, 'Type your message...'),
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 500,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon:
                  _isSending
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.send),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    final timestamp = DateTime.parse(message['created_at']).toLocal();
    final messageType = message['file_type'] ?? 'text';
    final isCurrentUser = message['user_id'] == _currentUserId;
    final hasText =
        message['message'] != null && message['message'].toString().isNotEmpty;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color:
          isCurrentUser
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment:
              isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment:
                  isCurrentUser
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        message['display_name'] ?? 'Anonymous',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeFormat.format(timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (messageType == 'image' && message['file_url'] != null)
                  GestureDetector(
                    onTap: () => _showFullScreenImage(message['file_url']),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        message['file_url'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress
                                    .cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            height: 200,
                            child: Center(child: Icon(Icons.error)),
                          );
                        },
                      ),
                    ),
                  ),
                if (messageType == 'audio' && message['file_url'] != null)
                  _buildAudioPlayer(message['file_url']),
                if (messageType == 'document' && message['file_url'] != null)
                  _buildDocumentPreview(message['file_url']),
                if (messageType == 'video' && message['file_url'] != null)
                  VideoPlayerWidget(url: message['file_url']),
                if (hasText)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      message['message'] ?? '',
                      textAlign:
                      isCurrentUser ? TextAlign.right : TextAlign.left,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioPlayer(String url) {
    final isCurrentAudio = url == _currentlyPlayingAudioUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                isCurrentAudio && _isPlaying ? Icons.pause : Icons.play_arrow,
              ),
              onPressed: () async {
                try {
                  if (isCurrentAudio && _isPlaying) {
                    await _audioPlayer.pause();
                  } else {
                    if (_currentlyPlayingAudioUrl != null) {
                      await _audioPlayer.release();
                    }
                    setState(() => _currentlyPlayingAudioUrl = url);
                    await _audioPlayer.play(UrlSource(url));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () async {
                try {
                  await _audioPlayer.stop();
                  await _audioPlayer.release(); // Add this line
                  if (mounted) {
                    setState(() {
                      _currentlyPlayingAudioUrl = null;
                      _isPlaying = false;
                      _audioPosition = Duration.zero;
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error stopping audio: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
          ],
        ),
        if (isCurrentAudio && _audioDuration != null && _audioPosition != null)
          Slider(
            value: _audioPosition!.inSeconds.toDouble(),
            min: 0,
            max: _audioDuration!.inSeconds.toDouble(),
            onChanged: (value) async {
              try {
                await _audioPlayer.seek(Duration(seconds: value.toInt()));
                if (!_isPlaying) {
                  await _audioPlayer.resume();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error seeking audio: ${e.toString()}')),
                  );
                }
              }
            },
          ),
        if (isCurrentAudio && _audioDuration != null && _audioPosition != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_audioPosition!)),
                Text(_formatDuration(_audioDuration!)),
              ],
            ),
          ),
      ],
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Image'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildDocumentPreview(String url) {
    return InkWell(
      onTap: () async {
        try {
          final file = await _chatService.downloadFile(url);
          if (file != null) {
            await OpenFile.open(file);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to open document: ${e.toString()}'),
              ),
            );
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(url.split('/').last, overflow: TextOverflow.ellipsis),
                  const Text(
                    'Document',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    return ListTile(
      leading: Icon(_getFileTypeIcon(), color: Colors.blue),
      title: Text(_selectedFile?.path.split('/').last ?? ''),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed:
            () => setState(() {
          _selectedFile = null;
          _fileType = null;
        }),
      ),
    );
  }

  IconData _getFileTypeIcon() {
    switch (_fileType) {
      case 'image':
        return Icons.image;
      case 'audio':
        return Icons.audiotrack;
      case 'document':
        return Icons.insert_drive_file;
      case 'video':
        return Icons.videocam;
      default:
        return Icons.attach_file;
    }
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String url;

  const VideoPlayerWidget({super.key, required this.url});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    _videoPlayerController = VideoPlayerController.network(widget.url)
      ..setLooping(false);

    try {
      await _videoPlayerController.initialize();
      if (_isDisposed || !mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false,
        looping: false,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blue,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey.shade300,
        ),
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialized = false);
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _videoPlayerController.pause();
    _chewieController?.dispose();
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return AspectRatio(
      aspectRatio: _videoPlayerController.value.aspectRatio,
      child: GestureDetector(
        onTap: () => _showFullScreenVideo(context),
        child: Chewie(controller: _chewieController!),
      ),
    );
  }

  void _showFullScreenVideo(BuildContext context) {
    _videoPlayerController.addListener(() {
      if (_videoPlayerController.value.isCompleted) {
        _chewieController?.pause();
      }
    });

    final fullScreenController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.blue,
        handleColor: Colors.blue,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.grey.shade300,
      ),
      autoInitialize: true,
      allowPlaybackSpeedChanging: false,
    );

    fullScreenController.addListener(() {
      if (fullScreenController.isFullScreen &&
          _videoPlayerController.value.isCompleted) {
        fullScreenController.pause();
      }
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(L10n.getTranslatedText(context, 'Video Player')),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                fullScreenController.pause();
                Navigator.pop(context);
              },
            ),
          ),
          body: Center(
            child: AspectRatio(
              aspectRatio: _videoPlayerController.value.aspectRatio,
              child: Chewie(controller: fullScreenController),
            ),
          ),
        ),
      ),
    ).then((_) {
      fullScreenController.dispose();
    });
  }
}

enum AttachmentType { image, audio, document, video }
