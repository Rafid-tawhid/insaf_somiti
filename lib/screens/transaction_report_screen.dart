import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction_filter.dart';
import '../providers/loan_provider.dart';
import '../providers/transaction_report_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/loan_provider.dart';
import '../providers/transaction_report_provider.dart';

class CombinedReportScreen extends ConsumerStatefulWidget {
  const CombinedReportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CombinedReportScreen> createState() => _CombinedReportScreenState();
}

class _CombinedReportScreenState extends ConsumerState<CombinedReportScreen> {
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'bn_BD', symbol: '৳');
  String _selectedReport = 'today'; // 'today', 'monthly', 'full'

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final loansAsync = ref.watch(loansProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'আজকের রিপোর্ট',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.purple[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Report Type Selector
          _buildReportSelector(),

          // Summary Cards
          _buildSummaryCards(transactionsAsync, loansAsync),

          // Report Content
          Expanded(
            child: _buildReportContent(transactionsAsync, loansAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildReportButton('আজকের', 'today'),
          _buildReportButton('মাসিক', 'monthly'),
          _buildReportButton('সম্পূর্ণ', 'full'),
        ],
      ),
    );
  }

  Widget _buildReportButton(String text, String value) {
    final isSelected = _selectedReport == value;
    return Expanded(
      child: Material(
        color: isSelected ? Colors.purple[700] : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            setState(() => _selectedReport = value);
            // Update transaction filters
            ref.read(transactionFiltersProvider.notifier).state =
                TransactionFilters(filterType: value);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(AsyncValue<List<dynamic>> transactionsAsync, AsyncValue<List<dynamic>> loansAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Total Savings
          Expanded(
            child: _buildSummaryCard(
              title: 'মোট সঞ্চয়',
              icon: Icons.savings,
              color: Colors.green,
              asyncValue: transactionsAsync,
              valueExtractor: (transactions) {
                final total = transactions.fold<double>(0, (sum, transaction) => sum + transaction.amount);
                return _currencyFormat.format(total);
              },
            ),
          ),
          const SizedBox(width: 12),
          // Total Loans
          Expanded(
            child: _buildSummaryCard(
              title: 'মোট ঋণ',
              icon: Icons.credit_card,
              color: Colors.orange,
              asyncValue: loansAsync,
              valueExtractor: (loans) {
                final total = loans.fold<double>(0, (sum, loan) => sum + loan.loanAmount);
                return _currencyFormat.format(total);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required IconData icon,
    required Color color,
    required AsyncValue<List<dynamic>> asyncValue,
    required String Function(List<dynamic>) valueExtractor,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: asyncValue.when(
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    data.length.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                valueExtractor(data),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error', style: TextStyle(color: Colors.red[300])),
        ),
      ),
    );
  }

  Widget _buildReportContent(AsyncValue<List<dynamic>> transactionsAsync, AsyncValue<List<dynamic>> loansAsync) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Final Money Calculation
          _buildFinalMoneyCard(transactionsAsync, loansAsync),

          const SizedBox(height: 16),

          // Transactions List
          Expanded(
            child: _buildTransactionsList(transactionsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalMoneyCard(AsyncValue<List<dynamic>> transactionsAsync, AsyncValue<List<dynamic>> loansAsync) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: transactionsAsync.when(
          data: (transactions) => loansAsync.when(
            data: (loans) {
              final totalSavings = transactions.fold<double>(0, (sum, transaction) => sum + transaction.amount);
              final totalLoans = loans.fold<double>(0, (sum, loan) => sum + loan.loanAmount);
              final finalMoney = totalSavings - totalLoans;

              return Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.purple[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'নিট ব্যালেন্স',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currencyFormat.format(finalMoney),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: finalMoney >= 0 ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            _currencyFormat.format(totalSavings),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          Text(
                            'মোট সঞ্চয়',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            _currencyFormat.format(totalLoans),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                          Text(
                            'মোট ঋণ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('Error: $error'),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(AsyncValue<List<dynamic>> transactionsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'সঞ্চয় লেনদেন',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return _buildEmptyState('কোন লেনদেন নেই');
              }

              return ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return _buildTransactionCard(transaction);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorState(error.toString()),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    transaction.memberName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _currencyFormat.format(transaction.amount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transaction.memberNumber,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  _dateFormat.format(transaction.transactionDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, color: Colors.grey[400], size: 48),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red[300], size: 48),
          const SizedBox(height: 8),
          Text(
            'ত্রুটি হয়েছে',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}