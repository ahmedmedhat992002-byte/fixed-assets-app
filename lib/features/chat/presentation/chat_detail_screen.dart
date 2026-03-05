import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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

import '../../../core/supabase/supabase_config.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/chat/chat_service.dart';
import '../../../core/chat/call_service.dart';
import '../../../core/theme/app_colors.dart';
import 'call_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/voice_message_bubble.dart';
import 'widgets/profile_preview_dialog.dart';
import 'widgets/asset_picker_bottom_sheet.dart';
import '../../../core/profile/profile_service.dart';
import '../../../core/profile/models/profile_model.dart';
import '../../../core/assets/asset_service.dart';
import '../../../core/sync/models/asset_local.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../assets/presentation/unified_asset_detail_screen.dart';

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

  // VoIP - For incoming calls
  bool _isCallListenerSet = false;
  StreamSubscription? _msgSubscription;

  void _showPreview(BuildContext context, ProfileModel profile) {
    showDialog(
      context: context,
      builder: (_) => ProfilePreviewDialog(
        profile: profile,
        onChatTap: () {},
        onCallTap: () => _makeCall(false),
        onVideoCallTap: () => _makeCall(true),
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
  String? _recordingPath;
  Timer? _recordingTimer;
  String _recordingDuration = '0:00';
  bool _isSwipeToCancel = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _loadNickname();
    _loadFavoriteStickers();
    _markRead();

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

    _msgCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForIncomingCalls();
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
    final otherUid = participants.firstWhere(
      (id) => id != currentUid,
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

  // ── Nickname helpers ───────────────────────────────────────────────────────

  String get _displayName => (_nickname != null && _nickname!.isNotEmpty)
      ? _nickname!
      : widget.contactName;

  String _resolvedName(ProfileModel? profile, bool isWaiting) {
    if (_nickname != null && _nickname!.isNotEmpty) return _nickname!;
    if (profile != null &&
        profile.fullName.isNotEmpty &&
        profile.fullName.toLowerCase() != 'user') {
      return profile.fullName;
    }
    String name = _displayName;
    if ((name.isEmpty ||
            name.toLowerCase() == 'user' ||
            name == 'Unknown Sender') &&
        profile?.email != null &&
        profile!.email.isNotEmpty) {
      final prefix = profile.email.split('@')[0];
      return prefix[0].toUpperCase() + prefix.substring(1);
    }
    if (name.isEmpty ||
        name.toLowerCase() == 'user' ||
        name == 'Unknown Sender') {
      return isWaiting ? 'Loading...' : 'Unknown Sender';
    }
    return name;
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
    final list = List<String>.from(_favoriteStickers);
    if (list.contains(url)) {
      list.remove(url);
    } else {
      list.insert(0, url);
    }
    await prefs.setStringList('favorite_stickers', list);
    if (mounted) setState(() => _favoriteStickers = list);
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
    final reactions = msg['reactions'] as Map? ?? {};
    if (reactions.isEmpty) return const SizedBox.shrink();

    // Group reactions by emoji
    final Map<String, int> counts = {};
    reactions.values.forEach((emoji) {
      if (emoji is String) {
        counts[emoji] = (counts[emoji] ?? 0) + 1;
      }
    });

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: counts.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (isMine ? Colors.white : AppColors.primaryLight)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isMine ? Colors.white70 : AppColors.primary).withValues(
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
                      color: isMine ? Colors.white : AppColors.primary,
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

  Future<void> _makeCall(bool isVideo) async {
    final callService = context.read<CallService>();
    final authService = context.read<AuthService>();
    final currentUid = authService.firebaseUser?.uid ?? '';
    final currentEmail = authService.firebaseUser?.email ?? '';
    final currentName =
        authService.profile?.name ??
        authService.firebaseUser?.displayName ??
        currentEmail.split('@')[0];

    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      final participants = List<String>.from(
        chatDoc.data()?['participants'] ?? [],
      );
      final otherUid = participants.firstWhere(
        (id) => id != currentUid,
        orElse: () => '',
      );

      if (otherUid.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot find other participant')),
          );
        }
        return;
      }

      final call = CallModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        callerId: currentUid,
        callerName: currentName,
        receiverId: otherUid,
        receiverName: widget.contactName,
        channelId: widget.chatId,
        isVideo: isVideo,
        status: CallStatus.dialling,
        timestamp: DateTime.now(),
      );

      await callService.makeCall(call);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CallScreen(call: call, isIncoming: false),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to initiate call: $e')));
      }
    }
  }

  void _listenForIncomingCalls() {
    if (_isCallListenerSet) return;
    _isCallListenerSet = true;

    final authService = context.read<AuthService>();
    final currentUid = authService.firebaseUser?.uid ?? '';
    if (currentUid.isEmpty) return;

    final callService = context.read<CallService>();
    callService.callStream(currentUid).listen((call) {
      if (call != null && call.status == CallStatus.dialling && mounted) {
        _showIncomingCallDialog(call);
      }
    });
  }

  void _showIncomingCallDialog(CallModel call) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Incoming ${call.isVideo ? 'Video' : 'Voice'} Call'),
        content: Text('${call.callerName} is calling you...'),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: () {
              context.read<CallService>().updateCallStatus(
                call.id,
                CallStatus.rejected,
              );
              Navigator.pop(ctx);
            },
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.green),
            onPressed: () {
              context.read<CallService>().updateCallStatus(
                call.id,
                CallStatus.ongoing,
              );
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CallScreen(call: call, isIncoming: true),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

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

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        _recordingPath = p.join(
          directory.path,
          'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );

        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        );
        await _audioRecorder.start(config, path: _recordingPath!);

        setState(() {
          _isRecording = true;
          _isSwipeToCancel = false;
          _recordingDuration = '0:00';
        });

        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          final duration = Duration(seconds: timer.tick);
          String twoDigits(int n) => n.toString().padLeft(2, "0");
          String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
          String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
          if (mounted) {
            setState(() {
              _recordingDuration = "$twoDigitMinutes:$twoDigitSeconds";
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    final path = await _audioRecorder.stop();

    if (_isSwipeToCancel || path == null) {
      setState(() {
        _isRecording = false;
        _isSwipeToCancel = false;
      });
      return;
    }

    setState(() {
      _isRecording = false;
      _isUploading = true;
    });

    try {
      debugPrint('Voice Note: stopping recorder, path result: $path');
      final file = File(path);
      if (!await file.exists()) {
        throw 'Recorded file does not exist at path: $path';
      }

      final fileSize = await file.length();
      debugPrint('Voice Note: file exists, size: $fileSize bytes');

      final fileBytes = await file.readAsBytes();
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storagePath = 'voice/$fileName';

      debugPrint(
        'Voice Note: starting Supabase upload to: ${SupabaseConfig.chatBucket}/$storagePath',
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

      await Supabase.instance.client.storage
          .from(SupabaseConfig.chatBucket)
          .uploadBinary(storagePath, fileBytes);

      final downloadUrl = Supabase.instance.client.storage
          .from(SupabaseConfig.chatBucket)
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
    await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _isSwipeToCancel = false;
    });
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
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
      setState(() {
        _showStickerPicker = false;
        _replyingTo = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send sticker: $e')));
      }
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

  void _showMessageOptions(Map<String, dynamic> msg) {
    final currentUid = context.read<AuthService>().firebaseUser?.uid ?? '';
    final isMine = msg['senderId'] == currentUid;
    final type = msg['type'] as String? ?? 'text';
    final isSticker = type == 'sticker';
    final isFavorite = isSticker && _favoriteStickers.contains(msg['fileUrl']);

    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.reply_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _replyingTo = msg);
                _focusNode.requestFocus();
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'React with',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['👍', '❤️', '😂', '😮', '😢'].map((emoji) {
                final reactions = msg['reactions'] as Map? ?? {};
                final currentUid = context
                    .read<AuthService>()
                    .firebaseUser
                    ?.uid;
                final isSelected = reactions[currentUid] == emoji;

                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<ChatService>().toggleReaction(
                      chatId: widget.chatId,
                      messageId: msg['id'],
                      userId: currentUid ?? '',
                      emoji: emoji,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.forward_rounded,
                color: AppColors.primary,
              ),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(ctx);
                _showForwardDialog(msg);
              },
            ),
            if (isSticker)
              ListTile(
                leading: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber,
                ),
                title: Text(isFavorite ? 'Unstar Sticker' : 'Star Sticker'),
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleFavoriteSticker(msg['fileUrl']);
                },
              ),
            if (isMine && !isSticker && type == 'text')
              ListTile(
                leading: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.primary,
                ),
                title: Text(AppLocalizations.of(context)!.chatMenuEdit),
                onTap: () {
                  Navigator.pop(ctx);
                  _editMessage(msg);
                },
              ),
            if (isMine)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                title: Text(AppLocalizations.of(context)!.chatMenuDelete),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteMessage(msg);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _editMessage(Map<String, dynamic> msg) {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: msg['text'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chatMenuEditTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.chatMenuEditHint),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.buttonCancel),
          ),
          TextButton(
            onPressed: () async {
              final newText = ctrl.text.trim();
              if (newText.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await context.read<ChatService>().editMessage(
                  chatId: widget.chatId,
                  messageId: msg['id'],
                  newText: newText,
                );
                // Success - UI updates via stream
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.errorUnexpected}: $e')),
                  );
                }
              }
            },
            child: Text(l10n.buttonConfirm),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(Map<String, dynamic> msg) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chatMenuDeleteConfirmTitle),
        content: Text(l10n.chatMenuDeleteConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.buttonCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<ChatService>().deleteMessage(
                  chatId: widget.chatId,
                  messageId: msg['id'],
                );
                // Success - UI updates via stream
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
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showForwardDialog(Map<String, dynamic> msgToForward) {
    final authService = context.read<AuthService>();
    final chatService = context.read<ChatService>();
    final uid = authService.firebaseUser?.uid ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forward Message'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: chatService.getChatsStream(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              final chats = snapshot.data ?? [];
              if (chats.isEmpty) {
                return const Center(child: Text('No active chats found.'));
              }

              return ListView.builder(
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chatData = chats[index];
                  final participantNamesMap = chatData['participantNames'];
                  if (participantNamesMap == null ||
                      participantNamesMap is! Map) {
                    return const SizedBox.shrink();
                  }
                  final participants = Map<String, dynamic>.from(
                    participantNamesMap,
                  );
                  participants.remove(uid);
                  final profileName =
                      participants.values.first?.toString() ?? '';
                  String name = profileName;
                  if (name.isEmpty || name.toLowerCase() == 'user') {
                    final emailsMap = chatData['participantEmails'] as Map?;
                    if (emailsMap != null) {
                      final emails = Map<String, dynamic>.from(emailsMap);
                      emails.remove(uid);
                      final otherEmail = emails.values.first?.toString();
                      if (otherEmail != null) {
                        final prefix = otherEmail.split('@')[0];
                        name = prefix[0].toUpperCase() + prefix.substring(1);
                      }
                    }
                  }
                  if (name.isEmpty) name = 'User';
                  final chatId = chatData['id'] as String;

                  if (chatId == widget.chatId) return const SizedBox.shrink();

                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(name),
                    onTap: () {
                      Navigator.pop(ctx);
                      _forwardMessage(msgToForward, chatId, name);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _forwardMessage(
    Map<String, dynamic> msg,
    String targetChatId,
    String targetName,
  ) async {
    final chatService = context.read<ChatService>();
    final authService = context.read<AuthService>();
    final uid = authService.firebaseUser?.uid ?? '';
    final email = authService.firebaseUser?.email ?? '';
    final name =
        authService.profile?.name ??
        authService.firebaseUser?.displayName ??
        email.split('@')[0];

    try {
      await chatService.sendMessage(
        chatId: targetChatId,
        senderId: uid,
        senderName: name,
        senderEmail: email,
        text: msg['text'] ?? '',
        fileUrl: msg['fileUrl'],
        fileName: msg['fileName'],
        fileType: msg['fileType'],
        messageType: msg['type'] ?? 'text',
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Forwarded to $targetName')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to forward: $e')));
      }
    }
  }

  Widget _buildReplyPreview(Map<String, dynamic> replyTo, bool isMine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (isMine ? Colors.white : AppColors.primaryLight).withValues(
          alpha: 0.2,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isMine ? Colors.white70 : AppColors.primary,
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
                    color: isMine ? Colors.white : AppColors.primary,
                  ),
                ),
                Text(
                  replyTo['type'] == 'sticker' ? 'Sticker' : replyTo['text'],
                  style: TextStyle(
                    fontSize: 11,
                    color: isMine ? Colors.white70 : AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (replyTo['type'] == 'sticker')
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  replyTo['fileUrl'],
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

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
        text: 'Sent an attachment: $fileName',
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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

              names.remove(currentUid);
              emails.remove(currentUid);

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
                    color: AppColors.divider,
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
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
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
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
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
                otherUid = participants.firstWhere(
                  (uid) => uid != currentUid,
                  orElse: () => '',
                );
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
                                          ).isNotEmpty
                                          ? _resolvedName(
                                              profile,
                                              profileSnap.connectionState ==
                                                  ConnectionState.waiting,
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
            IconButton(
              icon: const Icon(Icons.call_outlined),
              tooltip: AppLocalizations.of(context)!.chatVoiceCall,
              onPressed: () => _makeCall(false),
            ),
            IconButton(
              icon: const Icon(Icons.videocam_outlined),
              tooltip: AppLocalizations.of(context)!.chatVideoCall,
              onPressed: () => _makeCall(true),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
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
        body: Column(
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
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMine = msg['senderId'] == currentUid;
                      final text = msg['text'] as String? ?? '';
                      final String? msgSenderName =
                          msg['senderName'] as String?;
                      final String msgSenderEmail =
                          msg['senderEmail'] as String? ?? '';

                      final senderName =
                          (msgSenderName != null &&
                              msgSenderName.isNotEmpty &&
                              msgSenderName != 'User')
                          ? msgSenderName
                          : (isMine
                                ? 'Me'
                                : (widget.contactName.isNotEmpty &&
                                          widget.contactName != 'User'
                                      ? widget.contactName
                                      : (msgSenderEmail.isNotEmpty &&
                                                msgSenderEmail != 'User'
                                            ? msgSenderEmail.split('@')[0]
                                            : 'Unknown Sender')));
                      final timestamp = msg['timestamp'] as Timestamp?;
                      final String type = msg['type'] as String? ?? 'text';
                      final replyTo = msg['replyTo'] as Map<String, dynamic>?;

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
                          (!isMine &&
                              _nickname != null &&
                              _nickname!.isNotEmpty)
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
                            alignment: isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: isMine
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (replyTo != null)
                                    _buildReplyPreview(replyTo, isMine),
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
                                    onLongPress: () => _showMessageOptions(msg),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        msg['fileUrl'],
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.error,
                                              color: Colors.red,
                                            ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 4,
                                      right: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          timeStr,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(fontSize: 9),
                                        ),
                                        _buildStatusTicks(msg, isMine),
                                      ],
                                    ),
                                  ),
                                  _buildReactions(msg, isMine),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      if (type == 'asset') {
                        final assetId = msg['fileUrl'] ?? '';
                        final assetName = msg['fileName'] ?? 'Asset';
                        final assetCategory = msg['fileType'] ?? 'Unknown';

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
                            alignment: isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: isMine
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (replyTo != null)
                                    _buildReplyPreview(replyTo, isMine),
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
                                    onLongPress: () => _showMessageOptions(msg),
                                    onTap: () async {
                                      if (!mounted) return;
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      final navigator = Navigator.of(context);
                                      final assetService = context
                                          .read<AssetService>();
                                      final asset = await assetService
                                          .findAssetByNameOrId(assetId);

                                      if (asset != null) {
                                        navigator.push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                UnifiedAssetDetailScreen(
                                                  asset: asset,
                                                ),
                                          ),
                                        );
                                      } else {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Asset details not found',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: 250,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isMine
                                            ? theme.colorScheme.primaryContainer
                                            : theme
                                                  .colorScheme
                                                  .surfaceContainer,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isMine
                                              ? theme
                                                    .colorScheme
                                                    .primaryContainer
                                              : theme.dividerColor,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.business_center_rounded,
                                                  color: AppColors.primary,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      assetName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      assetCategory,
                                                      style: theme
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color: theme
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                              horizontal: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.visibility_outlined,
                                                  size: 14,
                                                  color: AppColors.primary,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'View Asset Details',
                                                  style: theme
                                                      .textTheme
                                                      .labelMedium
                                                      ?.copyWith(
                                                        color:
                                                            AppColors.primary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  timeStr,
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(fontSize: 10),
                                                ),
                                                _buildStatusTicks(
                                                  msg,
                                                  isMine,
                                                  isInsideBubble: isMine,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isMine)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 4,
                                        right: 4,
                                      ),
                                      child: _buildStatusTicks(msg, isMine),
                                    ),
                                  _buildReactions(msg, isMine),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

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
                            alignment: isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: isMine
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (replyTo != null)
                                    _buildReplyPreview(replyTo, isMine),
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
                                    onLongPress: () => _showMessageOptions(msg),
                                    child: VoiceMessageBubble(
                                      url: msg['fileUrl'],
                                      isMine: isMine,
                                      timeStr: timeStr,
                                      statusTicks: _buildStatusTicks(
                                        msg,
                                        isMine,
                                        isInsideBubble: isMine,
                                      ),
                                    ),
                                  ),
                                  if (isMine)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 4,
                                        right: 4,
                                      ),
                                      child: _buildStatusTicks(msg, isMine),
                                    ),
                                  _buildReactions(msg, isMine),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

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
                          alignment: isMine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: GestureDetector(
                            onLongPress: () => _showMessageOptions(msg),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMine
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isMine ? 20 : 6),
                                  bottomRight: Radius.circular(isMine ? 6 : 20),
                                ),
                                border: Border.all(
                                  color: isMine
                                      ? theme.colorScheme.primaryContainer
                                      : theme.dividerColor.withValues(
                                          alpha: 0.6,
                                        ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (replyTo != null)
                                    _buildReplyPreview(replyTo, isMine),
                                  if (!isMine)
                                    Text(
                                      incomingLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.8),
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  if (!isMine) const SizedBox(height: 4),
                                  // File display logic
                                  if (msg['fileUrl'] != null &&
                                      type != 'sticker') ...[
                                    if ([
                                      'jpg',
                                      'jpeg',
                                      'png',
                                      'webp',
                                      'gif',
                                    ].contains(
                                      (msg['fileType'] as String? ?? '')
                                          .toLowerCase(),
                                    ))
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          msg['fileUrl'],
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return const SizedBox(
                                                  height: 150,
                                                  child: Center(
                                                    child: Icon(
                                                      Icons
                                                          .broken_image_rounded,
                                                      color:
                                                          AppColors.textMuted,
                                                      size: 40,
                                                    ),
                                                  ),
                                                );
                                              },
                                        ),
                                      )
                                    else
                                      InkWell(
                                        onTap: () => launchUrl(
                                          Uri.parse(msg['fileUrl']),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.insert_drive_file_rounded,
                                                color: AppColors.primary,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  msg['fileName'] ?? 'File',
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                  ],
                                  Text(
                                    text,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (msg['isEdited'] == true)
                                          Padding(
                                            padding:
                                                const EdgeInsetsDirectional.only(
                                                  end: 4,
                                                ),
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.chatMessageEdited,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    fontSize: 8,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant
                                                        .withValues(alpha: 0.7),
                                                  ),
                                            ),
                                          ),
                                        Text(
                                          timeStr,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        _buildStatusTicks(msg, isMine),
                                      ],
                                    ),
                                  ),
                                  _buildReactions(msg, isMine),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (_isUploading) const SizedBox(height: 2),

            // ── Input Bar ──────────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyingTo != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 4,
                          ),
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
                                  _replyingTo!['type'] == 'sticker'
                                      ? 'Sticker'
                                      : _replyingTo!['text'],
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
                                child: Image.network(
                                  _replyingTo!['fileUrl'],
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _replyingTo = null),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      if (_isRecording) ...[
                        const Icon(Icons.mic, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _recordingDuration,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Swipe left to cancel',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _showEmojiPicker = !_showEmojiPicker;
                              _showStickerPicker = false;
                              if (_showEmojiPicker) _focusNode.unfocus();
                            });
                          },
                          icon: Icon(
                            _showEmojiPicker
                                ? Icons.keyboard_rounded
                                : Icons.emoji_emotions_outlined,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _showStickerPicker = !_showStickerPicker;
                              _showEmojiPicker = false;
                              if (_showStickerPicker) _focusNode.unfocus();
                            });
                          },
                          icon: Icon(
                            Icons.sticky_note_2_outlined,
                            color: _showStickerPicker
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _msgCtrl,
                            focusNode: _focusNode,
                            enabled: !_isUploading,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText: 'Type a message',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              prefixIcon: IconButton(
                                icon: Icon(
                                  Icons.attach_file_rounded,
                                  color: theme.colorScheme.primary,
                                ),
                                onPressed: _isUploading
                                    ? null
                                    : _showAttachmentMenu,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: theme.dividerColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: theme.dividerColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      GestureDetector(
                        onLongPressStart: _msgCtrl.text.isEmpty && !_isUploading
                            ? (_) => _startRecording()
                            : null,
                        onLongPressMoveUpdate: (details) {
                          if (_isRecording &&
                              details.localOffsetFromOrigin.dx < -50) {
                            if (!_isSwipeToCancel) {
                              setState(() => _isSwipeToCancel = true);
                              _cancelRecording();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Recording cancelled'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          }
                        },
                        onLongPressEnd: (_) {
                          if (_isRecording) {
                            _stopRecording();
                          }
                        },
                        onTap: _isUploading
                            ? null
                            : () {
                                if (_msgCtrl.text.isNotEmpty) {
                                  _sendMessage();
                                }
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isUploading
                                ? theme.colorScheme.onSurfaceVariant
                                : (_isRecording
                                      ? Colors.red
                                      : theme.colorScheme.primary),
                          ),
                          padding: EdgeInsets.all(_isRecording ? 16 : 12),
                          child: Icon(
                            _msgCtrl.text.isEmpty
                                ? Icons.mic_rounded
                                : Icons.send_rounded,
                            color: Colors.white,
                            size: _isRecording ? 28 : 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Emoji Picker ────────────────────────────────────────────────
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

            // ── Sticker Picker ──────────────────────────────────────────────
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
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16), // Bottom safe area offset
          ],
        ),
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
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
