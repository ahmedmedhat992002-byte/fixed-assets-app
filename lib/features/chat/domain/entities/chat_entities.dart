class ChatSummary {
  const ChatSummary({
    required this.id,
    required this.name,
    required this.lastMessagePreview,
    required this.timestamp,
    required this.isPinned,
    required this.status,
    required this.avatarUrl,
    required this.isTyping,
    required this.unreadCount,
  });

  final String id;
  final String name;
  final String lastMessagePreview;
  final String timestamp;
  final bool isPinned;
  final ChatStatus status;
  final String avatarUrl;
  final bool isTyping;
  final int unreadCount;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.time,
    required this.isMine,
  });

  final String id;
  final String sender;
  final String message;
  final String time;
  final bool isMine;
}

enum ChatStatus { online, offline, away }
