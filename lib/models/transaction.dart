class TransactionRecord {
  final String id;
  final double amount;
  final String categoryId;
  final DateTime createdAt;
  final String? note;

  TransactionRecord({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.createdAt,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'categoryId': categoryId,
        'createdAt': createdAt.toIso8601String(),
        'note': note,
      };

  factory TransactionRecord.fromJson(Map<String, dynamic> json) =>
      TransactionRecord(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        categoryId: json['categoryId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        note: json['note'] as String?,
      );
}
