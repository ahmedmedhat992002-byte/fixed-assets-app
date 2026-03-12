import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../supabase/supabase_config.dart';
import '../../features/notifications/data/notification_service.dart';
import '../../features/notifications/data/notification_model.dart';
import '../chat/fcm_service.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _supabase = Supabase.instance.client;

  NotificationService? _notificationService;

  void setNotificationService(NotificationService service) {
    _notificationService = service;
  }

  /// Returns a total unread count stream for a user.
  Stream<int> getTotalUnreadCountStream(String uid) {
    if (uid.isEmpty) return Stream.value(0);
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (final doc in snapshot.docs) {
            final unreadCounts = doc.data()['unreadCounts'] as Map?;
            if (unreadCounts != null) {
              total += (unreadCounts[uid] as num? ?? 0).toInt();
            }
          }
          return total;
        });
  }

  /// Returns a stream of chats for the current user.
  Stream<List<Map<String, dynamic>>> getChatsStream(String uid) {
    if (uid.isEmpty) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return {'id': doc.id, ...data};
            }).toList();
          } catch (e) {
            debugPrint('ERROR: [ChatService] getChatsStream mapping error: $e');
            return <Map<String, dynamic>>[];
          }
        })
        .handleError((error) {
          debugPrint('Firestore error in getChatsStream: $error');
          throw error;
        });
  }

  /// Returns a stream of messages for a specific chat.
  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    if (chatId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return {'id': doc.id, ...data};
            }).toList();
          } catch (e) {
            debugPrint(
              'ERROR: [ChatService] getMessagesStream mapping error: $e',
            );
            return <Map<String, dynamic>>[];
          }
        })
        .handleError((error) {
          debugPrint('Firestore error in getMessagesStream: $error');
          throw error;
        });
  }

  /// Uploads a file to Supabase Storage and returns the public URL.
  Future<String> uploadFile(String chatId, File file, String fileName) async {
    try {
      final String fileExt = fileName.split('.').last;
      final String path =
          '$chatId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _supabase.storage
          .from(SupabaseConfig.chatBucket)
          .upload(path, file);

      return _supabase.storage
          .from(SupabaseConfig.chatBucket)
          .getPublicUrl(path);
    } catch (e) {
      debugPrint('ERROR: [ChatService] uploadFile failed: $e');
      throw Exception('Failed to upload file to Supabase: $e');
    }
  }

  /// Sends a message and updates the parent chat document.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderEmail,
    required String text,
    String? fileUrl,
    String? fileName,
    String? fileType,
    String messageType = 'text',
    Map<String, dynamic>? replyTo,
  }) async {
    if (chatId.isEmpty || (text.trim().isEmpty && fileUrl == null && messageType == 'text')) return;

    final batch = _firestore.batch();
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();
    final chatRef = _firestore.collection('chats').doc(chatId);

    batch.set(messageRef, {
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'text': text.trim(),
      'type': messageType,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent', // Initial status
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileType != null) 'fileType': fileType,
      if (replyTo != null) 'replyTo': replyTo,
    });

    batch.update(chatRef, {
      'lastMessage': messageType == 'sticker'
          ? 'Sent a sticker'
          : messageType == 'asset'
          ? 'Sent an asset'
          : (fileUrl != null && text.trim().isEmpty)
          ? (_isImageType(fileType) ? '📷 Photo' : '📎 ${fileName ?? 'File'}')
          : text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
      'lastSenderName': senderName,
      'lastSenderEmail': senderEmail,
      'unreadCounts.$senderId': 0, // Reset sender's unread
    });

    // Increment recipient's unread count
    // We need to fetch participants to know who the recipient is, but for 1-1 chats,
    // it's easier to just update the other participant if we can identify them.
    // However, Increment is best done on the server.
    // We use a trick: in Firestore rules or here, we target the OTHER user.
    // For now, let's assume we update the specific map entry if we can find it.
    // A better way is to use FieldValue.increment inside a map.

    // We'll update the 'unreadCounts' map using dot notation to target the OTHER user.
    // We'd need the recipient ID here. Let's find it from the chat doc or pass it.
    // To keep sendMessage API clean, we'll try to find the recipient from a cached chat if possible,
    // or just increment the other key in unreadCounts.

    // Actually, let's just use a simple approach: any participant who is NOT senderId gets incremented.
    // This handles 1-1 chats perfectly.
    // We'll use a transaction or just a separate update if needed, but batch.update works with dot notation
    // if we know the ID. Since we don't have recipient ID here easily, let's modify the signature or logic.

    // Actually, let's fetch the chat doc once if needed or just handle it in the UI/Rules?
    // No, server-side increment is best.

    // REFINE: Let's fetch the recipient ID first.
    final chatDoc = await chatRef.get();
    if (chatDoc.exists) {
      final participants = List<String>.from(
        chatDoc.data()?['participants'] ?? [],
      );
      for (final pId in participants) {
        if (pId != senderId) {
          batch.update(chatRef, {'unreadCounts.$pId': FieldValue.increment(1)});

          // Trigger in-app notification for the recipient
          if (_notificationService != null) {
            _notificationService!.sendSystemNotificationToUser(
              targetUid: pId,
              title: 'New Message from $senderName',
              subtitle: 'From $senderName',
              body: (fileUrl != null && text.trim().isEmpty)
                  ? (_isImageType(fileType) ? '📷 Photo' : '📎 ${fileName ?? 'File'}')
                  : (text.trim().isEmpty ? 'New message' : text.trim()),
              type: NotificationType.message,
              routeName: '/chat_detail',
              routeArgs: {'chatId': chatId},
            );
          }

          // Send FCM push notification
          final pushBody = (fileUrl != null && text.trim().isEmpty)
              ? (_isImageType(fileType) ? '📷 Photo' : '📎 ${fileName ?? 'File'}')
              : (text.trim().isEmpty ? 'New message' : text.trim());
          FcmService().sendPushToUser(
            targetUid: pId,
            title: senderName,
            body: pushBody,
            data: {'chatId': chatId, 'type': 'chat_message'},
          ).ignore();
        }
      }
    }

    try {
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Finds a user by email to start a new chat.
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    final searchEmail = email.trim().toLowerCase();
    if (searchEmail.isEmpty) {
      debugPrint('[ChatService] findUserByEmail: Empty email provided.');
      return null;
    }

    debugPrint(
      '[ChatService] findUserByEmail: Searching for "$searchEmail"...',
    );

    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: searchEmail)
          .limit(1)
          .get();

      debugPrint(
        '[ChatService] findUserByEmail: Query completed. Docs found: ${query.docs.length}',
      );

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        debugPrint('[ChatService] findUserByEmail: Found user UID: ${doc.id}');
        return {'uid': doc.id, ...data};
      } else {
        debugPrint(
          '[ChatService] findUserByEmail: No user found with email "$searchEmail".',
        );
      }
    } on FirebaseException catch (e) {
      debugPrint(
        'ERROR: [ChatService] FirebaseException in findUserByEmail: ${e.code} - ${e.message}',
      );
    } catch (e) {
      debugPrint('ERROR: [ChatService] Unknown error in findUserByEmail: $e');
    }
    return null;
  }

  /// Marks a chat as read for a specific user.
  Future<void> markAsRead(String chatId, String uid) async {
    if (chatId.isEmpty || uid.isEmpty) return;
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCounts.$uid': 0,
      });

      // Mark all incoming messages as seen when chat is opened.
      // Fetch all messages by the other user and update their status.
      // Note: We avoid multiple inequality filters by only filtering on senderId.
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: uid)
          .get();

      if (messages.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in messages.docs) {
          final status = doc.data()['status'] as String? ?? '';
          if (status != 'seen') {
            batch.update(doc.reference, {'status': 'seen'});
          }
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error in markAsRead: $e');
    }
  }

  /// Updates the status of a specific message.
  Future<void> updateMessageStatus(
    String chatId,
    String messageId,
    String status,
  ) async {
    if (chatId.isEmpty || messageId.isEmpty) return;
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'status': status});
    } catch (e) {
      debugPrint('Error in updateMessageStatus: $e');
    }
  }

  /// Creates a new chat or returns an existing one.
  Future<String> getOrCreateChat(
    String currentUid,
    String currentName,
    String currentEmail,
    String otherUid,
    String otherName,
    String otherEmail,
  ) async {
    try {
      // Check for existing 1-on-1 chat
      final existing = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUid)
          .get();

      for (final doc in existing.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.length == 2 && participants.contains(otherUid)) {
          return doc.id;
        }
      }

      // Create new chat - Fetch latest names from users collection to be sure
      String currentSyncName = currentName;
      String otherSyncName = otherName;

      try {
        final currentDoc = await _firestore
            .collection('users')
            .doc(currentUid)
            .get();
        if (currentDoc.exists) {
          final data = currentDoc.data();
          final n = data?['name'] ?? data?['firstName'];
          if (n != null && n.toString().isNotEmpty) {
            currentSyncName = n.toString();
          }
        }

        final otherDoc = await _firestore
            .collection('users')
            .doc(otherUid)
            .get();
        if (otherDoc.exists) {
          final data = otherDoc.data();
          final n = data?['name'] ?? data?['firstName'];
          if (n != null && n.toString().isNotEmpty) {
            otherSyncName = n.toString();
          }
        }
      } catch (e) {
        debugPrint(
          'Non-critical: Failed to fetch latest names for chat creation: $e',
        );
      }

      final chatDoc = _firestore.collection('chats').doc();
      await chatDoc.set({
        'participants': [currentUid, otherUid],
        'participantNames': {
          currentUid: currentSyncName,
          otherUid: otherSyncName,
        },
        'participantEmails': {currentUid: currentEmail, otherUid: otherEmail},
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': 'New chat started',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      return chatDoc.id;
    } catch (e) {
      debugPrint('Error in getOrCreateChat: $e');
      throw Exception('Failed to setup chat: $e');
    }
  }

  /// Deletes all messages in a specific chat.
  Future<void> clearChat(String chatId) async {
    if (chatId.isEmpty) return;
    try {
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      if (messages.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in messages.docs) {
          batch.delete(doc.reference);
        }
        batch.update(_firestore.collection('chats').doc(chatId), {
          'lastMessage': 'Chat cleared',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'unreadCounts': {}, // Reset all unread counts
        });
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error clearing chat: $e');
      throw Exception('Failed to clear chat: $e');
    }
  }

  /// Toggles blocking/unblocking a user.
  Future<void> toggleBlockUser(String currentUid, String otherUid) async {
    if (currentUid.isEmpty || otherUid.isEmpty) return;
    try {
      final userDoc = _firestore.collection('users').doc(currentUid);
      final snapshot = await userDoc.get();
      final data = snapshot.data();
      final List<String> blockedUsers = List<String>.from(
        data?['blockedUsers'] ?? [],
      );

      if (blockedUsers.contains(otherUid)) {
        blockedUsers.remove(otherUid);
      } else {
        blockedUsers.add(otherUid);
      }

      await userDoc.update({'blockedUsers': blockedUsers});
    } catch (e) {
      debugPrint('Error toggling block user: $e');
      throw Exception('Failed to update block status: $e');
    }
  }

  /// Toggles a reaction on a message.
  Future<void> toggleReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    if (chatId.isEmpty || messageId.isEmpty || userId.isEmpty) return;

    try {
      final msgRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(msgRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});

        if (reactions[userId] == emoji) {
          // Remove reaction if same emoji is picked
          reactions.remove(userId);
        } else {
          // Update or add reaction
          reactions[userId] = emoji;
        }

        transaction.update(msgRef, {'reactions': reactions});
      });
    } catch (e) {
      debugPrint('Error toggling reaction: $e');
      throw Exception('Failed to update reaction: $e');
    }
  }

  /// Edits a message's text.
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    if (chatId.isEmpty || messageId.isEmpty) return;
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'text': newText,
            'editedAt': FieldValue.serverTimestamp(),
            'isEdited': true,
          });
    } catch (e) {
      debugPrint('Error editing message: $e');
      throw Exception('Failed to edit message: $e');
    }
  }

  /// Deletes a message.
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    if (chatId.isEmpty || messageId.isEmpty) return;
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting message: $e');
      throw Exception('Failed to delete message: $e');
    }
  }
  bool _isImageType(String? fileType) {
    if (fileType == null) return false;
    return ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(fileType.toLowerCase());
  }

  /// Forwards a message to a another chat.
  Future<void> forwardMessage({
    required String targetChatId,
    required String senderId,
    required String senderName,
    required String senderEmail,
    required Map<String, dynamic> originalMessage,
  }) async {
    final text = originalMessage['text'] as String? ?? '';
    final fileUrl = originalMessage['fileUrl'] as String?;
    final fileName = originalMessage['fileName'] as String?;
    final fileType = originalMessage['fileType'] as String?;
    final messageType = originalMessage['type'] as String? ?? 'text';

    await sendMessage(
      chatId: targetChatId,
      senderId: senderId,
      senderName: senderName,
      senderEmail: senderEmail,
      text: text,
      fileUrl: fileUrl,
      fileName: fileName,
      fileType: fileType,
      messageType: messageType,
    );
  }

  /// Toggles starring of a message.
  Future<void> toggleStarMessage({
    required String chatId,
    required String messageId,
    required String userId,
  }) async {
    if (chatId.isEmpty || messageId.isEmpty || userId.isEmpty) return;

    try {
      final msgRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(msgRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final starredBy = List<String>.from(data['starredBy'] ?? []);

        if (starredBy.contains(userId)) {
          starredBy.remove(userId);
        } else {
          starredBy.add(userId);
        }

        transaction.update(msgRef, {'starredBy': starredBy});
      });
    } catch (e) {
      debugPrint('Error toggling star message: $e');
      throw Exception('Failed to update star status: $e');
    }
  }
}
