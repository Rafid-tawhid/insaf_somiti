import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/members.dart';
import '../providers/member_providers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/members.dart';
import '../providers/member_providers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemberEntryScreen extends ConsumerStatefulWidget {
  final Member? member; // Add this parameter for edit mode
  final bool isEditMode; // Add this to track if we're editing

  const MemberEntryScreen({
    Key? key,
    this.member, // Make it optional for add mode
    this.isEditMode = false, // Default is false (add mode)
  }) : super(key: key);

  @override
  ConsumerState<MemberEntryScreen> createState() => _MemberEntryScreenState();
}

class _MemberEntryScreenState extends ConsumerState<MemberEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = List.generate(12, (_) => TextEditingController());
  final FocusNode _mobileFocusNode = FocusNode();
  bool _isCheckingMobile = false;
  bool _isMobileUnique = true;
  bool _isEditMode = false;
  String? _memberId; // Store member ID for updates

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((v){
      _isEditMode = widget.isEditMode;

      if (_isEditMode && widget.member != null) {
        debugPrint('Member Id is ${widget.member!.id}');
        _memberId = widget.member!.id;
        _initializeFormWithMemberData(widget.member!);
        setState(() {

        });
      }
      _mobileFocusNode.addListener(_onMobileFocusChange);
    });
  }

  void _initializeFormWithMemberData(Member member) {
    // Initialize all text controllers with member data
    _controllers[0].text = member.memberNumber;
    _controllers[1].text = member.memberName;
    _controllers[2].text = member.fatherOrHusbandName;
    _controllers[3].text = member.memberMobile;
    _controllers[4].text = member.nationalIdOrBirthCertificate;
    _controllers[5].text = member.nomineeName;
    _controllers[6].text = member.nomineeRelation;
    _controllers[7].text = member.nomineeMobile;
    _controllers[8].text = member.nomineeNationalId;
    _controllers[9].text = member.guarantorName;
    _controllers[10].text = member.guarantorNationalId;
    _controllers[11].text = member.guarantorMobile;

    // Update the provider with existing data
    final memberNotifier = ref.read(memberFormProvider.notifier);
    memberNotifier.updateMemberNumber(member.memberNumber);
    memberNotifier.updateMemberName(member.memberName);
    memberNotifier.updateFatherOrHusbandName(member.fatherOrHusbandName);
    memberNotifier.updateMemberMobile(member.memberMobile);
    memberNotifier.updateNationalId(member.nationalIdOrBirthCertificate);
    memberNotifier.updateNomineeName(member.nomineeName);
    memberNotifier.updateNomineeRelation(member.nomineeRelation);
    memberNotifier.updateNomineeMobile(member.nomineeMobile);
    memberNotifier.updateNomineeNationalId(member.nomineeNationalId);
    memberNotifier.updateGuarantorName(member.guarantorName);
    memberNotifier.updateGuarantorNationalId(member.guarantorNationalId);
    memberNotifier.updateGuarantorMobile(member.guarantorMobile);
  }

  void _onMobileFocusChange() {
    if (!_mobileFocusNode.hasFocus && _controllers[3].text.isNotEmpty) {
      // Only check mobile uniqueness in add mode or if mobile number changed in edit mode
      if (!_isEditMode || (_isEditMode && widget.member?.memberMobile != _controllers[3].text)) {
        _checkMobileUnique(_controllers[3].text);
      }
    }
  }

  Future<void> _checkMobileUnique(String mobile) async {
    if (mobile.isEmpty) return;

    setState(() {
      _isCheckingMobile = true;
      _isMobileUnique = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('members')
          .where('memberMobile', isEqualTo: mobile)
          .limit(1)
          .get();

      setState(() {
        // In edit mode, allow the same mobile number if it belongs to the same member
        if (_isEditMode && widget.member != null) {
          _isMobileUnique = snapshot.docs.isEmpty ||
              snapshot.docs.first.id == widget.member!.id;
        } else {
          _isMobileUnique = snapshot.docs.isEmpty;
        }
      });
    } catch (e) {
      print('Error checking mobile uniqueness: $e');
    } finally {
      setState(() {
        _isCheckingMobile = false;
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _mobileFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isMobileUnique) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('এই মোবাইল নম্বরটি ইতিমধ্যে ব্যবহৃত হয়েছে!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isCheckingMobile) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('দয়া করে মোবাইল নম্বর চেক হওয়ার জন্য অপেক্ষা করুন'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final member = ref.read(memberFormProvider);
      final firebaseService = ref.read(firebaseServiceProvider);

      if (_isEditMode && _memberId != null) {
        // Create a map with only changed fields
        final Map<String, dynamic> updatedData = {};

        // Compare each field with original member data
        if (_controllers[0].text != widget.member!.memberNumber) {
          updatedData['memberNumber'] = _controllers[0].text;
        }
        if (_controllers[1].text != widget.member!.memberName) {
          updatedData['memberName'] = _controllers[1].text;
        }
        if (_controllers[2].text != widget.member!.fatherOrHusbandName) {
          updatedData['fatherOrHusbandName'] = _controllers[2].text;
        }
        if (_controllers[3].text != widget.member!.memberMobile) {
          updatedData['memberMobile'] = _controllers[3].text;
        }
        if (_controllers[4].text != widget.member!.nationalIdOrBirthCertificate) {
          updatedData['nationalIdOrBirthCertificate'] = _controllers[4].text;
        }
        if (_controllers[5].text != widget.member!.nomineeName) {
          updatedData['nomineeName'] = _controllers[5].text;
        }
        if (_controllers[6].text != widget.member!.nomineeRelation) {
          updatedData['nomineeRelation'] = _controllers[6].text;
        }
        if (_controllers[7].text != widget.member!.nomineeMobile) {
          updatedData['nomineeMobile'] = _controllers[7].text;
        }
        if (_controllers[8].text != widget.member!.nomineeNationalId) {
          updatedData['nomineeNationalId'] = _controllers[8].text;
        }
        if (_controllers[9].text != widget.member!.guarantorName) {
          updatedData['guarantorName'] = _controllers[9].text;
        }
        if (_controllers[10].text != widget.member!.guarantorNationalId) {
          updatedData['guarantorNationalId'] = _controllers[10].text;
        }
        if (_controllers[11].text != widget.member!.guarantorMobile) {
          updatedData['guarantorMobile'] = _controllers[11].text;
        }

        // Add updated timestamp
        updatedData['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

        // Only update if there are changes
        if (updatedData.isNotEmpty) {
          await firebaseService.updateMember(updatedData, _memberId!);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('সদস্য তথ্য সফলভাবে আপডেট করা হয়েছে!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('কোনো পরিবর্তন পাওয়া যায়নি!'),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Navigate back
        Navigator.pop(context, true);
      } else {
        // Add new member - keep existing code
        final snapshot = await FirebaseFirestore.instance
            .collection('members')
            .where('memberMobile', isEqualTo: member.memberMobile)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('এই মোবাইল নম্বরটি ইতিমধ্যে ব্যবহৃত হয়েছে!'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        await firebaseService.addMember(member);

        // Reset form
        ref.read(memberFormProvider.notifier).resetForm();
        for (var controller in _controllers) {
          controller.clear();
        }
        setState(() {
          _isMobileUnique = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('সদস্য সফলভাবে যোগ করা হয়েছে!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final memberNotifier = ref.read(memberFormProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'সদস্য তথ্য সম্পাদনা করুন' : 'নতুন সদস্য যোগ করুন',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: _isEditMode ? Colors.orange[700] : Colors.green[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Info Card
              _buildInfoCard(),

              const SizedBox(height: 16),

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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'সদস্য নং প্রয়োজন';
                      }
                      return null;
                    },
                  ),
                  CustomTextField(
                    label: 'সদস্যের নাম',
                    hintText: 'সদস্যের পুরো নাম লিখুন',
                    controller: _controllers[1],
                    onChanged: memberNotifier.updateMemberName,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'সদস্যের নাম প্রয়োজন';
                      }
                      return null;
                    },
                  ),
                  CustomTextField(
                    label: 'পিতা/স্বামীর নাম',
                    hintText: 'পিতা বা স্বামীর নাম লিখুন',
                    controller: _controllers[2],
                    onChanged: memberNotifier.updateFatherOrHusbandName,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'পিতা/স্বামীর নাম প্রয়োজন';
                      }
                      return null;
                    },
                  ),
                  CustomTextField(
                    label: 'সদস্যের মোবাইল নং',
                    hintText: '01XXXXXXXXX',
                    keyboardType: TextInputType.phone,
                    controller: _controllers[3],
                    focusNode: _mobileFocusNode,
                    onChanged: (value) {
                      memberNotifier.updateMemberMobile(value);
                      if (value.length == 11) {
                        if (!_isEditMode || (_isEditMode && widget.member?.memberMobile != value)) {
                          _checkMobileUnique(value);
                        }
                      }
                    },
                    isRequired: true,
                    suffix: _isCheckingMobile
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : _controllers[3].text.isNotEmpty &&
                        (!_isEditMode || (_isEditMode && widget.member?.memberMobile != _controllers[3].text))
                        ? Icon(
                      _isMobileUnique ? Icons.check_circle : Icons.error,
                      color: _isMobileUnique ? Colors.green : Colors.red,
                      size: 20,
                    )
                        : null,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'মোবাইল নম্বর প্রয়োজন';
                      }
                      if (value.length != 11 || !value.startsWith('01')) {
                        return 'সঠিক মোবাইল নম্বর লিখুন';
                      }
                      return null;
                    },
                  ),
                  CustomTextField(
                    label: 'জাতীয় পরিচয় পত্র/জন্ম নিবন্ধন নং',
                    hintText: 'জাতীয় পরিচয় পত্র বা জন্ম নিবন্ধন নং লিখুন',
                    keyboardType: TextInputType.number,
                    controller: _controllers[4],
                    onChanged: memberNotifier.updateNationalId,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'জাতীয় পরিচয় পত্র/জন্ম নিবন্ধন নং প্রয়োজন';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'নমিনির নাম প্রয়োজন';
                      }
                      return null;
                    },
                  ),
                  CustomTextField(
                    label: 'নমিনির সম্পর্ক',
                    hintText: 'সম্পর্ক লিখুন (পুত্র/কন্যা/স্ত্রী ইত্যাদি)',
                    controller: _controllers[6],
                    onChanged: memberNotifier.updateNomineeRelation,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'নমিনির সম্পর্ক প্রয়োজন';
                      }
                      return null;
                    },
                  ),
                  CustomTextField(
                    label: 'নমিনির মোবাইল নং',
                    hintText: '01XXXXXXXXX',
                    keyboardType: TextInputType.phone,
                    controller: _controllers[7],
                    onChanged: memberNotifier.updateNomineeMobile,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'নমিনির মোবাইল নম্বর প্রয়োজন';
                      }
                      if (value.length != 11 || !value.startsWith('01')) {
                        return 'সঠিক মোবাইল নম্বর লিখুন';
                      }
                      return null;
                    },
                  ),
                  CustomTextField(
                    label: 'নমিনির জাতীয় পরিচয় পত্র',
                    hintText: 'নমিনির জাতীয় পরিচয় পত্র নং লিখুন',
                    keyboardType: TextInputType.number,
                    controller: _controllers[8],
                    onChanged: memberNotifier.updateNomineeNationalId,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'নমিনির জাতীয় পরিচয় পত্র প্রয়োজন';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

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
                  ),
                  CustomTextField(
                    label: 'জামিনদারের জাতীয় পরিচয় পত্র',
                    hintText: 'জামিনদারের জাতীয় পরিচয় পত্র নং লিখুন',
                    keyboardType: TextInputType.number,
                    controller: _controllers[10],
                    onChanged: memberNotifier.updateGuarantorNationalId,
                  ),
                  CustomTextField(
                    label: 'জামিনদারের মোবাইল নং',
                    hintText: '01XXXXXXXXX',
                    keyboardType: TextInputType.phone,
                    controller: _controllers[11],
                    onChanged: memberNotifier.updateGuarantorMobile,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isEditMode ? Colors.orange[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isEditMode ? Colors.orange[200]! : Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            _isEditMode ? Icons.edit : Icons.info,
            color: _isEditMode ? Colors.orange[700] : Colors.blue[700],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEditMode
                  ? 'সদস্যের তথ্য সম্পাদনা করুন। মোবাইল নম্বর পরিবর্তন করলে ইউনিক চেক হবে।'
                  : 'সকল তথ্য সঠিকভাবে পূরণ করুন। মোবাইল নম্বর ইউনিক হতে হবে।',
              style: TextStyle(
                color: _isEditMode ? Colors.orange[800] : Colors.blue[800],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isEditMode ? Colors.orange[700] : Colors.green[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon: Icon(
          _isEditMode ? Icons.update : Icons.save,
          color: Colors.white,
        ),
        label: Text(
          _isEditMode ? 'আপডেট করুন' : 'সদস্য সংরক্ষণ করুন',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
                  color: _isEditMode ? Colors.orange[700] : Colors.green[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isEditMode ? Colors.orange[700] : Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
//
class CustomTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final bool isRequired;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const CustomTextField({
    Key? key,
    required this.label,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.isRequired = false,
    this.suffix,
    this.validator,
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
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(

              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: suffix != null
                  ? Padding(
                padding: const EdgeInsets.only(right: 16),
                child: suffix,
              )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                maxHeight: 20,
                maxWidth: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}