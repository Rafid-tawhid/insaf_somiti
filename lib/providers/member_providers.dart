import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/members.dart';
import '../service/service_class.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final memberListProvider = StreamProvider<List<Member>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getMembers();
});

// Correct way for Riverpod 2.0+
final memberFormProvider = NotifierProvider<MemberFormNotifier, Member>(() {
  return MemberFormNotifier();
});

class MemberFormNotifier extends Notifier<Member> {
  @override
  Member build() {
    return Member(
      memberNumber: '',
      memberName: '',
      fatherOrHusbandName: '',
      memberMobile: '',
      nationalIdOrBirthCertificate: '',
      nomineeName: '',
      nomineeRelation: '',
      nomineeMobile: '',
      nomineeNationalId: '',
      guarantorName: '',
      guarantorNationalId: '',
      guarantorMobile: '',
      createdAt: DateTime.now(),
    );
  }

  // All your update methods remain the same...
  void updateMemberNumber(String value) {
    state = state.copyWith(memberNumber: value);
  }

  void updateMemberName(String value) {
    state = state.copyWith(memberName: value);
  }

  void updateFatherOrHusbandName(String value) {
    state = state.copyWith(fatherOrHusbandName: value);
  }

  void updateMemberMobile(String value) {
    state = state.copyWith(memberMobile: value);
  }

  void updateNationalId(String value) {
    state = state.copyWith(nationalIdOrBirthCertificate: value);
  }

  void updateNomineeName(String value) {
    state = state.copyWith(nomineeName: value);
  }

  void updateNomineeRelation(String value) {
    state = state.copyWith(nomineeRelation: value);
  }

  void updateNomineeMobile(String value) {
    state = state.copyWith(nomineeMobile: value);
  }

  void updateNomineeNationalId(String value) {
    state = state.copyWith(nomineeNationalId: value);
  }

  void updateGuarantorName(String value) {
    state = state.copyWith(guarantorName: value);
  }

  void updateGuarantorNationalId(String value) {
    state = state.copyWith(guarantorNationalId: value);
  }

  void updateGuarantorMobile(String value) {
    state = state.copyWith(guarantorMobile: value);
  }

  void resetForm() {
    state = Member(
      memberNumber: '',
      memberName: '',
      fatherOrHusbandName: '',
      memberMobile: '',
      nationalIdOrBirthCertificate: '',
      nomineeName: '',
      nomineeRelation: '',
      nomineeMobile: '',
      nomineeNationalId: '',
      guarantorName: '',
      guarantorNationalId: '',
      guarantorMobile: '',
      createdAt: DateTime.now(),
    );
  }
}