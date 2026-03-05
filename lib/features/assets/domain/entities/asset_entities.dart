class AssetItem {
  const AssetItem({
    required this.name,
    required this.category,
    required this.valuedAt,
    required this.date,
    this.status,
  });

  final String name;
  final String category;
  final String valuedAt;
  final String date;
  final String? status;
}

class TransactionItem {
  const TransactionItem({
    required this.title,
    required this.amount,
    required this.date,
    required this.isGain,
  });

  final String title;
  final String amount;
  final String date;
  final bool isGain;
}
