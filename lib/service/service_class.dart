import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
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
      // Start a batch write for atomic operation
      final batch = _firestore.batch();

      // Get member reference
      final memberRef = _firestore.collection('members').doc(memberId);
      final memberDoc = await memberRef.get();

      if (!memberDoc.exists) {
        throw Exception('Member not found');
      }

      final member = Member.fromMap(memberDoc.id, memberDoc.data()!);
      final newBalance = member.totalSavings + amount;

      // Update member's total savings
      batch.update(memberRef, {
        'totalSavings': newBalance,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Create transaction record
      final transactionRef = _firestore.collection('transactions').doc();
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

      batch.set(transactionRef, transaction.toMap());

      // Commit both operations
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to add savings: $e');
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
}


