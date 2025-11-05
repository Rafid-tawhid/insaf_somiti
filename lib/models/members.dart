class Member {
  final String? id;
  final String memberNumber;
  final String memberName;
  final String fatherOrHusbandName;
  final String memberMobile;
  final String nationalIdOrBirthCertificate;
  final String nomineeName;
  final String nomineeRelation;
  final String nomineeMobile;
  final String nomineeNationalId;
  final String guarantorName;
  final String guarantorNationalId;
  final String guarantorMobile;
  final double totalSavings; // NEW: Total savings amount
  final DateTime createdAt;
  final DateTime? updatedAt;

  Member({
    this.id,
    required this.memberNumber,
    required this.memberName,
    required this.fatherOrHusbandName,
    required this.memberMobile,
    required this.nationalIdOrBirthCertificate,
    required this.nomineeName,
    required this.nomineeRelation,
    required this.nomineeMobile,
    required this.nomineeNationalId,
    required this.guarantorName,
    required this.guarantorNationalId,
    required this.guarantorMobile,
    this.totalSavings = 0.0, // Initialize with 0
    required this.createdAt,
    this.updatedAt,
  });

  Member copyWith({
    String? id,
    String? memberNumber,
    String? memberName,
    String? fatherOrHusbandName,
    String? memberMobile,
    String? nationalIdOrBirthCertificate,
    String? nomineeName,
    String? nomineeRelation,
    String? nomineeMobile,
    String? nomineeNationalId,
    String? guarantorName,
    String? guarantorNationalId,
    String? guarantorMobile,
    double? totalSavings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Member(
      id: id ?? this.id,
      memberNumber: memberNumber ?? this.memberNumber,
      memberName: memberName ?? this.memberName,
      fatherOrHusbandName: fatherOrHusbandName ?? this.fatherOrHusbandName,
      memberMobile: memberMobile ?? this.memberMobile,
      nationalIdOrBirthCertificate: nationalIdOrBirthCertificate ?? this.nationalIdOrBirthCertificate,
      nomineeName: nomineeName ?? this.nomineeName,
      nomineeRelation: nomineeRelation ?? this.nomineeRelation,
      nomineeMobile: nomineeMobile ?? this.nomineeMobile,
      nomineeNationalId: nomineeNationalId ?? this.nomineeNationalId,
      guarantorName: guarantorName ?? this.guarantorName,
      guarantorNationalId: guarantorNationalId ?? this.guarantorNationalId,
      guarantorMobile: guarantorMobile ?? this.guarantorMobile,
      totalSavings: totalSavings ?? this.totalSavings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberNumber': memberNumber,
      'memberName': memberName,
      'fatherOrHusbandName': fatherOrHusbandName,
      'memberMobile': memberMobile,
      'nationalIdOrBirthCertificate': nationalIdOrBirthCertificate,
      'nomineeName': nomineeName,
      'nomineeRelation': nomineeRelation,
      'nomineeMobile': nomineeMobile,
      'nomineeNationalId': nomineeNationalId,
      'guarantorName': guarantorName,
      'guarantorNationalId': guarantorNationalId,
      'guarantorMobile': guarantorMobile,
      'totalSavings': totalSavings, // NEW
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory Member.fromMap(String id, Map<String, dynamic> map) {
    return Member(
      id: id,
      memberNumber: map['memberNumber'] ?? '',
      memberName: map['memberName'] ?? '',
      fatherOrHusbandName: map['fatherOrHusbandName'] ?? '',
      memberMobile: map['memberMobile'] ?? '',
      nationalIdOrBirthCertificate: map['nationalIdOrBirthCertificate'] ?? '',
      nomineeName: map['nomineeName'] ?? '',
      nomineeRelation: map['nomineeRelation'] ?? '',
      nomineeMobile: map['nomineeMobile'] ?? '',
      nomineeNationalId: map['nomineeNationalId'] ?? '',
      guarantorName: map['guarantorName'] ?? '',
      guarantorNationalId: map['guarantorNationalId'] ?? '',
      guarantorMobile: map['guarantorMobile'] ?? '',
      totalSavings: (map['totalSavings'] ?? 0.0).toDouble(), // NEW
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
    );
  }
}