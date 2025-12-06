import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:insaf_somiti/screens/profile_entry_screen.dart';
import 'package:insaf_somiti/screens/single_member_details_screen.dart';
import '../models/loan_model.dart';
import '../models/members.dart';
import '../providers/loan_provider.dart';

class MemberListScreen extends StatefulWidget {
  const MemberListScreen({Key? key}) : super(key: key);

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Active members stream
  Stream<List<Member>> getActiveMembers() {
    return _firestore
        .collection('members')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Member.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Inactive members stream
  Stream<List<Member>> getInactiveMembers() {
    return _firestore
        .collection('members')
        .where('isActive', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Member.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Filter members based on search query
  List<Member> _filterMembers(List<Member> members, String query) {
    if (query.isEmpty) return members;

    return members.where((member) {
      return member.memberName.toLowerCase().contains(query.toLowerCase()) ||
          member.memberNumber.contains(query) ||
          member.memberMobile.contains(query) ||
          member.nationalIdOrBirthCertificate.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'সদস্য নাম, নম্বর বা মোবাইল সার্চ করুন...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        )
            : const Text('সদস্য তালিকা'),
        backgroundColor: Colors.green[700],
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = '';
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              _handlePopupMenuSelection(value);
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download, size: 20),
                    SizedBox(width: 8),
                    Text('ডেটা এক্সপোর্ট'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'stats',
                child: Row(
                  children: [
                    Icon(Icons.analytics, size: 20),
                    SizedBox(width: 8),
                    Text('পরিসংখ্যান'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(
              text: 'সক্রিয় সদস্য',
              icon: Icon(Icons.person, size: 20),
            ),
            Tab(
              text: 'নিষ্ক্রিয় সদস্য',
              icon: Icon(Icons.person_off, size: 20),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMembersTab(getActiveMembers(), 'সক্রিয়'),
          _buildMembersTab(getInactiveMembers(), 'নিষ্ক্রিয়'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => const MemberEntryScreen())
          );
        },
        backgroundColor: Colors.green[700],
        elevation: 4,
        child: const Icon(
          Icons.person_add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildMembersTab(Stream<List<Member>> stream, String type) {
    return StreamBuilder<List<Member>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        List<Member> members = snapshot.data ?? [];
        List<Member> filteredMembers = _filterMembers(members, _searchQuery);

        if (filteredMembers.isEmpty) {
          return _buildEmptyState(type, _searchQuery.isNotEmpty);
        }

        return Column(
          children: [

            // Members Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'মোট সদস্য: ${filteredMembers.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    Text(
                      'সার্চ রেজাল্ট',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            // Members List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filteredMembers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final member = filteredMembers[index];
                  return _buildMemberCard(member);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMemberCard(Member member) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemberDetailsScreen(member: member),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar with status
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.green[700],
                      size: 30,
                    ),
                  ),
                  if (member.isActive)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                            BorderSide(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              // Member Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.memberName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            member.memberNumber,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      member.memberMobile,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Colors.green[700],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '৳${member.totalSavings.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Spacer(),
                        Text('${member.lastSavingsGiven}')

                      ],
                    ),
                   if(member.isLoanActive) Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Colors.red[700],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '৳${member.loanGiven.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Spacer(),
                        Text('${member.lastLoanGiven}')

                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Forward arrow
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSummaryItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      color: Colors.grey[200],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      color: Colors.grey[200],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[300],
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'ডেটা লোড করতে সমস্যা হয়েছে',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.refresh),
            label: const Text('আবার চেষ্টা করুন'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String type, bool isSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            color: Colors.grey[300],
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'কোন সদস্য পাওয়া যায়নি' : 'কোন $type সদস্য নেই',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          if (!isSearch) ...[
            const SizedBox(height: 8),
            const Text(
              'নতুন সদস্য যোগ করতে নিচের বাটনে ক্লিক করুন',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handlePopupMenuSelection(String value) {
    switch (value) {
      case 'export':
        _showExportDialog();
        break;
      case 'stats':
        _showStatistics();
        break;
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ডেটা এক্সপোর্ট'),
        content: const Text('সদস্য তালিকা এক্সপোর্ট করুন'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement export functionality
            },
            child: const Text('এক্সপোর্ট'),
          ),
        ],
      ),
    );
  }

  void _showStatistics() {
    // Implement statistics screen
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}