import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/chat_service.dart' as PrivateChat; // Add alias
import '../../services/global_chat_service.dart' as GlobalChat; // Add alias

class ChatScreen extends StatefulWidget {
  final String therapistName;
  final String therapistId;

  const ChatScreen({
    super.key,
    required this.therapistName,
    required this.therapistId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PrivateChat.ChatService>(context, listen: false) // Use alias
          .loadChatHistory(widget.therapistId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<PrivateChat.ChatService>(context); // Use alias

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.therapistName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<PrivateChat.ChatMessage>>( // Use alias
              stream: chatService.messagesStream,
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ChatBubble(
                      message: message,
                      isMe: message.senderId == 'current_user_id',
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final chatService = Provider.of<PrivateChat.ChatService>(context, listen: false); // Use alias
    chatService.sendMessage(
      therapistId: widget.therapistId,
      message: _messageController.text,
    );

    _messageController.clear();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}

class ChatBubble extends StatelessWidget {
  final PrivateChat.ChatMessage message; // Use alias
  final bool isMe;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}