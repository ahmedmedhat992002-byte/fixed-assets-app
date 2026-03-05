import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/chat/chat_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/profile/profile_service.dart';
import '../../../core/profile/models/profile_model.dart';
import '../domain/entities/chat_entities.dart';
import 'widgets/profile_preview_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({
    super.key,
    this.onTapChat,
    this.onOpenDrawer,
    this.isDrawerVisible = false,
  });

  final void Function(ChatSummary summary)? onTapChat;
  final VoidCallback? onOpenDrawer;
  final bool isDrawerVisible;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // chatId → custom nickname (local-only)
  Map<String, String> _nicknames = {};

  @override
  void initState() {
    super.initState();
    _loadNicknames();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Nicknames ─────────────────────────────────────────────────────────────

  Future<void> _loadNicknames() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('chat_nickname_'));
    final map = <String, String>{};
    for (final k in keys) {
      final chatId = k.replaceFirst('chat_nickname_', '');
      map[chatId] = prefs.getString(k) ?? '';
    }
    if (mounted) setState(() => _nicknames = map);
  }

  Future<void> _saveNickname(String chatId, String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    if (nickname.isEmpty) {
      await prefs.remove('chat_nickname_$chatId');
    } else {
      await prefs.setString('chat_nickname_$chatId', nickname);
    }
    setState(() {
      if (nickname.isEmpty) {
        _nicknames.remove(chatId);
      } else {
        _nicknames[chatId] = nickname;
      }
    });
  }

  void _showRenameDialog(
    BuildContext context,
    String chatId,
    String originalName,
  ) {
    final ctrl = TextEditingController(text: _nicknames[chatId] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set a custom name for "$originalName" that only you can see.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nickname',
                hintText: originalName,
                prefixIcon: const Icon(Icons.edit_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Remove nickname',
                  onPressed: () => ctrl.clear(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final nick = ctrl.text.trim();
              _saveNickname(chatId, nick);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChatExtras({
    required BuildContext context,
    required ChatSummary summary,
    required String otherUid,
    required String originalName,
    required ProfileModel? profile,
  }) {
    final theme = Theme.of(context);
    final chatService = context.read<ChatService>();
    final authService = context.read<AuthService>();
    final currentUid = authService.firebaseUser?.uid ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              summary.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Show User Data'),
              onTap: () {
                Navigator.pop(ctx);
                if (profile != null) {
                  showDialog(
                    context: context,
                    builder: (_) => ProfilePreviewDialog(
                      profile: profile,
                      onChatTap: () {},
                      onCallTap: () {},
                      onVideoCallTap: () {},
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Name'),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(context, summary.id, originalName);
              },
            ),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final List<String> blockedUsers = List<String>.from(
                  data?['blockedUsers'] ?? [],
                );
                final isBlocked = blockedUsers.contains(otherUid);

                return ListTile(
                  leading: Icon(
                    isBlocked
                        ? Icons.check_circle_outline_rounded
                        : Icons.block_flipped,
                    color: isBlocked ? AppColors.success : AppColors.danger,
                  ),
                  title: Text(
                    isBlocked ? 'Unblock User' : 'Block User',
                    style: TextStyle(
                      color: isBlocked ? AppColors.success : AppColors.danger,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await chatService.toggleBlockUser(currentUid, otherUid);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isBlocked
                                  ? 'User unblocked successfully'
                                  : 'User blocked successfully',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
              ),
              title: const Text(
                'Delete Chat',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Chat'),
                    content: const Text(
                      'Are you sure you want to clear this conversation? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  try {
                    await chatService.clearChat(summary.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chat cleared successfully'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── New chat dialog ────────────────────────────────────────────────────────

  void _showNewChatDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('New Message'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the email address of the person you want to chat with.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'example@email.com',
                ),
              ),
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: const SizedBox.shrink(),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      if (email.isEmpty) return;

                      setModalState(() => loading = true);

                      final chatService = context.read<ChatService>();
                      final authService = context.read<AuthService>();

                      try {
                        final otherUser = await chatService.findUserByEmail(
                          email,
                        );
                        if (otherUser == null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'User not found. Ensure they are registered.',
                                ),
                              ),
                            );
                          }
                          setModalState(() => loading = false);
                          return;
                        }

                        final currentUid = authService.firebaseUser?.uid ?? '';
                        final currentEmail =
                            authService.firebaseUser?.email ?? '';
                        final currentName =
                            authService.profile?.name ??
                            authService.firebaseUser?.displayName ??
                            currentEmail.split('@')[0];

                        final otherUid = otherUser['uid'] as String;
                        final otherEmail = otherUser['email'] as String? ?? '';
                        final otherName =
                            otherUser['name'] as String? ??
                            otherUser['firstName'] ??
                            otherEmail.split('@')[0];

                        if (currentUid == otherUid) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('You cannot chat with yourself.'),
                              ),
                            );
                          }
                          setModalState(() => loading = false);
                          return;
                        }

                        final chatId = await chatService.getOrCreateChat(
                          currentUid,
                          currentName,
                          currentEmail,
                          otherUid,
                          otherName,
                          otherEmail,
                        );

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          widget.onTapChat?.call(
                            ChatSummary(
                              id: chatId,
                              name: otherName,
                              lastMessagePreview: '',
                              timestamp: 'Just now',
                              isPinned: false,
                              status: ChatStatus.online,
                              avatarUrl: '',
                              isTyping: false,
                              unreadCount: 0,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                        setModalState(() => loading = false);
                      }
                    },
              child: const Text('Start Chat'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final chatService = context.watch<ChatService>();
    final uid = authService.firebaseUser?.uid ?? '';

    if (uid.isEmpty) {
      return const Scaffold(body: Center(child: Text('Please login to chat.')));
    }

    return Scaffold(
      appBar: AppBar(
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu, color: AppColors.primary),
                onPressed: widget.onOpenDrawer,
              )
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_comment_outlined,
              color: AppColors.primary,
            ),
            onPressed: () => _showNewChatDialog(context),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/profile'),
              child: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.person, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: chatService.getChatsStream(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }

          final chats = snapshot.data ?? [];
          final filteredChats = chats.where((c) {
            final names =
                (c['participantNames'] as Map<dynamic, dynamic>?)?.values
                    .join(' ')
                    .toLowerCase() ??
                '';
            // Also search by nickname
            final chatId = c['id']?.toString() ?? '';
            final nick = _nicknames[chatId]?.toLowerCase() ?? '';
            return names.contains(_searchQuery) || nick.contains(_searchQuery);
          }).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              const SizedBox(height: 8),
              TextField(
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
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
              ),
              const SizedBox(height: 24),
              if (filteredChats.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No messages yet. Start a conversation!'),
                  ),
                )
              else
                ...filteredChats.map((data) {
                  final participantNamesMap = data['participantNames'];
                  if (participantNamesMap == null ||
                      participantNamesMap is! Map) {
                    return const SizedBox.shrink();
                  }

                  final participants = Map<String, dynamic>.from(
                    participantNamesMap,
                  );
                  participants.remove(uid);

                  final emailsMap = data['participantEmails'] as Map?;
                  String? otherEmail;
                  if (emailsMap != null) {
                    final emails = Map<String, dynamic>.from(emailsMap);
                    emails.remove(uid);
                    otherEmail = emails.values.first?.toString();
                  }

                  final profileName =
                      participants.values.first?.toString() ?? '';
                  String originalName = profileName;

                  if ((originalName.isEmpty ||
                          originalName.toLowerCase() == 'user') &&
                      otherEmail != null) {
                    final emailPrefix = otherEmail.split('@')[0];
                    originalName =
                        emailPrefix[0].toUpperCase() + emailPrefix.substring(1);
                  }

                  if (originalName.isEmpty ||
                      originalName.toLowerCase() == 'user') {
                    originalName = '';
                  }

                  final chatId = data['id']?.toString() ?? '';

                  // Use nickname if set, otherwise show original
                  final displayName = _nicknames[chatId]?.isNotEmpty == true
                      ? _nicknames[chatId]!
                      : originalName;

                  final lastMsg = data['lastMessage']?.toString() ?? '';
                  final lastTimestamp = data['lastMessageAt'] as Timestamp?;

                  String timeStr = '...';
                  if (lastTimestamp != null) {
                    final date = lastTimestamp.toDate();
                    int hour = date.hour;
                    String ampm = hour >= 12 ? 'PM' : 'AM';
                    if (hour > 12) hour -= 12;
                    if (hour == 0) hour = 12;
                    timeStr =
                        '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $ampm';
                  }

                  final unreadCountMap = data['unreadCounts'] as Map?;
                  int unreadCount = 0;
                  if (unreadCountMap != null) {
                    unreadCount = (unreadCountMap[uid] as num? ?? 0).toInt();
                  }

                  final summary = ChatSummary(
                    id: chatId,
                    name: displayName,
                    lastMessagePreview: lastMsg,
                    timestamp: timeStr,
                    isPinned: false,
                    status: ChatStatus.online,
                    avatarUrl: '',
                    isTyping: false,
                    unreadCount: unreadCount,
                  );

                  return _ChatTile(
                    chat: summary,
                    otherUid: participants.keys.first,
                    hasNickname: _nicknames.containsKey(chatId),
                    onTap: () => widget.onTapChat?.call(summary),
                    onLongPress: (profile) => _showChatExtras(
                      context: context,
                      summary: summary,
                      otherUid: participants.keys.first,
                      originalName: originalName,
                      profile: profile,
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.chat,
    required this.otherUid,
    required this.onTap,
    required this.onLongPress,
    this.hasNickname = false,
  });

  final ChatSummary chat;
  final String otherUid;
  final VoidCallback? onTap;
  final void Function(ProfileModel? profile)? onLongPress;
  final bool hasNickname;

  void _showPreview(BuildContext context, ProfileModel profile) {
    showDialog(
      context: context,
      builder: (ctx) => ProfilePreviewDialog(
        profile: profile,
        onChatTap: () => Navigator.maybePop(ctx), // Close dialog
        onCallTap: () {
          // Future: Implement voice call from preview
        },
        onVideoCallTap: () {
          // Future: Implement video call from preview
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileService = ProfileService();

    return StreamBuilder<ProfileModel?>(
      stream: profileService.getProfileStream(otherUid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final photoUrl = profile?.photoUrl ?? '';

        String resolvedName = chat.name;

        if (hasNickname &&
            chat.name.isNotEmpty &&
            chat.name != 'Unknown Sender') {
          resolvedName = chat.name;
        } else {
          if (profile != null &&
              profile.fullName.isNotEmpty &&
              profile.fullName.toLowerCase() != 'user') {
            resolvedName = profile.fullName;
          }

          if ((resolvedName.isEmpty ||
                  resolvedName.toLowerCase() == 'user' ||
                  resolvedName == 'Unknown Sender') &&
              profile?.email != null &&
              profile!.email.isNotEmpty &&
              profile.email.toLowerCase() != 'user') {
            final prefix = profile.email.split('@')[0];
            resolvedName = prefix[0].toUpperCase() + prefix.substring(1);
          }

          if (resolvedName.isEmpty ||
              resolvedName.toLowerCase() == 'user' ||
              resolvedName == 'Unknown Sender') {
            final isWaiting =
                snapshot.connectionState == ConnectionState.waiting;
            resolvedName = isWaiting ? 'Loading...' : 'Unknown Sender';
          }
        }

        return InkWell(
          onTap: onTap,
          onLongPress: () => onLongPress?.call(profile),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: profile != null
                      ? () => _showPreview(context, profile)
                      : null,
                  child: Hero(
                    tag: 'avatar_$otherUid',
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: photoUrl.isNotEmpty
                          ? CachedNetworkImageProvider(photoUrl)
                          : null,
                      child: photoUrl.isEmpty
                          ? Text(
                              resolvedName.isNotEmpty
                                  ? resolvedName
                                        .split(' ')
                                        .map((e) => e[0])
                                        .take(2)
                                        .join()
                                  : '?',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  resolvedName,
                                  style: theme.textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hasNickname) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit_rounded,
                                  size: 12,
                                  color: AppColors.primary.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            chat.timestamp,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.isTyping
                                  ? 'Typing…'
                                  : chat.lastMessagePreview,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: chat.isTyping
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (chat.unreadCount > 0)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
