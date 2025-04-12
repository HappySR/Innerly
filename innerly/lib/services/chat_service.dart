import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _storage = Supabase.instance.client.storage;
  final _uuid = Uuid();

  Stream<List<Map<String, dynamic>>> getGlobalChatStream() {
    return _supabase
        .from('global_chat')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50)
        .map((messages) => messages.where((m) => m['deleted'] == false).toList());
  }

  Future<String> uploadFile(File file) async {
    try {
      final fileExtension = file.path.split('.').last;
      final fileName = '${_uuid.v4()}.$fileExtension';

      await _storage
          .from('chat-media')
          .upload(fileName, file);

      return _storage
          .from('chat-media')
          .getPublicUrl(fileName);
    } on StorageException catch (e) {
      throw Exception('Upload failed: ${e.message}');
    } catch (e) {
      throw Exception('File upload error: $e');
    }
  }

  Future<void> sendMessage(String message, {String? fileUrl, String? fileType}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final messageData = {
        'user_id': user.id,
        'message': message,
        'display_name': 'Anonymous${user.id.substring(0, 4)}',
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
      final Uint8List bytes = await _storage
          .from('chat-media')
          .download(fileName);

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