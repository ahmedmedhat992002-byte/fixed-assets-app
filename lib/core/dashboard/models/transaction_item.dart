import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/data_utils.dart';

class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final String type;
  final Timestamp? date;
  final Timestamp? createdAt;

  TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.createdAt,
  });

  factory TransactionItem.fromMap(Map<String, dynamic> data, String docId) {
    return TransactionItem(
      id: docId,
      title: DataUtils.asString(data['title'], 'Unknown Transaction'),
      amount: DataUtils.asDouble(data['amount']),
      type: DataUtils.asString(data['type'], 'expense'),
      date: DataUtils.asTimestamp(data['date']),
      createdAt: DataUtils.asTimestamp(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'type': type,
      'date': date ?? FieldValue.serverTimestamp(),
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
