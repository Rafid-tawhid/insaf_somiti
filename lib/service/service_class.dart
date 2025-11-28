import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
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
        } else if (transaction.transactionType == 'withdrawal') {
          currentBalance -= transaction.amount;
        }
      }

      // Calculate new balance after savings
      final newBalance = currentBalance + amount;

      // Create savings transaction
      final transaction = Transaction(
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

  // NEW: Get transaction history for a member
  Stream<List<Transaction>> getMemberTransactions(String memberId) {
    return _firestore
        .collection('transactions')
        .where('memberId', isEqualTo: memberId)
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Transaction.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // NEW: Get all transactions
  Stream<List<Transaction>> getAllTransactions() {
    return _firestore
        .collection('transactions')
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Transaction.fromMap(doc.id, doc.data());
      }).toList();
    });
  }


  Stream<List<Transaction>> getAllTransactionsById(String id) {
    return _firestore
        .collection('transactions')
        .where('memberId', isEqualTo: id) // <-- Filter by ID field
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Transaction.fromMap(doc.id, doc.data());
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
      await _firestore.collection('loans').add(loan.toMap());
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
        return Loan.fromMap(doc.id, doc.data() as Map<String, dynamic>);
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


  Stream<List<Transaction>> getTransactionsWithFilters(TransactionFilters filters) {
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
        return Transaction.fromMap(doc.id, doc.data() as Map<String, dynamic>);
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
      final transaction = Transaction(
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


  ///nov 27
  Future<void> addLoanInstallment(LoanInstallment installment) async {
    FirebaseFirestore _firestore = FirebaseFirestore.instance;
    try {
      await _firestore.collection('loanInstallments').add(installment.toMap());
    } catch (e) {
      throw Exception('কিস্তি সংরক্ষণ করতে সমস্যা: $e');
    }
  }

  Future<List<LoanInstallment>> getLoanInstallments(String loanId) async {
    try {
      FirebaseFirestore _firestore = FirebaseFirestore.instance;
      final querySnapshot = await _firestore
          .collection('loanInstallments')
          .where('loanId', isEqualTo: loanId)
          .orderBy('paymentDate', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return LoanInstallment.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      throw Exception('কিস্তি লোড করতে সমস্যা: $e');
    }
  }

  Future<void> updateLoan(Loan loan) async {
    try {
      FirebaseFirestore _firestore = FirebaseFirestore.instance;
      await _firestore.collection('loans').doc(loan.id).update(loan.toMap());
    } catch (e) {
      throw Exception('ঋণ আপডেট করতে সমস্যা: $e');
    }
  }

  Future<Loan> getLoanById(String loanId) async {
    try {
      FirebaseFirestore _firestore = FirebaseFirestore.instance;
      final doc = await _firestore.collection('loans').doc(loanId).get();
      if (doc.exists) {
        return Loan.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      } else {
        throw Exception('ঋণ পাওয়া যায়নি');
      }
    } catch (e) {
      throw Exception('ঋণ লোড করতে সমস্যা: $e');
    }
  }
}


