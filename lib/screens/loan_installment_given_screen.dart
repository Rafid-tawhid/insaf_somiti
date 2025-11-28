// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
// import '../models/loan_model.dart';
// import '../models/loan_installment.dart';
// import '../providers/member_providers.dart';
// import '../service/service_class.dart';
//
// class LoanInstallmentScreen extends ConsumerStatefulWidget {
//   final String loanId;
//   final Loan? loan; // Make loan optional
//
//   const LoanInstallmentScreen({
//     Key? key,
//     required this.loanId,
//     this.loan, // Can be null initially
//   }) : super(key: key);
//
//   @override
//   ConsumerState<LoanInstallmentScreen> createState() => _LoanInstallmentScreenState();
// }
//
// class _LoanInstallmentScreenState extends ConsumerState<LoanInstallmentScreen> {
//   final _amountController = TextEditingController();
//   final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'bn_BD', symbol: '৳');
//
//   Loan? _loan;
//   List<LoanInstallment> _installments = [];
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }
//
//   Future<void> _loadData() async {
//     try {
//       // If loan object wasn't passed, load it from Firestore
//       if (widget.loan == null) {
//         _loan = await ref.read(firebaseServiceProvider).getLoanById(widget.loanId);
//       } else {
//         _loan = widget.loan;
//       }
//
//       // Load installments
//       final installments = await ref.read(firebaseServiceProvider).getLoanInstallments(widget.loanId);
//       setState(() {
//         _installments = installments;
//       });
//     } catch (e) {
//       _showError('ডেটা লোড করতে সমস্যা: $e');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _submitInstallment() async {
//     if (_loan == null) {
//       _showError('ঋণের তথ্য পাওয়া যায়নি');
//       return;
//     }
//
//     final amount = double.tryParse(_amountController.text) ?? 0.0;
//
//     if (amount <= 0) {
//       _showError('দয়া করে সঠিক পরিমাণ লিখুন');
//       return;
//     }
//
//     if (amount > _loan!.remainingBalance) {
//       _showError('পরিশোধের পরিমাণ বাকি টাকার চেয়ে বেশি হতে পারবে না');
//       return;
//     }
//
//     try {
//       setState(() {
//         _isLoading = true;
//       });
//
//       // Calculate new values
//       final newRemainingBalance = _loan!.remainingBalance - amount;
//       final newCurrentTenure = _loan!.currentTenureNumber + 1;
//       final newTotalPaid = _loan!.totalPaid + amount;
//       final newStatus = newRemainingBalance <= 0 ? 'completed' : 'active';
//
//       // Create new installment
//       final installment = LoanInstallment(
//         loanId: widget.loanId,
//         memberId: _loan!.memberId,
//         memberName: _loan!.memberName,
//         memberNumber: _loan!.memberNumber,
//         memberMobile: _loan!.memberMobile,
//         amount: amount,
//         installmentNumber: newCurrentTenure,
//         paymentDate: DateTime.now(),
//         previousBalance: _loan!.remainingBalance,
//         remainingBalance: newRemainingBalance,
//         createdAt: DateTime.now(),
//       );
//
//       // Add installment to Firestore
//       await ref.read(firebaseServiceProvider).addLoanInstallment(installment);
//
//       // Update loan details
//       final updatedLoan = _loan!.copyWith(
//         remainingBalance: newRemainingBalance,
//         currentTenureNumber: newCurrentTenure,
//         totalPaid: newTotalPaid,
//         status: newStatus,
//       );
//
//       await ref.read(firebaseServiceProvider).updateLoan(updatedLoan);
//
//       // Clear form and reload data
//       _amountController.clear();
//       await _loadData();
//
//       _showSuccess('কিস্তি সফলভাবে সংরক্ষণ করা হয়েছে!');
//
//       if (newStatus == 'completed') {
//         _showCompletionDialog();
//       }
//     } catch (e) {
//       _showError('ত্রুটি: $e');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   void _showCompletionDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('অভিনন্দন!'),
//         content: const Text('ঋণটি সম্পূর্ণরূপে পরিশোধিত হয়েছে।'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('ঠিক আছে'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showSuccess(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     if (_loan == null) {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text('ত্রুটি'),
//         ),
//         body: const Center(
//           child: Text('ঋণের তথ্য পাওয়া যায়নি'),
//         ),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('ঋণের কিস্তি প্রদান'),
//         backgroundColor: Colors.blue[700],
//       ),
//       body: Column(
//         children: [
//           // Loan Summary
//           _buildLoanSummaryCard(),
//
//           // Payment Form
//           if (_loan!.status == 'active') _buildPaymentForm(),
//
//           // Installments List
//           Expanded(
//             child: _buildInstallmentsList(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLoanSummaryCard() {
//     final isCompleted = _loan!.status == 'completed';
//
//     return Card(
//       margin: const EdgeInsets.all(16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               _loan!.memberName,
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             Text('মোবাইল: ${_loan!.memberMobile}'),
//             const SizedBox(height: 10),
//             _buildSummaryRow('মোট ঋণ', _currencyFormat.format(_loan!.loanAmount)),
//             _buildSummaryRow('বাকি আছে', _currencyFormat.format(_loan!.remainingBalance)),
//             _buildSummaryRow('কিস্তি সংখ্যা', '${_loan!.currentTenureNumber}/${_loan!.tenureNumber}'),
//             if (isCompleted)
//               const Text(
//                 '✅ ঋণ সম্পূর্ণ পরিশোধিত',
//                 style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSummaryRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label),
//           Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPaymentForm() {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             TextField(
//               controller: _amountController,
//               keyboardType: TextInputType.number,
//               decoration: InputDecoration(
//                 labelText: 'কিস্তির পরিমাণ',
//                 hintText: 'সর্বোচ্চ ${_currencyFormat.format(_loan!.remainingBalance)}',
//               ),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _isLoading ? null : _submitInstallment,
//               child: _isLoading
//                   ? const CircularProgressIndicator()
//                   : const Text('কিস্তি জমা দিন'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInstallmentsList() {
//     if (_installments.isEmpty) {
//       return const Center(
//         child: Text('কোন কিস্তি পাওয়া যায়নি'),
//       );
//     }
//
//     return ListView.builder(
//       itemCount: _installments.length,
//       itemBuilder: (context, index) {
//         final installment = _installments[index];
//         return ListTile(
//           leading: CircleAvatar(
//             child: Text('${installment.installmentNumber}'),
//           ),
//           title: Text(_currencyFormat.format(installment.amount)),
//           subtitle: Text(DateFormat('dd MMM yyyy').format(installment.paymentDate)),
//           trailing: Text('বাকি: ${_currencyFormat.format(installment.remainingBalance)}'),
//         );
//       },
//     );
//   }
// }