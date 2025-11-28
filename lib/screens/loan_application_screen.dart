import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:insaf_somiti/screens/profile_entry_screen.dart';
import 'package:insaf_somiti/screens/savings_screen.dart';
import 'package:intl/intl.dart';
import '../models/loan_model.dart';
import '../models/members.dart';
import '../providers/loan_provider.dart';
import '../providers/member_providers.dart';
import '../service/service_class.dart';
import '../widgets/search_screen.dart';
import 'member_transaction_info_list.dart';


class LoanApplicationScreen extends ConsumerStatefulWidget {
  final String memberId;

  const LoanApplicationScreen({
    Key? key,
    required this.memberId,
  }) : super(key: key);

  @override
  ConsumerState<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends ConsumerState<LoanApplicationScreen> {
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _installmentController = TextEditingController();
  final _installmentCountController = TextEditingController();
  final _interestController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'bn_BD', symbol: '৳');
  Member? _member;
  String _selectedLoanType = 'মাসিক'; // দৈনিক, সাপ্তাহিক, মাসিক

  // Calculation results
  double _totalPayable = 0;
  double _totalInterest = 0;
  bool _showCalculation = false;

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    _installmentController.dispose();
    _installmentCountController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _loadMemberData() async {
    try {
      final member = await ref.read(firebaseServiceProvider).getMemberById(widget.memberId);
      setState(() {
        _member = member;
      });
    } catch (e) {
      _showError('সদস্য তথ্য লোড করতে সমস্যা: $e');
    }
  }

  void _calculateLoan() {
    final loanAmount = double.tryParse(_amountController.text) ?? 0.0;
    final installmentAmount = double.tryParse(_installmentController.text) ?? 0.0;
    final installmentCount = int.tryParse(_installmentCountController.text) ?? 0;
    final interestRate = double.tryParse(_interestController.text) ?? 0.0;

    if (loanAmount <= 0 || installmentCount <= 0 || interestRate < 0) {
      _showError('দয়া করে সকল তথ্য সঠিকভাবে পূরণ করুন');
      return;
    }

    // Calculate interest and total payable
    _totalInterest = (loanAmount * interestRate) / 100;
    _totalPayable = loanAmount + _totalInterest;

    setState(() {
      _showCalculation = true;
    });
  }

  Future<void> _submitLoan() async {
    if (_member == null) {
      _showError('সদস্য তথ্য পাওয়া যায়নি');
      return;
    }

    if (!_showCalculation) {
      _showError('দয়া করে প্রথমে গণনা করুন');
      return;
    }

    final loanAmount = double.tryParse(_amountController.text) ?? 0.0;
    final installmentAmount = double.tryParse(_installmentController.text) ?? 0.0;
    final installmentCount = int.tryParse(_installmentCountController.text) ?? 0;
    final interestRate = double.tryParse(_interestController.text) ?? 0.0;

    if (loanAmount <= 0) {
      _showError('দয়া করে সঠিক ঋণের পরিমাণ লিখুন');
      return;
    }

    if (installmentAmount <= 0) {
      _showError('দয়া করে সঠিক কিস্তির পরিমাণ লিখুন');
      return;
    }

    if (installmentCount <= 0) {
      _showError('দয়া করে সঠিক কিস্তির সংখ্যা লিখুন');
      return;
    }

    try {
      ref.read(loanFormProvider.notifier).setLoading(true);

      final loan = Loan(
        memberId: widget.memberId,
        memberName: _member!.memberName,
        memberNumber: _member!.memberNumber,
        memberMobile: _member!.memberMobile,
        loanAmount: loanAmount,
        interestRate: interestRate,
        tenureNumber: installmentCount,
        loanPurpose: _purposeController.text,
        loanDate: DateTime.now(),
        totalPayable: _totalPayable,
        installmentAmount: installmentAmount,
        remainingBalance: _totalPayable,
        // loanType: _selectedLoanType,
        // installmentAmount: installmentAmount,
        // totalInstallments: installmentCount,
        createdAt: DateTime.now(),
        currentTenureNumber: 0,
      );

      await ref.read(firebaseServiceProvider).addLoan(loan);

      // Reset form
      _amountController.clear();
      _purposeController.clear();
      _installmentController.clear();
      _installmentCountController.clear();
      _interestController.clear();

      setState(() {
        _showCalculation = false;
        _totalPayable = 0;
        _totalInterest = 0;
      });

      _showSuccess('ঋণ সফলভাবে যোগ করা হয়েছে!');
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
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
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
          'ঋণ প্রদান',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _member == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Member Card
            _buildMemberCard(_member!),

            const SizedBox(height: 20),

            // Loan Details
            _buildSectionCard(
              title: 'ঋণের বিবরণ',
              icon: Icons.money,
              children: [
                CustomTextField(
                  label: 'ঋণের পরিমাণ',
                  hintText: 'ঋণের পরিমাণ লিখুন',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                ),

                const SizedBox(height: 16),

                // Loan Type Dropdown
                const Text(
                  'ঋণের ধরন',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedLoanType,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ['দৈনিক', 'সাপ্তাহিক', 'মাসিক']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedLoanType = newValue!;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Installment Amount
                TextField(
                  controller: _installmentController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _getInstallmentLabel(),
                    hintText: 'কিস্তির পরিমাণ লিখুন',
                    border: const OutlineInputBorder(),
                    suffixText: 'টাকা',
                  ),
                ),

                const SizedBox(height: 16),

                // Number of Installments
                TextField(
                  controller: _installmentCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'কিস্তির সংখ্যা',
                    hintText: 'মোট কতটি কিস্তি দিবেন',
                    border: OutlineInputBorder(),
                    suffixText: 'টি',
                  ),
                ),

                const SizedBox(height: 16),

                // Interest Rate
                TextField(
                  controller: _interestController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'সুদ হার (%)',
                    hintText: 'সুদের হার লিখুন',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                  ),
                ),

                const SizedBox(height: 16),

                // Calculate Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _calculateLoan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.calculate, color: Colors.white),
                    label: const Text(
                      'গণনা করুন',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                CustomTextField(
                  label: 'ঋণের উদ্দেশ্য',
                  hintText: 'ঋণ কী কাজে ব্যবহার হবে',
                  controller: _purposeController,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Loan Calculation Preview
            if (_showCalculation)
              _buildCalculationCard(),

            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: loanState.isLoading ? null : _submitLoan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: loanState.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'ঋণ সংরক্ষণ করুন',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInstallmentLabel() {
    switch (_selectedLoanType) {
      case 'দৈনিক':
        return 'দৈনিক কিস্তি';
      case 'সাপ্তাহিক':
        return 'সাপ্তাহিক কিস্তি';
      case 'মাসিক':
        return 'মাসিক কিস্তি';
      default:
        return 'কিস্তি';
    }
  }

  Widget _buildMemberCard(Member member) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'সদস্য তথ্য',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  final service = FirebaseService();
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => CombinedHistoryScreen(
                        memberId: member.id ?? '',
                        transactionStream: service.getAllTransactionsById(member.id ?? ''),
                        loanStream: service.getLoansById(member.id ?? ''),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.info, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('নাম: ${member.memberName}'),
          Text('সদস্য নং: ${member.memberNumber}'),
          Text('মোবাইল: ${member.memberMobile}'),
        ],
      ),
    );
  }

  Widget _buildCalculationCard() {
    final loanAmount = double.tryParse(_amountController.text) ?? 0.0;
    final installmentAmount = double.tryParse(_installmentController.text) ?? 0.0;
    final installmentCount = int.tryParse(_installmentCountController.text) ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                'গণনা প্রিভিউ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCalculationRow('ঋণের পরিমাণ', _currencyFormat.format(loanAmount)),
          _buildCalculationRow('${_getInstallmentLabel()} পরিমাণ', _currencyFormat.format(installmentAmount)),
          _buildCalculationRow('কিস্তির সংখ্যা', '$installmentCount টি'),
          _buildCalculationRow('সুদ হার', '${_interestController.text}%'),
          _buildCalculationRow('মোট সুদ', _currencyFormat.format(_totalInterest)),
          _buildCalculationRow('মোট পরিমাণ', _currencyFormat.format(installmentCount*installmentAmount)),
          SizedBox(height: 4,),
          _buildCalculationRow('মোট প্রদেয়', _currencyFormat.format(_totalPayable)),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'মোট ${installmentCount}টি কিস্তিতে মোট ${_currencyFormat.format(_totalPayable)} প্রদেয় হবে',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.orange[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}