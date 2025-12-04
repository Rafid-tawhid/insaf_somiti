// screens/cashbox_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/cashbox_summery.dart';
import '../models/loan_installment.dart';
import '../models/transaction_model.dart';
import '../providers/member_providers.dart';
import '../providers/transaction_report_provider.dart';
import '../service/service_class.dart';

// screens/cashbox_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../service/service_class.dart';

class CashboxScreen extends ConsumerStatefulWidget {
  const CashboxScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CashboxScreen> createState() => _CashboxScreenState();
}

class _CashboxScreenState extends ConsumerState<CashboxScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'bn_BD', symbol: '৳');
  final NumberFormat _compactFormat = NumberFormat.compact(locale: 'bn_BD');

  @override
  Widget build(BuildContext context) {
    final cashboxSummary = ref.watch(cashboxSummaryProvider);
    final recentTransactions = ref.watch(recentTransactionsProvider);
    final recentInstallments = ref.watch(recentInstallmentsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'ক্যাশবক্স সারাংশ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              ref.refresh(cashboxSummaryProvider);
              ref.refresh(recentTransactionsProvider);
              ref.refresh(recentInstallmentsProvider);
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: cashboxSummary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 60, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'তথ্য লোড করতে সমস্যা:\n$error',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref.refresh(cashboxSummaryProvider),
                child: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ),
        ),
        data: (summary) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(cashboxSummaryProvider);
              ref.refresh(recentTransactionsProvider);
              ref.refresh(recentInstallmentsProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header Balance Card
                  _buildBalanceCard(summary),

                  const SizedBox(height: 20),

                  // Quick Stats
                  _buildQuickStats(summary),

                  const SizedBox(height: 20),

                  // Financial Overview
                  _buildFinancialOverview(summary),

                  const SizedBox(height: 20),

                  // Recent Activity
                  _buildRecentActivity(recentTransactions, recentInstallments),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ... Keep all the existing methods (_buildBalanceCard, _buildBalanceItem,
  // _buildQuickStats, _buildStatCard, _buildFinancialOverview, _buildFinancialRow)
  // exactly the same as before ...

  Widget _buildRecentActivity(
      AsyncValue<List<TransactionModel>> transactions,
      AsyncValue<List<InstallmentTransaction>> installments,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;

        if (isWideScreen) {
          // Horizontal layout for wide screens
          return Row(
            children: [
              Expanded(child: _buildRecentTransactions(transactions)),
              const SizedBox(width: 16),
              Expanded(child: _buildRecentInstallments(installments)),
            ],
          );
        } else {
          // Vertical layout for mobile screens
          return Column(
            children: [
              _buildRecentTransactions(transactions),
              const SizedBox(height: 16),
              _buildRecentInstallments(installments),
            ],
          );
        }
      },
    );
  }

  Widget _buildRecentTransactions(AsyncValue<List<TransactionModel>> transactions) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'সাম্প্রতিক লেনদেন',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          transactions.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'লেনদেন লোড করতে সমস্যা',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
            data: (transactions) {
              if (transactions.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'কোন লেনদেন নেই',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }
              return Column(
                children: transactions.map((transaction) => _buildTransactionItem(transaction)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInstallments(AsyncValue<List<InstallmentTransaction>> installments) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'সাম্প্রতিক কিস্তি',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          installments.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'কিস্তি লোড করতে সমস্যা',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
            data: (installments) {
              if (installments.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'কোন কিস্তি নেই',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }
              return Column(
                children: installments.map((installment) => _buildInstallmentItem(installment)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: transaction.transactionType == 'savings'
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              transaction.transactionType == 'savings' ? Icons.arrow_downward : Icons.arrow_upward,
              color: transaction.transactionType == 'savings' ? Colors.green : Colors.red,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.memberName,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('MMM dd').format(transaction.transactionDate),
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            _currencyFormat.format(transaction.amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: transaction.transactionType == 'savings' ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentItem(InstallmentTransaction installment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.payment, color: Colors.blue, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${installment.numberOfInstallments} কিস্তি',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                ),
                Text(
                  DateFormat('MMM dd').format(installment.paymentDate),
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            _currencyFormat.format(installment.amount),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBalanceCard(CashboxSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[700]!, Colors.blue[900]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'বর্তমান ব্যালেন্স',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(summary.currentBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBalanceItem('মোট সঞ্চয়', summary.totalSavings, Icons.savings),
              _buildBalanceItem('মোট উত্তোলন', summary.totalWithdrawals, Icons.money_off),
              _buildBalanceItem('ঋণ আদায়', summary.totalLoanCollected, Icons.payments),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, double amount, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          _currencyFormat.format(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(CashboxSummary summary) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'সদস্য',
            '${summary.totalMembers}',
            Icons.people,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'সক্রিয় ঋণ',
            '${summary.activeLoans}',
            Icons.account_balance_wallet,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'সম্পন্ন ঋণ',
            '${summary.completedLoans}',
            Icons.check_circle,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialOverview(CashboxSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'আর্থিক সারাংশ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFinancialRow('মোট ঋণ প্রদান', summary.totalLoanGiven, Icons.credit_card),
          _buildFinancialRow('ঋণ বাকি', summary.totalLoanPending, Icons.pending_actions),
          _buildFinancialRow('ঋণ আদায়', summary.totalLoanCollected, Icons.payment),
          _buildFinancialRow('মোট সঞ্চয়', summary.totalSavings, Icons.savings),
          _buildFinancialRow('মোট উত্তোলন', summary.totalWithdrawals, Icons.money_off),
          const SizedBox(height: 8),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 8),
          _buildFinancialRow('নিট ব্যালেন্স', summary.currentBalance, Icons.account_balance,
              isTotal: true),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, double amount, IconData icon, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: isTotal ? Colors.green : Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.green : Colors.black87,
              ),
            ),
          ),
          Text(
            _currencyFormat.format(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isTotal ? Colors.green : Colors.blue,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }


}