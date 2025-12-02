import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/loan_installment.dart';
import '../models/loan_model.dart';
import '../models/members.dart';
import '../providers/loan_provider.dart';
import '../providers/member_providers.dart';
import '../service/service_class.dart';

class SimpleInstallmentScreen extends ConsumerStatefulWidget {
  final String memberId;

  const SimpleInstallmentScreen({
    Key? key,
    required this.memberId,
  }) : super(key: key);

  @override
  ConsumerState<SimpleInstallmentScreen> createState() => _SimpleInstallmentScreenState();
}

class _SimpleInstallmentScreenState extends ConsumerState<SimpleInstallmentScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'bn_BD', symbol: '৳');
  final TextEditingController _amountController = TextEditingController();

  Member? _member;
  List<Loan> _loans = [];
  List<InstallmentTransaction> _transactions = [];
  bool _isLoading = true;
  Loan? _selectedLoan;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final member = await ref.read(firebaseServiceProvider).getMemberById(widget.memberId);
      final loans = await ref.read(firebaseServiceProvider).getLoansByMemberId(widget.memberId);

      final activeLoans = loans.where((loan) => loan.status == 'active').toList();

      setState(() {
        _member = member;
        _loans = activeLoans;
        _selectedLoan = activeLoans.isNotEmpty ? activeLoans.first : null;
      });

      // Load transactions if loan exists
      if (_selectedLoan != null && _selectedLoan!.id != null) {
        await _loadTransactionsForLoan(_selectedLoan!);
      }

      // Auto-fill amount with installment amount if only one loan
      if (activeLoans.length == 1) {
        _amountController.text = activeLoans.first.installmentAmount.toStringAsFixed(0);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _showError('তথ্য লোড করতে সমস্যা: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTransactionsForLoan(Loan loan) async {
    try {
      final transactions = await ref.read(firebaseServiceProvider)
          .getInstallmentTransactionsByLoanId(loan.id!);
      setState(() {
        _transactions = transactions;
      });
    } catch (e) {
      print('Error loading transactions: $e');
    }
  }

  Future<void> _submitPayment() async {
    if (_selectedLoan == null) {
      _showError('দয়া করে একটি ঋণ নির্বাচন করুন');
      return;
    }

    final paymentAmount = double.tryParse(_amountController.text) ?? 0.0;

    if (paymentAmount <= 0) {
      _showError('দয়া করে সঠিক পরিমাণ লিখুন');
      return;
    }

    if (paymentAmount > _selectedLoan!.remainingBalance) {
      _showError('পরিশোধের পরিমাণ বাকি টাকার বেশি হতে পারবে না');
      return;
    }

    try {
      ref.read(loanFormProvider.notifier).setLoading(true);

      // Calculate how many full installments this payment covers
      final double installmentAmount = _selectedLoan!.installmentAmount;
      final int fullInstallmentsCovered = (paymentAmount / installmentAmount).floor();
      final double remainingAmount = paymentAmount - (fullInstallmentsCovered * installmentAmount);

      // Update loan details
      int newCurrentTenure = _selectedLoan!.currentTenureNumber + fullInstallmentsCovered;
      double newTotalPaid = _selectedLoan!.totalPaid + paymentAmount;
      double newRemainingBalance = _selectedLoan!.remainingBalance - paymentAmount;

      String newStatus = newRemainingBalance <= 0 ? 'completed' : 'active';

      // Update loan
      final updatedLoan = Loan(
        id: _selectedLoan!.id,
        memberId: _selectedLoan!.memberId,
        memberName: _selectedLoan!.memberName,
        memberNumber: _selectedLoan!.memberNumber,
        memberMobile: _selectedLoan!.memberMobile,
        loanAmount: _selectedLoan!.loanAmount,
        interestRate: _selectedLoan!.interestRate,
        tenureNumber: _selectedLoan!.tenureNumber,
        currentTenureNumber: newCurrentTenure,
        loanPurpose: _selectedLoan!.loanPurpose,
        loanDate: _selectedLoan!.loanDate,
        status: newStatus,
        totalPayable: _selectedLoan!.totalPayable,
        installmentAmount: _selectedLoan!.installmentAmount,
        remainingBalance: newRemainingBalance,
        totalPaid: newTotalPaid,
        createdAt: _selectedLoan!.createdAt,
        loanType: _selectedLoan!.loanType,
      );

      // Create transaction record
      final transaction = InstallmentTransaction(
        loanId: _selectedLoan!.id!,
        memberId: widget.memberId,
        amount: paymentAmount,
        numberOfInstallments: fullInstallmentsCovered + (remainingAmount > 0 ? 1 : 0),
        paymentDate: DateTime.now(),
        paymentMethod: 'cash',
        note: '',
        createdAt: DateTime.now(),
      );

      // Save to Firebase
      await ref.read(firebaseServiceProvider).updateLoan(updatedLoan);
      await ref.read(firebaseServiceProvider).addInstallmentTransaction(transaction);

      _showSuccess('কিস্তি সফলভাবে জমা দেওয়া হয়েছে!');

      // Reset and reload
      _amountController.clear();
      if (_selectedLoan != null) {
        _amountController.text = _selectedLoan!.installmentAmount.toStringAsFixed(0);
      }
      await _loadData();

    } catch (e) {
      _showError('ত্রুটি: $e');
    } finally {
      ref.read(loanFormProvider.notifier).setLoading(false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loanState = ref.watch(loanFormProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'ঋণ কিস্তি জমা',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _member == null
          ? const Center(child: Text('সদস্যের তথ্য পাওয়া যায়নি'))
          : _loans.isEmpty
          ? _buildNoLoansView()
          : SingleChildScrollView( // Wrap with SingleChildScrollView
        child: Column(
          children: [
            // Payment Section
            _buildPaymentSection(loanState.isLoading),

            // Transactions List
            _buildTransactionsList(),
          ],
        ),
      ),
    );
  }

  Widget  _buildPaymentSection(bool isLoading) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member Info
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green[100],
                child: Icon(Icons.person, color: Colors.green[700]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _member!.memberName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'সদস্য নং: ${_member!.memberNumber}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Loan Summary
          if (_selectedLoan != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'বাকি আছে: ${_currencyFormat.format(_selectedLoan!.remainingBalance)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'কিস্তি: ${_currencyFormat.format(_selectedLoan!.installmentAmount)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_selectedLoan!.currentTenureNumber}/${_selectedLoan!.tenureNumber} কিস্তি',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 60,
                        child: LinearProgressIndicator(
                          value: _selectedLoan!.totalPaid / _selectedLoan!.totalPayable,
                          backgroundColor: Colors.grey[300],
                          color: Colors.green,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Amount Input
          const Text(
            'কিস্তির পরিমাণ',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'টাকার পরিমাণ লিখুন',
              border: const OutlineInputBorder(),
              suffixText: 'টাকা',
              prefixIcon: const Icon(Icons.attach_money),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
          ),

          const SizedBox(height: 16),

          // Quick Amount Buttons
          if (_selectedLoan != null) ...[
            const Text(
              'দ্রুত নির্বাচন:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 100,
                  child: OutlinedButton(
                    onPressed: () {
                      _amountController.text = _selectedLoan!.installmentAmount.toStringAsFixed(0);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('১ কিস্তি', style: TextStyle(fontSize: 12)),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: OutlinedButton(
                    onPressed: () {
                      _amountController.text = (_selectedLoan!.installmentAmount * 2).toStringAsFixed(0);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('২ কিস্তি', style: TextStyle(fontSize: 12)),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: OutlinedButton(
                    onPressed: () {
                      _amountController.text = _selectedLoan!.remainingBalance.toStringAsFixed(0);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('সম্পূর্ণ', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : _submitPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'কিস্তি জমা দিন',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.history, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'কিস্তির হিস্ট্রি',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_transactions.length}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 300, // Limit the height of transaction list
            ),
            child: _transactions.isEmpty
                ? _buildEmptyTransactions()
                : ListView.builder(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final transaction = _transactions[index];
                return _buildTransactionItem(transaction, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(InstallmentTransaction transaction, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.payment,
            color: Colors.green[700],
            size: 20,
          ),
        ),
        title: Text(
          _currencyFormat.format(transaction.amount),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${transaction.numberOfInstallments} কিস্তি',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              DateFormat('dd MMM yyyy - hh:mm a').format(transaction.paymentDate),
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 50,
            color: Colors.grey,
          ),
          SizedBox(height: 12),
          Text(
            'কোন কিস্তি জমা দেওয়া হয়নি',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoLoansView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.money_off,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'কোন সক্রিয় ঋণ নেই',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}