import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for input formatters
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Required for formatting the Date Picker
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

  // 🌟 New Controllers for your new goals
  late TextEditingController _goalCaloriesCtrl;
  late TextEditingController _goalStepsCtrl;

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

    // Stripping out "cm" and "kg" if they exist so it's just the integer
    _heightCtrl = TextEditingController(
      text: p.height.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    _weightCtrl = TextEditingController(
      text: p.currentWeight.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    _goalWeightCtrl = TextEditingController(
      text: p.goalWeight.replaceAll(RegExp(r'[^0-9]'), ''),
    );

    // Initialize new goals (Assuming default values for now until added to AppState)
    _goalCaloriesCtrl = TextEditingController(text: '2000');
    _goalStepsCtrl = TextEditingController(text: '10000');

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
    _goalCaloriesCtrl.dispose();
    _goalStepsCtrl.dispose();
    super.dispose();
  }

  // 🌟 Date Picker Logic
  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 3, 15), // Default starting date
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.teal, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: AppColors.textDark, // Body text color
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
    if (!_formKey.currentState!.validate()) return;

    // 🌟 1. Prepare the data payload
    final updatedData = {
      "name": _nameCtrl.text.trim(),
      "email": _emailCtrl.text.trim(),
      "dateOfBirth": _dobCtrl.text.trim(),
      "height": "${_heightCtrl.text.trim()} cm",
      "currentWeight": "${_weightCtrl.text.trim()} kg",
      "goalWeight": "${_goalWeightCtrl.text.trim()} kg",
      "goalCalories": int.tryParse(_goalCaloriesCtrl.text.trim()) ?? 2000,
      "goalSteps": int.tryParse(_goalStepsCtrl.text.trim()) ?? 10000,
      "activityLevel": _activityLevel,
    };

    // 🌟 2. TODO: Send Data to your FastAPI Backend
    /*
    try {
      final response = await http.patch(
        Uri.parse('https://your-api.com/users/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );
      if (response.statusCode != 200) throw Exception('Failed to save');
    } catch (e) {
      // Show error snackbar and return early
    }
    */

    // 3. Update local state
    AppState().updateProfile(
      UserProfile(
        name: updatedData["name"] as String,
        email: updatedData["email"] as String,
        dateOfBirth: updatedData["dateOfBirth"] as String,
        height: updatedData["height"] as String,
        currentWeight: updatedData["currentWeight"] as String,
        goalWeight: updatedData["goalWeight"] as String,
        activityLevel: updatedData["activityLevel"] as String,
      ),
    );

    // 4. Close sheet and show success
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
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
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
                _field(
                  'Full Name *',
                  _nameCtrl,
                  'e.g. Sarah Rivera',
                  validator: (v) => v!.isEmpty ? 'Required' : null,
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

                // 🌟 Using the Date Picker for Date of Birth
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
                        'Daily Calories',
                        _goalCaloriesCtrl,
                        '2000',
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        'Daily Steps',
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
                          onTap: () => setState(() => _activityLevel = level),
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

  // 🌟 Updated to handle isNumber, readOnly, and onTap
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
          keyboardType: isNumber ? TextInputType.number : keyboardType,
          // Restricts input to 0-9 if isNumber is true
          inputFormatters:
              isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
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
