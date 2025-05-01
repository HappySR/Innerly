class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final String? userId;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    this.userId,
  });

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'],
      title: map['title'],
      createdAt: DateTime.parse(map['created_at']),
      userId: map['user_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
    };
  }
}