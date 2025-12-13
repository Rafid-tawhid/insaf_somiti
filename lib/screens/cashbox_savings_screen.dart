// screens/simple_cash_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:insaf_somiti/models/daily_savings_summary.dart';
import 'package:intl/intl.dart';
import '../models/savings_summary_model.dart';
import '../providers/cashbox_savings_provider.dart';

// screens/simple_cash_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SimpleCashDashboard extends ConsumerStatefulWidget {
  const SimpleCashDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<SimpleCashDashboard> createState() => _SimpleCashDashboardState();
}

class _SimpleCashDashboardState extends ConsumerState<SimpleCashDashboard> {
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'bn_BD', symbol: '৳');
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _daysToShow = 7; // Default show last 7 days

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cashSummary = ref.watch(simpleCashSummaryProvider);
    final dailySummaries = ref.watch(dailySummariesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'ক্যাশ ড্যাশবোর্ড',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[800],
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAddCostDialog(),
            icon: const Icon(Icons.add, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              ref.refresh(simpleCashSummaryProvider);
              ref.refresh(dailySummariesProvider);
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCostDialog(),
        backgroundColor: Colors.green[800],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: cashSummary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'তথ্য লোড করতে সমস্যা',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref.refresh(simpleCashSummaryProvider),
                child: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ),
        ),
        data: (summary) => RefreshIndicator(
          onRefresh: () async {
            ref.refresh(simpleCashSummaryProvider);
            ref.refresh(dailySummariesProvider);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Overall Summary Card
                _buildOverallSummaryCard(summary),

                const SizedBox(height: 20),

                // Daily Summaries Section
                _buildDailySummariesSection(dailySummaries),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverallSummaryCard(SimpleCashSummary summary) {
    final bool isPositive = summary.netBalance >= 0;
    final Color cardColor = isPositive ? Colors.green[800]! : Colors.red[800]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'সর্বমোট সারাংশ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('dd MMMM yyyy').format(DateTime.now()),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _currencyFormat.format(summary.netBalance.abs()),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary.netBalance >= 0 ? 'নিট ব্যালেন্স' : 'নিট ঘাটতি',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverallStat('সঞ্চয়', summary.totalSavings, Icons.savings, Colors.green),
              _buildOverallStat('উত্তোলন', summary.totalWithdrawals, Icons.money_off, Colors.red),
              _buildOverallStat('খরচ', summary.totalGeneralCost, Icons.receipt, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStat(String label, double amount, IconData icon, Color iconColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          _currencyFormat.format(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildDailySummariesSection(AsyncValue<List<DailySummary>> summaries) {
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
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'দৈনিক সারাংশ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              PopupMenuButton<int>(
                icon: const Icon(Icons.filter_list, color: Colors.green),
                onSelected: (value) {
                  setState(() {
                    _daysToShow = value;
                  });
                  // Refresh with new days count
                  ref.refresh(dailySummariesProvider);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 7,
                    child: Text('সাপ্তাহিক (৭ দিন)'),
                  ),
                  const PopupMenuItem(
                    value: 30,
                    child: Text('মাসিক (৩০ দিন)'),
                  ),
                  const PopupMenuItem(
                    value: 90,
                    child: Text('ত্রৈমাসিক (৯০ দিন)'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          summaries.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'দৈনিক তথ্য লোড করতে সমস্যা',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            data: (summaries) {
              if (summaries.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.inbox, color: Colors.grey, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'কোন দৈনিক তথ্য নেই',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Calculate totals for the period
              double periodSavings = 0;
              double periodWithdrawals = 0;
              double periodCosts = 0;
              double periodNet = 0;

              for (var summary in summaries) {
                periodSavings += summary.savings;
                periodWithdrawals += summary.withdrawals;
                periodCosts += summary.generalCosts;
                periodNet += summary.netBalance;
              }

              return Column(
                children: [
                  // Period Summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPeriodStat('সর্বমোট সঞ্চয়', periodSavings, Colors.green),
                        _buildPeriodStat('সর্বমোট খরচ', periodWithdrawals + periodCosts, Colors.red),
                        _buildPeriodStat('নিট', periodNet, periodNet >= 0 ? Colors.green : Colors.red),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Daily Summaries List
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: summaries.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final summary = summaries[index];
                      return _buildDailySummaryItem(summary);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodStat(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _currencyFormat.format(amount),
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDailySummaryItem(DailySummary summary) {
    final bool isToday = summary.date.day == DateTime.now().day &&
        summary.date.month == DateTime.now().month &&
        summary.date.year == DateTime.now().year;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isToday ? Colors.blue[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? Colors.blue[100]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          // Date Row
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: isToday ? Colors.blue : Colors.grey[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  summary.date.toString(),
                  style: TextStyle(
                    color: isToday ? Colors.blue : Colors.grey[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                summary.formattedDate,
                style: TextStyle(
                  color: isToday ? Colors.blue : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3-Column Summary
          Row(
            children: [
              // Column 1: Savings
              Expanded(
                child: _buildDailyColumn(
                  label: 'সঞ্চয়',
                  amount: summary.savings,
                  icon: Icons.arrow_downward,
                  color: Colors.green,
                  isPositive: true,
                ),
              ),

              // Column 2: Expenses
              Expanded(
                child: _buildDailyColumn(
                  label: 'খরচ',
                  amount: summary.expenses,
                  icon: Icons.arrow_upward,
                  color: Colors.red,
                  isPositive: false,
                ),
              ),

              // Column 3: Net
              Expanded(
                child: _buildDailyColumn(
                  label: 'নিট',
                  amount: summary.netBalance,
                  icon: summary.netBalance >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: summary.netBalance >= 0 ? Colors.green : Colors.red,
                  isPositive: summary.netBalance >= 0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Breakdown Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDailyBreakdownItem('উত্তোলন', summary.withdrawals, Icons.money_off),
              _buildDailyBreakdownItem('সাধারণ', summary.generalCosts, Icons.receipt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyColumn({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
    required bool isPositive,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _currencyFormat.format(amount.abs()),
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyBreakdownItem(String label, double amount, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[500], size: 12),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          _currencyFormat.format(amount),
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showAddCostDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('সাধারণ খরচ যোগ করুন'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'খরচের পরিমাণ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.money),
                      hintText: 'টাকার পরিমাণ লিখুন',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'খরচের বিবরণ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                      hintText: 'খরচের বিবরণ লিখুন',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _selectedDate = pickedDate;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'তারিখ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(DateFormat('dd MMMM, yyyy').format(_selectedDate)),
                          ),
                          const Icon(Icons.calendar_month, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('বাতিল'),
              ),
              ElevatedButton(
                onPressed: () => _addGeneralCost(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                ),
                child: const Text('খরচ যোগ করুন'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addGeneralCost(BuildContext context) async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('খরচের পরিমাণ লিখুন')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সঠিক পরিমাণ লিখুন')),
      );
      return;
    }

    if (_noteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('খরচের বিবরণ লিখুন')),
      );
      return;
    }

    try {
      final service = ref.read(cashboxServiceProvider);
      await service.addGeneralCost(
        amount: amount,
        note: _noteController.text,
        date: _selectedDate,
      );

      // Clear fields
      _amountController.clear();
      _noteController.clear();
      _selectedDate = DateTime.now();

      // Close dialog
      Navigator.pop(context);

      // Refresh data
      ref.refresh(simpleCashSummaryProvider);
      ref.refresh(dailyCombinedActivityProvider);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('খরচ সফলভাবে যোগ হয়েছে'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('খরচ যোগ করতে সমস্যা: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



}