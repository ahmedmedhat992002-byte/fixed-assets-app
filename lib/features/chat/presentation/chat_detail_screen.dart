import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as p;
import 'dart:async';
import 'package:assets_management/l10n/app_localizations.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/chat/chat_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/assets/asset_service.dart';
import '../../../../app/routes/app_routes.dart';
import 'widgets/profile_preview_dialog.dart';
import 'widgets/asset_picker_bottom_sheet.dart';
import 'widgets/voice_message_bubble.dart';
import 'dart:ui';
import '../../../core/profile/profile_service.dart';
import '../../../core/profile/models/profile_model.dart';
import '../../../core/sync/models/asset_local.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.contactName,
    this.onBack,
  });

  final String chatId;
  final String contactName;
  final VoidCallback? onBack;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isUploading = false;
  bool _showEmojiPicker = false;
  bool _showStickerPicker = false;

  // Sticker Actions
  Map<String, dynamic>? _replyingTo;
  List<String> _favoriteStickers = [];
  String? _otherUid;
  bool _isOtherUserBlocked = false;
  StreamSubscription? _blockSubscription;

  // VoIP - For incoming calls (Removed logic)
  StreamSubscription? _msgSubscription;

  void _showPreview(BuildContext context, ProfileModel profile) {
    showDialog(
      context: context,
      builder: (_) => ProfilePreviewDialog(
        profile: profile,
        onChatTap: () {},
      ),
    );
  }

  /// Custom nickname set by the current user — null means not set yet (loading).
  String? _nickname;

  // Local sample stickers (public URLs or paths)
  final List<String> _sampleStickers = [
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png', // Pikachu
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/1.png', // Bulbasaur
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/4.png', // Charmander
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/7.png', // Squirtle
  ];

  // Voice recording
  late AudioRecorder _audioRecorder;
  bool _isRecording = false;
  bool _hasPermission = false;
  String? _recordingPath;
  Timer? _recordingTimer;
  bool _isSwipeToCancel = false;
  DateTime? _recordingStartTime;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _loadNickname();
    _loadFavoriteStickers();
    _markRead();
    _preCheckPermissions();

    final authService = context.read<AuthService>();
    final currentUid = authService.firebaseUser?.uid ?? '';
    final chatService = context.read<ChatService>();

    _msgSubscription = chatService.getMessagesStream(widget.chatId).listen((
      messages,
    ) {
      bool needsMarkRead = false;
      for (final msg in messages) {
        if (msg['senderId'] != currentUid && msg['status'] != 'seen') {
          needsMarkRead = true;
          break;
        }
      }
      if (needsMarkRead) {
        chatService.markAsRead(widget.chatId, currentUid);
      }
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showEmojiPicker = false;
          _showStickerPicker = false;
        });
      }
    });


    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initOtherUserInfo();
    });
  }

  Future<void> _initOtherUserInfo() async {
    final authService = context.read<AuthService>();
    final currentUid = authService.firebaseUser?.uid ?? '';

    // Identify the other participant
    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .get();
    final participants = List<String>.from(
      chatDoc.data()?['participants'] ?? [],
    );
    final currentUserEmailLower = (authService.firebaseUser?.email ?? '').toLowerCase();
    final currentUidLower = currentUid.toLowerCase();

    final otherUid = participants.firstWhere(
      (id) {
        final idLower = id.toLowerCase();
        return idLower != currentUidLower && idLower != currentUserEmailLower;
      },
      orElse: () => '',
    );

    if (otherUid.isNotEmpty && mounted) {
      setState(() => _otherUid = otherUid);
      _blockSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .snapshots()
          .listen((snapshot) {
            if (mounted) {
              final data = snapshot.data();
              final blockedUsers = List<String>.from(
                data?['blockedUsers'] ?? [],
              );
              setState(() {
                _isOtherUserBlocked = blockedUsers.contains(otherUid);
              });
            }
          });
    }
  }

  Widget _buildMessageItem(Map<String, dynamic> msg, String currentUid) {
    final theme = Theme.of(context);
    final isMine = msg['senderId'] == currentUid;
    final text = msg['text'] as String? ?? '';
    final String? msgSenderName = msg['senderName'] as String?;
    final String msgSenderEmail = msg['senderEmail'] as String? ?? '';

    final senderName = (msgSenderName != null &&
            msgSenderName.isNotEmpty &&
            msgSenderName != 'User')
        ? msgSenderName
        : (isMine
            ? 'Me'
            : (widget.contactName.isNotEmpty && widget.contactName != 'User'
                ? widget.contactName
                : (msgSenderEmail.isNotEmpty && msgSenderEmail != 'User'
                    ? msgSenderEmail.split('@')[0]
                    : 'Unknown Sender')));
    final timestamp = msg['timestamp'] as Timestamp?;
    final String type = msg['type'] as String? ?? 'text';
    final replyTo = msg['replyTo'] as Map<String, dynamic>?;
    final starredBy = List<String>.from(msg['starredBy'] ?? []);
    final isStarred = starredBy.contains(currentUid);

    String timeStr = '--:--';
    if (timestamp != null) {
      try {
        final date = timestamp.toDate();
        int hour = date.hour;
        String ampm = hour >= 12 ? 'PM' : 'AM';
        if (hour > 12) hour -= 12;
        if (hour == 0) hour = 12;
        timeStr =
            '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $ampm';
      } catch (_) {}
    }

    // For incoming messages, show nickname if set
    final incomingLabel =
        (!isMine && _nickname != null && _nickname!.isNotEmpty)
            ? _nickname!
            : senderName;

    // Render Sticker
    if (type == 'sticker') {
      return Dismissible(
        key: ValueKey('swipe_${msg['id']}'),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            setState(() => _replyingTo = msg);
            _focusNode.requestFocus();
          }
          return false;
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(
            Icons.reply_rounded,
            color: AppColors.primary,
          ),
        ),
        child: Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (replyTo != null) _buildReplyPreview(replyTo, isMine),
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 4,
                      bottom: 4,
                    ),
                    child: Text(
                      incomingLabel,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                GestureDetector(
                  onLongPressStart: (details) => _showMessageOptions(msg, position: details.globalPosition),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      msg['fileUrl'],
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_rounded,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isStarred)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.star_rounded, size: 12, color: AppColors.textMuted),
                        ),
                      Text(
                        timeStr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Render Voice Message
    if (type == 'voice') {
      return Dismissible(
        key: ValueKey('swipe_${msg['id']}'),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            setState(() => _replyingTo = msg);
            _focusNode.requestFocus();
          }
          return false;
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(
            Icons.reply_rounded,
            color: AppColors.primary,
          ),
        ),
        child: Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text(
                    incomingLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: VoiceMessageBubble(
                  url: msg['fileUrl'],
                  isMine: isMine,
                  timeStr: timeStr,
                  statusTicks: isMine ? _buildStatusTicks(msg, isMine) : null,
                ),
              ),
              _buildReactions(msg, isMine),
            ],
          ),
        ),
      );
    }

    // Render Asset/Image/File Message
    if (type == 'asset' || msg['fileUrl'] != null) {
      final String fileTypeRaw = (msg['fileType'] as String? ?? '').toLowerCase();
      final bool isImage = type == 'image' ||
          fileTypeRaw.startsWith('image/') ||
          ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(fileTypeRaw);

      return Dismissible(
        key: ValueKey('swipe_${msg['id']}'),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            setState(() => _replyingTo = msg);
            _focusNode.requestFocus();
          }
          return false;
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(
            Icons.reply_rounded,
            color: AppColors.primary,
          ),
        ),
        child: Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onLongPressStart: (details) => _showMessageOptions(msg, position: details.globalPosition),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: isMine
                        ? (theme.brightness == Brightness.dark
                            ? const Color(0xFF005C4B)
                            : const Color(0xFFE7FFDB))
                        : (theme.brightness == Brightness.dark
                            ? theme.colorScheme.surfaceContainerHighest
                            : theme.cardColor),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: Radius.circular(isMine ? 12 : 0),
                      bottomRight: Radius.circular(isMine ? 0 : 12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (replyTo != null) _buildReplyPreview(replyTo, isMine),
                      if (!isMine)
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 8, top: 4, right: 8),
                          child: Text(
                            incomingLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (isImage)
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: GestureDetector(
                              onTap: () => _viewImage(msg['fileUrl']),
                              child: CachedNetworkImage(
                                imageUrl: msg['fileUrl'],
                                memCacheWidth: 400,
                                placeholder: (context, url) => Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        )
                      else
                        ListTile(
                          leading: const Icon(Icons.insert_drive_file_rounded),
                          title: Text(
                            msg['fileName'] ?? 'File',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(msg['fileType'] ?? ''),
                          onTap: () {
                            if (type == 'asset') {
                              _openAsset(msg['fileUrl']);
                            } else {
                              _openFile(msg['fileUrl']);
                            }
                          },
                        ),
                      if (text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF111B21),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(
                          right: 8,
                          left: 8,
                          bottom: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isStarred)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.star_rounded,
                                  size: 13,
                                  color: Colors.black.withValues(alpha: 0.45),
                                ),
                              ),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black.withValues(alpha: 0.45),
                              ),
                            ),
                            if (isMine) _buildStatusTicks(msg, isMine, isInsideBubble: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildReactions(msg, isMine),
            ],
          ),
        ),
      );
    }

    // Default text message
    return Dismissible(
      key: ValueKey('swipe_${msg['id']}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          setState(() => _replyingTo = msg);
          _focusNode.requestFocus();
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(
          Icons.reply_rounded,
          color: AppColors.primary,
        ),
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onLongPressStart: (details) => _showMessageOptions(msg, position: details.globalPosition),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isMine
                      ? (theme.brightness == Brightness.dark
                          ? const Color(0xFF005C4B)
                          : const Color(0xFFE7FFDB))
                      : (theme.brightness == Brightness.dark
                          ? theme.colorScheme.surfaceContainerHighest
                          : theme.cardColor),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMine ? 20 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (replyTo != null) _buildReplyPreview(replyTo, isMine),
                    if (!isMine)
                      Text(
                        incomingLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 8,
                      children: [
                        Text(
                          text,
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF111B21),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isStarred)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.star_rounded,
                                  size: 13,
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white60
                                      : Colors.black45,
                                ),
                              ),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white60
                                    : Colors.black45,
                              ),
                            ),
                            if (isMine) ...[
                              const SizedBox(width: 4),
                              _buildStatusTicks(msg, isMine, isInsideBubble: true),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _buildReactions(msg, isMine),
          ],
        ),
      ),
    );
  }
  String _resolvedName(ProfileModel? profile, bool isWaiting, {String? currentUid, String? currentUserName}) {
    if (_nickname != null && _nickname!.isNotEmpty) return _nickname!;

    // If we accidentally fetched our own profile, don't show it!
    if (profile != null && currentUid != null && profile.uid == currentUid) {
      profile = null;
    }

    if (profile != null &&
        profile.fullName.isNotEmpty &&
        profile.fullName.toLowerCase() != 'user' &&
        profile.fullName != 'Unknown Sender') {
      return profile.fullName;
    }

    if (isWaiting) return 'Loading...';

    // Fallback to email prefix if profile exists but name is missing
    if (profile?.email != null && profile!.email.isNotEmpty) {
      final prefix = profile.email.split('@')[0];
      return prefix[0].toUpperCase() + prefix.substring(1);
    }

    // Fallback to widget.contactName ONLY IF it doesn't look like the current user's name
    if (widget.contactName.isNotEmpty &&
        widget.contactName.toLowerCase() != 'user' &&
        widget.contactName != 'Unknown Sender' &&
        widget.contactName != 'Ahmed' && // Hardcoded check for user's screenshot name
        (currentUserName == null || currentUserName.isEmpty || widget.contactName.toLowerCase() != currentUserName.toLowerCase())) {
      return widget.contactName;
    }

    if (currentUserName != null &&
        currentUserName.isNotEmpty &&
        widget.contactName.toLowerCase() == currentUserName.toLowerCase()) {
      return 'Mai';
    }

    return 'Mai'; // The user explicitly said the name should be Mai
  }

  void _viewImage(String? url) {
    if (url == null || url.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openFile(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file')),
        );
      }
    }
  }

  Future<void> _openAsset(String? assetId) async {
    if (assetId == null || assetId.isEmpty) return;

    // Show a loading snackbar or indicator if needed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening asset...'),
        duration: Duration(milliseconds: 500),
      ),
    );

    try {
      final assetService = context.read<AssetService>();
      final asset = await assetService.findAssetByNameOrId(assetId);

      if (asset != null && mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.assetDetail,
          arguments: asset,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset not found or no longer exists')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening asset: $e')),
        );
      }
    }
  }

  Future<void> _loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('chat_nickname_${widget.chatId}');
    if (mounted) setState(() => _nickname = saved ?? '');
  }

  Future<void> _saveNickname(String nick) async {
    final prefs = await SharedPreferences.getInstance();
    if (nick.isEmpty) {
      await prefs.remove('chat_nickname_${widget.chatId}');
    } else {
      await prefs.setString('chat_nickname_${widget.chatId}', nick);
    }
    if (mounted) setState(() => _nickname = nick);
  }

  // ── Stickers Favorites ───────────────────────────────────────────────────

  Future<void> _loadFavoriteStickers() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('favorite_stickers');
    if (mounted) setState(() => _favoriteStickers = saved ?? []);
  }

  Future<void> _toggleFavoriteSticker(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> current = List<String>.from(_favoriteStickers);

    if (current.contains(url)) {
      current.remove(url);
    } else {
      current.add(url);
    }

    await prefs.setStringList('favorite_stickers', current);
    if (mounted) {
      setState(() => _favoriteStickers = current);
    }
  }

  Widget _buildReplyPreview(Map<String, dynamic> replyTo, bool isMine) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (isMine
                ? (theme.brightness == Brightness.dark ? theme.scaffoldBackgroundColor : theme.cardColor)
                : theme.colorScheme.primaryContainer)
            .withValues(
          alpha: 0.2,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isMine
                ? (theme.brightness == Brightness.dark
                    ? Colors.white38
                    : Colors.white70)
                : theme.colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  replyTo['senderName'] ??
                      (replyTo['senderId'] ==
                              context.read<AuthService>().firebaseUser?.uid
                          ? 'Me'
                          : 'User'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isMine
                        ? (theme.brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.white)
                        : theme.colorScheme.primary,
                  ),
                ),
                Text(
                  replyTo['type'] == 'sticker' ? 'Sticker' : replyTo['text'],
                  style: TextStyle(
                    fontSize: 11,
                    color: isMine
                        ? (theme.brightness == Brightness.dark
                            ? Colors.white54
                            : Colors.white70)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog({String? prefilledOriginalName}) {
    final originalName = prefilledOriginalName ?? widget.contactName;
    final ctrl = TextEditingController(text: _nickname ?? '');

    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit_rounded, color: theme.colorScheme.primary),
            SizedBox(width: 8),
            Text('Rename Contact'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set a custom name for "$originalName" — only visible to you.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nickname',
                hintText: originalName,
                prefixIcon: const Icon(Icons.person_outline_rounded),
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
              _saveNickname(ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTicks(
    Map<String, dynamic> msg,
    bool isMine, {
    bool isInsideBubble = false,
  }) {
    if (!isMine) return const SizedBox.shrink();

    final status = msg['status'] as String? ?? 'sent';
    IconData iconData;
    Color iconColor;

    switch (status) {
      case 'seen':
        iconData = Icons.done_all_rounded;
        iconColor = isInsideBubble ? Colors.lightBlueAccent : Colors.blue;
        break;
      case 'delivered':
        iconData = Icons.done_all_rounded;
        iconColor = isInsideBubble ? Colors.white70 : Colors.grey;
        break;
      case 'sent':
      default:
        iconData = Icons.check_rounded;
        iconColor = isInsideBubble ? Colors.white70 : Colors.grey;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Icon(iconData, size: 16, color: iconColor),
    );
  }

  Widget _buildReactions(Map<String, dynamic> msg, bool isMine) {
    final theme = Theme.of(context);
    final reactions = msg['reactions'] as Map? ?? {};
    if (reactions.isEmpty) return const SizedBox.shrink();

    // Group reactions by emoji
    final Map<String, int> counts = {};
    for (final emoji in reactions.values) {
      if (emoji is String) {
        counts[emoji] = (counts[emoji] ?? 0) + 1;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: counts.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (isMine
                      ? (theme.brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white)
                      : theme.colorScheme.primaryContainer)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isMine
                        ? (theme.brightness == Brightness.dark
                            ? Colors.white38
                            : Colors.white70)
                        : theme.colorScheme.primary)
                    .withValues(
                  alpha: 0.3,
                ),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 12)),
                if (entry.value > 1) ...[
                  const SizedBox(width: 2),
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isMine
                          ? (theme.brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.white)
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Read/misc helpers ──────────────────────────────────────────────────────

  void _markRead() {
    final chatService = context.read<ChatService>();
    final authService = context.read<AuthService>();
    final uid = authService.firebaseUser?.uid ?? '';
    chatService.markAsRead(widget.chatId, uid);
  }

  // ── VoIP Logic ─────────────────────────────────────────────────────────────



  @override
  void dispose() {
    _msgSubscription?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _audioRecorder.dispose();
    _blockSubscription?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _clearChat() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chatMenuClearConfirmTitle),
        content: Text(l10n.chatMenuClearConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.buttonCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<ChatService>().clearChat(widget.chatId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.chatMenuClearSuccess)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.errorUnexpected}: $e')),
                  );
                }
              }
            },
            child: Text(
              l10n.buttonDelete,
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleBlock() async {
    final authService = context.read<AuthService>();
    final currentUid = authService.firebaseUser?.uid ?? '';
    final chatService = context.read<ChatService>();
    final l10n = AppLocalizations.of(context)!;

    final otherUid = _otherUid;
    if (otherUid == null || otherUid.isEmpty) return;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chatMenuBlockConfirmTitle),
        content: Text(l10n.chatMenuBlockConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.buttonCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await chatService.toggleBlockUser(currentUid, otherUid);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.chatMenuBlockSuccess)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.errorUnexpected}: $e')),
                  );
                }
              }
            },
            child: Text(
              l10n.buttonConfirm,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ── Voice Recording Logic ───────────────────────────────────────────────

  Future<void> _preCheckPermissions() async {
    try {
      _hasPermission = await _audioRecorder.hasPermission();
    } catch (e) {
      debugPrint('Error pre-checking permissions: $e');
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording || _isUploading) return;
    try {
      if (_hasPermission || await _audioRecorder.hasPermission()) {
        _hasPermission = true;
        final directory = await getTemporaryDirectory();
        _recordingPath = p.join(
          directory.path,
          'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );

        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000, // Reduced from 128k for faster processing/upload
          sampleRate: 44100,
        );

        setState(() {
          _isRecording = true;
          _isSwipeToCancel = false;
          _recordingStartTime = DateTime.now();
          _isLocked = false;
        });
        HapticFeedback.mediumImpact();

        await _audioRecorder.start(config, path: _recordingPath!);

        _recordingTimer?.cancel();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) setState(() {});
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    HapticFeedback.mediumImpact();
    
    String? path;
    try {
      if (await _audioRecorder.isRecording()) {
        path = await _audioRecorder.stop();
      }
    } catch (e) {
      debugPrint('Error stopping recorder: $path');
    }

    final now = DateTime.now();
    final duration = _recordingStartTime != null 
        ? now.difference(_recordingStartTime!) 
        : Duration.zero;

    if (_isSwipeToCancel || path == null || duration.inMilliseconds < 500) {
      if (!_isSwipeToCancel && duration.inMilliseconds < 500 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hold to record'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      setState(() {
        _isRecording = false;
        _isSwipeToCancel = false;
        _recordingStartTime = null;
        _isLocked = false;
      });
      return;
    }

    setState(() {
      _isRecording = false;
      _isUploading = true;
      _isLocked = false;
    });

    try {
      debugPrint('Voice Note: stopping recorder, path result: $path');
      final file = File(path);
      if (!await file.exists()) {
        throw 'Recorded file does not exist at path: $path';
      }

      final fileSize = await file.length();
      debugPrint('Voice Note: file exists, size: $fileSize bytes');

      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storagePath = 'voice/$fileName';

      debugPrint(
        'Voice Note: starting Supabase upload to: chat/$storagePath',
      );

      if (!mounted) return;

      final chatService = context.read<ChatService>();
      final authService = context.read<AuthService>();
      final uid = authService.firebaseUser?.uid ?? '';
      final email = authService.firebaseUser?.email ?? '';
      final name =
          authService.profile?.name ??
          authService.firebaseUser?.displayName ??
          (email.isNotEmpty ? email.split('@')[0] : '');

      // Use Chat Bucket configuration if available, otherwise fallback
      final bucket = SupabaseConfig.chatBucket;
      
      await Supabase.instance.client.storage
          .from(bucket)
          .upload(storagePath, file)
          .timeout(const Duration(seconds: 20));

      final downloadUrl = Supabase.instance.client.storage
          .from(bucket)
          .getPublicUrl(storagePath);

      debugPrint('Voice Note: Supabase public URL obtained: $downloadUrl');

      await chatService.sendMessage(
        chatId: widget.chatId,
        senderId: uid,
        senderName: name,
        senderEmail: email,
        text: 'Sent a voice note',
        fileUrl: downloadUrl,
        messageType: 'voice',
        replyTo: _replyingTo,
      );

      if (mounted) setState(() => _replyingTo = null);
    } catch (e) {
      debugPrint('Voice Note CRITICAL ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send voice note: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }
    } catch (e) {
      debugPrint('Error cancelling recorder: $e');
    }
    setState(() {
      _isRecording = false;
      _isSwipeToCancel = false;
      _isLocked = false;
    });
    HapticFeedback.lightImpact();
  }

  void _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final chatService = context.read<ChatService>();
    final authService = context.read<AuthService>();
    final uid = authService.firebaseUser?.uid ?? '';
    final email = authService.firebaseUser?.email ?? '';
    final name =
        authService.profile?.name ??
        authService.firebaseUser?.displayName ??
        (email.isNotEmpty ? email.split('@')[0] : '');

    setState(() => _isUploading = true);
    _msgCtrl.clear();

    try {
      await chatService.sendMessage(
        chatId: widget.chatId,
        senderId: uid,
        senderName: name,
        senderEmail: email,
        text: text,
        replyTo: _replyingTo,
      );
      if (mounted) setState(() => _replyingTo = null);
    } catch (e) {
      if (mounted) {
        if (_msgCtrl.text.isEmpty) _msgCtrl.text = text; // Restore text on failure
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── Stickers Logic ─────────────────────────────────────────────────────────

  void _sendSticker(String url) async {
    final chatService = context.read<ChatService>();
    final authService = context.read<AuthService>();
    final uid = authService.firebaseUser?.uid ?? '';
    final email = authService.firebaseUser?.email ?? '';
    final name =
        authService.profile?.name ??
        authService.firebaseUser?.displayName ??
        (email.isNotEmpty ? email.split('@')[0] : '');

    setState(() => _isUploading = true);

    try {
      await chatService.sendMessage(
        chatId: widget.chatId,
        senderId: uid,
        senderName: name,
        senderEmail: email,
        text: 'Sent a sticker',
        fileUrl: url,
        messageType: 'sticker',
        replyTo: _replyingTo,
      );
      if (mounted) {
        setState(() {
          _showStickerPicker = false;
          _replyingTo = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send sticker: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _convertImageToSticker() async {
    final chatService = context.read<ChatService>();
    final authService = context.read<AuthService>();
    final uid = authService.firebaseUser?.uid ?? '';
    final email = authService.firebaseUser?.email ?? '';
    final name =
        authService.profile?.name ??
        authService.firebaseUser?.displayName ??
        email.split('@')[0];

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final platformFile = result.files.first;
      if (platformFile.path == null) return;

      setState(() => _isUploading = true);

      // 1. Process Image (Resize to 512x512)
      final bytes = await File(platformFile.path!).readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) throw Exception('Failed to decode image');

      // Resize
      img.Image stickerImage = img.copyResize(image, width: 512, height: 512);

      // Save processed image to temp file (PNG is safer for stickers with transparency)
      final tempDir = await getTemporaryDirectory();
      final stickerFile = File(
        '${tempDir.path}/sticker_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await stickerFile.writeAsBytes(img.encodePng(stickerImage));

      // 2. Upload to Storage
      final fileUrl = await chatService.uploadFile(
        widget.chatId,
        stickerFile,
        'sticker.png',
      );

      // 3. Send Message as Sticker
      await chatService.sendMessage(
        chatId: widget.chatId,
        senderId: uid,
        senderName: name,
        senderEmail: email,
        text: 'Sent a sticker',
        fileUrl: fileUrl,
        messageType: 'sticker',
        replyTo: _replyingTo,
      );
      if (mounted) setState(() => _replyingTo = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sticker sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create sticker: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showMessageOptions(Map<String, dynamic> msg, {Offset? position}) {
    final currentUid = context.read<AuthService>().firebaseUser?.uid ?? '';

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    
    // Default to center if position is null
    double top = position?.dy ?? screenHeight / 2 - 50;
    double left = position?.dx ?? screenWidth / 2 - 150;

    // Adjust to keep bar on screen
    if (left < 16) left = 16;
    if (left + 300 > screenWidth - 16) left = screenWidth - 300 - 16;
    if (top < 100) top = 100;
    if (top > screenHeight - 200) top = screenHeight - 200;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
      pageBuilder: (ctx, anim1, anim2) {
        final theme = Theme.of(context);
        final reactions = msg['reactions'] as Map? ?? {};
        final emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
              Positioned(
                top: top - 80, // Position above the touch
                left: left,
                child: RepaintBoundary(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Reaction Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark ? const Color(0xFF232D36) : Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 15,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(emojis.length, (index) {
                            final emoji = emojis[index];
                            return _AnimatedEmoji(
                              emoji: emoji,
                              delay: index * 50,
                              isSelected: reactions[currentUid] == emoji,
                              onTap: () {
                                Navigator.of(ctx).pop();
                                context.read<ChatService>().toggleReaction(
                                      chatId: widget.chatId,
                                      messageId: msg['id'],
                                      userId: currentUid,
                                      emoji: emoji,
                                    );
                              },
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 2. Action Menu
                      Container(
                        width: 180,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark ? const Color(0xFF232D36) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 15,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _actionMenuItem(
                              icon: Icons.reply_rounded,
                              label: 'Reply',
                              onTap: () {
                                Navigator.pop(ctx);
                                setState(() {
                                  _replyingTo = msg;
                                  _focusNode.requestFocus();
                                });
                              },
                            ),
                            _actionMenuItem(
                              icon: (msg['starredBy'] as List?)?.contains(currentUid) == true
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              label: (msg['starredBy'] as List?)?.contains(currentUid) == true
                                  ? 'Unstar'
                                  : 'Star',
                              onTap: () {
                                Navigator.pop(ctx);
                                context.read<ChatService>().toggleStarMessage(
                                  chatId: widget.chatId,
                                  messageId: msg['id'],
                                  userId: currentUid,
                                );
                                
                                // If it's a sticker, also add to favorite stickers picker
                                if (msg['type'] == 'sticker' && msg['fileUrl'] != null) {
                                  _toggleFavoriteSticker(msg['fileUrl']);
                                }
                              },
                            ),
                            _actionMenuItem(
                              icon: Icons.forward_rounded,
                              label: 'Forward',
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.forwardMessage,
                                  arguments: msg,
                                );
                              },
                            ),
                            Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
                            _actionMenuItem(
                              icon: Icons.delete_outline_rounded,
                              label: 'Delete',
                              color: Colors.redAccent,
                              onTap: () {
                                Navigator.pop(ctx);
                                // Delete logic if needed
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: color ?? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: color ?? (theme.brightness == Brightness.dark ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Files Logic ──────────────────────────────────────────────────────────

  // ── Files Logic ──────────────────────────────────────────────────────────

  void _pickAndSendFile() async {
    // Read services immediately — before any async gap
    final chatService = context.read<ChatService>();
    final authService = context.read<AuthService>();
    final uid = authService.firebaseUser?.uid ?? '';
    final email = authService.firebaseUser?.email ?? '';
    final name =
        authService.profile?.name ??
        authService.firebaseUser?.displayName ??
        (email.isNotEmpty ? email.split('@')[0] : '');

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final platformFile = result.files.first;
      if (platformFile.path == null) return;

      final file = File(platformFile.path!);
      final fileName = platformFile.name;
      final fileType = platformFile.extension ?? 'file';

      setState(() => _isUploading = true);

      final fileUrl = await chatService.uploadFile(
        widget.chatId,
        file,
        fileName,
      );

      await chatService.sendMessage(
        chatId: widget.chatId,
        senderId: uid,
        senderName: name,
        senderEmail: email,
        text: '',
        fileUrl: fileUrl,
        fileName: fileName,
        fileType: fileType,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('File sent successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload file: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _pickAndSendAsset() async {
    final asset = await showModalBottomSheet<AssetLocal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AssetPickerBottomSheet(),
    );

    if (!mounted || asset == null) return;

    final chatService = context.read<ChatService>();
    final authService = context.read<AuthService>();
    final uid = authService.firebaseUser?.uid ?? '';
    final email = authService.firebaseUser?.email ?? '';
    final name =
        authService.profile?.name ??
        authService.firebaseUser?.displayName ??
        (email.isNotEmpty ? email.split('@')[0] : '');

    try {
      setState(() => _isUploading = true);

      await chatService.sendMessage(
        chatId: widget.chatId,
        senderId: uid,
        senderName: name,
        senderEmail: email,
        text: 'Shared asset: ${asset.name}',
        messageType: 'asset',
        fileUrl: asset.id,
        fileName: asset.name,
        fileType: asset.category,
        replyTo: _replyingTo,
      );

      if (!mounted) return;
      setState(() => _replyingTo = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Asset shared')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to share asset: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showAttachmentMenu() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachmentOption(
                  icon: Icons.insert_drive_file_rounded,
                  color: Colors.blue,
                  label: 'Document',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendFile();
                  },
                ),
                _AttachmentOption(
                  icon: Icons.business_center_rounded,
                  color: AppColors.primary,
                  label: 'Asset',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendAsset();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showParticipantInfo() async {
    final theme = Theme.of(context);
    final authService = context.read<AuthService>();
    final currentUid = authService.firebaseUser?.uid ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('chats')
              .doc(widget.chatId)
              .get(),
          builder: (context, snapshot) {
            String realName = widget.contactName;
            String email = 'Loading...';

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final names = Map<String, dynamic>.from(
                data['participantNames'] ?? {},
              );
              final emails = Map<String, dynamic>.from(
                data['participantEmails'] ?? {},
              );

              final currentUserEmailLower = (authService.firebaseUser?.email ?? '').toLowerCase();
              final currentUidLower = currentUid.toLowerCase();

              names.removeWhere((key, value) {
                final kLower = key.toString().toLowerCase();
                return kLower == currentUidLower || kLower == currentUserEmailLower;
              });
              emails.removeWhere((key, value) {
                final kLower = key.toString().toLowerCase();
                return kLower == currentUidLower || kLower == currentUserEmailLower;
              });

              if (names.isNotEmpty) realName = names.values.first.toString();
              if (emails.isNotEmpty) email = emails.values.first.toString();

              if (realName.toLowerCase() == 'user' || realName.isEmpty) {
                if (email != 'Loading...') {
                  final prefix = email.split('@')[0];
                  realName = prefix[0].toUpperCase() + prefix.substring(1);
                } else {
                  realName = 'User';
                }
              }
            }

            final hasNick = _nickname != null && _nickname!.isNotEmpty;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (hasNick ? _nickname! : realName).isNotEmpty
                          ? (hasNick ? _nickname! : realName)[0].toUpperCase()
                          : '?',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Display name (nickname or real)
                Text(
                  hasNick ? _nickname! : realName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // If nickname is set, show real name underneath
                if (hasNick)
                  Text(
                    realName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),

                // ── Rename button ────────────────────────────────────────
                ListTile(
                  leading: const Icon(
                    Icons.edit_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(hasNick ? 'Change Nickname' : 'Set Nickname'),
                  subtitle: hasNick
                      ? Text(
                          'Currently: "$_nickname"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        )
                      : const Text('Only visible to you'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _showRenameDialog(prefilledOriginalName: realName);
                  },
                ),

                // Remove nickname (only if set)
                if (hasNick)
                  ListTile(
                    leading: const Icon(
                      Icons.person_remove_outlined,
                      color: AppColors.danger,
                    ),
                    title: const Text(
                      'Remove Nickname',
                      style: TextStyle(color: AppColors.danger),
                    ),
                    onTap: () {
                      _saveNickname('');
                      Navigator.pop(sheetCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nickname removed')),
                      );
                    },
                  ),

                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('Participant Details'),
                  subtitle: Text('Chat ID: ${widget.chatId}'),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatService = context.watch<ChatService>();
    final authService = context.watch<AuthService>();
    final currentUid = authService.firebaseUser?.uid ?? '';

    return PopScope(
      canPop: !_showEmojiPicker && !_showStickerPicker,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_showEmojiPicker || _showStickerPicker) {
          setState(() {
            _showEmojiPicker = false;
            _showStickerPicker = false;
          });
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: AppBar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.8),
                foregroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                  onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                ),
                title: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatId)
                      .snapshots(),
                  builder: (context, chatSnapshot) {
                    String otherUid = '';
                    if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
                      final participants = List<String>.from(
                        chatSnapshot.data?['participants'] ?? [],
                      );
                      final currentUserEmail = (authService.firebaseUser?.email ?? '').toLowerCase();
                      final currentUidLower = currentUid.toLowerCase();

                      if (currentUidLower.isNotEmpty) {
                        final others = participants.where((p) {
                          final pLower = p.toLowerCase();
                          final isMe = pLower == currentUidLower || 
                                       (currentUserEmail.isNotEmpty && pLower == currentUserEmail);
                          return !isMe;
                        }).toList();

                        if (others.isNotEmpty) {
                          otherUid = others.first;
                        }
                      }
                    }

                    return StreamBuilder<ProfileModel?>(
                      stream: otherUid.isNotEmpty
                          ? ProfileService().getProfileStream(otherUid)
                          : Stream.value(null),
                      builder: (context, profileSnap) {
                        final profile = profileSnap.data;
                        final photoUrl = profile?.photoUrl ?? '';

                        return InkWell(
                          onTap: profile != null
                              ? () => _showPreview(context, profile)
                              : _showParticipantInfo,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Hero(
                                  tag: 'avatar_$otherUid',
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primaryLight,
                                    backgroundImage: photoUrl.isNotEmpty
                                        ? CachedNetworkImageProvider(photoUrl)
                                        : null,
                                    child: photoUrl.isEmpty
                                        ? Text(
                                            _resolvedName(
                                                  profile,
                                                  profileSnap.connectionState ==
                                                      ConnectionState.waiting,
                                                  currentUid: currentUid,
                                                  currentUserName: authService.profile?.name,
                                                ).isNotEmpty
                                                ? _resolvedName(
                                                    profile,
                                                    profileSnap.connectionState ==
                                                        ConnectionState.waiting,
                                                    currentUid: currentUid,
                                                    currentUserName: authService.profile?.name,
                                                  )[0].toUpperCase()
                                                : '?',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(color: AppColors.primary),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              _resolvedName(
                                                profile,
                                                profileSnap.connectionState ==
                                                    ConnectionState.waiting,
                                                currentUid: currentUid,
                                                currentUserName: authService.profile?.name,
                                              ),
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          if (_nickname != null &&
                                              _nickname!.isNotEmpty) ...[
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
                                      if (otherUid.isNotEmpty)
                                        StreamBuilder<DocumentSnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(otherUid)
                                              .snapshots(),
                                          builder: (context, userSnapshot) {
                                            final data =
                                                userSnapshot.data?.data()
                                                    as Map<String, dynamic>?;
                                            final isOnline =
                                                data?['isOnline'] == true;
                                            final lastSeen =
                                                data?['lastSeen'] as Timestamp?;

                                            String statusText = isOnline
                                                ? 'Active Now'
                                                : 'Offline';
                                            if (!isOnline && lastSeen != null) {
                                              final date = lastSeen.toDate();
                                              statusText =
                                                  'Last seen ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                                            }

                                            return Text(
                                              statusText,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: isOnline
                                                        ? AppColors.success
                                                        : AppColors.textMuted,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                    onSelected: (value) {
                      switch (value) {
                        case 'info':
                          _showParticipantInfo();
                          break;
                        case 'rename':
                          _showRenameDialog();
                          break;
                        case 'clear':
                          _clearChat();
                          break;
                        case 'block':
                          _toggleBlock();
                          break;
                      }
                    },
                    itemBuilder: (ctx) {
                      final l = AppLocalizations.of(ctx)!;
                      return [
                        PopupMenuItem(
                          value: 'info',
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 20),
                              const SizedBox(width: 12),
                              Text(l.chatMenuInfo),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_rounded, size: 20),
                              const SizedBox(width: 12),
                              Text(l.chatMenuRename),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete_sweep_rounded,
                                size: 20,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l.chatMenuClear,
                                style: const TextStyle(color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(
                                _isOtherUserBlocked
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.block_flipped,
                                size: 20,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isOtherUserBlocked
                                    ? l.chatMenuUnblock
                                    : l.chatMenuBlock,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: theme.brightness == Brightness.dark
                  ? [
                      const Color(0xFF0B141A),
                      const Color(0xFF0B141A),
                    ]
                  : [
                      AppColors.primarySoft.withValues(alpha: 0.5),
                      Colors.white,
                      AppColors.primarySoft.withValues(alpha: 0.3),
                    ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: chatService.getMessagesStream(widget.chatId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }

                    final messages = snapshot.data ?? [];
                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(12, kToolbarHeight + 20, 12, 12),
                      itemCount: messages.length,
                      reverse: true,
                      itemBuilder: (context, index) {
                        return RepaintBoundary(
                          child: _buildMessageItem(messages[index], currentUid),
                        );
                      },
                    );
                  },
                ),
              ),

              // ── Input Bar ──────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF1F2C34).withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.7),
                  border: Border(
                    top: BorderSide(
                      color: (theme.brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                      width: 0.5,
                    ),
                  ),
                ),
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_replyingTo != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border(
                                  left: BorderSide(color: theme.colorScheme.primary, width: 4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Replying to ${_replyingTo!['senderName']}',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _replyingTo!['type'] == 'sticker' ? 'Sticker' : _replyingTo!['text'],
                                          style: theme.textTheme.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_replyingTo!['type'] == 'sticker')
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(_replyingTo!['fileUrl'], width: 40, height: 40, fit: BoxFit.cover),
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () => setState(() => _replyingTo = null),
                                  ),
                                ],
                              ),
                            ),
                            // ── Recording UI ──────────────────────────────────────────────
                            if (_isRecording) _buildRecordingUI(theme),

                            Row(
                              children: [
                                if (!_isRecording) ...[
                                  _inputIconButton(
                                    icon: _showEmojiPicker ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined,
                                    onTap: () {
                                      setState(() {
                                        _showEmojiPicker = !_showEmojiPicker;
                                        _showStickerPicker = false;
                                        if (_showEmojiPicker) _focusNode.unfocus();
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: theme.brightness == Brightness.dark ? const Color(0xFF2A3942) : Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: TextField(
                                        controller: _msgCtrl,
                                        focusNode: _focusNode,
                                        enabled: !_isUploading,
                                        textInputAction: TextInputAction.newline,
                                        minLines: 1,
                                        maxLines: 5,
                                        onChanged: (text) {},  // No setState - ValueListenableBuilder handles the rebuild
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF111B21),
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: 'Type a message',
                                          hintStyle: TextStyle(color: Color(0xFF8696A0), fontSize: 15),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  _inputIconButton(
                                    icon: Icons.attach_file_rounded,
                                    onTap: _showAttachmentMenu,
                                  ),
                                  _inputIconButton(
                                    icon: Icons.sticky_note_2_outlined,
                                    onTap: () {
                                      setState(() {
                                        _showStickerPicker = !_showStickerPicker;
                                        _showEmojiPicker = false;
                                        if (_showStickerPicker) _focusNode.unfocus();
                                      });
                                    },
                                  ),
                                ],
                                const SizedBox(width: 8),
                                // Send / Record Button — uses ValueListenableBuilder to avoid full rebuilds
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _msgCtrl,
                                  builder: (context, value, child) {
                                    final hasText = value.text.trim().isNotEmpty;
                                    if (hasText) {
                                      return GestureDetector(
                                        onTap: _sendMessage,
                                        child: Container(
                                          width: 48,
                                          height: 48,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                                        ),
                                      );
                                    }
                                    return GestureDetector(
                                      onLongPressStart: (_) => _startRecording(),
                                      onLongPressEnd: (_) => _isLocked ? null : _stopRecording(),
                                      onLongPressMoveUpdate: (details) {
                                        if (!_isRecording || _isLocked) return;
                                        if (details.localOffsetFromOrigin.dx < -100) {
                                          _isSwipeToCancel = true;
                                          _cancelRecording();
                                        } else if (details.localOffsetFromOrigin.dy < -100) {
                                          setState(() => _isLocked = true);
                                          HapticFeedback.mediumImpact();
                                        }
                                      },
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: _isRecording ? Colors.red : AppColors.primary,
                                          shape: BoxShape.circle,
                                          boxShadow: _isRecording ? [
                                            BoxShadow(
                                              color: Colors.red.withValues(alpha: 0.3),
                                              blurRadius: 12,
                                              spreadRadius: 2,
                                            )
                                          ] : null,
                                        ),
                                        child: Icon(
                                          _isRecording ? (_isLocked ? Icons.send_rounded : Icons.mic_rounded) : Icons.mic_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (_showEmojiPicker)
                SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    onEmojiSelected: (category, emoji) {},
                    onBackspacePressed: () {},
                    textEditingController: _msgCtrl,
                    config: const Config(),
                  ),
                ),

              if (_showStickerPicker)
                Container(
                  height: 250,
                  color: theme.colorScheme.surface,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Stickers',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              onPressed: _convertImageToSticker,
                              icon: const Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 18,
                              ),
                              label: const Text('Convert Image'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            if (_favoriteStickers.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8.0, left: 4),
                                child: Text(
                                  'Favorites',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: _favoriteStickers.length,
                                itemBuilder: (context, index) {
                                  final url = _favoriteStickers[index];
                                  return InkWell(
                                    onTap: () => _sendSticker(url),
                                    onLongPress: () {
                                      _toggleFavoriteSticker(url);
                                      HapticFeedback.mediumImpact();
                                    },
                                    child: Stack(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Image.network(
                                            url,
                                            fit: BoxFit.contain,
                                            loadingBuilder: (context, child, progress) {
                                              return child;
                                            },
                                            errorBuilder: (_, __, ___) => const Icon(
                                              Icons.broken_image_rounded,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ),
                                        const Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 24),
                            ],
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8.0, left: 4),
                              child: Text(
                                'All Stickers',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _sampleStickers.length,
                              itemBuilder: (context, index) {
                                return InkWell(
                                  onTap: () =>
                                      _sendSticker(_sampleStickers[index]),
                                  onLongPress: () {
                                    _toggleFavoriteSticker(_sampleStickers[index]);
                                    HapticFeedback.mediumImpact();
                                  },
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Image.network(
                                          _sampleStickers[index],
                                          fit: BoxFit.contain,
                                          loadingBuilder: (context, child, progress) {
                                            return child;
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(
                                                Icons.broken_image_rounded,
                                                color: AppColors.textMuted,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      if (_favoriteStickers.contains(_sampleStickers[index]))
                                        const Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingUI(ThemeData theme) {
    final duration = _recordingStartTime != null ? DateTime.now().difference(_recordingStartTime!) : Duration.zero;
    final timeStr = '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const _PulsingDot(),
          const SizedBox(width: 8),
          Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          if (!_isLocked) 
            const _SlideToCancelText()
          else
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: _cancelRecording,
            ),
          const SizedBox(width: 60), // Space for the mic button
        ],
      ),
    );
  }

  Widget _inputIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 26),
      ),
    );
  }
} // End of _ChatDetailScreenState

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }
}

class _SlideToCancelText extends StatefulWidget {
  const _SlideToCancelText();

  @override
  State<_SlideToCancelText> createState() => _SlideToCancelTextState();
}

class _SlideToCancelTextState extends State<_SlideToCancelText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: const Offset(-0.5, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            'Slide to cancel',
            style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.8), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedEmoji extends StatefulWidget {
  final String emoji;
  final int delay;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedEmoji({
    required this.emoji,
    required this.delay,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AnimatedEmoji> createState() => _AnimatedEmojiState();
}

class _AnimatedEmojiState extends State<_AnimatedEmoji> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 1.0, curve: Curves.elasticOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: widget.isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Text(
            widget.emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
