import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService with ChangeNotifier {
  late SupabaseClient _supabase;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  Timer? _pollingTimer;
  bool _isDisposed = false;

  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  void initialize() {
    _supabase = Supabase.instance.client;
    debugPrint('ChatService initialized');
  }

  Future<void> sendMessage({
    required String receiverId,
    required String message,
    required String senderType,
    String? fileUrl,
    String? fileType,
  }) async {
    try {
      _isLoading = true;
      if (!_isDisposed) notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('private_messages').insert({
        'sender_id': userId,
        'receiver_id': receiverId,
        'message': message,
        'sender_type': senderType,
        'file_url': fileUrl,
        'file_type': fileType,
      });
    } catch (e) {
      debugPrint('Message sending failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Stream<List<Map<String, dynamic>>> getMessagesStream(String receiverId) {
    final controller = StreamController<List<Map<String, dynamic>>>();
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      controller.addError('User not authenticated');
      return controller.stream;
    }

    Future<void> fetchMessages() async {
      try {
        final response = await _supabase
            .from('private_messages')
            .select()
            .or('and(sender_id.eq.${userId},receiver_id.eq.${receiverId}),and(sender_id.eq.${receiverId},receiver_id.eq.${userId})')
            .order('created_at', ascending: true);

        if (!controller.isClosed) {
          controller.add(List<Map<String, dynamic>>.from(response));
          debugPrint('Fetched ${response.length} messages');
        }
      } catch (e) {
        debugPrint('Message fetch error: $e');
        if (!controller.isClosed) controller.add([]);
      }
    }

    // Initial fetch
    fetchMessages();

    // Set up polling
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) => fetchMessages());

    // Clean up
    controller.onCancel = () {
      _pollingTimer?.cancel();
      if (!controller.isClosed) controller.close();
    };

    return controller.stream;
  }

  // In chat_service.dart
  Future<void> loadInitialMessages(String receiverId) async {
    if (_isDisposed) return;

    try {
      _isLoading = true;
      if (!_isDisposed) notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('private_messages')
          .select()
          .or('and(sender_id.eq.${userId},receiver_id.eq.${receiverId}),and(sender_id.eq.${receiverId},receiver_id.eq.${userId})')
          .order('created_at', ascending: true);

      _messages = List<Map<String, dynamic>>.from(response);
      debugPrint('Loaded ${_messages.length} initial messages');
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      debugPrint('Load messages error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<String?> uploadFile(File file) async {
    try {
      _isLoading = true;
      if (!_isDisposed) notifyListeners();

      final fileName = 'chat_files/${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final fileBytes = await file.readAsBytes();

      await _supabase.storage
          .from('private-chat-files')
          .uploadBinary(fileName, fileBytes);

      return _supabase.storage
          .from('private-chat-files')
          .getPublicUrl(fileName);
    } catch (e) {
      debugPrint('File upload failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<Uint8List?> downloadFile(String fileUrl) async {
    try {
      _isLoading = true;
      if (!_isDisposed) notifyListeners();

      final uri = Uri.parse(fileUrl);
      final filePath = uri.pathSegments.lastWhere(
            (segment) => segment.isNotEmpty,
        orElse: () => '',
      );

      return await _supabase.storage
          .from('private-chat-files')
          .download(filePath);
    } catch (e) {
      debugPrint('File download failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _messagesSubscription?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }
}