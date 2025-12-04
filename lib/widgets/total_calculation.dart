import '../models/loan_model.dart';
import '../models/transaction_model.dart';
import 'package:flutter/material.dart';

class FinancialSummaryWidget extends StatelessWidget {
  final List<TransactionModel> transactions;
  final List<Loan> loans;

  const FinancialSummaryWidget({
    Key? key,
    required this.transactions,
    required this.loans,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final calculations = _calculateFinancialSummary();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[800]!, Colors.blue[600]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.white.withOpacity(0.9)),
              const SizedBox(width: 8),
              Text(
                'Financial Summary',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Summary Cards
          Row(
            children: [
              // Total Savings
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Savings',
                  amount: calculations.totalSavings,
                  icon: Icons.savings,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              // Total Loans
              Expanded(
                child: _buildSummaryCard(
                  title: 'Active Loans',
                  amount: calculations.totalActiveLoans,
                  icon: Icons.credit_card,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Total Loan Interest
              Expanded(
                child: _buildSummaryCard(
                  title: 'Loan Interest',
                  amount: calculations.totalLoanInterest,
                  icon: Icons.percent,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              // Net Position
              Expanded(
                child: _buildNetPositionCard(calculations),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetPositionCard(FinancialCalculations calculations) {
    final isPositive = calculations.netFinancialPosition >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    final status = isPositive ? 'In Savings' : 'In Loans';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                'Net Position',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '₹${calculations.netFinancialPosition.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  FinancialCalculations _calculateFinancialSummary() {
    // Calculate total savings
    double totalSavings = transactions
        .where((t) => t.transactionType.toLowerCase() == 'savings')
        .fold(0.0, (sum, transaction) => sum + transaction.amount);

    // Calculate active loans
    final activeLoans = loans.where((loan) => loan.status == 'active').toList();

    double totalActiveLoanPrincipal = activeLoans
        .fold(0.0, (sum, loan) => sum + loan.loanAmount);

    double totalLoanInterest = activeLoans
        .fold(0.0, (sum, loan) => sum + (loan.totalPayable - loan.loanAmount));

    double totalActiveLoans = activeLoans
        .fold(0.0, (sum, loan) => sum + loan.totalPayable);

    // Calculate net position (Savings - Total Loan Liability)
    double netFinancialPosition = totalSavings - totalActiveLoans;

    return FinancialCalculations(
      totalSavings: totalSavings,
      totalActiveLoanPrincipal: totalActiveLoanPrincipal,
      totalLoanInterest: totalLoanInterest,
      totalActiveLoans: totalActiveLoans,
      netFinancialPosition: netFinancialPosition,
    );
  }
}

class FinancialCalculations {
  final double totalSavings;
  final double totalActiveLoanPrincipal;
  final double totalLoanInterest;
  final double totalActiveLoans;
  final double netFinancialPosition;

  FinancialCalculations({
    required this.totalSavings,
    required this.totalActiveLoanPrincipal,
    required this.totalLoanInterest,
    required this.totalActiveLoans,
    required this.netFinancialPosition,
  });
}