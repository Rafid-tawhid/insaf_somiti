import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/loan_provider.dart';
import '../providers/member_providers.dart';
import '../providers/savings_provider.dart';
import '../models/transaction_model.dart';

import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;

class SavingsWithdrawEntryScreen extends ConsumerStatefulWidget {
  final String memberId;
  final String transactionType; // 'savings' or 'withdraw'

  const SavingsWithdrawEntryScreen({
    Key? key,
    required this.memberId,
    required this.transactionType,
  }) : super(key: key);

  @override
  ConsumerState<SavingsWithdrawEntryScreen> createState() =>
      _SavingsWithdrawEntryScreenState();
}

class _SavingsWithdrawEntryScreenState
    extends ConsumerState<SavingsWithdrawEntryScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitTransaction() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (amount <= 0) {
      _showError('দয়া করে সঠিক পরিমাণ লিখুন');
      return;
    }

    try {
      ref.read(savingsFormProvider.notifier).setLoading(true);

      const agentId = 'agent_001';
      const agentName = 'এজেন্ট';

      if (widget.transactionType == 'savings') {
        await ref
            .read(firebaseServiceProvider)
            .addSavings(
              memberId: widget.memberId,
              amount: amount,
              agentId: agentId,
              agentName: agentName,
              notes: _notesController.text,
            );
      } else {
        await ref
            .read(firebaseServiceProvider)
            .addWithdrawal(
              memberId: widget.memberId,
              amount: amount,
              agentId: agentId,
              agentName: agentName,
              notes: _notesController.text,
            );
      }

      _amountController.clear();
      _notesController.clear();
      _showSuccess('লেনদেন সফলভাবে সম্পন্ন হয়েছে!');
    } catch (e) {
      _showError('ত্রুটি: $e');
    } finally {
      ref.read(savingsFormProvider.notifier).setLoading(false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  double _calculateTotalBalance(List<TransactionModel> transactions) {
    double balance = 0;
    for (final transaction in transactions) {
      if (transaction.transactionType == 'savings') {
        balance += transaction.amount;
      } else if (transaction.transactionType == 'withdrawal') {
        balance -= transaction.amount;
      }
    }
    return balance;
  }

  String _getScreenTitle() {
    switch (widget.transactionType) {
      case 'savings':
        return 'সঞ্চয় সংগ্রহ';
      case 'withdraw':
        return 'সঞ্চয় উত্তোলন';
      default:
        return 'লেনদেন';
    }
  }

  String _getButtonText() {
    switch (widget.transactionType) {
      case 'savings':
        return 'জমা করুন';
      case 'withdraw':
        return 'লোন দিন';
      default:
        return 'সাবমিট করুন';
    }
  }

  Color _getPrimaryColor() {
    switch (widget.transactionType) {
      case 'savings':
        return Colors.green[700]!;
      case 'withdraw':
        return Colors.orange[700]!;
      default:
        return Colors.blue[700]!;
    }
  }

  Color _getLightColor() {
    switch (widget.transactionType) {
      case 'savings':
        return Colors.green[50]!;
      case 'withdraw':
        return Colors.orange[50]!;
      default:
        return Colors.blue[50]!;
    }
  }

  Color _getBorderColor() {
    switch (widget.transactionType) {
      case 'savings':
        return Colors.green[200]!;
      case 'withdraw':
        return Colors.orange[200]!;
      default:
        return Colors.blue[200]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final savingsState = ref.watch(savingsFormProvider);
    final transactionsStream = ref
        .watch(firebaseServiceProvider)
        .getAllTransactionsById(widget.memberId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        backgroundColor: _getPrimaryColor(),
        actions: [],
      ),
      body: Column(
        children: [
          // Total Balance Card
          StreamBuilder<List<TransactionModel>>(
            stream: transactionsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(); // Hide while loading
              }

              final transactions = snapshot.data ?? [];
              final totalBalance = _calculateTotalBalance(transactions);

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getLightColor(),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getBorderColor()),
                ),
                child: Column(
                  children: [
                    Text(
                      'মোট ব্যালেন্স',
                      style: TextStyle(
                        fontSize: 16,
                        color: _getPrimaryColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '৳${totalBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getPrimaryColor(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Transactions List
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: transactionsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final transactions = snapshot.data ?? [];

                if (transactions.isEmpty) {
                  return const Center(child: Text('কোন লেনদেন নেই'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          transaction.transactionType == 'savings'
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: transaction.transactionType == 'savings'
                              ? Colors.green
                              : Colors.orange,
                        ),
                        title: Text(
                          '${_getTransactionTypeText(transaction.transactionType)} - ৳${transaction.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (transaction.notes != null &&
                                transaction.notes!.isNotEmpty)
                              Text('মন্তব্য: ${transaction.notes}'),
                            Text('এজেন্ট: ${transaction.agentName}'),
                            Text(
                              'ব্যালেন্স: ৳${transaction.balanceAfter.toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat(
                                'dd/MM/yy',
                              ).format(transaction.transactionDate),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) async {
                                if (value == 'Edit') {
                                  await _showEditDialog(transaction);
                                } else if (value == 'Delete') {
                                  await _showDeleteDialog(transaction);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'Edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit),
                                    title: Text('Edit'),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'Delete',
                                  child: ListTile(
                                    leading: Icon(Icons.delete),
                                    title: Text('Delete'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // New Transaction Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                // Transaction Type Display (Read-only)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: _getLightColor(),
                    border: Border.all(color: _getBorderColor()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTransactionTypeText(widget.transactionType),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _getPrimaryColor(),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'পরিমাণ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'মন্তব্য (ঐচ্ছিক)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: savingsState.isLoading
                        ? null
                        : _submitTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getPrimaryColor(),
                    ),
                    child: savingsState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _getButtonText(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTransactionTypeText(String type) {
    switch (type) {
      case 'savings':
        return 'সঞ্চয়';
      case 'withdraw':
        return 'লোন';
      default:
        return type;
    }
  }

  // Add these methods to your _SavingsWithdrawEntryScreenState class
  Future<void> _showEditDialog(TransactionModel transaction) async {
    final editAmountController = TextEditingController(
      text: transaction.amount.toStringAsFixed(2),
    );
    final editNotesController = TextEditingController(
      text: transaction.notes ?? '',
    );

    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              'Edit ${_getTransactionTypeText(transaction.transactionType)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: editAmountController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.attach_money),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => editAmountController.clear(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: editNotesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final newAmount =
                            double.tryParse(editAmountController.text) ?? 0.0;

                        if (newAmount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid amount'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setState(() => isSaving = true);

                        try {
                          await ref
                              .read(editTransactionProvider.notifier)
                              .updateTransaction(
                                memberId: widget.memberId,
                                transactionId: transaction.id ?? '',
                                newAmount: newAmount,
                                notes: editNotesController.text.trim(),
                              );



                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${_getTransactionTypeText(transaction.transactionType)} updated successfully',
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getPrimaryColor(),
                ),
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDeleteDialog(TransactionModel transaction) async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isDeleting = false;

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: Colors.orange[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Confirm Delete',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            transaction.transactionType == 'savings'
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: transaction.transactionType == 'savings'
                                ? Colors.green
                                : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getTransactionTypeText(
                              transaction.transactionType,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Amount: ৳${transaction.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      if (transaction.notes != null &&
                          transaction.notes!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Notes: ${transaction.notes}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${DateFormat('dd/MM/yyyy').format(transaction.transactionDate)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Are you sure you want to delete this transaction?',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setState(() => isDeleting = true);

                        try {
                          await ref
                              .read(deleteTransactionProvider.notifier)
                              .deleteTransaction(
                                memberId: widget.memberId,
                                transactionId: transaction.id ?? '',
                              );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${_getTransactionTypeText(transaction.transactionType)} deleted successfully',
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => isDeleting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isDeleting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline, size: 18),
                          SizedBox(width: 6),
                          Text('Delete'),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
