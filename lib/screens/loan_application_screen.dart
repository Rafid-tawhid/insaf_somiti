import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/loan_model.dart';
import '../models/members.dart';
import '../providers/loan_provider.dart';
import '../providers/member_providers.dart';
import '../service/service_class.dart';
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
  // Controllers
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _installmentController = TextEditingController();
  final _installmentCountController = TextEditingController();
  final _interestController = TextEditingController();

  // Formatters
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'bn_BD', symbol: '৳');

  // State variables
  Member? _member;
  String _selectedLoanType = 'মাসিক';
  double _totalPayable = 0;
  double _totalInterest = 0;
  bool _showCalculation = false;
  bool _hasNomineeError = false;
  bool _isLoadingMember = false;

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _amountController.dispose();
    _purposeController.dispose();
    _installmentController.dispose();
    _installmentCountController.dispose();
    _interestController.dispose();
  }

  Future<void> _loadMemberData() async {
    try {
      setState(() => _isLoadingMember = true);
      final member = await ref.read(firebaseServiceProvider).getMemberById(widget.memberId);

      _checkNomineeInfo(member);
      setState(() => _member = member);
    } catch (e) {
      _showError('সদস্য তথ্য লোড করতে সমস্যা: $e');
    } finally {
      setState(() => _isLoadingMember = false);
    }
  }

  void _checkNomineeInfo(Member member) {
    final hasNomineeInfo = member.nomineeName.isNotEmpty &&
        member.nomineeMobile.isNotEmpty &&
        member.nomineeNationalId.isNotEmpty;

    setState(() => _hasNomineeError = !hasNomineeInfo);

    if (_hasNomineeError) {
      _showWarning('সদস্যের নামিনির তথ্য অনুপস্থিত। প্রথমে নামিনির তথ্য যোগ করুন।');
    }
  }

  // Validation Methods
  bool _validateForm() {
    if (_member == null) {
      _showError('সদস্য তথ্য পাওয়া যায়নি');
      return false;
    }

    if (_hasNomineeError) {
      _showError('প্রথমে নামিনির তথ্য যোগ করুন');
      return false;
    }

    if (!_showCalculation) {
      _showError('দয়া করে প্রথমে গণনা করুন');
      return false;
    }

    final loanAmount = double.tryParse(_amountController.text) ?? 0.0;
    final installmentAmount = double.tryParse(_installmentController.text) ?? 0.0;
    final installmentCount = int.tryParse(_installmentCountController.text) ?? 0;

    if (loanAmount <= 0) {
      _showError('দয়া করে সঠিক ঋণের পরিমাণ লিখুন');
      return false;
    }

    if (installmentAmount <= 0) {
      _showError('দয়া করে সঠিক কিস্তির পরিমাণ লিখুন');
      return false;
    }

    if (installmentCount <= 0) {
      _showError('দয়া করে সঠিক কিস্তির সংখ্যা লিখুন');
      return false;
    }

    return true;
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

    _totalInterest = (loanAmount * interestRate) / 100;
    _totalPayable = loanAmount + _totalInterest;

    setState(() => _showCalculation = true);
  }

  Future<void> _submitLoan() async {
    if (!_validateForm()) return;

    try {
      ref.read(loanFormProvider.notifier).setLoading(true);

      final loan = Loan(
        memberId: widget.memberId,
        memberName: _member!.memberName,
        memberNumber: _member!.memberNumber,
        memberMobile: _member!.memberMobile,
        loanAmount: double.parse(_amountController.text),
        interestRate: double.parse(_interestController.text),
        tenureNumber: int.parse(_installmentCountController.text),
        loanPurpose: _purposeController.text,
        loanDate: DateTime.now(),
        totalPayable: _totalPayable,
        installmentAmount: double.parse(_installmentController.text),
        remainingBalance: _totalPayable,
        loanType: _getInstallmentType(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentTenureNumber: 0,
      );

      await ref.read(firebaseServiceProvider).addLoan(loan);
      _resetForm();
      _showSuccess('ঋণ সফলভাবে যোগ করা হয়েছে!');
    } catch (e) {
      _showError('ত্রুটি: $e');
    } finally {
      ref.read(loanFormProvider.notifier).setLoading(false);
    }
  }

  void _resetForm() {
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
  }

  // Helper Methods
  String _getInstallmentLabel() {
    switch (_selectedLoanType) {
      case 'দৈনিক': return 'দৈনিক কিস্তি';
      case 'সাপ্তাহিক': return 'সাপ্তাহিক কিস্তি';
      case 'মাসিক': return 'মাসিক কিস্তি';
      default: return 'কিস্তি';
    }
  }

  String _getInstallmentType() {
    switch (_selectedLoanType) {
      case 'দৈনিক': return 'Daily';
      case 'সাপ্তাহিক': return 'Weekly';
      case 'মাসিক': return 'Monthly';
      default: return 'Daily';
    }
  }

  // UI Helper Methods
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

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToHistory() {
    final service = FirebaseService();
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => CombinedHistoryScreen(
          memberId: _member?.id ?? '',
          transactionStream: service.getAllTransactionsById(_member?.id ?? ''),
          loanStream: service.getLoansById(_member?.id ?? ''),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loanState = ref.watch(loanFormProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoadingMember
          ? const Center(child: CircularProgressIndicator())
          : _member == null
          ? const Center(child: Text('সদস্য পাওয়া যায়নি'))
          : _buildBody(loanState),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
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
    );
  }

  Widget _buildBody(LoanFormState loanState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMemberCard(),
          const SizedBox(height: 20),
          _buildLoanDetailsSection(),
          const SizedBox(height: 20),
          if (_showCalculation) _buildCalculationCard(),
          const SizedBox(height: 30),
          if (!_hasNomineeError) _buildSubmitButton(loanState),
        ],
      ),
    );
  }

  Widget _buildMemberCard() {
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
          _buildMemberCardHeader(),
          const SizedBox(height: 12),
          _buildMemberInfo(),
          if (_hasNomineeError) _buildNomineeWarning(),
        ],
      ),
    );
  }

  Widget _buildMemberCardHeader() {
    return Row(
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
          onPressed: _navigateToHistory,
          icon: const Icon(Icons.info, color: Colors.green),
        ),
      ],
    );
  }

  Widget _buildMemberInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('নাম: ${_member!.memberName}'),
        Text('সদস্য নং: ${_member!.memberNumber}'),
        Text('মোবাইল: ${_member!.memberMobile}'),
      ],
    );
  }

  Widget _buildNomineeWarning() {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 18),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'সদস্যের নামিনির তথ্য অনুপস্থিত। প্রথমে নামিনির তথ্য যোগ করুন।',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanDetailsSection() {
    return _buildSectionCard(
      title: 'ঋণের বিবরণ',
      icon: Icons.money,
      children: [
        _buildAmountField(),
        const SizedBox(height: 16),
        _buildLoanTypeDropdown(),
        const SizedBox(height: 16),
        _buildInstallmentField(),
        const SizedBox(height: 16),
        _buildInstallmentCountField(),
        const SizedBox(height: 16),
        _buildInterestField(),
        const SizedBox(height: 16),
        _buildCalculateButton(),
        const SizedBox(height: 16),
        _buildPurposeField(),
      ],
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'ঋণের পরিমাণ',
        hintText: 'ঋণের পরিমাণ লিখুন',
        border: OutlineInputBorder(),
        suffixText: 'টাকা',
      ),
    );
  }

  Widget _buildLoanTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            items: ['দৈনিক', 'সাপ্তাহিক', 'মাসিক'].map((value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() => _selectedLoanType = newValue!);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInstallmentField() {
    return TextField(
      controller: _installmentController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: _getInstallmentLabel(),
        hintText: 'কিস্তির পরিমাণ লিখুন',
        border: const OutlineInputBorder(),
        suffixText: 'টাকা',
      ),
    );
  }

  Widget _buildInstallmentCountField() {
    return TextField(
      controller: _installmentCountController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'কিস্তির সংখ্যা',
        hintText: 'মোট কতটি কিস্তি দিবেন',
        border: OutlineInputBorder(),
        suffixText: 'টি',
      ),
    );
  }

  Widget _buildInterestField() {
    return TextField(
      controller: _interestController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'সুদ হার (%)',
        hintText: 'সুদের হার লিখুন',
        border: OutlineInputBorder(),
        suffixText: '%',
      ),
    );
  }

  Widget _buildCalculateButton() {
    return SizedBox(
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
    );
  }

  Widget _buildPurposeField() {
    return TextField(
      controller: _purposeController,
      decoration: const InputDecoration(
        labelText: 'ঋণের উদ্দেশ্য',
        hintText: 'ঋণ কী কাজে ব্যবহার হবে',
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
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
          _buildCalculationHeader(),
          const SizedBox(height: 12),
          _buildCalculationRow('ঋণের পরিমাণ', _currencyFormat.format(loanAmount)),
          _buildCalculationRow('${_getInstallmentLabel()} পরিমাণ', _currencyFormat.format(installmentAmount)),
          _buildCalculationRow('কিস্তির সংখ্যা', '$installmentCount টি'),
          _buildCalculationRow('সুদ হার', '${_interestController.text}%'),
          _buildCalculationRow('মোট সুদ', _currencyFormat.format(_totalInterest)),
          _buildCalculationRow('মোট পরিমাণ', _currencyFormat.format(installmentCount * installmentAmount)),
          const SizedBox(height: 4),
          _buildCalculationRow('মোট প্রদেয়', _currencyFormat.format(_totalPayable)),
          const SizedBox(height: 8),
          _buildTotalSummary(installmentCount),
        ],
      ),
    );
  }

  Widget _buildCalculationHeader() {
    return Row(
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
    );
  }

  Widget _buildTotalSummary(int installmentCount) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'মোট $installmentCountটি কিস্তিতে মোট ${_currencyFormat.format(_totalPayable)} প্রদেয় হবে',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
        textAlign: TextAlign.center,
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

  Widget _buildSubmitButton(LoanFormState loanState) {
    return SizedBox(
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