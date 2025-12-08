import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/cupertino.dart';
import '../models/cashbox_summery.dart';
import '../models/loan_installment.dart';
import '../models/loan_model.dart';
import '../models/members.dart';
import '../models/transaction_filter.dart';
import '../models/transaction_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Existing methods for members...
  Future<void> addMember(Member member) async {
    try {
      await _firestore.collection('members').add(member.toMap());
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }
  Future<void> updateMember(dynamic member,String id) async {
    try {
      debugPrint('Updating member with ID: $id');
      await _firestore.collection('members').doc(id).update(member);
    } catch (e) {
      throw Exception('Failed to update member: $e');
    }
  }

  Stream<List<Member>> getMembers() {
    return _firestore
        .collection('members')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Member.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
  //
  // // NEW: Search members by name, ID, or phone
  // Stream<List<Member>> searchMembers(String query) {
  //   if (query.isEmpty) {
  //     return getMembers();
  //   }
  //
  //   return _firestore
  //       .collection('members')
  //       .where('memberName', isGreaterThanOrEqualTo: query)
  //       .where('memberName', isLessThan: query + 'z')
  //       .snapshots()
  //       .map((snapshot) {
  //     return snapshot.docs.map((doc) {
  //       return Member.fromMap(doc.id, doc.data());
  //     }).toList();
  //   });
  // }


  // In your FirebaseService class
  Stream<List<Member>> searchMembers(String query) {
    if (query.isEmpty) {
      // CHANGE THIS LINE - return getMembers() instead of Stream.empty()
      return getMembers(); // This will show all members when search is empty
    }

    // Convert query to lowercase for case-insensitive search
    final searchQuery = query.toLowerCase();

    return FirebaseFirestore.instance
        .collection('members')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Member.fromMap(doc.id, doc.data()))
        .where((member) =>
    member.memberName.toLowerCase().contains(searchQuery) ||
        member.memberNumber.toLowerCase().contains(searchQuery) ||
        member.memberMobile.contains(searchQuery))
        .toList());
  }

  // NEW: Add savings transaction
  Future<void> addSavings({
    required String memberId,
    required double amount,
    required String agentId,
    required String agentName,
    String? notes,
  }) async {
    try {
      // Get member details and current balance
      final member = await getMemberById(memberId);
      final transactions = await getAllTransactionsById(memberId).first;

      // Calculate current balance
      double currentBalance = 0;
      for (final transaction in transactions) {
        if (transaction.transactionType == 'savings') {
          currentBalance += transaction.amount;
          _firestore.collection('members').doc(memberId).update({
            'lastSavingsGiven': DateTime.now().millisecondsSinceEpoch,
          });
        } else if (transaction.transactionType == 'withdrawal') {
          currentBalance -= transaction.amount;
        }
      }

      // Calculate new balance after savings
      final newBalance = currentBalance + amount;

      // Create savings transaction
      final transaction = TransactionModel(
        memberId: memberId,
        memberName: member.memberName,
        memberNumber: member.memberNumber,
        memberMobile: member.memberMobile,
        transactionType: 'savings',
        amount: amount,
        balanceAfter: newBalance,
        agentId: agentId,
        agentName: agentName,
        notes: notes,
        transactionDate: DateTime.now(),
      );

      // Add to Firestore
      await _firestore.collection('transactions').add(transaction.toMap());

      // Update member's total savings
      await updateMemberSavings(memberId, newBalance);

    } catch (e) {
      throw Exception('সঞ্চয় যোগ করতে সমস্যা: $e');
    }
  }

  Future<void> updateMemberSavings(String memberId, double newBalance) async {
    try {
      await _firestore.collection('members').doc(memberId).update({
        'totalSavings': newBalance,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('সদস্যের ব্যালেন্স আপডেট করতে সমস্যা: $e');
    }
  }


  // NEW: Get all transactions
  Stream<List<TransactionModel>> getAllTransactions() {
    return _firestore
        .collection('transactions')
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }


  Stream<List<TransactionModel>> getAllTransactionsById(String id) {
    return _firestore
        .collection('transactions')
        .where('memberId', isEqualTo: id) // <-- Filter by ID field
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }



  // Add to your existing FirebaseService class



// Get transaction statistics
  Future<Map<String, dynamic>> getTransactionStats(TransactionFilters filters) async {
    final transactions = await getTransactionsWithFilters(filters).first;

    double totalAmount = 0;
    int transactionCount = transactions.length;
    Map<String, double> typeWiseTotal = {};

    for (var transaction in transactions) {
      totalAmount += transaction.amount;
      typeWiseTotal.update(
        transaction.transactionType,
            (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    return {
      'totalAmount': totalAmount,
      'transactionCount': transactionCount,
      'typeWiseTotal': typeWiseTotal,
      'averageAmount': transactionCount > 0 ? totalAmount / transactionCount : 0,
    };
  }


  // Add to your existing FirebaseService class

// Simple loan methods
  Future<void> addLoan(Loan loan) async {
    try {
      var id=_firestore.collection('loans').doc();
      var loanWithId=loan.copyWith(id: id.id);

      await _firestore.collection('loans').add(loanWithId.toMap());
      await _firestore.collection('members').doc(loan.memberId).update({
        'isLoanActive': true,
        'loanType': loan.loanType,
      });
    } catch (e) {
      throw Exception('Failed to add loan: $e');
    }
  }

  Stream<List<Loan>> getLoans() {
    return _firestore
        .collection('loans')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Loan.fromMap(doc.id, doc.data());
      }).toList();
    });
  }


  Stream<List<Loan>> getLoansById(String id) {
    return _firestore
        .collection('loans')
        .orderBy('createdAt', descending: true).where('memberId',isEqualTo: id)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Loan.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

// Simple loan calculation
  Map<String, double> calculateLoan(double amount, double interestRate, int months) {
    final monthlyRate = interestRate / 12 / 100;
    final totalPayable = amount * (1 + (monthlyRate * months));
    final monthlyInstallment = totalPayable / months;

    return {
      'totalPayable': totalPayable,
      'monthlyInstallment': monthlyInstallment,
      'totalInterest': totalPayable - amount,
    };
  }


  Stream<List<TransactionModel>> getTransactionsWithFilters(TransactionFilters filters) {
    CollectionReference transactionsRef = _firestore.collection('transactions');
    Query query = transactionsRef.orderBy('transactionDate', descending: true);

    final now = DateTime.now();

    switch (filters.filterType) {
      case 'today':
        final startOfDay = DateTime(now.year, now.month, now.day);
        query = query.where('transactionDate', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch);
        break;

      case 'monthly':
        final startOfMonth = DateTime(now.year, now.month, 1);
        query = query.where('transactionDate', isGreaterThanOrEqualTo: startOfMonth.millisecondsSinceEpoch);
        break;

      case 'full':
      // No date filter for full report
        break;
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }


  Future<void> addWithdrawal({
    required String memberId,
    required double amount,
    required String agentId,
    required String agentName,
    String? notes,
  }) async {
    try {
      // Get member details and current balance
      final member = await getMemberById(memberId);
      final transactions = await getAllTransactionsById(memberId).first;

      // Calculate current balance from transactions
      double currentBalance = 0;
      for (final transaction in transactions) {
        if (transaction.transactionType == 'savings') {
          currentBalance += transaction.amount;
        } else if (transaction.transactionType == 'withdrawal') {
          currentBalance -= transaction.amount;
        }
      }

      // Check if sufficient balance exists
      if (amount > currentBalance) {
        throw Exception('পর্যাপ্ত ব্যালেন্স নেই। বর্তমান ব্যালেন্স: ৳${currentBalance.toStringAsFixed(2)}');
      }

      // Calculate new balance after withdrawal
      final newBalance = currentBalance - amount;

      // Create withdrawal transaction
      final transaction = TransactionModel(
        memberId: memberId,
        memberName: member.memberName,
        memberNumber: member.memberNumber,
        memberMobile: member.memberMobile,
        transactionType: 'withdrawal',
        amount: amount,
        balanceAfter: newBalance,
        agentId: agentId,
        agentName: agentName,
        notes: notes,
        transactionDate: DateTime.now(),
      );

      // Add to Firestore
      await _firestore.collection('transactions').add(transaction.toMap());

      // Update member's total savings
      await updateMemberSavings(memberId, newBalance);

    } catch (e) {
      throw Exception('উত্তোলন করতে সমস্যা: $e');
    }
  }

  Future<Member> getMemberById(String memberId) async {
    try {
      final doc = await _firestore.collection('members').doc(memberId).get();

      if (!doc.exists) {
        throw Exception('সদস্য পাওয়া যায়নি');
      }

      return Member.fromMap(doc.id, doc.data()!);
    } catch (e) {
      throw Exception('সদস্য তথ্য লোড করতে সমস্যা: $e');
    }
  }




  ///nov 29

  // Add these to your FirebaseService
  Future<List<Loan>> getLoansByMemberId(String memberId) async {
    final query = _firestore.collection('loans').where('memberId', isEqualTo: memberId);
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Loan.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> updateLoan(Loan loan) async {
    if (loan.id == null) throw Exception('Loan ID is required for update');
    await _firestore.collection('loans').doc(loan.id).update(loan.toMap());
    await _firestore.collection('members').doc(loan.memberId).update({
      'lastLoanGiven': DateTime.now().millisecondsSinceEpoch,
      'loanGiven':loan.totalPaid
    });
  }


  // Add to your FirebaseService class
  final CollectionReference _installmentTransactionsCollection =
  FirebaseFirestore.instance.collection('installment_transactions');

  Future<void> addInstallmentTransaction(InstallmentTransaction transaction) async {
    await _installmentTransactionsCollection.add(transaction.toMap());
  }

  Future<List<InstallmentTransaction>> getInstallmentTransactionsByLoanId(String loanId) async {
    final query = _installmentTransactionsCollection.where('loanId', isEqualTo: loanId);
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => InstallmentTransaction.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
  }






  // Add these methods to your FirebaseService class

  Future<CashboxSummary> getCashboxSummary() async {
    try {
      // Get all transactions
      final allTransactions = await _firestore
          .collection('transactions')
          .get()
          .then((snapshot) => snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
          .toList());

      // Get all loans
      final allLoans = await _firestore
          .collection('loans')
          .get()
          .then((snapshot) => snapshot.docs
          .map((doc) => Loan.fromMap(doc.id, doc.data()))
          .toList());

      // Get all members
      final allMembers = await _firestore
          .collection('members')
          .get()
          .then((snapshot) => snapshot.docs.length);

      // Calculate totals
      double totalSavings = 0;
      double totalWithdrawals = 0;
      double totalLoanGiven = 0;
      double totalLoanCollected = 0;
      double totalLoanPending = 0;
      int activeLoans = 0;
      int completedLoans = 0;

      // Calculate transaction totals
      for (final transaction in allTransactions) {
        if (transaction.transactionType == 'savings') {
          totalSavings += transaction.amount;
        } else if (transaction.transactionType == 'withdrawal') {
          totalWithdrawals += transaction.amount;
        }
      }

      // Calculate loan totals
      for (final loan in allLoans) {
        totalLoanGiven += loan.loanAmount;
        totalLoanCollected += loan.totalPaid;
        totalLoanPending += loan.remainingBalance;

        if (loan.status == 'active') {
          activeLoans++;
        } else if (loan.status == 'completed') {
          completedLoans++;
        }
      }

      // Calculate current balance
      final currentBalance = totalSavings - totalWithdrawals + totalLoanCollected;

      return CashboxSummary(
        totalSavings: totalSavings,
        totalWithdrawals: totalWithdrawals,
        totalLoanGiven: totalLoanGiven,
        totalLoanCollected: totalLoanCollected,
        totalLoanPending: totalLoanPending,
        currentBalance: currentBalance,
        totalMembers: allMembers,
        activeLoans: activeLoans,
        completedLoans: completedLoans,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('ক্যাশবক্স তথ্য লোড করতে সমস্যা: $e');
    }
  }

// Get recent transactions
  Stream<List<TransactionModel>> getRecentTransactions({int limit = 10}) {
    return _firestore
        .collection('transactions')
        .orderBy('transactionDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

// Get recent loan installments
  Stream<List<InstallmentTransaction>> getRecentInstallments({int limit = 10}) {
    return _installmentTransactionsCollection
        .orderBy('paymentDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return InstallmentTransaction.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

}


