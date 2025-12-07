import 'package:cloud_firestore/cloud_firestore.dart';

class MemberServiceClass {
  final FirebaseFirestore _firestore=FirebaseFirestore.instance;

  Future<void> activeMember(String memberId,bool status) async {
    await _firestore.collection('members').doc(memberId).update({
      'isActive': status,
    });
  }

}