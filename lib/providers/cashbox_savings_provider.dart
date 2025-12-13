// providers/simple_cash_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:insaf_somiti/service/cashbox_service.dart';

import '../models/general_cost.dart';
import '../models/savings_summary_model.dart';
import '../models/daily_savings_summary.dart';

// Provider for CashboxService
final cashboxServiceProvider = Provider<CashboxService>((ref) {
  return CashboxService();
});

// Provider for simple cash summary
final simpleCashSummaryProvider = FutureProvider<SimpleCashSummary>((ref) async {
  final service = ref.read(cashboxServiceProvider);
  try {
    return await service.getSimpleCashSummary();
  } catch (e) {
    print('Error in simpleCashSummaryProvider: $e');
    // Return a default summary if there's an error
    return SimpleCashSummary(
      totalSavings: 0,
      totalWithdrawals: 0,
      totalGeneralCost: 0,
      netBalance: 0,
      lastUpdated: DateTime.now(),
    );
  }
});

// Provider for daily combined activity
final dailyCombinedActivityProvider = FutureProvider<List<DailyCombinedActivity>>((ref) async {
  final service = ref.read(cashboxServiceProvider);
  try {
    return await service.getDailyCombinedActivity();
  } catch (e) {
    print('Error in dailyCombinedActivityProvider: $e');
    return [];
  }
});

// Provider for general costs
final generalCostsProvider = FutureProvider<List<GeneralCost>>((ref) async {
  final service = ref.read(cashboxServiceProvider);
  try {
    return await service.getAllGeneralCosts();
  } catch (e) {
    print('Error in generalCostsProvider: $e');
    return [];
  }
});


// providers/simple_cash_providers.dart (replace todaySummaryProvider)
final dailySummariesProvider = FutureProvider<List<DailySummary>>((ref) async {
  final service = ref.read(cashboxServiceProvider);
  return await service.getDailySummaries(daysBack: 30); // Get last 30 days
});