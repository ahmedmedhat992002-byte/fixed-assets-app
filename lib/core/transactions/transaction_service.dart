import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../dashboard/models/transaction_item.dart';

class TransactionService extends ChangeNotifier {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Records a new transaction in Firestore under the current user's scope.
  Future<bool> recordTransaction({
    required String title,
    required double amount,
    required String type, // e.g., 'purchase', 'disposal', 'maintenance'
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final transactionId = const Uuid().v4();
      final now = Timestamp.now();

      final transaction = TransactionItem(
        id: transactionId,
        title: title,
        amount: amount,
        type: type,
        date: now,
        createdAt: now,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(transactionId)
          .set(transaction.toMap());

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error recording transaction: $e');
      }
      return false;
    }
  }
}
