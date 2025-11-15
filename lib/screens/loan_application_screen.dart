import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:insaf_somiti/screens/profile_entry_screen.dart';
import 'package:insaf_somiti/screens/savings_screen.dart';
import 'package:intl/intl.dart';
import '../models/loan_model.dart';
import '../models/members.dart';
import '../providers/loan_provider.dart';
import '../providers/member_providers.dart';

class LoanApplicationScreen extends ConsumerStatefulWidget {
  const LoanApplicationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends ConsumerState<LoanApplicationScreen> {
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'bn_BD', symbol: '৳');

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }



  Future<void> _submitLoan() async {
    final loanState = ref.read(loanFormProvider);
    final member = loanState.selectedMember;

    if (member == null) {
      _showError('দয়া করে একজন সদস্য নির্বাচন করুন');
      return;
    }

    if (loanState.loanAmount <= 0) {
      _showError('দয়া করে সঠিক ঋণের পরিমাণ লিখুন');
      return;
    }

    try {
      ref.read(loanFormProvider.notifier).setLoading(true);

      final calculation = ref.read(firebaseServiceProvider).calculateLoan(
        loanState.loanAmount,
        loanState.interestRate,
        loanState.tenureMonths,
      );

      final loan = Loan(
        memberId: member.id!,
        memberName: member.memberName,
        memberNumber: member.memberNumber,
        memberMobile: member.memberMobile,
        loanAmount: loanState.loanAmount,
        interestRate: loanState.interestRate,
        tenureMonths: loanState.tenureMonths,
        loanPurpose: loanState.loanPurpose,
        loanDate: DateTime.now(),
        totalPayable: calculation['totalPayable']!,
        monthlyInstallment: calculation['monthlyInstallment']!,
        remainingBalance: calculation['totalPayable']!,
        createdAt: DateTime.now(),
      );

      await ref.read(firebaseServiceProvider).addLoan(loan);

      // Reset form
      ref.read(loanFormProvider.notifier).resetForm();
      _amountController.clear();
      _purposeController.clear();

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
    final selectedMember = loanState.selectedMember;
    final calculation = ref.read(firebaseServiceProvider).calculateLoan(
      loanState.loanAmount,
      loanState.interestRate,
      loanState.tenureMonths,
    );

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Selected Member Card
            if (selectedMember != null) _buildMemberCard(selectedMember),

            // Member Selection
            _buildSectionCard(
              title: 'সদস্য নির্বাচন',
              icon: Icons.person_search,
              children: [
                GestureDetector(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>MemberSearchDialog(
                      onMemberSelected: (member) {
                        ref.read(loanFormProvider.notifier).selectMember(member);
                        Navigator.pop(context);
                      },
                    )));
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.orange[700]),
                        const SizedBox(width: 12),
                        Text(
                          selectedMember != null
                              ? '${selectedMember.memberName} - ${selectedMember.memberNumber}'
                              : 'সদস্য খুঁজুন (নাম, নং বা মোবাইল দ্বারা)',
                          style: TextStyle(
                            color: selectedMember != null
                                ? Colors.black
                                : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

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
                  onChanged: (value) {
                    final amount = double.tryParse(value) ?? 0.0;
                    ref.read(loanFormProvider.notifier).updateLoanAmount(amount);
                  },
                  isRequired: true,
                ),

                const SizedBox(height: 16),
                const Text(
                  'সুদ হার (%)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: loanState.interestRate,
                  min: 5,
                  max: 20,
                  divisions: 15,
                  label: '${loanState.interestRate}%',
                  onChanged: (value) {
                    ref.read(loanFormProvider.notifier).updateInterestRate(value);
                  },
                ),
                Text(
                  '${loanState.interestRate}%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),
                const Text(
                  'ঋণের মেয়াদ (মাস)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: loanState.tenureMonths.toDouble(),
                  min: 1,
                  max: 36,
                  divisions: 35,
                  label: '${loanState.tenureMonths} মাস',
                  onChanged: (value) {
                    ref.read(loanFormProvider.notifier).updateTenure(value.toInt());
                  },
                ),
                Text(
                  '${loanState.tenureMonths} মাস',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                CustomTextField(
                  label: 'ঋণের উদ্দেশ্য',
                  hintText: 'ঋণ কী কাজে ব্যবহার হবে',
                  controller: _purposeController,
                  onChanged: (value) {
                    ref.read(loanFormProvider.notifier).updateLoanPurpose(value);
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Loan Calculation Card
            _buildCalculationCard(calculation),

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
                'নির্বাচিত সদস্য',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
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

  Widget _buildCalculationCard(Map<String, double> calculation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'গণনা ফলাফল',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCalculationRow('মোট প্রদেয়', _currencyFormat.format(calculation['totalPayable']!)),
          _buildCalculationRow('মাসিক কিস্তি', _currencyFormat.format(calculation['monthlyInstallment']!)),
          _buildCalculationRow('মোট সুদ', _currencyFormat.format(calculation['totalInterest']!)),
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