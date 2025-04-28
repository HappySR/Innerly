import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService with ChangeNotifier {
  late SupabaseClient _supabase;
  RealtimeChannel? _messagesChannel;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isDisposed = false;

  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  ChatService() {
    initialize();
  }

  void initialize() {
    _supabase = Supabase.instance.client;
    debugPrint('ChatService initialized');
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    _messagesChannel = _supabase
        .channel('private_messages')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'private_messages',
      callback: (payload) => _handleNewMessage(payload.newRecord as Map<String, dynamic>),
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'private_messages',
      callback: (payload) => _handleUpdatedMessage(payload.newRecord as Map<String, dynamic>),
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'private_messages',
      callback: (payload) => _handleDeletedMessage(payload.oldRecord as Map<String, dynamic>),
    )
        .subscribe((status, [error]) {
      if (status == 'SUBSCRIBED') {
        debugPrint('Realtime subscription established');
      }
      if (error != null) {
        debugPrint('Realtime error: $error');
      }
    });
  }

  Future<void> _handleNewMessage(Map<String, dynamic> message) async {
    if (_isDisposed) return;

    // Generate signed URL if needed
    if (message['file_url'] != null) {
      final signedUrl = await getSignedUrl(message['file_url']);
      message['file_url'] = signedUrl;
    }

    // Insert message in correct position based on timestamp
    final newMessages = [..._messages, message]
      ..sort((a, b) => DateTime.parse(a['created_at'])
          .compareTo(DateTime.parse(b['created_at'])));

    _messages = newMessages;
    notifyListeners();
  }

  void _handleUpdatedMessage(Map<String, dynamic> updatedMessage) {
    if (_isDisposed) return;

    final index = _messages.indexWhere((m) => m['id'] == updatedMessage['id']);
    if (index != -1) {
      _messages[index] = updatedMessage;
      notifyListeners();
    }
  }

  void _handleDeletedMessage(Map<String, dynamic> deletedMessage) {
    if (_isDisposed) return;

    _messages.removeWhere((m) => m['id'] == deletedMessage['id']);
    notifyListeners();
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
      notifyListeners();

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
      notifyListeners();
    }
  }

  Future<String?> getSignedUrl(String path) async {
    try {
      final response = await _supabase.storage
          .from('private-chat-files')
          .createSignedUrl(path, 60 * 60); // 1 hour expiration

      return response;
    } catch (e) {
      debugPrint('Signed URL error: $e');
      return null;
    }
  }

  Future<void> loadInitialMessages(String receiverId) async {
    if (_isDisposed) return;

    try {
      _isLoading = true;

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('private_messages')
          .select()
          .or('and(sender_id.eq.$userId,receiver_id.eq.$receiverId),and(sender_id.eq.$receiverId,receiver_id.eq.$userId)')
          .order('created_at', ascending: true);

      final List<Map<String, dynamic>> messagesWithUrls = [];
      for (var message in List<Map<String, dynamic>>.from(response)) {
        if (message['file_url'] != null) {
          final signedUrl = await getSignedUrl(message['file_url']);
          messagesWithUrls.add({...message, 'file_url': signedUrl});
        } else {
          messagesWithUrls.add(message);
        }
      }

      _messages = messagesWithUrls;
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      debugPrint('Load messages error: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<String?> uploadFile(File file) async {
    try {
      _isLoading = true;
      notifyListeners();

      final fileName = 'chat_files/${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final fileBytes = await file.readAsBytes();

      await _supabase.storage
          .from('private-chat-files')
          .uploadBinary(fileName, fileBytes);

      return fileName;
    } catch (e) {
      debugPrint('File upload failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Uint8List?> downloadFile(String filePath) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase.storage
          .from('private-chat-files')
          .download(filePath);

      return response;
    } catch (e) {
      debugPrint('File download failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _messagesChannel?.unsubscribe();
    super.dispose();
  }
}