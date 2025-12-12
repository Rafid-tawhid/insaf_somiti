// models/general_cost.dart
class GeneralCost {
  final String? id;
  final double amount;
  final String note;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  GeneralCost({
    this.id,
    required this.amount,
    required this.note,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'note': note,
      'date': date.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory GeneralCost.fromMap(String id, Map<String, dynamic> map) {
    return GeneralCost(
      id: id,
      amount: (map['amount'] ?? 0.0).toDouble(),
      note: map['note'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }
}