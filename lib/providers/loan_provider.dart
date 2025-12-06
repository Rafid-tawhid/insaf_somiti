import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:insaf_somiti/service/loan_service_class.dart';

import '../models/loan_model.dart';
import '../models/members.dart';
import 'member_providers.dart';


final loanFormProvider = StateNotifierProvider<LoanFormNotifier, LoanFormState>((ref) {
  return LoanFormNotifier();
});
//
class LoanFormState {
  final Member? selectedMember;
  final double loanAmount;
  final double interestRate;
  final int tenureMonths;
  final String loanPurpose;
  final bool isLoading;

  LoanFormState({
    this.selectedMember,
    this.loanAmount = 0.0,
    this.interestRate = 10.0,
    this.tenureMonths = 12,
    this.loanPurpose = '',
    this.isLoading = false,
  });

  LoanFormState copyWith({
    Member? selectedMember,
    double? loanAmount,
    double? interestRate,
    int? tenureMonths,
    String? loanPurpose,
    bool? isLoading,
  }) {
    return LoanFormState(
      selectedMember: selectedMember ?? this.selectedMember,
      loanAmount: loanAmount ?? this.loanAmount,
      interestRate: interestRate ?? this.interestRate,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      loanPurpose: loanPurpose ?? this.loanPurpose,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LoanFormNotifier extends StateNotifier<LoanFormState> {
  LoanFormNotifier() : super(LoanFormState());

  void selectMember(Member member) {
    state = state.copyWith(selectedMember: member);
  }

  void updateLoanAmount(double amount) {
    state = state.copyWith(loanAmount: amount);
  }

  void updateInterestRate(double rate) {
    state = state.copyWith(interestRate: rate);
  }

  void updateTenure(int months) {
    state = state.copyWith(tenureMonths: months);
  }

  void updateLoanPurpose(String purpose) {
    state = state.copyWith(loanPurpose: purpose);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void resetForm() {
    state = LoanFormState();
  }
}

final loansProvider = StreamProvider<List<Loan>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getLoans();
});




Future<Map<String,dynamic>> getMemberLoanInfoById(String memberId) {
  // This is a placeholder implementation.
  // Replace with actual logic to fetch transactions for the given memberId.
  final loanService = LoanServiceClass(); // Assume FirebaseService is defined elsewhere
  return loanService.getMemberLoanInfoById(memberId);
}
