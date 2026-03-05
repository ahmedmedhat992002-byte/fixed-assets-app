import '../domain/entities/chat_entities.dart';

class MockChatRepository {
  const MockChatRepository();

  List<ChatSummary> fetchPinnedChats() {
    return const [
      ChatSummary(
        id: '1',
        name: 'David Nelson',
        lastMessagePreview: 'Typing',
        timestamp: '4:30 PM',
        isPinned: true,
        status: ChatStatus.online,
        avatarUrl: '',
        isTyping: true,
        unreadCount: 0,
      ),
      ChatSummary(
        id: '2',
        name: 'Ahmed Medi',
        lastMessagePreview: 'Sounds great!',
        timestamp: '11:36 AM',
        isPinned: true,
        status: ChatStatus.away,
        avatarUrl: '',
        isTyping: false,
        unreadCount: 2,
      ),
    ];
  }

  List<ChatSummary> fetchRecentChats() {
    return const [
      ChatSummary(
        id: '3',
        name: 'Rajesh Madiba',
        lastMessagePreview: 'I wanted to inquire about t...',
        timestamp: 'Yesterday',
        isPinned: false,
        status: ChatStatus.offline,
        avatarUrl: '',
        isTyping: false,
        unreadCount: 1,
      ),
      ChatSummary(
        id: '4',
        name: 'William Ruto',
        lastMessagePreview: 'Thank you so much for de...',
        timestamp: '10/02/2023',
        isPinned: false,
        status: ChatStatus.offline,
        avatarUrl: '',
        isTyping: false,
        unreadCount: 0,
      ),
    ];
  }

  List<ChatMessage> fetchMessages(String chatId) {
    return const [
      ChatMessage(
        id: 'm1',
        sender: 'David Nelson',
        message:
            'I had a question about the project. What is our spending limit for purchasing software and hiring developers',
        time: '3:30 PM',
        isMine: false,
      ),
      ChatMessage(
        id: 'm2',
        sender: 'Me',
        message: 'Hello David',
        time: '3:30 PM',
        isMine: true,
      ),
      ChatMessage(
        id: 'm3',
        sender: 'David Nelson',
        message: 'I had a question about the project. What is...',
        time: '3:30 PM',
        isMine: true,
      ),
      ChatMessage(
        id: 'm4',
        sender: 'Me',
        message: 'Yeah sure!',
        time: '3:55 PM',
        isMine: true,
      ),
    ];
  }
}
