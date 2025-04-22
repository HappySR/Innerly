import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get realtime stream of messages for a specific chat room
  Stream<List<Map<String, dynamic>>> getMessages(String roomId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('sent_at', ascending: true);
  }

  // Send a new message to a chat room
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String content,
  }) async {
    try {
      await _supabase.from('messages').insert({
        'room_id': roomId,
        'sender_id': senderId,
        'content': content,
      });
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String roomId, String currentUserId) async {
    try {
      await _supabase
          .from('messages')
          .update({'read': true})
          .eq('room_id', roomId)
          .neq('sender_id', currentUserId)
          .eq('read', false);
    } catch (e) {
      throw Exception('Failed to mark messages as read: ${e.toString()}');
    }
  }

  // Get the last message from each chat room for a user
  Future<List<Map<String, dynamic>>> getChatRoomsSummary(String userId) async {
    try {
      final response = await _supabase.rpc('get_chat_rooms_summary', params: {
        'user_id': userId,
      });

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      throw Exception('Failed to get chat rooms summary: ${e.toString()}');
    }
  }

  // Create a new chat room between two users
  Future<String> createChatRoom(String user1Id, String user2Id) async {
    try {
      // Create consistent room ID by sorting user IDs alphabetically
      final participants = [user1Id, user2Id]..sort();
      final roomId = participants.join('_');

      // Check if room already exists
      final existingRoom = await _supabase
          .from('messages')
          .select()
          .eq('room_id', roomId)
          .limit(1);

      if (existingRoom.isEmpty) {
        // Optionally store room metadata in a separate table if needed
        await _supabase.from('chat_rooms').insert({
          'room_id': roomId,
          'participants': participants,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return roomId;
    } catch (e) {
      throw Exception('Failed to create chat room: ${e.toString()}');
    }
  }
}