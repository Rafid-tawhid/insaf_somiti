import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../service/savings_service_class.dart';
import '../models/members.dart';
import '../models/transaction_model.dart';
import 'member_providers.dart';


// Provider for savings form state
final savingsFormProvider = StateNotifierProvider<SavingsFormNotifier, SavingsFormState>((ref) {
  return SavingsFormNotifier();
});

class SavingsFormState {
  final Member? selectedMember;
  final double amount;
  final String notes;
  final bool isLoading;
  final TransactionModel? editingTransaction;

  SavingsFormState({
    this.selectedMember,
    this.amount = 0.0,
    this.notes = '',
    this.isLoading = false,
    this.editingTransaction,
  });

  SavingsFormState copyWith({
    Member? selectedMember,
    double? amount,
    String? notes,
    bool? isLoading,
    TransactionModel? editingTransaction,
  }) {
    return SavingsFormState(
      selectedMember: selectedMember ?? this.selectedMember,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      editingTransaction: editingTransaction ?? this.editingTransaction,
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

  void setEditingTransaction(TransactionModel transaction) {
    state = state.copyWith(
      editingTransaction: transaction,
      amount: transaction.amount,
      notes: transaction.notes ?? '',
    );
  }

  void clearEditingTransaction() {
    state = state.copyWith(
      editingTransaction: null,
      amount: 0.0,
      notes: '',
    );
  }

  void resetForm() {
    state = SavingsFormState();
  }
}

// Edit Transaction Provider
final editTransactionProvider = StateNotifierProvider<EditTransactionNotifier, EditTransactionState>((ref) {
  return EditTransactionNotifier(ref);
});

class EditTransactionNotifier extends StateNotifier<EditTransactionState> {
  final Ref _ref;

  EditTransactionNotifier(this._ref) : super(EditTransactionState.initial());

  Future<void> updateTransaction({
    required String memberId,
    required String transactionId,
    required double newAmount,
    String? notes,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        loadingTransactionId: transactionId,
      );

      final savingsService = SavingsServiceClass();

      await savingsService.updateTransaction(
        memberId: memberId,
        transactionId: transactionId,
        newAmount: newAmount,
        newNotes: notes,
      );

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        loadingTransactionId: null,
      );

      // Reset success after a delay
      Future.delayed(const Duration(seconds: 2), () {
        state = state.copyWith(isSuccess: false);
      });

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update transaction: $e',
        loadingTransactionId: null,
      );
    }
  }

  void reset() {
    state = EditTransactionState.initial();
  }
}

class EditTransactionState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final String? loadingTransactionId;

  EditTransactionState({
    required this.isLoading,
    required this.isSuccess,
    this.errorMessage,
    this.loadingTransactionId,
  });

  factory EditTransactionState.initial() => EditTransactionState(
    isLoading: false,
    isSuccess: false,
    errorMessage: null,
    loadingTransactionId: null,
  );

  EditTransactionState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    String? loadingTransactionId,
  }) {
    return EditTransactionState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      loadingTransactionId: loadingTransactionId ?? this.loadingTransactionId,
    );
  }
}

// Delete Transaction Provider
final deleteTransactionProvider = StateNotifierProvider<DeleteTransactionNotifier, DeleteTransactionState>((ref) {
  return DeleteTransactionNotifier(ref);
});

class DeleteTransactionNotifier extends StateNotifier<DeleteTransactionState> {
  final Ref _ref;

  DeleteTransactionNotifier(this._ref) : super(DeleteTransactionState.initial());

  Future<void> deleteTransaction({
    required String memberId,
    required String transactionId,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        loadingTransactionId: transactionId,
      );

      final savingsService = SavingsServiceClass();

      await savingsService.deleteTransaction(
        memberId: memberId,
        transactionId: transactionId,
      );

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        loadingTransactionId: null,
      );

      // Reset success after a delay
      Future.delayed(const Duration(seconds: 2), () {
        state = state.copyWith(isSuccess: false);
      });

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete transaction: $e',
        loadingTransactionId: null,
      );
    }
  }

  void reset() {
    state = DeleteTransactionState.initial();
  }
}

class DeleteTransactionState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final String? loadingTransactionId;

  DeleteTransactionState({
    required this.isLoading,
    required this.isSuccess,
    this.errorMessage,
    this.loadingTransactionId,
  });

  factory DeleteTransactionState.initial() => DeleteTransactionState(
    isLoading: false,
    isSuccess: false,
    errorMessage: null,
    loadingTransactionId: null,
  );

  DeleteTransactionState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    String? loadingTransactionId,
  }) {
    return DeleteTransactionState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      loadingTransactionId: loadingTransactionId ?? this.loadingTransactionId,
    );
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
final transactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getAllTransactions();
});