import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum CallStatus { dialling, ringing, ongoing, ended, rejected, busy }

class CallModel {
  final String id;
  final String callerId;
  final String callerName;
  final String receiverId;
  final String receiverName;
  final String channelId;
  final bool isVideo;
  final CallStatus status;
  final DateTime timestamp;

  CallModel({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.receiverId,
    required this.receiverName,
    required this.channelId,
    required this.isVideo,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'callerId': callerId,
      'callerName': callerName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'channelId': channelId,
      'isVideo': isVideo,
      'status': status.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory CallModel.fromMap(Map<String, dynamic> map) {
    return CallModel(
      id: map['id'] ?? '',
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      channelId: map['channelId'] ?? '',
      isVideo: map['isVideo'] ?? false,
      status: CallStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CallStatus.ended,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }
}

class CallService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of calls for a specific user (to show ringing screen)
  Stream<CallModel?> callStream(String userId) {
    return _firestore
        .collection('calls')
        .where('receiverId', isEqualTo: userId)
        .where('status', whereIn: ['dialling', 'ringing', 'ongoing'])
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return CallModel.fromMap(snapshot.docs.first.data());
        });
  }

  Future<void> makeCall(CallModel call) async {
    try {
      await _firestore.collection('calls').doc(call.id).set(call.toMap());
    } catch (e) {
      debugPrint('Error making call: $e');
      rethrow;
    }
  }

  Future<void> updateCallStatus(String callId, CallStatus status) async {
    try {
      await _firestore.collection('calls').doc(callId).update({
        'status': status.name,
      });
    } catch (e) {
      debugPrint('Error updating call status: $e');
    }
  }

  Future<void> endCall(String callId) async {
    await updateCallStatus(callId, CallStatus.ended);
  }
}
