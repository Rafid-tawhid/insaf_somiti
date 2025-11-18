import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction_filter.dart';
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

  // Default to today
  String _selectedReport = 'today';

  @override
  Widget build(BuildContext context) {
    // Watch both providers
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final loansAsync = ref.watch(loansProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'রিপোর্ট',
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

          // Report Content (Combined List)
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
              title: 'মোট সঞ্চয় জমা',
              icon: Icons.savings,
              color: Colors.green,
              asyncValue: transactionsAsync,
              // Assuming transactions are pre-filtered by the provider
              valueExtractor: (transactions) {
                final total = transactions.fold<double>(0, (sum, transaction) => sum + transaction.amount);
                return _currencyFormat.format(total);
              },
            ),
          ),
          const SizedBox(width: 12),
          // Total Loans (Need to filter locally if provider returns all)
          Expanded(
            child: _buildSummaryCard(
              title: 'মোট ঋণ প্রদান',
              icon: Icons.credit_card,
              color: Colors.orange,
              asyncValue: loansAsync,
              valueExtractor: (loans) {
                final filteredLoans = _filterLoans(loans);
                final total = filteredLoans.fold<double>(0, (sum, loan) => sum + loan.loanAmount);
                return _currencyFormat.format(total);
              },
              countExtractor: (loans) => _filterLoans(loans).length,
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
    int Function(List<dynamic>)? countExtractor,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: asyncValue.when(
          data: (data) {
            final count = countExtractor != null ? countExtractor(data) : data.length;
            return Column(
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
                      count.toString(),
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
            );
          },
          loading: () => const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
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
          // Final Money Calculation (Net Balance)
          _buildFinalMoneyCard(transactionsAsync, loansAsync),

          const SizedBox(height: 16),

          // Combined Activity List Title
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'লেনদেন এবং ঋণ বিবরণ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Combined List
          Expanded(
            child: _buildCombinedActivityList(transactionsAsync, loansAsync),
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
              // Filter loans based on selected tab before calculating
              final filteredLoans = _filterLoans(loans);

              final totalSavings = transactions.fold<double>(0, (sum, transaction) => sum + transaction.amount);
              final totalLoans = filteredLoans.fold<double>(0, (sum, loan) => sum + loan.loanAmount);

              // Net Balance calculation
              final finalMoney = totalSavings - totalLoans;

              return Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.purple[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'নিট ক্যাশ',
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
                          Text('জমা (আয়)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      Container(height: 30, width: 1, color: Colors.grey[300]),
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
                          Text('ঋণ (ব্যয়)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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

  Widget _buildCombinedActivityList(AsyncValue<List<dynamic>> transactionsAsync, AsyncValue<List<dynamic>> loansAsync) {
    if (transactionsAsync.isLoading || loansAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transactionsAsync.hasError || loansAsync.hasError) {
      return _buildErrorState('ডেটা লোড করতে সমস্যা হয়েছে');
    }

    final transactions = transactionsAsync.value ?? [];
    final loans = loansAsync.value ?? [];

    // 1. Filter Loans
    final filteredLoans = _filterLoans(loans);

    // 2. Merge Data
    final List<Map<String, dynamic>> combinedList = [];

    for (var t in transactions) {
      combinedList.add({
        'type': 'transaction',
        'date': t.transactionDate,
        'data': t,
      });
    }

    for (var l in filteredLoans) {
      combinedList.add({
        'type': 'loan',
        'date': l.loanDate, // Assuming your loan model has loanDate
        'data': l,
      });
    }

    // 3. Sort by Date Descending
    combinedList.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    if (combinedList.isEmpty) {
      return _buildEmptyState('কোন লেনদেন বা ঋণ পাওয়া যায়নি');
    }

    return ListView.builder(
      itemCount: combinedList.length,
      itemBuilder: (context, index) {
        final item = combinedList[index];
        if (item['type'] == 'transaction') {
          return _buildTransactionCard(item['data']);
        } else {
          return _buildLoanCard(item['data']);
        }
      },
    );
  }

  Widget _buildTransactionCard(dynamic transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Colors.green[50],
          child: Icon(Icons.savings, color: Colors.green[700], size: 20),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                transaction.memberName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _currencyFormat.format(transaction.amount),
              style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'সঞ্চয় জমা',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              _dateFormat.format(transaction.transactionDate),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanCard(dynamic loan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Colors.orange[50],
          child: Icon(Icons.credit_card, color: Colors.orange[700], size: 20),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                loan.memberName, // Assuming Loan model has memberName
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _currencyFormat.format(loan.loanAmount),
              style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ঋণ প্রদান',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              _dateFormat.format(loan.loanDate),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
          Icon(Icons.receipt_long, color: Colors.grey[300], size: 60),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
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
          Icon(Icons.error_outline, color: Colors.red[300], size: 60),
          const SizedBox(height: 12),
          Text(
            error,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // --- Helper Logic for Loans Filtering ---

  List<dynamic> _filterLoans(List<dynamic> allLoans) {
    final now = DateTime.now();

    return allLoans.where((loan) {
      final DateTime date = loan.loanDate;

      if (_selectedReport == 'today') {
        return date.year == now.year && date.month == now.month && date.day == now.day;
      } else if (_selectedReport == 'monthly') {
        return date.year == now.year && date.month == now.month;
      } else {
        return true; // 'full'
      }
    }).toList();
  }
}