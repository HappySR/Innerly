import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  Stream<List<Map<String, dynamic>>> get messagesStream => getMessageStream(
      receiverId: _messages.isNotEmpty ?
      _messages.first['sender_id'] == _supabase.auth.currentUser?.id ?
      _messages.first['receiver_id'] :
      _messages.first['sender_id']
          : ''
  );

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

      final messageData = {
        'sender_id': _supabase.auth.currentUser!.id,
        'receiver_id': receiverId,
        'message': message,
        'sender_type': senderType,
        'file_url': fileUrl,
        'file_type': fileType,
      };

      final response = await _supabase
          .from('private_messages')
          .insert(messageData)
          .select('id'); // Explicitly select the ID

      if (response.isEmpty) {
        throw Exception('Failed to send message: empty response');
      }
    } catch (e) {
      throw Exception('Message sending failed: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Replace the messagesStream getter with:
  Stream<List<Map<String, dynamic>>> getMessagesStream(String receiverId) {
    return getMessageStream(receiverId: receiverId);
  }

// Update getMessageStream to:
  Stream<List<Map<String, dynamic>>> getMessageStream({
    required String receiverId,
  }) {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null || receiverId.isEmpty) {
      return const Stream.empty();
    }

    return _supabase
        .from('private_messages')
        .select()
        .or('and(sender_id.eq.$userId,receiver_id.eq.$receiverId),and(sender_id.eq.$receiverId,receiver_id.eq.$userId)')
        .order('created_at', ascending: false)
        .asStream()
        .handleError((error) {
      debugPrint('Message stream error: $error');
      throw Exception('Message stream error: $error');
    });
  }

  Future<String?> uploadFile(File file) async {
    try {
      _isLoading = true;
      notifyListeners();

      final fileName = 'chat_files/${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';

      // Read file as bytes - no need for casting
      final fileBytes = await file.readAsBytes();

      final uploadResponse = await _supabase.storage
          .from('private-chat-files')
          .upload(fileName, fileBytes as File); // Remove the 'as File' cast

      return _supabase.storage
          .from('private-chat-files')
          .getPublicUrl(fileName);
    } catch (e) {
      throw Exception('File upload failed: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Uint8List?> downloadFile(String fileUrl) async {
    try {
      _isLoading = true;
      notifyListeners();

      final fileName = fileUrl.split('/').last;
      // Corrected download call
      final data = await _supabase.storage
          .from('private-chat-files')
          .download(fileName);

      return data;
    } on StorageException catch (e) {
      throw Exception('File download failed: ${e.message}');
    } catch (e) {
      throw Exception('File download failed: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadInitialMessages(String receiverId) async {
    if (receiverId.isEmpty) {
      throw Exception('Invalid receiver ID');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('private_messages')
          .select()
          .or('and(sender_id.eq.$userId,receiver_id.eq.$receiverId),and(sender_id.eq.$receiverId,receiver_id.eq.$userId)')
          .order('created_at', ascending: false)
          .limit(50);

      _messages = List<Map<String, dynamic>>.from(response).reversed.toList();
    } catch (e) {
      debugPrint('Message load error: $e');
      throw Exception('Message load failed: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void subscribeToMessages(String receiverId) {
    _messagesSubscription?.cancel();
    _messagesSubscription = getMessageStream(receiverId: receiverId).listen(
          (messages) {
        _messages = messages.reversed.toList();
        notifyListeners();
      },
      onError: (error) {
        throw Exception('Message stream error: $error');
      },
    );
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase
          .from('private_messages')
          .delete()
          .eq('id', messageId)
          .eq('sender_id', _supabase.auth.currentUser!.id);

      if (response.error != null) {
        throw Exception(response.error!.message);
      }
    } catch (e) {
      throw Exception('Message deletion failed: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('conversations')
          .select('''
            id, 
            created_at, 
            last_message, 
            participants:conversation_participants!inner(
              user:profiles(id, name, avatar_url)
            )
          ''')
          .contains('participants.user_id', [userId]);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Conversations load failed: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }
}