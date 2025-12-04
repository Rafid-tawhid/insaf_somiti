import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/cashbox_summery.dart';
import '../models/loan_installment.dart';
import '../models/transaction_filter.dart';
import '../models/transaction_model.dart';
import 'member_providers.dart';





// Date range provider for custom date selection

final startDateProvider = StateProvider<DateTime?>((ref) => null);
final endDateProvider = StateProvider<DateTime?>((ref) => null);


// providers/cashbox_provider.dart


final cashboxSummaryProvider = FutureProvider<CashboxSummary>((ref) async {
  final firebaseService = ref.read(firebaseServiceProvider);
  return await firebaseService.getCashboxSummary();
});

final recentTransactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final firebaseService = ref.read(firebaseServiceProvider);
  return firebaseService.getRecentTransactions(limit: 5);
});

final recentInstallmentsProvider = StreamProvider<List<InstallmentTransaction>>((ref) {
  final firebaseService = ref.read(firebaseServiceProvider);
  return firebaseService.getRecentInstallments(limit: 5);
});