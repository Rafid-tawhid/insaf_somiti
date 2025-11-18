import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

// Assuming these models exist in your project
import '../models/loan_model.dart';
import '../models/transaction_model.dart';
import 'package:insaf_somiti/widgets/total_calculation.dart'; // Keep your existing import

// 1. Create a Data Class to hold all calculated data
class HistoryData {
  final List<Transaction> allTransactions;
  final List<Loan> allLoans;
  final List<CombinedItem> allItems;
  final FinancialCalculations calculations;

  HistoryData({
    required this.allTransactions,
    required this.allLoans,
    required this.allItems,
    required this.calculations,
  });
}

class CombinedHistoryScreen extends StatefulWidget {
  final String memberId;
  final Stream<List<Transaction>> transactionStream;
  final Stream<List<Loan>> loanStream;

  const CombinedHistoryScreen({
    Key? key,
    required this.memberId,
    required this.transactionStream,
    required this.loanStream,
  }) : super(key: key);

  @override
  State<CombinedHistoryScreen> createState() => _CombinedHistoryScreenState();
}

class _CombinedHistoryScreenState extends State<CombinedHistoryScreen> {
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _timeFormat = DateFormat('hh:mm a');
  final DateFormat _dayFormat = DateFormat('EEEE');

  int _selectedSegment = 0;
  final List<String> _segments = ['All', 'Transactions', 'Loans'];

  // Store the stream here so it doesn't recreate on setState
  late Stream<HistoryData> _combinedStream;

  @override
  void initState() {
    super.initState();
    _combinedStream = _createCombinedStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Activity History'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      // ONE StreamBuilder for the whole page
      body: StreamBuilder<HistoryData>(
        stream: _combinedStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingWidget();
          }

          if (!snapshot.hasData) {
            return _buildEmptyWidget();
          }

          final data = snapshot.data!;

          return Column(
            children: [
              // Financial Summary (Uses calculated data directly)
              FinancialSummaryWidget(
                calculations: data.calculations,
              ),

              // Segment Control
              _buildSegmentControl(),
              const SizedBox(height: 16),

              // Filtered List
              Expanded(
                child: _buildTimelineList(data.allItems),
              ),
            ],
          );
        },
      ),
    );
  }

  Stream<HistoryData> _createCombinedStream() {
    return CombineLatestStream.combine2(
      widget.transactionStream,
      widget.loanStream,
          (List<Transaction> transactions, List<Loan> loans) {
        // Process everything at once here

        // 1. Calculate Items
        final combinedItems = <CombinedItem>[];
        for (final t in transactions) {
          combinedItems.add(CombinedItem(
            date: t.transactionDate,
            type: ItemType.transaction,
            transaction: t,
          ));
        }
        for (final l in loans) {
          combinedItems.add(CombinedItem(
            date: l.loanDate,
            type: ItemType.loan,
            loan: l,
          ));
        }
        // Sort descending (newest first)
        combinedItems.sort((a, b) => b.date.compareTo(a.date));

        // 2. Calculate Financials
        final calculations = _calculateFinancials(transactions, loans);

        return HistoryData(
          allTransactions: transactions,
          allLoans: loans,
          allItems: combinedItems,
          calculations: calculations,
        );
      },
    );
  }

  FinancialCalculations _calculateFinancials(List<Transaction> transactions, List<Loan> loans) {
    double totalSavings = transactions
        .where((t) => t.transactionType.toLowerCase() == 'savings')
        .fold(0.0, (sum, t) => sum + t.amount);

    final activeLoans = loans.where((l) => l.status == 'active').toList();

    double totalActiveLoanPrincipal = activeLoans
        .fold(0.0, (sum, l) => sum + l.loanAmount);

    double totalActiveLoansPayable = activeLoans
        .fold(0.0, (sum, l) => sum + l.totalPayable);

    double totalLoanInterest = activeLoans
        .fold(0.0, (sum, l) => sum + (l.totalPayable - l.loanAmount));

    double netPosition = totalSavings - totalActiveLoansPayable;

    return FinancialCalculations(
      totalSavings: totalSavings,
      totalActiveLoanPrincipal: totalActiveLoanPrincipal,
      totalLoanInterest: totalLoanInterest,
      totalActiveLoans: totalActiveLoansPayable,
      netFinancialPosition: netPosition,
    );
  }

  Widget _buildSegmentControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(_segments.length, (index) {
          final isSelected = _selectedSegment == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSegment = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[700] : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                      : [],
                ),
                child: Text(
                  _segments[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimelineList(List<CombinedItem> allItems) {
    // Filter based on state selection
    final filteredItems = allItems.where((item) {
      switch (_selectedSegment) {
        case 1: return item.type == ItemType.transaction;
        case 2: return item.type == ItemType.loan;
        default: return true;
      }
    }).toList();

    if (filteredItems.isEmpty) {
      return _buildEmptyFilteredWidget();
    }

    // Use AnimatedSwitcher for smooth transition when filtering
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: ListView.builder(
        key: ValueKey<int>(_selectedSegment), // Forces rebuild animation on tab change
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          final isSameDayAsPrevious = index > 0 &&
              _isSameDay(item.date, filteredItems[index - 1].date);

          return Column(
            children: [
              if (!isSameDayAsPrevious) _buildDateHeader(item.date),
              const SizedBox(height: 8),
              _buildTimelineItem(item),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  // ... [Keep your existing _buildDateHeader, _buildTimelineItem,
  //      _buildTransactionItem, _buildLoanItem, helpers, etc. exactly as they were] ...

  // Re-pasting helper widgets for completeness just in case
  Widget _buildDateHeader(DateTime date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _dateFormat.format(date),
            style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold),
          ),
          Text(_dayFormat.format(date), style: TextStyle(color: Colors.blue[700], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(CombinedItem item) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Stack(
        children: [
          Positioned(left: -12, top: 0, bottom: 0, child: Container(width: 2, color: Colors.grey[200])),
          Padding(
            padding: const EdgeInsets.all(16),
            child: item.type == ItemType.transaction
                ? _buildTransactionItem(item.transaction!)
                : _buildLoanItem(item.loan!),
          ),
        ],
      ),
    );
  }

  // KEEP: _buildTransactionItem, _buildLoanItem, _getItemColor, _getStatusColor, _isSameDay
  // KEEP: _buildLoadingWidget, _buildEmptyWidget, _buildErrorWidget, _formatTransactionType

  Widget _buildTransactionItem(Transaction transaction) {
    final isCredit = transaction.transactionType.toLowerCase() == 'savings';
    final color = isCredit ? Colors.green : Colors.red;
    final sign = isCredit ? '+' : '-';

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatTransactionType(transaction.transactionType), style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('$sign₹${transaction.amount.toStringAsFixed(2)}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Balance: ₹${transaction.balanceAfter.toStringAsFixed(2)} • ${_timeFormat.format(transaction.transactionDate)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoanItem(Loan loan) {
    final color = loan.status == 'active' ? Colors.orange : Colors.purple;
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(Icons.credit_card, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Loan Activity', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('₹${loan.loanAmount.toStringAsFixed(2)}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${loan.status.toUpperCase()} • ${loan.tenureMonths} Months',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getItemColor(CombinedItem item) {
    if (item.type == ItemType.transaction) {
      return item.transaction!.transactionType.toLowerCase() == 'savings' ? Colors.green : Colors.red;
    }
    return item.loan!.status == 'active' ? Colors.orange : Colors.purple;
  }

  Color _getStatusColor(String status) {
    return status == 'active' ? Colors.orange : Colors.green;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Widget _buildLoadingWidget() => const Center(child: CircularProgressIndicator());
  Widget _buildEmptyWidget() => const Center(child: Text('No data available'));
  Widget _buildErrorWidget(String e) => Center(child: Text('Error: $e'));
  String _formatTransactionType(String s) => s; // Add your formatter logic

  Widget _buildEmptyFilteredWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No items in this category', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

// --- UPDATED FinancialSummaryWidget ---
// Modified to accept calculations directly
class FinancialSummaryWidget extends StatelessWidget {
  final FinancialCalculations calculations;

  const FinancialSummaryWidget({
    Key? key,
    required this.calculations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[800]!, Colors.blue[600]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.white.withOpacity(0.9)),
              const SizedBox(width: 8),
              Text(
                'Financial Summary',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildSummaryCard(title: 'Total Savings', amount: calculations.totalSavings, icon: Icons.savings, color: Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard(title: 'Active Loans', amount: calculations.totalActiveLoans, icon: Icons.credit_card, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSummaryCard(title: 'Interest', amount: calculations.totalLoanInterest, icon: Icons.percent, color: Colors.red)),
              const SizedBox(width: 12),
              Expanded(child: _buildNetPositionCard(calculations)),
            ],
          ),
        ],
      ),
    );
  }

  // Keep your existing _buildSummaryCard and _buildNetPositionCard logic
  Widget _buildSummaryCard({required String title, required double amount, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 4), Text(title, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12))]),
          const SizedBox(height: 6),
          Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNetPositionCard(FinancialCalculations calc) {
    final isPositive = calc.netFinancialPosition >= 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: (isPositive ? Colors.green : Colors.red).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.trending_up, size: 16, color: isPositive ? Colors.green : Colors.red), const SizedBox(width: 4), Text('Net', style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontSize: 12))]),
          const SizedBox(height: 6),
          Text('₹${calc.netFinancialPosition.abs().toStringAsFixed(0)}', style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Keep Data Classes
class FinancialCalculations {
  final double totalSavings;
  final double totalActiveLoanPrincipal;
  final double totalLoanInterest;
  final double totalActiveLoans;
  final double netFinancialPosition;

  FinancialCalculations({
    required this.totalSavings,
    required this.totalActiveLoanPrincipal,
    required this.totalLoanInterest,
    required this.totalActiveLoans,
    required this.netFinancialPosition,
  });
}

enum ItemType { transaction, loan }

class CombinedItem {
  final DateTime date;
  final ItemType type;
  final Transaction? transaction;
  final Loan? loan;

  CombinedItem({required this.date, required this.type, this.transaction, this.loan});
}