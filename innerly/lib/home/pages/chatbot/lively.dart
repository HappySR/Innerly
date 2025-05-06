import 'package:Innerly/innerly_theme.dart';
import 'package:Innerly/localization/i10n.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:Innerly/home/pages/chatbot/file_view.dart';
import 'package:Innerly/home/pages/chatbot/chat_history_drawer.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:open_file/open_file.dart';
import 'package:Innerly/widget/audio_player.dart';
import 'package:Innerly/widget/full_screen_video.dart';
import 'package:Innerly/widget/typing_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:Innerly/home/pages/chatbot/models/chat_session.dart';
import '../../../widget/innerly_theme.dart';

class Lively extends StatefulWidget {
  String? initialMessage;
  Lively({super.key, this.initialMessage});

  @override
  LivelyState createState() => LivelyState();
}

class LivelyState extends State<Lively> {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _currentChatId;
  List<ChatSession> _chatHistory = [];
  bool _isLoadingChats = true;

  final ScrollController _scrollController = ScrollController();
  String selectedLanguage = "en";
  List<Map<String, dynamic>> chatMessages = [];

  final TextEditingController _textController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  Timer? _timer;
  int _seconds = 0;
  bool isConverting = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String searchQuery = "";
  List<Map<String, String>> languages = [
    {'name': 'English', 'code': 'en'},
    {'name': 'Spanish', 'code': 'es'},
    {'name': 'French', 'code': 'fr'},
    {'name': 'German', 'code': 'de'},
    {'name': 'Hindi', 'code': 'hi'},
    {'name': 'Chinese', 'code': 'zh'},
    {'name': 'Japanese', 'code': 'ja'},
    {'name': 'Bengali', 'code': 'bn'},
  ];
  final Map<String, Map<String, String>> errorMessages = {
    'server_error': {
      'en': 'Oops! Something went wrong. Please try again.',
      'es': '¡Vaya! Algo salió mal. Por favor, inténtalo de nuevo.',
      'fr': 'Oups ! Quelque chose s\'est mal passé. Veuillez réessayer.',
      'de': 'Ups! Etwas ist schief gelaufen. Bitte versuche es erneut.',
      'hi': 'उफ़! कुछ गलत हो गया। कृपया पुनः प्रयास करें।',
      'zh': '哎呀！出了点问题。请再试一次。',
      'ja': 'おっと！問題が発生しました。もう一度お試しください。',
      'bn': 'ওহ! কিছু ভুল হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
    },
    'connection_error': {
      'en':
          'Error connecting to the server. Please check your internet connection.',
      'es':
          'Error al conectar con el servidor. Por favor, revise su conexión a internet.',
      'fr':
          'Erreur de connexion au serveur. Veuillez vérifier votre connexion Internet.',
      'de':
          'Fehler beim Verbinden mit dem Server. Bitte überprüfen Sie Ihre Internetverbindung.',
      'hi':
          'सर्वर से कनेक्ट करने में त्रुटि। कृपया अपना इंटरनेट कनेक्शन जांचें।',
      'zh': '连接服务器出错。请检查您的互联网连接。',
      'ja': 'サーバーへの接続エラー。インターネット接続を確認してください。',
      'bn':
          'সার্ভারের সাথে সংযোগে ত্রুটি হয়েছে। অনুগ্রহ করে আপনার ইন্টারনেট সংযোগ পরীক্ষা করুন।',
    },
  };

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addAssistantMessage(String message) async {
    if (_currentChatId == null) {
      final supabase = Supabase.instance.client;
      final newChat = await supabase
          .from('chats')
          .insert({'title': 'New Chat', 'user_id': _supabase.auth.currentUser?.id})
          .select()
          .single();
      _currentChatId = newChat['id'] as String;
    }

    final messageData = {
      'chat_id': _currentChatId,
      'role': 'assistant',
      'content': message,
    };

    await _supabase.from('messages').insert(messageData);

    setState(() {
      chatMessages.add({
        "role": "assistant",
        "text": message,
        "timestamp": DateTime.now(),
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _loadChatHistory();
    if (widget.initialMessage != null) {
      _addAssistantMessage(widget.initialMessage!);
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final response = await _supabase
          .from('chats')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _chatHistory =
            (response as List).map((e) => ChatSession.fromMap(e)).toList();
        _isLoadingChats = false;
      });
    } catch (e) {
      debugPrint("Error loading chat history: $e");
      _isLoadingChats = false;
    }
  }

  Future<void> _startNewChat() async {
    // Only create new chat if current chat has content
    if (chatMessages.isEmpty && _textController.text.isEmpty) {
      return;
    }

    try {
      final newChat = {
        'title': 'New Chat',
        'user_id': _supabase.auth.currentUser?.id,
      };

      final response =
      await _supabase.from('chats').insert(newChat).select().single();

      setState(() {
        _currentChatId = response['id'];
        chatMessages.clear();
        _textController.clear();
        _isRecording = false;
        _timer?.cancel();
        _seconds = 0;
      });
      await _loadChatHistory();
    } catch (e) {
      debugPrint("Error creating new chat: $e");
    }
  }

  Future<void> _loadChatSession(ChatSession chat) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('chat_id', chat.id)
          .order('created_at', ascending: true);

      setState(() {
        _currentChatId = chat.id;
        chatMessages = (response as List)
            .map((m) => {
          'role': m['role'] ?? 'user',
          'text': m['content'] ?? '',
          'media_type': m['media_type'],
          'file_url': m['file_url'],
          'storage_path': m['storage_path'],
          'created_at': DateTime.parse(m['created_at']),
        })
            .toList();
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint("Error loading chat session: $e");
    }
  }

  Future<void> _initRecorder() async {
    bool hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      debugPrint("Recording permission not granted.");
    }
  }

  String getTranslatedError(String key, String langCode) {
    return errorMessages[key]?[langCode] ??
        errorMessages[key]?['en'] ??
        'An error occurred';
  }

  void _showPromptDialog(File file, String fileType) {
    TextEditingController promptController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(L10n.getTranslatedText(context, 'Add Optional Prompt')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.attach_file),
                  title: Text(file.path.split('/').last),
                  subtitle: Text(
                    "${(file.lengthSync() / 1024).toStringAsFixed(1)}KB",
                  ),
                ),
                TextField(
                  controller: promptController,
                  decoration: InputDecoration(
                    hintText: L10n.getTranslatedText(
                      context,
                      'Enter your prompt (optional)',
                    ),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(L10n.getTranslatedText(context, 'Cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _uploadFile(file, fileType, promptController.text);
                },
                child: Text(L10n.getTranslatedText(context, 'Upload')),
              ),
            ],
          ),
    );
  }

  Future<void> _pickFile(String fileType) async {
    FileType type;
    List<String>? allowedExtensions;

    switch (fileType) {
      case 'Image':
        type = FileType.image;
        break;
      case 'Document':
        type = FileType.custom;
        allowedExtensions = ['pdf', 'docx', 'txt'];
        break;
      case 'Video':
        type = FileType.video;
        break;
      case 'Audio':
        type = FileType.audio;
        break;
      default:
        debugPrint("❌ Invalid file type.");
        return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: (type == FileType.custom) ? allowedExtensions : null,
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      _showPromptDialog(file, fileType);
    } else {
      debugPrint("❌ File selection canceled.");
    }
  }

  Future<void> _uploadFile(
    File file,
    String fileType, [
    String prompt = '',
  ]) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // 1. Upload to Supabase Storage
      final fileExt = file.path.split('.').last;
      final storagePath =
          '${user.id}/$_currentChatId/${fileType.toLowerCase()}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _supabase.storage.from('chatbot').upload(storagePath, file);

      final publicUrl = _supabase.storage
          .from('chatbot')
          .getPublicUrl(storagePath);

      // 2. Save to messages table
      final messageData = {
        'chat_id': _currentChatId,
        'user_id': user.id,
        'role': 'user',
        'content': prompt.isNotEmpty ? prompt : "Uploaded $fileType",
        'media_type': fileType.toLowerCase(),
        'storage_path': storagePath,
        'file_url': publicUrl,
      };

      await _supabase.from('messages').insert(messageData);

      // 3. Add to local state
      setState(() {
        chatMessages.add({
          "role": "user",
          "text": prompt.isNotEmpty ? prompt : "Uploaded $fileType",
          "media_type": fileType.toLowerCase(),
          "file_url": publicUrl,
          "storage_path": storagePath,
        });

        chatMessages.add({
          "role": "assistant",
          "text": "...",
          "isTyping": true,
        });
      });

      // 4. Send to backend API
      var backendUrl = Uri.parse(
        '${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/process_${fileType.toLowerCase()}',
      );

      var request = http.MultipartRequest('POST', backendUrl)
        ..fields.addAll({
          'prompt': prompt.isNotEmpty ? prompt : 'Describe this file',
          'source_lang': 'auto',
          'target_lang': selectedLanguage,
          'file_url': publicUrl, // Send Supabase URL instead of file
        });

      // If backend still needs file bytes, keep this part
      String fileFieldName = (fileType == 'Image') ? 'image' : 'file';
      String? mimeType = lookupMimeType(file.path);
      mimeType ??=
          (fileType == 'Video') ? 'video/mp4' : 'application/octet-stream';

      request.files.add(
        await http.MultipartFile.fromPath(
          fileFieldName,
          file.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(responseBody);
        String aiResponse =
            decodedResponse is Map<String, dynamic>
                ? decodedResponse.values.first.toString()
                : responseBody;

        // Update with AI response
        final aiMessageData = {
          'chat_id': _currentChatId,
          'role': 'assistant',
          'content': aiResponse,
        };

        await _supabase.from('messages').insert(aiMessageData);

        setState(() {
          chatMessages.removeWhere((msg) => msg["isTyping"] == true);
          chatMessages.add({"role": "assistant", "text": aiResponse});
        });
      } else {
        _handleUploadError(responseBody);
      }
    } catch (e) {
      _handleUploadError(e.toString());
    }
  }

  void _handleUploadError(String error) {
    setState(() {
      chatMessages.removeWhere((msg) => msg["isTyping"] == true);
      chatMessages.add({
        "role": "assistant",
        "text": "⚠️ Error: ${L10n.getTranslatedText(context, 'upload_failed')}",
      });
    });
    debugPrint("Upload error: $error");
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      String? path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _timer?.cancel();
        _seconds = 0;
      });

      if (path != null) {
        File file = File(path);
        debugPrint(
          "Audio file path: $path, Size: ${file.existsSync() ? file.lengthSync() : 'File not found'} bytes",
        );

        if (file.existsSync()) {
          debugPrint("File exists, uploading...");
          await _uploadSpeech(file);
        } else {
          debugPrint("File does NOT exist. Path: $path");
        }
      } else {
        debugPrint("Recording path is null.");
      }
    } else {
      // Request microphone permission
      PermissionStatus micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        debugPrint("Microphone permission not granted.");
        return;
      }

      // Prepare file path for recording in WAV format
      Directory tempDir = await getApplicationDocumentsDirectory();
      String filePath =
          '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      try {
        // Start recording with WAV format
        debugPrint("Starting recording at path: $filePath");
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.wav),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _seconds = 0;
        });

        // Timer for tracking recording duration
        _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
          setState(() {
            _seconds++;
          });
        });
      } catch (e) {
        debugPrint("Error starting recording: $e");
      }
    }
  }

  Future<void> _uploadSpeech(File file) async {
    try {
      if (!file.existsSync() || file.lengthSync() == 0) {
        debugPrint("❌ File does not exist or is empty.");
        return;
      }
      debugPrint("File size: ${file.lengthSync()} bytes");

      setState(() {
        isConverting = true;
      });

      var url = Uri.parse(
        '${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/process_stt',
      );

      var request = http.MultipartRequest('POST', url);

      selectedLanguage = selectedLanguage.isNotEmpty ? selectedLanguage : "hi";
      debugPrint("Selected target language: $selectedLanguage");

      request.fields.addAll({
        'prompt': 'इस ऑडियो को हिंदी में लिखो',
        'source_lang': 'auto',
        'target_lang': selectedLanguage,
      });

      final mimeType = lookupMimeType(file.path) ?? "audio/flac";
      debugPrint("Detected MIME type: $mimeType");

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      debugPrint("Server response: $responseBody");

      if (response.statusCode == 200) {
        debugPrint("✅ Audio uploaded successfully!");
        var decodedResponse = jsonDecode(responseBody);

        String detectedLang = decodedResponse['language'] ?? 'unknown';
        debugPrint("Detected Language: $detectedLang");

        if (detectedLang == 'hi' && selectedLanguage == "auto") {
          setState(() {
            selectedLanguage = 'hi';
          });
          debugPrint("✅ Updated selected language to Hindi");
        }

        await _handleServerResponse(decodedResponse);
      } else {
        debugPrint("❌ Upload failed with status: ${response.statusCode}");
        debugPrint("Server response: $responseBody");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              L10n.getTranslatedText(
                context,
                '❌ Something went wrong. Hugging Face may be down.',
              ),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error uploading audio: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            L10n.getTranslatedText(
              context,
              '❌ Error uploading audio. Hugging Face may be down.',
            ),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        isConverting = false;
      });
    }
  }

  Future<void> _handleServerResponse(Map<String, dynamic> response) async {
    try {
      if (response.containsKey('text')) {
        String responseText = response['text'];
        _textController.text = responseText;
      } else {
        debugPrint("❌ No text key in server response");
      }
    } catch (e) {
      debugPrint("❌ Error handling server response: $e");
    }
  }

  void _sendMessage(String message) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (_currentChatId == null) {
      final newChat = await supabase
          .from('chats')
          .insert({'title': 'New Chat', 'user_id': userId})
          .select()
          .single();
      _currentChatId = newChat['id'] as String;
    }

    // Add user message to UI immediately
    setState(() {
      chatMessages.add({
        "role": "user",
        "text": message,
        "timestamp": DateTime.now(),
      });

      // Add typing indicator
      chatMessages.add({
        "role": "assistant",
        "isTyping": true,
      });
    });

    // Get chat context from previous messages
    String context = await _getChatContext();

    // Create the full prompt with context
    String fullPrompt = "The past messages of this chat are:\n$context\n\n"
        "Current message: $message\n\n"
        "Please respond to the current message considering the chat history.";

    try {
      final url = Uri.parse(
        '${dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000'}/api/process_text',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'text': fullPrompt, 'target_language': selectedLanguage},
      );

      if (response.statusCode == 200) {
        final aiResponse = utf8.decode(response.bodyBytes);
        final aiMessage = jsonDecode(aiResponse)['response'];

        // Save to database
        final aiMessageData = {
          'chat_id': _currentChatId,
          'user_id': _supabase.auth.currentUser?.id,
          'role': 'assistant',
          'content': aiMessage,
        };
        await supabase.from('messages').insert(aiMessageData);

        // Update UI
        setState(() {
          // Remove typing indicator
          chatMessages.removeWhere((msg) => msg["isTyping"] == true);
          chatMessages.add({
            "role": "assistant",
            "text": aiMessage,
            "timestamp": DateTime.now(),
          });
        });
      }
    } catch (error) {
      setState(() {
        // Remove typing indicator on error too
        chatMessages.removeWhere((msg) => msg["isTyping"] == true);
        chatMessages.add({
          "role": "assistant",
          "text": getTranslatedError('connection_error', selectedLanguage),
          "timestamp": DateTime.now(),
        });
      });
    }

    _scrollToBottom();
  }

// New method to fetch chat context
  Future<String> _getChatContext() async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('chat_id', _currentChatId as Object)
          .order('created_at', ascending: false)
          .limit(10);

      List<Map<String, dynamic>> messages = (response as List)
          .map((m) => {
        'role': m['role'] ?? 'user',
        'content': m['content'] ?? '',
        'created_at': DateTime.parse(m['created_at']),
      })
          .toList();

      // Format messages for context
      String context = messages.reversed.map((msg) {
        return "${msg['role'] == 'user' ? 'User' : 'Assistant'}: ${msg['content']}";
      }).join('\n');

      return context.isNotEmpty ? context : "No previous messages";
    } catch (e) {
      debugPrint("Error fetching context: $e");
      return "Error loading chat history";
    }
  }

  void _showLanguageSelection() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
        String searchQuery = "";

        return StatefulBuilder(
          builder: (context, setModalState) {
            List<Map<String, String>> filteredLanguages =
                languages
                    .where(
                      (language) => language['name']!.toLowerCase().startsWith(
                        searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();

            return Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    L10n.getTranslatedText(context, 'Select Output Language'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Divider(),
                  TextField(
                    decoration: InputDecoration(
                      labelText: L10n.getTranslatedText(
                        context,
                        'Search Languages',
                      ),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (query) {
                      setModalState(() {
                        searchQuery = query;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredLanguages.length,
                      itemBuilder: (context, index) {
                        var language = filteredLanguages[index];
                        return _languageTile(
                          language['name'] ?? '',
                          language['code'] ?? '',
                          modalContext,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: InnerlyTheme.beige,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        title: SizedBox(
          height: kToolbarHeight,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.menu, size: 28, color: InnerlyTheme.secondary),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ),
              Center(
                child: Text(
                  'Lively',
                  style: TextStyle(
                    color: InnerlyTheme.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: newChatIcon(), onPressed: _startNewChat),
                    IconButton(
                      icon: Icon(
                        Icons.translate,
                        size: 28,
                        color: InnerlyTheme.secondary,
                      ),
                      onPressed: _showLanguageSelection,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: InnerlyTheme.appBackground,

      drawer: ChatHistoryDrawer(
        chatHistory: _chatHistory,
        isLoading: _isLoadingChats,
        onSelectChat: _loadChatSession,
        onDeleteChat: (chat) async {
          try {
            await _supabase.from('chats').delete().eq('id', chat.id);
            if (_currentChatId == chat.id) {
              _startNewChat();
            }
            await _loadChatHistory();
          } catch (e) {
            debugPrint("Error deleting chat: $e");
          }
        },
      ),

      body: chatMessages.isEmpty ? _buildInitialUI() : _buildChatUI(context),
      bottomNavigationBar: AnimatedPadding(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  icon: Icon(
                    Icons.attach_file,
                    color: InnerlyTheme.secondary,
                    size: 27,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (BuildContext context) {
                        return Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildAttachmentOption(
                                context,
                                Icons.image,
                                L10n.getTranslatedText(context, 'Image'),
                                Colors.blue,
                                'Image',
                              ),
                              _buildAttachmentOption(
                                context,
                                Icons.insert_drive_file,
                                L10n.getTranslatedText(context, 'Document'),
                                Colors.green,
                                'Document',
                              ),
                              _buildAttachmentOption(
                                context,
                                Icons.video_library,
                                L10n.getTranslatedText(context, 'Video'),
                                Colors.orange,
                                'Video',
                              ),
                              _buildAttachmentOption(
                                context,
                                Icons.audiotrack,
                                L10n.getTranslatedText(context, 'Audio'),
                                Colors.purple,
                                'Audio',
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    TextField(
                      controller: _textController,
                      maxLines: 2,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText:
                            isConverting
                                ? L10n.getTranslatedText(
                                  context,
                                  'Converting ... ',
                                )
                                : (_isRecording
                                    ? '${L10n.getTranslatedText(context, 'Recording')}... ${_seconds}s'
                                    : L10n.getTranslatedText(
                                      context,
                                      'Type a message ...',
                                    )),
                        contentPadding: EdgeInsets.only(
                          left: 20,
                          right: 60,
                          top: 14,
                          bottom: 14,
                        ),
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
                      ),
                    ),
                    Positioned(
                      right: 15,
                      child: GestureDetector(
                        onTap: _toggleRecording,
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: Colors.red[200]!,
                          size: 25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _textController,
                builder: (context, value, child) {
                  final bool isEmpty = value.text.trim().isEmpty;
                  return SizedBox(
                    width: 42,
                    height: 42,
                    child: IconButton(
                      icon: Icon(
                        Icons.send,
                        color: isEmpty ?  Color(0xFFCCE1A0): InnerlyTheme.secondary,
                        size: 25,
                      ),
                      onPressed:
                          isEmpty
                              ? null
                              : () {
                                String message = _textController.text.trim();
                                _sendMessage(message);
                                setState(() {
                                  _textController.clear();
                                });
                              },
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _textStyle(Color color) {
    return TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w600);
  }

  Widget _buildButton(IconData icon, String text, Color color, double width) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return ElevatedButton.icon(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.03,
          vertical: height * 0.01,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      icon: Icon(icon, size: width * 0.05),
      label: SizedBox(
        width: width * 0.25,
        child: AutoSizeText(
          text,
          maxLines: 1,
          minFontSize: 10,
          stepGranularity: 1,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    String fileType,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context);
        _pickFile(fileType);
      },
    );
  }

  Widget _languageTile(
    String language,
    String code,
    BuildContext modalContext,
  ) {
    return ListTile(
      title: Text(language),
      trailing:
          selectedLanguage == code
              ? Icon(Icons.check, color: Colors.blue)
              : null,
      onTap: () {
        setState(() {
          selectedLanguage = code;
        });
        Navigator.pop(modalContext);
      },
    );
  }

  Widget _buildInitialUI() {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Image.asset(
                  'assets/icons/requests.png',
                  width: width * 0.3,
                  height: height * 0.09,
                ),
                SizedBox(height: height * 0.01),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: L10n.getTranslatedText(
                          context,
                          'Hey there! I am ',
                        ),
                        style: _textStyle(Colors.black),
                      ),
                      TextSpan(
                        text: 'Lively',
                        style: _textStyle(Colors.amber[700]!),
                      ),
                      TextSpan(
                        text: L10n.getTranslatedText(
                          context,
                          ' your\npersonal tutor.',
                        ),
                        style: _textStyle(Colors.black),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            SizedBox(height: height * 0.03),
            Wrap(
              spacing: width * 0.03,
              runSpacing: height * 0.01,
              alignment: WrapAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildButton(
                      Icons.help_outline,
                      L10n.getTranslatedText(context, 'Speak with me'),
                      Colors.red[200]!,
                      width,
                    ),
                    SizedBox(width: width * 0.03),
                    _buildButton(
                      Icons.quiz,
                      L10n.getTranslatedText(context, 'Self-care'),
                      Colors.orange.shade200,
                      width,
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildButton(
                      Icons.upload_file,
                      L10n.getTranslatedText(context, 'Journal'),
                      InnerlyTheme.livelyJournal,
                      width,
                    ),
                    SizedBox(width: width * 0.03),
                    _buildButton(
                      Icons.more_horiz,
                      L10n.getTranslatedText(context, 'More'),
                      InnerlyTheme.livelyMore,
                      width,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatUI(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return ListView.builder(
      padding: EdgeInsets.all(10),
      controller: _scrollController,
      itemCount: chatMessages.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> message = chatMessages[index];
        bool isUser = message["role"] == "user";

        return Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.containsKey("media_type") &&
                message["media_type"] != null &&
                message["media_type"] != 'text')
              _buildMediaMessage(message),

            if (message.containsKey("text") && message["isTyping"] != true)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth:
                              isUser
                                  ? MediaQuery.of(context).size.width * 0.60
                                  : MediaQuery.of(context).size.width * 0.80,
                        ),
                        padding: EdgeInsets.all(15),
                        margin: EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          gradient:
                              isUser
                                  ? LinearGradient(
                                    colors: [
                                      Colors.blue[300]!,
                                      Colors.blue[700]!,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                  : null,
                          color: isUser ? null : Colors.grey[300]!,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow:
                              isUser
                                  ? [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(15),
                                      blurRadius: 6,
                                      offset: Offset(2, 4),
                                    ),
                                  ]
                                  : [],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _parseInlineBoldText(message["text"], isUser),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            if (!isUser && message["isTyping"] != true)
              if (!isUser && message["isTyping"] != true)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.flag, color: Colors.grey[600], size: 18),
                      onPressed: () {
                        _showReportDialog(context, message);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.content_copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: message["text"]));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              L10n.getTranslatedText(
                                context,
                                'Copied to clipboard',
                              ),
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
            if (message["isTyping"] == true) TypingIndicator(),
          ],
        );
      },
    );
  }

  Widget _buildMediaMessage(Map<String, dynamic> message) {
    // Add null checks for storage_path
    final storagePath = message['storage_path'];
    if (storagePath == null) return SizedBox.shrink();

    final url = ChatbotStorage.getPublicUrl(storagePath);
    final mediaType = message['media_type'] ?? 'unknown';

    switch (mediaType) {
      case 'image':
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenImage(imagePath: url),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              url,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.broken_image),
            ),
          ),
        );
      case 'video':
        return GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenVideo(videoPath: url),
                ),
              ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 250,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black12,
                ),
              ),
              Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
            ],
          ),
        );
      case 'audio':
        return Container(
          width: MediaQuery.of(context).size.width * 0.75,
          margin: EdgeInsets.symmetric(vertical: 5),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: AudioPlayerWidget(audioPath: url),
        );
      case 'document':
        return GestureDetector(
          onTap: () => OpenFile.open(message["fileInfo"]),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.55,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.insert_drive_file, color: Colors.blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    L10n.getTranslatedText(context, 'Open Document'),
                    style: TextStyle(color: Colors.blue),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return SizedBox.shrink();
    }
  }

  void _showReportDialog(BuildContext context, Map<String, dynamic> message) {
    TextEditingController reportController = TextEditingController();
    bool isButtonEnabled = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(L10n.getTranslatedText(context, 'Report Message')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    L10n.getTranslatedText(
                      context,
                      'Please describe the issue:',
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: reportController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText:
                          "${L10n.getTranslatedText(context, 'Enter your reason for reporting')}...",
                    ),
                    onChanged: (text) {
                      setState(() {
                        isButtonEnabled = text.trim().isNotEmpty;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(L10n.getTranslatedText(context, 'Cancel')),
                ),
                TextButton(
                  onPressed:
                      isButtonEnabled
                          ? () {
                            _submitReport(message, reportController.text);
                            Navigator.pop(context);
                          }
                          : null,
                  child: Text(L10n.getTranslatedText(context, 'Send')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitReport(Map<String, dynamic> message, String reportReason) {
    print("Reported message: ${message["text"]} | Reason: $reportReason");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(L10n.getTranslatedText(context, 'Report submitted.')),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget newChatIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: InnerlyTheme.beige,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.chat_bubble_outline, size: 26, color: InnerlyTheme.secondary),
        ),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 19,
            height: 19,
            decoration: BoxDecoration(
              color: InnerlyTheme.beige,
              shape: BoxShape.circle,
              border: Border.all(color: InnerlyTheme.secondary, width: 2),
            ),
            child: Center(
              child: Icon(Icons.add, size: 12, color: InnerlyTheme.secondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _parseInlineBoldText(String text, bool isUser) {
    List<InlineSpan> spans = [];
    List<String> parts = text.split(RegExp(r'(\*\*|\*)'));

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 1) {
        spans.add(
          TextSpan(
            text: parts[i],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isUser ? Colors.white : Colors.black87,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: parts[i],
            style: TextStyle(
              fontSize: 16,
              color: isUser ? Colors.white : Colors.black87,
            ),
          ),
        );
      }
    }

    return RichText(text: TextSpan(children: spans));
  }
}

class ChatbotStorage {
  static final _supabase = Supabase.instance.client;

  static Future<String> uploadMedia({
    required File file,
    required String mediaType,
    required String userId,
    required String chatId,
  }) async {
    final ext = file.path.split('.').last;
    final path =
        '$userId/$chatId/${mediaType.toLowerCase()}/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _supabase.storage.from('chatbot').upload(path, file);

    return path;
  }

  static String getPublicUrl(String path) {
    return _supabase.storage.from('chatbot').getPublicUrl(path);
  }
}
