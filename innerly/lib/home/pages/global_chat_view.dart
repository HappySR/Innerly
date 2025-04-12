import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import '../../services/chat_service.dart';

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

  File? _selectedFile;
  bool _isRecording = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _ensureAuth();
  }

  Future<void> _ensureAuth() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      await Supabase.instance.client.auth.signInAnonymously();
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      await _chatService.sendMessage(_messageController.text);
      _messageController.clear();
      _selectedFile = null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() => _selectedFile = File(result.files.single.path!));
    }
  }

  Future<void> _takePhoto() async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _selectedFile = File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Support Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickFile,
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _takePhoto,
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
                  onPressed: () => _isRecording ? _stopRecording() : _startRecording(),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 500,
                  ),
                ),
                IconButton(
                  icon: _isSending
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
    final timestamp = DateTime.parse(message['created_at']);
    final messageType = message['message_type'] ?? 'text';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  message['display_name'] ?? 'Anonymous',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(_timeFormat.format(timestamp)),
              ],
            ),
            const SizedBox(height: 4),
            if (messageType == 'text') Text(message['message'] ?? ''),
            if (messageType == 'image' && message['file_url'] != null)
              Image.network(message['file_url'], height: 200),
            if (messageType == 'audio' && message['file_url'] != null)
              _buildAudioPlayer(message['file_url']),
            if (messageType == 'file' && message['file_url'] != null)
              _buildFileDownload(message['file_url']),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayer(String url) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () => _audioPlayer.play(UrlSource(url)),
        ),
        IconButton(
          icon: const Icon(Icons.stop),
          onPressed: () => _audioPlayer.stop(),
        ),
      ],
    );
  }

  Widget _buildFileDownload(String url) {
    return InkWell(
      onTap: () => _chatService.downloadFile(url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                url.split('/').last,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    return ListTile(
      leading: const Icon(Icons.attach_file),
      title: Text(_selectedFile?.path.split('/').last ?? ''),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => setState(() => _selectedFile = null),
      ),
    );
  }

  void _startRecording() async {
    // Implement actual recording logic
    setState(() => _isRecording = true);
  }

  void _stopRecording() async {
    // Implement actual recording saving
    setState(() => _isRecording = false);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}