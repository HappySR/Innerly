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
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (chatHistory.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  L10n.getTranslatedText(context, 'No chat history'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: chatHistory.length,
                itemBuilder: (context, index) {
                  final chat = chatHistory[index];
                  return _ChatListItem(
                    chat: chat,
                    onSelect: () => onSelectChat(chat),
                    onDelete: () => _confirmDelete(context, chat),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ChatSession chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.getTranslatedText(context, 'Delete chat?')),
        content: Text(
          L10n.getTranslatedText(context, 'This action cannot be undone'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(L10n.getTranslatedText(context, 'Cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDeleteChat(chat);
            },
            child: Text(
              L10n.getTranslatedText(context, 'Delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final ChatSession chat;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  const _ChatListItem({
    required this.chat,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        (chat.title?.isNotEmpty ?? false)
            ? chat.title
            : L10n.getTranslatedText(context, 'Untitled chat'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _formatDate(chat.createdAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: onSelect,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 20),
        onPressed: onDelete,
        tooltip: L10n.getTranslatedText(context, 'Delete chat'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    try {
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}