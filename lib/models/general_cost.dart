// models/general_cost.dart
import 'package:cloud_firestore/cloud_firestore.dart';
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
      'date': date,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory GeneralCost.fromMap(String id, Map<String, dynamic> map) {
    try {
      // Helper function to parse dates
      DateTime parseDate(dynamic dateField) {
        if (dateField == null) return DateTime.now();

        if (dateField is Timestamp) {
          return dateField.toDate();
        } else if (dateField is DateTime) {
          return dateField;
        } else if (dateField is String) {
          return DateTime.parse(dateField);
        } else if (dateField is int) {
          return DateTime.fromMillisecondsSinceEpoch(dateField);
        }
        return DateTime.now();
      }

      return GeneralCost(
        id: id,
        amount: (map['amount'] ?? 0.0).toDouble(),
        note: map['note']?.toString() ?? '',
        date: parseDate(map['date']),
        createdAt: parseDate(map['createdAt']),
        updatedAt: parseDate(map['updatedAt']),
      );
    } catch (e) {
      print('Error parsing GeneralCost: $e');
      print('Map data: $map');
      // Return a default cost object if parsing fails
      final now = DateTime.now();
      return GeneralCost(
        id: id,
        amount: (map['amount'] ?? 0.0).toDouble(),
        note: map['note']?.toString() ?? 'পার্সিং ত্রুটি',
        date: now,
        createdAt: now,
        updatedAt: now,
      );
    }
  }
}