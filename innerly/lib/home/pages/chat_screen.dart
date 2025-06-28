import 'dart:async';
import 'dart:io';
import 'package:Innerly/localization/i10n.dart';
import 'package:Innerly/widget/innerly_theme.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
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
      if (user == null) await Supabase.instance.client.auth.signInAnonymously();

      if (mounted) {
        setState(() => _currentUserId = user?.id ?? Supabase.instance.client.auth.currentUser?.id);
      }

      if (_currentUserId != null) {
        await _loadInitialMessages();
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Initialization failed: ${e.toString()}');
    }
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

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isCurrentAudio && _isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 32,
                    color: Colors.blue,
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
                Expanded(
                  child: Column(
                    children: [
                      if (isCurrentAudio && _audioDuration != null && _audioPosition != null)
                        Slider(
                          value: _audioPosition!.inSeconds.toDouble(),
                          min: 0,
                          max: _audioDuration!.inSeconds.toDouble(),
                          onChanged: (value) async {
                            try {
                              await _audioPlayer.seek(Duration(seconds: value.toInt()));
                              if (!_isPlaying) await _audioPlayer.resume();
                            } catch (e) {
                              if (mounted) _showErrorSnackbar('Error seeking: ${e.toString()}');
                            }
                          },
                          activeColor: Colors.blue,
                          inactiveColor: Colors.grey,
                        ),
                      if (isCurrentAudio && _audioDuration != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_audioPosition ?? Duration.zero),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _formatDuration(_audioDuration!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview(String url) {
    final fileName = path.basename(url);
    final fileExtension = fileName.split('.').last.toLowerCase();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () async {
          try {
            final tempDir = await getTemporaryDirectory();
            final filePath = '${tempDir.path}/$fileName';
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
        child: Row(
          children: [
            _getFileTypeIcon(fileExtension),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to open',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new, size: 20, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    final fileName = _selectedFile?.path.split('/').last ?? '';
    final fileExtension = fileName.split('.').last.toLowerCase();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _getFileTypeIcon(fileExtension),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20, color: Colors.grey[600]),
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

  Widget _getFileTypeIcon(String extension) {
    const iconSize = 28.0;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        return const Icon(Icons.image, size: iconSize, color: Colors.blue);
      case 'mp3':
      case 'wav':
      case 'm4a':
        return const Icon(Icons.audiotrack, size: iconSize, color: Colors.purple);
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, size: iconSize, color: Colors.red);
      case 'doc':
      case 'docx':
        return const Icon(Icons.description, size: iconSize, color: Colors.blue);
      case 'mp4':
      case 'mov':
        return const Icon(Icons.videocam, size: iconSize, color: Colors.orange);
      default:
        return const Icon(Icons.insert_drive_file, size: iconSize, color: Colors.grey);
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
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
          maxHeight: 300,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 200,
                width: 200,
                padding: const EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      L10n.getTranslatedText(context, 'Failed to load image'),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
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
      String? filePath;
      if (_selectedFile != null) {
        filePath = await _chatService.uploadFile(_selectedFile!);
      }

      await _chatService.sendMessage(
        receiverId: widget.receiverId,
        message: _messageController.text,
        senderType: widget.isTherapist ? 'therapist' : 'user',
        fileUrl: filePath,
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
        backgroundColor: InnerlyTheme.beige,
        title: Text(widget.receiverName),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _showAttachmentOptions,
            tooltip: L10n.getTranslatedText(context, 'Attach file'),
          ),
        ],
      ),
      backgroundColor: InnerlyTheme.appBackground,
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatService>(
              builder: (context, chatService, child) {
                if (_isLoadingMessages) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (chatService.messages.isEmpty) {
                  return  Center(
                    child: Text(L10n.getTranslatedText(context, 'No messages yet')),
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
                  tooltip: _isRecording ? L10n.getTranslatedText(context, 'Stop recording') : L10n.getTranslatedText(context, 'Record audio'),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: L10n.getTranslatedText(context, 'Type your message...'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: Colors.grey,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: Colors.grey,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1.5,
                        ),
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
                  tooltip: L10n.getTranslatedText(context, 'Send message'),
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
    try {
      _videoPlayerController = VideoPlayerController.network(widget.url)
        ..setLooping(false);

      await _videoPlayerController.initialize();

      // Initialize ChewieController after video controller is ready
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
        placeholder: Container(
          color: Colors.grey,
        ),
        autoInitialize: true,
      );

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) setState(() => _isInitialized = false);
      debugPrint('Video initialization error: $e');
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
    if (!_isInitialized || _chewieController == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 10),
              Text(
                L10n.getTranslatedText(context, 'Loading video...'),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showFullScreenVideo(context),
      child: AspectRatio(
        aspectRatio: _videoPlayerController.value.aspectRatio,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Chewie(controller: _chewieController!),
          ),
        ),
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
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                fullScreenController.pause();
                Navigator.pop(context);
              },
            ),
          ),
          body: Center(
            child: Chewie(controller: fullScreenController),
          ),
        ),
      ),
    ).then((_) => fullScreenController.dispose());
  }
}

enum AttachmentType { image, audio, document, video }