// models/cashbox_summery.dart
class CashboxSummary {
  final double totalSavings;
  final double totalWithdrawals;
  final double totalLoanGiven;
  final double totalLoanCollected;
  final double totalLoanPending;
  final double totalGeneralCost;
  final double loanBalance; // Loan yet to be collected
  final double netSavings; // Savings after withdrawals and costs
  final double totalCash; // Total cash available
  final int totalMembers;
  final int activeLoans;
  final int completedLoans;
  final DateTime lastUpdated;

  CashboxSummary({
    required this.totalSavings,
    required this.totalWithdrawals,
    required this.totalLoanGiven,
    required this.totalLoanCollected,
    required this.totalLoanPending,
    required this.totalGeneralCost,
    required this.loanBalance,
    required this.netSavings,
    required this.totalCash,
    required this.totalMembers,
    required this.activeLoans,
    required this.completedLoans,
    required this.lastUpdated,
  });
}