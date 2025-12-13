// services/cashbox_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/savings_summary_model.dart';
import '../models/daily_savings_summary.dart';
import '../models/transaction_model.dart';
import '../models/general_cost.dart';

class CashboxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add new general cost
  Future<void> addGeneralCost({
    required double amount,
    required String note,
    required DateTime date,
  }) async {
    try {
      final now = DateTime.now();

      await _firestore.collection('general_costs').add({
        'amount': amount,
        'note': note,
        'date': date,
        'createdAt': now,
        'updatedAt': now,
      });

      print('General cost added successfully');
    } catch (e) {
      print('Error adding general cost: $e');
      throw Exception('সাধারণ খরচ যোগ করতে সমস্যা: $e');
    }
  }

  // Get all general costs
  Future<List<GeneralCost>> getAllGeneralCosts() async {
    try {
      final snapshot = await _firestore
          .collection('general_costs')
          .orderBy('date', descending: true)
          .get();

      final List<GeneralCost> costs = [];
      for (var doc in snapshot.docs) {
        try {
          costs.add(GeneralCost.fromMap(doc.id, doc.data()));
        } catch (e) {
          print('Error parsing cost document ${doc.id}: $e');
        }
      }
      return costs;
    } catch (e) {
      print('Error getting general costs: $e');
      throw Exception('সাধারণ খরচ লোড করতে সমস্যা: $e');
    }
  }

  // Get total general costs amount
  Future<double> getTotalGeneralCosts() async {
    try {
      final costs = await getAllGeneralCosts();
      double total = 0.0;
      for (var cost in costs) {
        total += cost.amount;
      }
      return total;
    } catch (e) {
      print('Error getting total general costs: $e');
      return 0.0;
    }
  }

  // Get simplified cash summary
  Future<SimpleCashSummary> getSimpleCashSummary() async {
    try {
      print('Getting simple cash summary...');

      // Get all transactions
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .get();

      print('Transactions count: ${transactionsSnapshot.docs.length}');

      final List<TransactionModel> allTransactions = [];
      for (var doc in transactionsSnapshot.docs) {
        try {
          allTransactions.add(TransactionModel.fromMap(doc.id, doc.data()));
        } catch (e) {
          print('Error parsing transaction ${doc.id}: $e');
        }
      }

      // Get all general costs
      final costsSnapshot = await _firestore
          .collection('general_costs')
          .get();

      print('General costs count: ${costsSnapshot.docs.length}');

      final List<GeneralCost> allGeneralCosts = [];
      for (var doc in costsSnapshot.docs) {
        try {
          allGeneralCosts.add(GeneralCost.fromMap(doc.id, doc.data()));
        } catch (e) {
          print('Error parsing general cost ${doc.id}: $e');
        }
      }

      // Calculate totals
      double totalSavings = 0.0;
      double totalWithdrawals = 0.0;
      double totalGeneralCost = 0.0;

      // Calculate transaction totals
      for (final transaction in allTransactions) {
        if (transaction.transactionType == 'savings') {
          totalSavings += transaction.amount;
        } else if (transaction.transactionType == 'withdrawal') {
          totalWithdrawals += transaction.amount;
        }
      }

      // Calculate general costs total
      for (final cost in allGeneralCosts) {
        totalGeneralCost += cost.amount;
      }

      // Calculate net balance: Total Savings - (Withdrawals + General Costs)
      final netBalance = totalSavings - (totalWithdrawals + totalGeneralCost);

      print('Summary calculated:');
      print('  Total Savings: $totalSavings');
      print('  Total Withdrawals: $totalWithdrawals');
      print('  Total General Cost: $totalGeneralCost');
      print('  Net Balance: $netBalance');

      return SimpleCashSummary(
        totalSavings: totalSavings,
        totalWithdrawals: totalWithdrawals,
        totalGeneralCost: totalGeneralCost,
        netBalance: netBalance,
        lastUpdated: DateTime.now(),
      );
    } catch (e, stack) {
      print('Error in getSimpleCashSummary: $e');
      print('Stack trace: $stack');
      throw Exception('ক্যাশবক্স তথ্য লোড করতে সমস্যা: $e');
    }
  }

  // Get daily combined activity (savings, withdrawals, and general costs)
  Future<List<DailyCombinedActivity>> getDailyCombinedActivity() async {
    try {
      print('Getting daily combined activity...');

      final List<DailyCombinedActivity> activities = [];

      // Get recent savings transactions
      final savingsSnapshot = await _firestore
          .collection('transactions')
          .where('transactionType', isEqualTo: 'savings')
          .orderBy('transactionDate', descending: true)
          .limit(15)
          .get();

      // Get recent withdrawal transactions
      final withdrawalSnapshot = await _firestore
          .collection('transactions')
          .where('transactionType', isEqualTo: 'withdrawal')
          .orderBy('transactionDate', descending: true)
          .limit(15)
          .get();

      // Get recent general costs
      final costsSnapshot = await _firestore
          .collection('general_costs')
          .orderBy('date', descending: true)
          .limit(15)
          .get();

      // Add savings activities
      for (var doc in savingsSnapshot.docs) {
        try {
          final transaction = TransactionModel.fromMap(doc.id, doc.data());
          activities.add(DailyCombinedActivity(
            id: doc.id,
            type: 'savings',
            amount: transaction.amount,
            description: transaction.memberName,
            date: transaction.transactionDate,
            note: 'সঞ্চয়',
          ));
        } catch (e) {
          print('Error parsing savings transaction ${doc.id}: $e');
        }
      }

      // Add withdrawal activities
      for (var doc in withdrawalSnapshot.docs) {
        try {
          final transaction = TransactionModel.fromMap(doc.id, doc.data());
          activities.add(DailyCombinedActivity(
            id: doc.id,
            type: 'withdrawal',
            amount: transaction.amount,
            description: transaction.memberName,
            date: transaction.transactionDate,
            note: 'উত্তোলন',
          ));
        } catch (e) {
          print('Error parsing withdrawal transaction ${doc.id}: $e');
        }
      }

      // Add general cost activities
      for (var doc in costsSnapshot.docs) {
        try {
          final cost = GeneralCost.fromMap(doc.id, doc.data());
          activities.add(DailyCombinedActivity(
            id: doc.id,
            type: 'general_cost',
            amount: cost.amount,
            description: cost.note,
            date: cost.date,
            note: 'সাধারণ খরচ',
          ));
        } catch (e) {
          print('Error parsing general cost ${doc.id}: $e');
        }
      }

      // Sort by date (newest first)
      activities.sort((a, b) => b.date.compareTo(a.date));

      print('Found ${activities.length} activities');
      return activities;
    } catch (e, stack) {
      print('Error in getDailyCombinedActivity: $e');
      print('Stack trace: $stack');
      throw Exception('দৈনিক কার্যকলাপ লোড করতে সমস্যা: $e');
    }
  }

  // Get total savings
  Future<double> getTotalSavings() async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('transactionType', isEqualTo: 'savings')
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += (data['amount'] ?? 0.0).toDouble();
      }
      return total;
    } catch (e) {
      print('Error getting total savings: $e');
      return 0.0;
    }
  }

  // Get total withdrawals
  Future<double> getTotalWithdrawals() async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('transactionType', isEqualTo: 'withdrawal')
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += (data['amount'] ?? 0.0).toDouble();
      }
      return total;
    } catch (e) {
      print('Error getting total withdrawals: $e');
      return 0.0;
    }
  }

  // services/cashbox_service.dart (add this method)
  // services/cashbox_service.dart (add this method)
  Future<List<DailySummary>> getDailySummaries({int daysBack = 7}) async {
    try {
      print('Getting daily summaries for last $daysBack days...');

      final List<DailySummary> summaries = [];
      final now = DateTime.now();

      // Get data for each day (starting from today and going back)
      for (int i = 0; i < daysBack; i++) {
        final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final nextDate = date.add(const Duration(days: 1));

        // Get savings for the day
        final savingsSnapshot = await _firestore
            .collection('transactions')
            .where('transactionType', isEqualTo: 'savings')
            .where('transactionDate', isGreaterThanOrEqualTo: date)
            .where('transactionDate', isLessThan: nextDate)
            .get();

        double dailySavings = 0.0;
        for (var doc in savingsSnapshot.docs) {
          final data = doc.data();
          dailySavings += (data['amount'] ?? 0.0).toDouble();
        }

        // Get withdrawals for the day
        final withdrawalsSnapshot = await _firestore
            .collection('transactions')
            .where('transactionType', isEqualTo: 'withdrawal')
            .where('transactionDate', isGreaterThanOrEqualTo: date)
            .where('transactionDate', isLessThan: nextDate)
            .get();

        double dailyWithdrawals = 0.0;
        for (var doc in withdrawalsSnapshot.docs) {
          final data = doc.data();
          dailyWithdrawals += (data['amount'] ?? 0.0).toDouble();
        }

        // Get general costs for the day
        final costsSnapshot = await _firestore
            .collection('general_costs')
            .where('date', isGreaterThanOrEqualTo: date)
            .where('date', isLessThan: nextDate)
            .get();

        double dailyGeneralCosts = 0.0;
        for (var doc in costsSnapshot.docs) {
          final data = doc.data();
          dailyGeneralCosts += (data['amount'] ?? 0.0).toDouble();
        }

        summaries.add(DailySummary(
          date: date,
          savings: dailySavings,
          withdrawals: dailyWithdrawals,
          generalCosts: dailyGeneralCosts,
        ));

        print('Date: ${date.toLocal()}, Savings: $dailySavings, Withdrawals: $dailyWithdrawals, Costs: $dailyGeneralCosts');
      }

      return summaries;
    } catch (e, stack) {
      print('Error in getDailySummaries: $e');
      print('Stack trace: $stack');
      return [];
    }
  }
}