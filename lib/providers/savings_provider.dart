


import 'package:flutter_riverpod/legacy.dart';

import '../models/members.dart';
import '../models/transaction_model.dart';
import 'member_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for savings form state
final savingsFormProvider = StateNotifierProvider<SavingsFormNotifier, SavingsFormState>((ref) {
  return SavingsFormNotifier();
});

class SavingsFormState {
  final Member? selectedMember;
  final double amount;
  final String notes;
  final bool isLoading;

  SavingsFormState({
    this.selectedMember,
    this.amount = 0.0,
    this.notes = '',
    this.isLoading = false,
  });

  SavingsFormState copyWith({
    Member? selectedMember,
    double? amount,
    String? notes,
    bool? isLoading,
  }) {
    return SavingsFormState(
      selectedMember: selectedMember ?? this.selectedMember,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SavingsFormNotifier extends StateNotifier<SavingsFormState> {
  SavingsFormNotifier() : super(SavingsFormState());

  void selectMember(Member member) {
    state = state.copyWith(selectedMember: member);
  }

  void updateAmount(double amount) {
    state = state.copyWith(amount: amount);
  }

  void updateNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void resetForm() {
    state = SavingsFormState();
  }
}

// Provider for member search
final memberSearchQueryProvider = StateProvider<String>((ref) => '');

final searchedMembersProvider = StreamProvider<List<Member>>((ref) {
  final searchQuery = ref.watch(memberSearchQueryProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.searchMembers(searchQuery);
});

// Provider for transactions
final transactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getAllTransactions();
});


