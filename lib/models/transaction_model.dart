class TransactionModel {
  final int? id;
  final String type; // Income / Expense
  final double amount;
  final DateTime date;
  final int categoryId;
  final int userId; // 👈 tambahkan ini

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.userId, // 👈 wajib untuk multi-user
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'categoryId': categoryId,
      'userId': userId, // 👈 pastikan disimpan di SQLite
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      type: map['type'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      categoryId: map['categoryId'],
      userId: map['userId'], // 👈 pastikan dibaca juga
    );
  }
}
