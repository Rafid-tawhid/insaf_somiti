import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:insaf_somiti/screens/profile_entry_screen.dart';
import '../models/members.dart';
import '../providers/member_providers.dart';
import '../providers/savings_provider.dart';

class SavingsEntryScreen extends ConsumerStatefulWidget {
  const SavingsEntryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SavingsEntryScreen> createState() => _SavingsEntryScreenState();
}

class _SavingsEntryScreenState extends ConsumerState<SavingsEntryScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _submitSavings() async {
    final savingsState = ref.read(savingsFormProvider);
    final member = savingsState.selectedMember;

    if (member == null) {
      _showError('দয়া করে একজন সদস্য নির্বাচন করুন');
      return;
    }

    if (savingsState.amount <= 0) {
      _showError('দয়া করে সঠিক পরিমাণ লিখুন');
      return;
    }

    try {
      ref.read(savingsFormProvider.notifier).setLoading(true);

      // In real app, get agent info from auth
      const agentId = 'agent_001';
      const agentName = 'এজেন্ট';

      await ref.read(firebaseServiceProvider).addSavings(
        memberId: member.id!,
        amount: savingsState.amount,
        agentId: agentId,
        agentName: agentName,
        notes: savingsState.notes,
      );

      // Reset form
      ref.read(savingsFormProvider.notifier).resetForm();
      _amountController.clear();
      _notesController.clear();
      _searchController.clear();
      ref.read(memberSearchQueryProvider.notifier).state = '';

      _showSuccess('সঞ্চয় সফলভাবে যোগ করা হয়েছে!');
    } catch (e) {
      _showError('ত্রুটি: $e');
    } finally {
      ref.read(savingsFormProvider.notifier).setLoading(false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final savingsState = ref.watch(savingsFormProvider);
    final selectedMember = savingsState.selectedMember;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'সঞ্চয় সংগ্রহ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Selected Member Card
            if (selectedMember != null) _buildMemberCard(selectedMember),

            // Member Selection Card
            _buildSectionCard(
              title: 'সদস্য নির্বাচন',
              icon: Icons.search,
              children: [
                GestureDetector(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>MemberSearchDialog(
                      onMemberSelected: (member) {
                        ref.read(savingsFormProvider.notifier).selectMember(member);
                        Navigator.pop(context);
                      },
                    )));
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.green[700]),
                        const SizedBox(width: 12),
                        Text(
                          selectedMember != null
                              ? '${selectedMember.memberName} - ${selectedMember.memberNumber}'
                              : 'সদস্য খুঁজুন (নাম, নং বা মোবাইল দ্বারা)',
                          style: TextStyle(
                            color: selectedMember != null
                                ? Colors.black
                                : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Savings Amount Card
            _buildSectionCard(
              title: 'সঞ্চয়ের তথ্য',
              icon: Icons.attach_money,
              children: [
                CustomTextField(
                  label: 'সঞ্চয়ের পরিমাণ',
                  hintText: 'টাকার পরিমাণ লিখুন',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final amount = double.tryParse(value) ?? 0.0;
                    ref.read(savingsFormProvider.notifier).updateAmount(amount);
                  },
                  isRequired: true,
                ),
                CustomTextField(
                  label: 'মন্তব্য (ঐচ্ছিক)',
                  hintText: 'কোন মন্তব্য থাকলে লিখুন',
                  controller: _notesController,
                  onChanged: (value) {
                    ref.read(savingsFormProvider.notifier).updateNotes(value);
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: savingsState.isLoading ? null : _submitSavings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: savingsState.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'সঞ্চয় সংরক্ষণ করুন',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(Member member) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                'নির্বাচিত সদস্য',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('নাম: ${member.memberName}'),
          Text('সদস্য নং: ${member.memberNumber}'),
          Text('মোবাইল: ${member.memberMobile}'),
          Text('মোট সঞ্চয়: ৳${member.totalSavings.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Icon(icon, color: Colors.green[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

// Member Search Dialog
class MemberSearchDialog extends ConsumerWidget {
  final Function(Member) onMemberSelected;

  const MemberSearchDialog({Key? key, required this.onMemberSelected}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(memberSearchQueryProvider);
    final membersAsync = ref.watch(searchedMembersProvider);

    print('Current search query: "$searchQuery"'); // Debug print

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'সদস্য খুঁজুন (নাম, নং বা মোবাইল)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                print('Search text changed to: "$value"'); // Debug print
                ref.read(memberSearchQueryProvider.notifier).state = value;
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: membersAsync.when(
                data: (members) {
                  print('Found ${members.length} members'); // Debug print
                  if (members.isEmpty && searchQuery.isNotEmpty) {
                    return const Center(
                      child: Text('কোন সদস্য পাওয়া যায়নি'),
                    );
                  }
                  return ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Text(
                              '${index+1}',
                              style: TextStyle(color: Colors.green[700]),
                            ),
                          ),
                          title: Text(member.memberName),
                          subtitle: Text('নং: ${member.memberNumber} | মোবাইল: ${member.memberMobile}'),
                          trailing: Text('৳${member.totalSavings.toStringAsFixed(2)}'),
                          onTap: () => onMemberSelected(member),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) {
                  print('Search error: $error'); // Debug print
                  return Center(
                    child: Text('ত্রুটি: $error'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}