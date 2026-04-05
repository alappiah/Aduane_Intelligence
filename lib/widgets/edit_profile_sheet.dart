import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';
import '../services/network_helper.dart';

void showEditProfileSheet(BuildContext context, Map<String, dynamic> user) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight:
          MediaQuery.of(context).size.height *
          0.90, // 🌟 2. Forces it to only take up 90% of the screen, leaving a clean gap at the top!
    ),
    builder: (_) => _EditProfileSheet(user: user),
  );
}

class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  const _EditProfileSheet({super.key, required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fNameCtrl;
  late TextEditingController _lNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _goalWeightCtrl;

  late TextEditingController _goalCaloriesCtrl;
  late TextEditingController _goalStepsCtrl;

  late String _activityLevel;
  late String _selectedHealthCondition;

  final List<String> _activityLevels = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
    'Extra Active',
  ];

  final List<String> _healthConditions = [
    'None',
    'Hypertension',
    'Diabetes',
    'High Cholesterol',
  ];

  @override
  void initState() {
    super.initState();
    final p = AppState().profile;

    final String firstName = widget.user['firstName'] ?? '';
    final String lastName = widget.user['lastName'] ?? '';
    final String dbName = [
      firstName,
      lastName,
    ].where((e) => e.isNotEmpty).join(' ');

    _fNameCtrl = TextEditingController(text: p.firstName);
    _lNameCtrl = TextEditingController(text: p.lastName);
    _emailCtrl = TextEditingController(text: widget.user['email'] ?? p.email);
    _dobCtrl = TextEditingController(text: p.dateOfBirth);

    _heightCtrl = TextEditingController(
      text:
          widget.user['height_cm']?.toString() ??
          p.height.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    _weightCtrl = TextEditingController(
      text:
          widget.user['current_weight_kg']?.toString() ??
          p.currentWeight.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    _goalWeightCtrl = TextEditingController(
      text:
          widget.user['goal_weight_kg']?.toString() ??
          p.goalWeight.replaceAll(RegExp(r'[^0-9.]'), ''),
    );

    _goalCaloriesCtrl = TextEditingController(
      text: widget.user['goal_calories']?.toString() ?? '2000',
    );
    _goalStepsCtrl = TextEditingController(
      text: widget.user['goal_steps']?.toString() ?? '10000',
    );

    _activityLevel = widget.user['activity_level'] ?? p.activityLevel;

    String currentCondition = widget.user['health_condition'] ?? 'None';
    if (!_healthConditions.contains(currentCondition)) {
      currentCondition = 'None';
    }
    _selectedHealthCondition = currentCondition;
  }

  @override
  void dispose() {
    _fNameCtrl.dispose();
    _lNameCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _goalWeightCtrl.dispose();
    _goalCaloriesCtrl.dispose();
    _goalStepsCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 3, 15),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.teal,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobCtrl.text = DateFormat('MMMM d, yyyy').format(picked);
      });
    }
  }

  void _save() async {
    bool hasInternet = await isConnectedToInternet();
    if (!hasInternet) return;
    if (!_formKey.currentState!.validate()) return;

    final updatedData = {
      "firstName": _fNameCtrl.text.trim(),
      "lastName": _lNameCtrl.text.trim(),
      "email": _emailCtrl.text.trim(),
      "health_condition": _selectedHealthCondition,
      "dateOfBirth": _dobCtrl.text.trim(),
      "height": "${_heightCtrl.text.trim()} cm",
      "currentWeight": "${_weightCtrl.text.trim()} kg",
      "goalWeight": "${_goalWeightCtrl.text.trim()} kg",
      "goalCalories": int.tryParse(_goalCaloriesCtrl.text.trim()) ?? 2000,
      "goalSteps": int.tryParse(_goalStepsCtrl.text.trim()) ?? 10000,
      "activityLevel": _activityLevel,
    };

    bool success = await ApiService.updateUserProfile(
      userId: widget.user['id'],
      firstName: _fNameCtrl.text.trim(),
      lastName: _lNameCtrl.text.trim(),
      dateOfBirth: _dobCtrl.text.trim(),
      height: int.tryParse(_heightCtrl.text.trim()) ?? 0,
      currentWeight: double.tryParse(_weightCtrl.text.trim()) ?? 0.0,
      goalWeight: double.tryParse(_goalWeightCtrl.text.trim()) ?? 0.0,
      goalCalories: int.tryParse(_goalCaloriesCtrl.text.trim()) ?? 2000,
      goalSteps: int.tryParse(_goalStepsCtrl.text.trim()) ?? 10000,
      activityLevel: _activityLevel,
      healthCondition: _selectedHealthCondition,
    );

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile. Please try again.',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // 🌟 THE COMPLETE FIX: Overwrite EVERY field in the parent map!
    widget.user['firstName'] = _fNameCtrl.text.trim();
    widget.user['lastName'] = _lNameCtrl.text.trim();
    widget.user['email'] = _emailCtrl.text.trim();
    widget.user['health_condition'] = _selectedHealthCondition;
    widget.user['activity_level'] = _activityLevel;
    widget.user['height_cm'] = _heightCtrl.text.trim();
    widget.user['current_weight_kg'] = _weightCtrl.text.trim();
    widget.user['goal_weight_kg'] = _goalWeightCtrl.text.trim();
    widget.user['goal_calories'] = updatedData["goalCalories"];
    widget.user['goal_steps'] = updatedData["goalSteps"];

    // Update the local AppState
    AppState().updateProfile(
      UserProfile(
        firstName: _fNameCtrl.text.trim(),
        lastName: _lNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        healthCondition: _selectedHealthCondition, // 🌟 Safe and direct!
        dateOfBirth: _dobCtrl.text.trim(),
        height: _heightCtrl.text.trim(),
        currentWeight: _weightCtrl.text.trim(),
        goalWeight: _goalWeightCtrl.text.trim(),
        activityLevel: _activityLevel, // 🌟 Safe and direct!
        goalCalories: int.tryParse(_goalCaloriesCtrl.text.trim()) ?? 2000,
        goalSteps: int.tryParse(_goalStepsCtrl.text.trim()) ?? 10000,
      ),
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated!',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        // 🌟 FIX: We use a Column to separate the pinned drag handle from the scroll view!
        child: Column(
          mainAxisSize:
              MainAxisSize
                  .min, // Shrinks to fit content, up to max screen height
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 1. PINNED DRAG HANDLE
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 🌟 2. SCROLLABLE FORM
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.tealLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: AppColors.teal,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Edit Profile',
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _sectionLabel('Personal Details'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              'First Name *',
                              _fNameCtrl,
                              'e.g. Sarah',
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              'Last Name *',
                              _lNameCtrl,
                              'e.g. Rivera',
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _field(
                        'Email *',
                        _emailCtrl,
                        'e.g. sarah@email.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Health Condition',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMedium,
                        ),
                      ),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<String>(
                        value: _selectedHealthCondition,
                        dropdownColor: Colors.white,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textLight,
                        ),
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.bg,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items:
                            _healthConditions.map((condition) {
                              return DropdownMenuItem(
                                value: condition,
                                child: Text(condition),
                              );
                            }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedHealthCondition = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      _field(
                        'Date of Birth',
                        _dobCtrl,
                        'Select your birthday',
                        readOnly: true,
                        onTap: () => _selectDate(context),
                      ),
                      const SizedBox(height: 20),

                      _sectionLabel('Body Metrics'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              'Height (cm)',
                              _heightCtrl,
                              '168',
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              'Current Weight (kg)',
                              _weightCtrl,
                              '65',
                              isNumber: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _sectionLabel('Health Goals'),
                      const SizedBox(height: 10),
                      _field(
                        'Goal Weight (kg)',
                        _goalWeightCtrl,
                        '60',
                        isNumber: true,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              'Goal Calories',
                              _goalCaloriesCtrl,
                              '2000',
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              'Goal Steps',
                              _goalStepsCtrl,
                              '10000',
                              isNumber: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _sectionLabel('Activity Level'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _activityLevels.map((level) {
                              final selected = _activityLevel == level;
                              return GestureDetector(
                                onTap:
                                    () =>
                                        setState(() => _activityLevel = level),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        selected
                                            ? AppColors.teal
                                            : AppColors.tealLight,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    level,
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          selected
                                              ? Colors.white
                                              : AppColors.teal,
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Save Changes',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: GoogleFonts.nunito(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: AppColors.textDark,
    ),
  );

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isNumber = false,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: ctrl,
          keyboardType:
              isNumber
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
          inputFormatters:
              isNumber
                  ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
                  : null,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.textLight,
            ),
            filled: true,
            fillColor: AppColors.bg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorStyle: GoogleFonts.nunito(fontSize: 11),
          ),
        ),
      ],
    );
  }
}
