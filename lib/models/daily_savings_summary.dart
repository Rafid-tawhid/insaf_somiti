// models/today_summary.dart
import 'package:intl/intl.dart';
class DailySummary {
  final DateTime date;
  final double savings;
  final double withdrawals;
  final double generalCosts;

  DailySummary({
    required this.date,
    required this.savings,
    required this.withdrawals,
    required this.generalCosts,
  });

  double get expenses => withdrawals + generalCosts;
  double get netBalance => savings - expenses;

  // Helper method to format date
  String get formattedDate => DateFormat('dd MMM, yyyy').format(date);
}