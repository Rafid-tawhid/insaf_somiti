import 'package:flutter/material.dart';
import 'package:insaf_somiti/models/members.dart';


class InstallmentStatus extends StatelessWidget {
  final DateTime givenDate;
  final String loanType;
  final Member? member;

  const InstallmentStatus({
    super.key,
    required this.givenDate,
    required this.loanType,
    this.member,
  });

  @override
  Widget build(BuildContext context) {
    String message = generateMessage(givenDate, loanType);

    return Text(
      message,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );
  }
  String generateMessage(DateTime date, String type) {
    final today = DateTime.now();

    int diffDays = today.difference(date).inDays;

    int missed = 0;

    if (type == "Daily") {
      missed = diffDays;
    } else if (type == "Weekly") {
      missed = (diffDays / 7).floor();
    } else if (type == "Monthly") {
      missed = (diffDays / 30).floor();
    }

    if (missed <= 0) {
      return "Loan: ৳${member!.loanGiven.toStringAsFixed(2)}";
    }

    return "$missed টি কিস্তি বাকি রয়েছে";
  }
}
