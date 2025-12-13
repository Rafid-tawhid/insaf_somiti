// models/simple_cash_summary.dart
class SimpleCashSummary {
  final double totalSavings;
  final double totalWithdrawals;
  final double totalGeneralCost;
  final double netBalance;
  final DateTime lastUpdated;

  SimpleCashSummary({
    required this.totalSavings,
    required this.totalWithdrawals,
    required this.totalGeneralCost,
    required this.netBalance,
    required this.lastUpdated,
  });

  @override
  String toString() {
    return 'SimpleCashSummary(totalSavings: $totalSavings, totalWithdrawals: $totalWithdrawals, totalGeneralCost: $totalGeneralCost, netBalance: $netBalance)';
  }
}

// models/daily_combined_activity.dart
class DailyCombinedActivity {
  final String id;
  final String type; // 'savings', 'withdrawal', or 'general_cost'
  final double amount;
  final String description;
  final DateTime date;
  final String note;

  DailyCombinedActivity({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    required this.note,
  });

  @override
  String toString() {
    return 'DailyCombinedActivity(id: $id, type: $type, amount: $amount, date: $date)';
  }
}