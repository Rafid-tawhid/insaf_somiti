class TransactionFilters {
  final String filterType; // 'today', 'monthly', 'full'
  final DateTime? startDate;
  final DateTime? endDate;

  TransactionFilters({
    required this.filterType,
    this.startDate,
    this.endDate,
  });
}