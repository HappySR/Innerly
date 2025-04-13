import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _storage = Supabase.instance.client.storage;
  final _uuid = Uuid();
  late final RealtimeChannel _channel;
  final StreamController<List<Map<String, dynamic>>> _controller =
  StreamController.broadcast();
  bool _isSubscribed = false;
  bool _isDisposed = false;

  ChatService() {
    _channel = _supabase.channel('global_chat').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'global_chat',
      callback: _handleRealtimeUpdate,
    );
  }

  Future<void> _handleRealtimeUpdate(PostgresChangePayload payload) async {
    if (_isDisposed) return;
    final updatedMessages = await _fetchMessages();
    if (!_controller.isClosed) {
      _controller.add(updatedMessages);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMessages() async {
    final response = await _supabase
        .from('global_chat')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    return response.where((m) => m['deleted'] == false).toList();
  }

  Stream<List<Map<String, dynamic>>> getGlobalChatStream() async* {
    if (_isDisposed) {
      throw Exception('ChatService has been disposed');
    }

    // Yield initial data
    yield await _fetchMessages();

    // Subscribe only once
    if (!_isSubscribed) {
      _isSubscribed = true;
      _channel.subscribe((status, [_]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _fetchMessages().then((messages) {
            if (!_controller.isClosed) {
              _controller.add(messages);
            }
          });
        }
      });
    }

    yield* _controller.stream;
  }

  Future<void> unsubscribe() async {
    if (!_isDisposed) {
      _isDisposed = true;
      if (_isSubscribed) {
        await _channel.unsubscribe();
        _isSubscribed = false;
      }
      if (!_controller.isClosed) {
        await _controller.close();
      }
    }
  }

  Future<String> uploadFile(File file) async {
    try {
      final fileExtension = file.path.split('.').last;
      final fileName = '${_uuid.v4()}.$fileExtension';

      await _storage.from('chat-media').upload(fileName, file);
      return _storage.from('chat-media').getPublicUrl(fileName);
    } on StorageException catch (e) {
      throw Exception('Upload failed: ${e.message}');
    } catch (e) {
      throw Exception('File upload error: $e');
    }
  }

  Future<void> sendMessage(String message,
      {String? fileUrl, String? fileType}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final messageData = {
        'user_id': user.id,
        'message': message,
        'display_name': 'Anonymous${user.id.substring(0, 4)}',
        'deleted': false,
        if (fileUrl != null) 'file_url': fileUrl,
        if (fileType != null) 'file_type': fileType,
      };

      await _supabase.from('global_chat').insert(messageData);
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    final response = await _supabase
        .from('global_chat')
        .update({'deleted': true})
        .eq('id', messageId);

    if (response.error != null) {
      throw Exception(response.error!.message);
    }
  }

  Future<String> downloadFile(String fileUrl) async {
    try {
      final fileName = fileUrl.split('/').last;
      final Uint8List bytes =
      await _storage.from('chat-media').download(fileName);

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final File localFile = File('${appDocDir.path}/$fileName');
      await localFile.writeAsBytes(bytes);

      return localFile.path;
    } on StorageException catch (e) {
      throw Exception('Download failed: ${e.message}');
    } catch (e) {
      throw Exception('File download error: $e');
    }
  }
}