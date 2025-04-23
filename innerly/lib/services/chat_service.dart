import 'dart:async';
import 'package:flutter/foundation.dart';

class ChatMessage {
  final String text;
  final DateTime timestamp;
  final String senderId;

  ChatMessage({
    required this.text,
    required this.timestamp,
    required this.senderId,
  });
}

class ChatService with ChangeNotifier {
  final StreamController<List<ChatMessage>> _messagesController =
  StreamController<List<ChatMessage>>.broadcast();
  List<ChatMessage> _messages = [];

  Stream<List<ChatMessage>> get messagesStream => _messagesController.stream;

  void loadChatHistory(String therapistId) {
    // Implement your chat history loading logic
    // This is a mock implementation
    _messages = [
      ChatMessage(
        text: 'Welcome to the chat!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        senderId: 'therapist',
      ),
    ];
    _messagesController.add(_messages);
  }

  void sendMessage({required String therapistId, required String message}) {
    final newMessage = ChatMessage(
      text: message,
      timestamp: DateTime.now(),
      senderId: 'current_user_id', // Replace with actual user ID
    );
    _messages.insert(0, newMessage);
    _messagesController.add(_messages);
    // Here you would typically send the message to your backend
  }

  @override
  void dispose() {
    _messagesController.close();
    super.dispose();
  }
}