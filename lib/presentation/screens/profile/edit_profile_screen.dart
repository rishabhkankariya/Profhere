import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/toast.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _codeCtrl   = TextEditingController();
  final _deptCtrl   = TextEditingController();
  int? _selectedYear;

  static const _years = [1, 2, 3, 4, 5];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).user;
    _nameCtrl.text  = user?.name ?? '';
    _phoneCtrl.text = user?.phoneNumber ?? '';
    _codeCtrl.text  = user?.studentCode ?? '';
    _deptCtrl.text  = user?.department ?? '';
    _selectedYear   = user?.yearOfStudy;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _codeCtrl.dispose(); _deptCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).updateProfile(
      name: _nameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      yearOfStudy: _selectedYear,
      department: _deptCtrl.text.trim().isEmpty ? null : _deptCtrl.text.trim(),
      studentCode: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      if (prev?.isLoading == true && !next.isLoading) {
        if (next.error != null) {
          Toast.error(context, next.error!, title: 'Update Failed');
          ref.read(authNotifierProvider.notifier).clearError();
        } else if (next.user != null) {
          Toast.success(context, 'Profile updated successfully!');
          Navigator.pop(context);
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Edit Profile',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: auth.isLoading ? null : _save,
              child: auth.isLoading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sectionLabel('Personal Info'),
              const SizedBox(height: 12),
              _field(_nameCtrl, 'Full Name', Icons.person_outline_rounded,
                  caps: TextCapitalization.words,
                  validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null),
              const SizedBox(height: 12),
              _field(_phoneCtrl, 'Phone Number', Icons.phone_outlined,
                  type: TextInputType.phone),
              const SizedBox(height: 20),

              _sectionLabel('Academic Info'),
              const SizedBox(height: 12),
              _field(_codeCtrl, 'Roll No / Enrollment Number', Icons.badge_outlined),
              const SizedBox(height: 12),
              _field(_deptCtrl, 'Department', Icons.business_outlined,
                  caps: TextCapitalization.words),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Year of Study',
                  prefixIcon: Icon(Icons.school_outlined, size: 18),
                ),
                items: _years.map((y) => DropdownMenuItem(
                  value: y, child: Text('Year $y'),
                )).toList(),
                onChanged: (v) => setState(() => _selectedYear = v),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: AppColors.textMuted, letterSpacing: 0.5));
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {
    TextInputType type = TextInputType.text,
    TextCapitalization caps = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      textCapitalization: caps,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 18)),
      validator: validator,
    );
  }
}
