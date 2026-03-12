import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/chat/chat_service.dart';
import '../domain/entities/chat_entities.dart';

class ForwardMessageScreen extends StatefulWidget {
  final Map<String, dynamic> message;

  const ForwardMessageScreen({super.key, required this.message});

  @override
  State<ForwardMessageScreen> createState() => _ForwardMessageScreenState();
}

class _ForwardMessageScreenState extends State<ForwardMessageScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _forwardTo(ChatSummary chat) async {
    final chatService = context.read<ChatService>();
    final authService = context.read<AuthService>();
    final currentUid = authService.firebaseUser?.uid ?? '';
    final currentName = authService.profile?.name ?? authService.firebaseUser?.displayName ?? 'User';
    final currentEmail = authService.firebaseUser?.email ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forward Message'),
        content: Text('Forward this message to ${chat.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Forward'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await chatService.forwardMessage(
          targetChatId: chat.id,
          senderId: currentUid,
          senderName: currentName,
          senderEmail: currentEmail,
          originalMessage: widget.message,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Message forwarded to ${chat.name}')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final chatService = context.watch<ChatService>();
    final uid = authService.firebaseUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forward to...'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchCtrl.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: chatService.getChatsStream(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final chats = snapshot.data ?? [];
                final filteredChats = chats.where((c) {
                  final participants = Map<String, dynamic>.from(c['participantNames'] ?? {});
                  final names = participants.values.join(' ').toLowerCase();
                  return names.contains(_searchQuery);
                }).toList();

                if (filteredChats.isEmpty) {
                  return const Center(child: Text('No chats found.'));
                }

                return ListView.builder(
                  itemCount: filteredChats.length,
                  itemBuilder: (context, index) {
                    final data = filteredChats[index];
                    final chatId = data['id'];
                    final participants = Map<String, dynamic>.from(data['participantNames'] ?? {});
                    participants.remove(uid);
                    
                    String displayName = participants.values.isNotEmpty 
                        ? participants.values.first.toString() 
                        : 'Unknown';

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?'),
                      ),
                      title: Text(displayName),
                      onTap: () => _forwardTo(ChatSummary(
                        id: chatId,
                        name: displayName,
                        lastMessagePreview: '',
                        timestamp: '',
                        isPinned: false,
                        status: ChatStatus.online,
                        avatarUrl: '',
                        isTyping: false,
                        unreadCount: 0,
                      )),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
