import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:open_file/open_file.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final bool isTherapist;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.isTherapist,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final DateFormat _timeFormat = DateFormat('HH:mm');
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _imagePicker = ImagePicker();
  late final ChatService _chatService;
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
  StreamSubscription? _chatSubscription;
  bool _isLoadingMessages = false;
  Timer? _messagePollingTimer;

  @override
  void initState() {
    super.initState();
    _chatService = Provider.of<ChatService>(context, listen: false);
    _setupAudioPlayer();

    // Defer initialization to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeChat();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _audioPlayer.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _chatSubscription?.cancel();
    _messagePollingTimer?.cancel();
    super.dispose();  // Removed _chatService.dispose() from here
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _initializeChat() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        await Supabase.instance.client.auth.signInAnonymously();
      }

      if (!mounted) return;

      setState(() {
        _currentUserId = Supabase.instance.client.auth.currentUser?.id;
      });

      if (_currentUserId != null && widget.receiverId.isNotEmpty) {
        await _loadInitialMessages();
        _startMessagePolling();
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Failed to initialize chat: ${e.toString()}');
    }
  }

  void _startMessagePolling() {
    _messagePollingTimer?.cancel();
    _messagePollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        context.read<ChatService>().loadInitialMessages(widget.receiverId);
      }
    });
  }

  Future<void> _loadInitialMessages() async {
    if (_isLoadingMessages) return;

    try {
      if (mounted) {
        setState(() => _isLoadingMessages = true);
      }

      await _chatService.loadInitialMessages(widget.receiverId);

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Failed to load messages: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMessages = false);
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final tempDir = await getTemporaryDirectory();
        _audioPath = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        if (!mounted) return;
        setState(() => _isRecording = true);

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _audioPath!,
        );
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Recording failed: ${e.toString()}');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        if (!mounted) return;
        setState(() {
          _isRecording = false;
          _selectedFile = File(path);
          _fileType = 'audio';
        });
        await _sendMessage();
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Stop recording failed: ${e.toString()}');
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

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _audioDuration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _audioPosition = position);
    });
  }

  Future<void> _pickImage() async {
    try {
      final source = await _showImageSourceDialog();
      if (source == null) return;

      final image = await _imagePicker.pickImage(source: source);
      if (image != null && mounted) {
        setState(() {
          _selectedFile = File(image.path);
          _fileType = 'image';
        });
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _pickAudio() async {
    try {
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
    } catch (e) {
      if (mounted) _showErrorSnackbar('Failed to pick audio: ${e.toString()}');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null && mounted) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileType = 'document';
        });
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Failed to pick document: ${e.toString()}');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final source = await _showImageSourceDialog();
      if (source == null) return;

      final video = await _imagePicker.pickVideo(source: source);
      if (video != null && mounted) {
        setState(() {
          _selectedFile = File(video.path);
          _fileType = 'video';
        });
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Failed to pick video: ${e.toString()}');
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
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

  Future<void> _showAttachmentOptions() async {
    final result = await showModalBottomSheet<AttachmentType>(
      context: context,
      builder: (context) => SafeArea(
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
                size: 32,
              ),
              onPressed: () async {
                try {
                  if (isCurrentAudio && _isPlaying) {
                    await _audioPlayer.pause();
                  } else {
                    if (_currentlyPlayingAudioUrl != null) {
                      await _audioPlayer.stop();
                    }
                    if (mounted) {
                      setState(() => _currentlyPlayingAudioUrl = url);
                    }
                    await _audioPlayer.play(UrlSource(url));
                  }
                } catch (e) {
                  if (mounted) _showErrorSnackbar('Error: ${e.toString()}');
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.stop, size: 32),
              onPressed: () async {
                try {
                  await _audioPlayer.stop();
                  if (mounted) {
                    setState(() {
                      _currentlyPlayingAudioUrl = null;
                      _isPlaying = false;
                      _audioPosition = Duration.zero;
                    });
                  }
                } catch (e) {
                  if (mounted) _showErrorSnackbar('Error stopping audio: ${e.toString()}');
                }
              },
            ),
          ],
        ),
        if (isCurrentAudio && _audioDuration != null && _audioPosition != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
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
                      if (mounted) _showErrorSnackbar('Error seeking audio: ${e.toString()}');
                    }
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(_audioPosition!)),
                    Text(_formatDuration(_audioDuration!)),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentPreview(String url) {
    return InkWell(
      onTap: () async {
        try {
          final tempDir = await getTemporaryDirectory();
          final filePath = '${tempDir.path}/${path.basename(url)}';
          final file = File(filePath);

          if (!await file.exists()) {
            final response = await _chatService.downloadFile(url);
            if (response != null) {
              await file.writeAsBytes(response);
            }
          }

          await OpenFile.open(filePath);
        } catch (e) {
          if (mounted) _showErrorSnackbar('Failed to open document: ${e.toString()}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path.basename(url),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to open',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(_getFileTypeIcon(), color: Colors.blue, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedFile?.path.split('/').last ?? '',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 24),
            onPressed: () {
              if (mounted) {
                setState(() {
                  _selectedFile = null;
                  _fileType = null;
                });
              }
            },
          ),
        ],
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text('Image'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
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

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildImageMessage(String url) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(
            maxHeight: 300,
            maxWidth: 300,
          ),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 200,
                width: 200,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                width: 200,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty && _selectedFile == null) return;

    if (!mounted) return;
    setState(() => _isSending = true);

    try {
      String? fileUrl;
      if (_selectedFile != null) {
        final fileSize = await _selectedFile!.length();
        if (fileSize > 10 * 1024 * 1024) {
          throw Exception('File size exceeds 10MB limit');
        }

        fileUrl = await _chatService.uploadFile(_selectedFile!);
      }

      await _chatService.sendMessage(
        receiverId: widget.receiverId,
        message: _messageController.text,
        senderType: widget.isTherapist ? 'therapist' : 'user',
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
      if (mounted) _showErrorSnackbar('Failed to send: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    final isMe = message['sender_id'] == _currentUserId;
    final messageType = message['file_type'] ?? 'text';
    final timestamp = DateTime.parse(message['created_at']).toLocal();
    final content = message['message']?.toString() ?? '';
    final fileUrl = message['file_url']?.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      widget.receiverName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  if (messageType == 'image' && fileUrl != null)
                    _buildImageMessage(fileUrl),
                  if (messageType == 'audio' && fileUrl != null)
                    _buildAudioPlayer(fileUrl),
                  if (messageType == 'document' && fileUrl != null)
                    _buildDocumentPreview(fileUrl),
                  if (messageType == 'video' && fileUrl != null)
                    VideoPlayerWidget(url: fileUrl),
                  if (content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        content,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _timeFormat.format(timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _showAttachmentOptions,
            tooltip: 'Attach file',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatService>(
              builder: (context, chatService, child) {
                if (_isLoadingMessages) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (chatService.messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: chatService.messages.length,
                  itemBuilder: (context, index) {
                    final reversedIndex = chatService.messages.length - 1 - index;
                    return _buildMessageItem(chatService.messages[reversedIndex]);
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
                  icon: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: _isRecording ? Colors.red : null,
                  ),
                  onPressed: () async {
                    if (_isRecording) await _stopRecording();
                    else await _startRecording();
                  },
                  tooltip: _isRecording ? 'Stop recording' : 'Record audio',
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: 5,
                    minLines: 1,
                  ),
                ),
                IconButton(
                  icon: _isSending
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.send),
                  onPressed: _isSending ? null : _sendMessage,
                  tooltip: 'Send message',
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      if (_isDisposed) return;

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

      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _isInitialized = false);
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text('Video Player'),
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