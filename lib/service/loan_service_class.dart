
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../models/loan_model.dart';

class LoanServiceClass {
  // Add your methods and properties here
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String,dynamic>> getMemberLoanInfoById(String memberId) async {
    double totalPaid = 0.0;
    double totalPayable = 0.0;
    // Implementation to fetch loan info by member ID
    var data=_firestore.collection('loans').
    where('memberId',isEqualTo: memberId).get();
    for(var doc in (await data).docs){
     // loanList.add(Loan.fromMap(doc.id,doc.data()));
      totalPaid += doc['totalPaid'] ?? 0.0;
      totalPayable += doc['totalPayable'] ?? 0.0;
    }
    debugPrint('Total Paid: $totalPaid');
    debugPrint('Total Payable: $totalPayable');
    return {
      'totalPaid': totalPaid,
      'totalPayable': totalPayable,
    };

  }


}