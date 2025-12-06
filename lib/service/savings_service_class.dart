
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../models/members.dart';
import '../models/transaction_model.dart';

class SavingsServiceClass {
  final _firestore = FirebaseFirestore.instance;
  // Add these methods to your FirebaseService class


  Future<void> updateTransaction({
    required String memberId,
    required String transactionId,
    required double newAmount,
    String? newNotes,
  }) async {
    try {

      // Get the existing transaction
      final transactionDoc = await _firestore
          .collection('transactions')
          .doc(transactionId)
          .get();

      if (!transactionDoc.exists) {
        throw Exception('Transaction not found');
      }

      final transactionData = transactionDoc.data()!;
      final oldAmount = transactionData['amount'] as double;
      final transactionType = transactionData['transactionType'] as String;
      final oldNotes = transactionData['notes'] as String?;

      // Calculate the difference
      final difference = newAmount - oldAmount;

      // Get all transactions for this member (sorted by date)
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .where('memberId', isEqualTo: memberId)
          .orderBy('transactionDate', descending: false)
          .get();

      final transactions = transactionsSnapshot.docs;
      List<Map<String, dynamic>> transactionsToUpdate = [];

      bool foundTarget = false;
      double runningBalance = 0;

      // First pass: Calculate running balances and find the target transaction
      for (final doc in transactions) {
        final data = doc.data();
        final amount = data['amount'] as double;
        final type = data['transactionType'] as String;

        // Update running balance
        if (type == 'savings') {
          runningBalance += amount;
        } else if (type == 'withdrawal') {
          runningBalance -= amount;
        }

        // If we found our target transaction
        if (doc.id == transactionId) {
          foundTarget = true;
          // Update the target transaction
          transactionsToUpdate.add({
            'docRef': doc.reference,
            'data': {
              ...data,
              'amount': newAmount,
              'notes': newNotes ?? oldNotes,
              'balanceAfter': runningBalance + (type == 'savings' ? difference : -difference),
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            }
          });
        } else if (foundTarget) {
          // For subsequent transactions, update their balances
          transactionsToUpdate.add({
            'docRef': doc.reference,
            'data': {
              ...data,
              'balanceAfter': (data['balanceAfter'] as double) + difference,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            }
          });
        }
      }

      // Execute all updates in a batch
      final batch = _firestore.batch();
      for (final update in transactionsToUpdate) {
        batch.update(update['docRef'] as DocumentReference, update['data'] as Map<String, dynamic>);
      }

      // Update member's total savings and lastSavingsGiven
      final memberTransactions = await getAllTransactionsById(memberId).first;
      double newTotalBalance = 0;

      for (final transaction in memberTransactions) {
        if (transaction.transactionType == 'savings') {
          newTotalBalance += transaction.amount;
        } else if (transaction.transactionType == 'withdrawal') {
          newTotalBalance -= transaction.amount;
        }
      }

      // Update member document
      final memberUpdateData = <String, dynamic>{
        'totalSavings': newTotalBalance,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      // If it's a savings transaction, update lastLoanGiven
      if (transactionType == 'savings') {
        memberUpdateData['lastSavingsGiven'] = DateTime.now().millisecondsSinceEpoch;
      }

      batch.update(
        _firestore.collection('members').doc(memberId),
        memberUpdateData,
      );

      await batch.commit();



    } catch (e) {
      throw Exception('লেনদেন আপডেট করতে সমস্যা: $e');
    }
  }

  Future<void> deleteTransaction({
    required String memberId,
    required String transactionId,
  }) async {
    try {
      // Get the transaction to delete
      final transactionDoc = await _firestore
          .collection('transactions')
          .doc(transactionId)
          .get();

      if (!transactionDoc.exists) {
        throw Exception('Transaction not found');
      }

      final transactionData = transactionDoc.data()!;
      final amount = transactionData['amount'] as double;
      final transactionType = transactionData['transactionType'] as String;

      // Get all transactions for this member (sorted by date)
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .where('memberId', isEqualTo: memberId)
          .orderBy('transactionDate', descending: false)
          .get();

      final transactions = transactionsSnapshot.docs;
      List<Map<String, dynamic>> transactionsToUpdate = [];
      DocumentReference? transactionToDelete;

      bool foundTarget = false;
      double runningBalance = 0;

      // First pass: Calculate running balances and find the target transaction
      for (final doc in transactions) {
        final data = doc.data();
        final docAmount = data['amount'] as double;
        final type = data['transactionType'] as String;

        // Skip the target transaction (will be deleted)
        if (doc.id == transactionId) {
          foundTarget = true;
          transactionToDelete = doc.reference;
          // For deletion, adjust the running balance
          if (type == 'savings') {
            runningBalance -= docAmount; // Remove savings amount
          } else if (type == 'withdrawal') {
            runningBalance += docAmount; // Add back withdrawal amount
          }
          continue;
        }

        // Update running balance for other transactions
        if (type == 'savings') {
          runningBalance += docAmount;
        } else if (type == 'withdrawal') {
          runningBalance -= docAmount;
        }

        // If we've passed the target transaction, update subsequent balances
        if (foundTarget) {
          // For withdrawals, we need to add back the amount to subsequent balances
          // For savings, we need to subtract the amount from subsequent balances
          final adjustment = transactionType == 'withdrawal' ? amount : -amount;

          transactionsToUpdate.add({
            'docRef': doc.reference,
            'data': {
              ...data,
              'balanceAfter': (data['balanceAfter'] as double) + adjustment,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            }
          });
        }
      }

      // Execute all operations in a batch
      final batch = _firestore.batch();

      // Delete the transaction
      if (transactionToDelete != null) {
        batch.delete(transactionToDelete);
      }

      // Update subsequent transactions
      for (final update in transactionsToUpdate) {
        batch.update(update['docRef'] as DocumentReference, update['data'] as Map<String, dynamic>);
      }

      // Update member's total savings
      final memberTransactions = await getAllTransactionsById(memberId).first;
      double newTotalBalance = 0;
      for (final transaction in memberTransactions) {
        if (transaction.transactionType == 'savings') {
          newTotalBalance += transaction.amount;
        } else if (transaction.transactionType == 'withdrawal') {
          newTotalBalance -= transaction.amount;
        }
      }

      // Update member document
      batch.update(
        _firestore.collection('members').doc(memberId),
        {
          'totalSavings': newTotalBalance,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
      );

      await batch.commit();

    } catch (e) {
      throw Exception('লেনদেন মুছতে সমস্যা: $e');
    }
  }

  // Helper method to get all transactions for a member
  Stream<List<TransactionModel>> getAllTransactionsById(String memberId) {
    return _firestore
        .collection('transactions')
        .where('memberId', isEqualTo: memberId)
        .orderBy('transactionDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.id,doc.data()))
        .toList());
  }


  // Helper method to get member by ID
  Future<Member> getMemberById(String memberId) async {
    final doc = await _firestore.collection('members').doc(memberId).get();
    if (!doc.exists) {
      throw Exception('Member not found');
    }
    return Member.fromMap(doc.id,doc.data()!);
  }

  void callLastGivenUpdate(String memberId) {
    debugPrint('Calling last given update for memberId: $memberId');
  }




}