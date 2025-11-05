import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/transaction_filter.dart';
import '../models/transaction_model.dart';
import 'member_providers.dart';


// Transaction filters provider
final transactionFiltersProvider = StateProvider<TransactionFilters>((ref) {
  return TransactionFilters(filterType: 'today');
});

// Filtered transactions provider
final filteredTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final filters = ref.watch(transactionFiltersProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getTransactionsWithFilters(filters);
});

// Transaction statistics provider
final transactionStatsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final filters = ref.watch(transactionFiltersProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getTransactionStats(filters).asStream();
});

// Date range provider for custom date selection

final startDateProvider = StateProvider<DateTime?>((ref) => null);
final endDateProvider = StateProvider<DateTime?>((ref) => null);
