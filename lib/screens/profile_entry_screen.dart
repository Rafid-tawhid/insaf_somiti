import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/member_providers.dart';

class MemberEntryScreen extends ConsumerStatefulWidget {
  const MemberEntryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MemberEntryScreen> createState() => _MemberEntryScreenState();
}

class _MemberEntryScreenState extends ConsumerState<MemberEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = List.generate(12, (_) => TextEditingController());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final member = ref.read(memberFormProvider);
        final firebaseService = ref.read(firebaseServiceProvider);

        await firebaseService.addMember(member);

        // Reset form
        ref.read(memberFormProvider.notifier).resetForm();
        for (var controller in _controllers) {
          controller.clear();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('সদস্য সফলভাবে যোগ করা হয়েছে!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ত্রুটি: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberNotifier = ref.read(memberFormProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'নতুন সদস্য যোগ করুন',
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Member Information Card
              _buildSectionCard(
                title: 'সদস্যের তথ্য',
                icon: Icons.person,
                children: [
                  CustomTextField(
                    label: 'সদস্যের নং',
                    hintText: 'সদস্য নং লিখুন',
                    controller: _controllers[0],
                    onChanged: memberNotifier.updateMemberNumber,
                    isRequired: true,
                  ),
                  CustomTextField(
                    label: 'সদস্যের নাম',
                    hintText: 'সদস্যের পুরো নাম লিখুন',
                    controller: _controllers[1],
                    onChanged: memberNotifier.updateMemberName,
                    isRequired: true,
                  ),
                  CustomTextField(
                    label: 'পিতা/স্বামীর নাম',
                    hintText: 'পিতা বা স্বামীর নাম লিখুন',
                    controller: _controllers[2],
                    onChanged: memberNotifier.updateFatherOrHusbandName,
                    isRequired: true,
                  ),
                  CustomTextField(
                    label: 'সদস্যের মোবাইল নং',
                    hintText: '01XXXXXXXXX',
                    keyboardType: TextInputType.phone,
                    controller: _controllers[3],
                    onChanged: memberNotifier.updateMemberMobile,
                    isRequired: true,
                  ),
                  CustomTextField(
                    label: 'জাতীয় পরিচয় পত্র/জন্ম নিবন্ধন নং',
                    hintText: 'জাতীয় পরিচয় পত্র বা জন্ম নিবন্ধন নং লিখুন',
                    keyboardType: TextInputType.number,
                    controller: _controllers[4],
                    onChanged: memberNotifier.updateNationalId,
                    isRequired: true,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Nominee Information Card
              _buildSectionCard(
                title: 'নমিনির তথ্য',
                icon: Icons.people,
                children: [
                  CustomTextField(
                    label: 'নমিনির নাম',
                    hintText: 'নমিনির পুরো নাম লিখুন',
                    controller: _controllers[5],
                    onChanged: memberNotifier.updateNomineeName,
                    isRequired: true,
                  ),
                  CustomTextField(
                    label: 'নমিনির সম্পর্ক',
                    hintText: 'সম্পর্ক লিখুন (পুত্র/কন্যা/স্ত্রী ইত্যাদি)',
                    controller: _controllers[6],
                    onChanged: memberNotifier.updateNomineeRelation,
                    isRequired: true,
                  ),
                  CustomTextField(
                    label: 'নমিনির মোবাইল নং',
                    hintText: '01XXXXXXXXX',
                    keyboardType: TextInputType.phone,
                    controller: _controllers[7],
                    onChanged: memberNotifier.updateNomineeMobile,
                    isRequired: true,
                  ),
                  CustomTextField(
                    label: 'নমিনির জাতীয় পরিচয় পত্র',
                    hintText: 'নমিনির জাতীয় পরিচয় পত্র নং লিখুন',
                    keyboardType: TextInputType.number,
                    controller: _controllers[8],
                    onChanged: memberNotifier.updateNomineeNationalId,
                    isRequired: true,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Guarantor Information Card
              _buildSectionCard(
                title: 'জামিনদারের তথ্য',
                icon: Icons.assignment_ind,
                children: [
                  CustomTextField(
                    label: 'জামিনদারের নাম',
                    hintText: 'জামিনদারের পুরো নাম লিখুন',
                    controller: _controllers[9],
                    onChanged: memberNotifier.updateGuarantorName,
                    isRequired: true,
                  ),
                  CustomTextField(
                    label: 'জামিনদারের জাতীয় পরিচয় পত্র',
                    hintText: 'জামিনদারের জাতীয় পরিচয় পত্র নং লিখুন',
                    keyboardType: TextInputType.number,
                    controller: _controllers[10],
                    onChanged: memberNotifier.updateGuarantorNationalId,
                    isRequired: true,
                  ),
                  CustomTextField(
                    label: 'জামিনদারের মোবাইল নং',
                    hintText: '01XXXXXXXXX',
                    keyboardType: TextInputType.phone,
                    controller: _controllers[11],
                    onChanged: memberNotifier.updateGuarantorMobile,
                    isRequired: true,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'সদস্য সংরক্ষণ করুন',
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
                Icon(
                  icon,
                  color: Colors.green[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
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
class CustomTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool isRequired;

  const CustomTextField({
    Key? key,
    required this.label,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    required this.controller,
    this.onChanged,
    this.isRequired = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}