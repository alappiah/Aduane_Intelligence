import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../state/app_state.dart';

void showEditProfileSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _EditProfileSheet(),
  );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _goalWeightCtrl;
  late String _activityLevel;

  final List<String> _activityLevels = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
    'Extra Active',
  ];

  @override
  void initState() {
    super.initState();
    final p = AppState().profile;
    _nameCtrl = TextEditingController(text: p.name);
    _emailCtrl = TextEditingController(text: p.email);
    _dobCtrl = TextEditingController(text: p.dateOfBirth);
    _heightCtrl = TextEditingController(text: p.height);
    _weightCtrl = TextEditingController(text: p.currentWeight);
    _goalWeightCtrl = TextEditingController(text: p.goalWeight);
    _activityLevel = p.activityLevel;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _goalWeightCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    AppState().updateProfile(UserProfile(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      dateOfBirth: _dobCtrl.text.trim(),
      height: _heightCtrl.text.trim(),
      currentWeight: _weightCtrl.text.trim(),
      goalWeight: _goalWeightCtrl.text.trim(),
      activityLevel: _activityLevel,
    ));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated!', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.edit_rounded, color: AppColors.teal, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text('Edit Profile', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  ],
                ),
                const SizedBox(height: 24),

                _sectionLabel('Personal Details'),
                const SizedBox(height: 10),
                _field('Full Name *', _nameCtrl, 'e.g. Sarah Rivera', validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                _field('Email *', _emailCtrl, 'e.g. sarah@email.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                _field('Date of Birth', _dobCtrl, 'e.g. March 15, 1995'),
                const SizedBox(height: 20),

                _sectionLabel('Body Metrics'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field('Height', _heightCtrl, 'e.g. 168 cm')),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Current Weight', _weightCtrl, 'e.g. 65.2 kg')),
                  ],
                ),
                const SizedBox(height: 12),
                _field('Goal Weight', _goalWeightCtrl, 'e.g. 60.0 kg'),
                const SizedBox(height: 20),

                _sectionLabel('Activity Level'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _activityLevels.map((level) {
                    final selected = _activityLevel == level;
                    return GestureDetector(
                      onTap: () => setState(() => _activityLevel = level),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.teal : AppColors.tealLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          level,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : AppColors.teal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Save Changes', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark),
  );

  Widget _field(String label, TextEditingController ctrl, String hint, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMedium)),
        const SizedBox(height: 5),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.textLight),
            filled: true,
            fillColor: AppColors.bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            errorStyle: GoogleFonts.nunito(fontSize: 11),
          ),
        ),
      ],
    );
  }
}