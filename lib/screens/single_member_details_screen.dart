import 'package:flutter/material.dart';
import 'package:insaf_somiti/screens/savings_withdraw_screen.dart';
import '../models/members.dart';
import '../providers/loan_provider.dart';
import 'loan_application_screen.dart';
import 'loan_installment_given_screen.dart';

class MemberDetailsScreen extends StatelessWidget {
  final Member member;

  const MemberDetailsScreen({Key? key, required this.member}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('সদস্য বিবরণ'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () {
              // Edit member functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, size: 20),
            onPressed: () {
              _shareMemberDetails(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section with Gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green[700]!,
                  Colors.green[600]!,
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Profile Avatar with Status
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.green[100]!,
                            Colors.green[200]!,
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.green[700],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: member.isActive ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          member.isActive ? Icons.check : Icons.close,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Member Name and Number
                Text(
                  member.memberName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'সদস্য নং: ${member.memberNumber}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                // Savings Amount
                Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'মোট সঞ্চয়: ৳${member.totalSavings.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Spacer(),
                    FutureBuilder(
                        future:  getMemberLoanInfoById(member.id??''),
                        builder: (context, value) {
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'মোট ঋণ: ৳${value.hasData ? value.requireData['totalPayable'] : '0.00'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'ঋণ প্রদান: ৳${value.hasData ? value.requireData['totalPaid']??'0.00' : '0.00'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quick Action Buttons
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.add_card,
                        iconColor: Colors.green,
                        backgroundColor: Colors.green[50]!,
                        label: 'সঞ্চয় আদায়',
                        onTap: () => _navigateToHisab(context, member,'savings')
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.remove_circle,
                        iconColor: Colors.red,
                        backgroundColor: Colors.red[50]!,
                        label: 'সঞ্চয় উত্তোলন',
                        onTap: () => _navigateToHisab(context, member,'withdraw'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.attach_money,
                        iconColor: Colors.blue,
                        backgroundColor: Colors.blue[50]!,
                        label: 'ঋণ আদায়',
                        onTap: () => _navigateToLoanCollect(context, member),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.money_outlined,
                        iconColor: Colors.orange,
                        backgroundColor: Colors.orange[50]!,
                        label: 'ঋণ প্রদান',
                        onTap: () => _navigateToLoan(context, member),
                      ),
                    ),
                  ],
                ),
              ],
            )
            ,
          ),

          // Details Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildDetailSection(
                    title: 'ব্যক্তিগত তথ্য',
                    icon: Icons.person_outline,
                    iconColor: Colors.blue,
                    items: [
                      _buildDetailItemWithIcon(
                        Icons.badge,
                        'পূর্ণ নাম',
                        member.memberName,
                      ),
                      _buildDetailItemWithIcon(
                        Icons.family_restroom,
                        'পিতা/স্বামীর নাম',
                        member.fatherOrHusbandName,
                      ),
                      _buildDetailItemWithIcon(
                        Icons.phone,
                        'মোবাইল নম্বর',
                        member.memberMobile,
                      ),
                      _buildDetailItemWithIcon(
                        Icons.credit_card,
                        'জাতীয় আইডি/জন্ম নিবন্ধন',
                        member.nationalIdOrBirthCertificate,
                      ),
                      _buildDetailItemWithIcon(
                        Icons.calendar_today,
                        'নিবন্ধনের তারিখ',
                        '${member.createdAt.day}/${member.createdAt.month}/${member.createdAt.year}',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildDetailSection(
                    title: 'নমিনি তথ্য',
                    icon: Icons.people_outline,
                    iconColor: Colors.green,
                    items: [
                      _buildDetailItemWithIcon(
                        Icons.person,
                        'নমিনির নাম',
                        member.nomineeName,
                      ),
                      _buildDetailItemWithIcon(
                        Icons.link,
                        'সম্পর্ক',
                        member.nomineeRelation,
                      ),
                      _buildDetailItemWithIcon(
                        Icons.phone_iphone,
                        'মোবাইল নম্বর',
                        member.nomineeMobile,
                      ),
                      _buildDetailItemWithIcon(
                        Icons.badge_outlined,
                        'জাতীয় আইডি',
                        member.nomineeNationalId,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildDetailSection(
                    title: 'গ্যারান্টর তথ্য',
                    icon: Icons.verified_user_outlined,
                    iconColor: Colors.orange,
                    items: [
                      _buildDetailItemWithIcon(
                        Icons.person,
                        'গ্যারান্টরের নাম',
                        member.guarantorName,
                      ),
                      _buildDetailItemWithIcon(
                        Icons.credit_card,
                        'জাতীয় আইডি',
                        member.guarantorNationalId,
                      ),
                      _buildDetailItemWithIcon(
                        Icons.phone,
                        'মোবাইল নম্বর',
                        member.guarantorMobile,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: items,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItemWithIcon(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'নাই',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToHisab(BuildContext context, Member member,String type) {

    if(type=='savings'){
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SavingsWithdrawEntryScreen(
            memberId: member.id.toString(),
            transactionType: 'savings',
          ),
        ),
      );
      return;
    }
    else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SavingsWithdrawEntryScreen(
            memberId: member.id.toString(),
            transactionType: 'withdraw',
          ),
        ),
      );
    }


  }

  void _navigateToLoan(BuildContext context, Member member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoanApplicationScreen(
          memberId: member.id.toString(),
        ),
      ),
    );
  }


  void _shareMemberDetails(BuildContext context) {
    // Share functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('শেয়ার করুন'),
        content: const Text('সদস্য তথ্য শেয়ার করুন'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement share functionality
            },
            child: const Text('শেয়ার'),
          ),
        ],
      ),
    );
  }

  void _navigateToLoanCollect(BuildContext context, Member member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleInstallmentScreen(
          memberId: member.id??'',
        ),
      ),
    );
  }

}
