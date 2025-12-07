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
  final double totalSavings;
  final double loanTaken;
  final double loanGiven;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final bool isLoanActive; // NEW FIELD - added
  final DateTime? lastSavingsGiven; // NEW FIELD - added
  final DateTime? lastLoanGiven; // NEW FIELD - added
  final String? loanType;

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
    this.totalSavings = 0.0,
    this.loanTaken = 0.0,
    this.loanGiven = 0.0,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.isLoanActive = false, // DEFAULT VALUE - added
    this.lastSavingsGiven, // Default null - added
    this.lastLoanGiven,
    this.loanType// Default null - added
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
    double? loanTaken,
    double? loanGiven,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isLoanActive, // Added
    DateTime? lastSavingsGiven, // Added
    DateTime? lastLoanGiven, // Added
    String? loanType,// Added
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
      loanTaken: loanTaken ?? this.loanTaken, // Fixed: was incorrectly using totalSavings
      loanGiven: loanGiven ?? this.loanGiven, // Fixed: was incorrectly using totalSavings
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isLoanActive: isLoanActive ?? this.isLoanActive, // Added
      lastSavingsGiven: lastSavingsGiven ?? this.lastSavingsGiven, // Added
      lastLoanGiven: lastLoanGiven ?? this.lastLoanGiven, // Added
      loanType: loanType ?? this.loanType,// Added
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
      'totalSavings': totalSavings,
      'loanTaken': loanTaken,
      'loanGiven': loanGiven,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'isActive': isActive,
      'isLoanActive': isLoanActive, // ADDED
      'lastSavingsGiven': lastSavingsGiven?.millisecondsSinceEpoch, // ADDED - null safe
      'lastLoanGiven': lastLoanGiven?.millisecondsSinceEpoch, // ADDED - null safe
      'loanType': loanType,// ADDED
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
      totalSavings: (map['totalSavings'] ?? 0.0).toDouble(),
      loanTaken: (map['loanTaken'] ?? 0.0).toDouble(),
      loanGiven: (map['loanGiven'] ?? 0.0).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
      isActive: map['isActive'] ?? true,
      isLoanActive: map['isLoanActive'] ?? false, // ADDED
      lastSavingsGiven: map['lastSavingsGiven'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSavingsGiven'])
          : null, // ADDED
      lastLoanGiven: map['lastLoanGiven'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLoanGiven'])
          : null, // ADDED
      loanType: map['loanType']??'',// ADDED
    );
  }
}