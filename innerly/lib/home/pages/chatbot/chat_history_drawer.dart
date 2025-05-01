import 'package:Innerly/home/pages/chatbot/models/chat_session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../localization/i10n.dart';

class ChatHistoryDrawer extends StatelessWidget {
  final List<ChatSession> chatHistory;
  final bool isLoading;
  final Function(ChatSession) onSelectChat;
  final Function(ChatSession) onDeleteChat;

  const ChatHistoryDrawer({
    super.key,
    required this.chatHistory,
    required this.isLoading,
    required this.onSelectChat,
    required this.onDeleteChat,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          AppBar(
            title: Text(L10n.getTranslatedText(context, 'Chat History')),
            automaticallyImplyLeading: false,
          ),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: ListView.builder(
                itemCount: chatHistory.length,
                itemBuilder: (context, index) {
                  final chat = chatHistory[index];
                  return ListTile(
                    title: Text(chat.title),
                    subtitle: Text(
                      '${chat.createdAt.day}/${chat.createdAt.month}/${chat.createdAt.year}',
                    ),
                    onTap: () => onSelectChat(chat),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => onDeleteChat(chat),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}