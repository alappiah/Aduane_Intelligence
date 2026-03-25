import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

void showAddWorkoutSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddWorkoutSheet(),
  );
}

class _AddWorkoutSheet extends StatefulWidget {
  const _AddWorkoutSheet();

  @override
  State<_AddWorkoutSheet> createState() => _AddWorkoutSheetState();
}

class _AddWorkoutSheetState extends State<_AddWorkoutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  // 🌟 Split into Hours and Mins!
  final _hoursCtrl = TextEditingController();
  final _minsCtrl = TextEditingController();

  final _caloriesCtrl = TextEditingController();
  String _selectedType = 'Cardio';
  final List<String> _workoutTypes = [
    'Cardio',
    'Strength',
    'Yoga',
    'HIIT',
    'Sports',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // 🌟 Set the auto-name immediately when the sheet opens
    _generateAutoName();

    // Listen to BOTH time fields to calculate calories dynamically
    _hoursCtrl.addListener(_calculateCalories);
    _minsCtrl.addListener(_calculateCalories);
  }

  @override
  void dispose() {
    _hoursCtrl.removeListener(_calculateCalories);
    _minsCtrl.removeListener(_calculateCalories);
    _nameCtrl.dispose();
    _hoursCtrl.dispose();
    _minsCtrl.dispose();
    _caloriesCtrl.dispose();
    super.dispose();
  }

  // 🌟 SMART UX: Auto-generates names like "Morning Yoga" or "Evening Sports"
  void _generateAutoName() {
    final hour = DateTime.now().hour;
    String timeOfDay = 'Morning';
    if (hour >= 12 && hour < 17) {
      timeOfDay = 'Afternoon';
    } else if (hour >= 17) {
      timeOfDay = 'Evening';
    }
    _nameCtrl.text = '$timeOfDay $_selectedType';
  }

  // 🌟 THE AUTO-CALCULATOR (Now handles both Hours and Mins)
  void _calculateCalories() {
    int h = int.tryParse(_hoursCtrl.text) ?? 0;
    int m = int.tryParse(_minsCtrl.text) ?? 0;

    int totalMinutes = (h * 60) + m;

    if (totalMinutes == 0) {
      _caloriesCtrl.clear();
      return;
    }

    String weightStr = AppState().profile.currentWeight.replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );
    double weightKg = double.tryParse(weightStr) ?? 65.0;

    double met = 4.0;
    switch (_selectedType) {
      case 'Yoga':
        met = 2.5;
        break;
      case 'Strength':
        met = 3.0;
        break;
      case 'Sports':
        met = 6.0;
        break;
      case 'Cardio':
        met = 7.0;
        break;
      case 'HIIT':
        met = 8.0;
        break;
      case 'Other':
        met = 4.0;
        break;
    }

    double timeInHours = totalMinutes / 60.0;
    int estimatedCalories = (met * weightKg * timeInHours).round();

    _caloriesCtrl.text = estimatedCalories.toString();
  }

  void _submit() async {
    // 🌟 Added async here!
    if (!_formKey.currentState!.validate()) return;

    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    final time = '$hour:${now.minute.toString().padLeft(2, '0')} $period';

    // Combine for the database
    int h = int.tryParse(_hoursCtrl.text) ?? 0;
    int m = int.tryParse(_minsCtrl.text) ?? 0;
    int totalMinutes = (h * 60) + m;

    // Prevent saving 0 minute workouts
    if (totalMinutes == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a duration!')));
      return;
    }

    int calories = int.tryParse(_caloriesCtrl.text) ?? 0;

    // 🌟 1. Grab the current user ID from AppState
    int currentUserId =
        AppState().currentUserId ?? 1; // Fallback to 1 just in case

    // 🌟 2. Send the data to your FastAPI Backend!
    bool success = await ApiService.logWorkout(
      userId: currentUserId,
      name: _nameCtrl.text.trim(),
      type: _selectedType,
      durationMinutes: totalMinutes,
      caloriesBurned: calories,
      time: time,
    );

    // 🌟 3. Handle server errors
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save workout to server.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    // 🌟 4. If the server says OK, update the local UI
    AppState().addWorkout(
      WorkoutEntry(
        name: _nameCtrl.text.trim(),
        type: _selectedType,
        durationMinutes: totalMinutes,
        caloriesBurned: calories,
        time: time,
      ),
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Workout added!',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.pink,
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
                        color: AppColors.pinkLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.monitor_heart_rounded,
                        color: AppColors.pink,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Add Workout',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text('Workout Type', style: _labelStyle()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _workoutTypes.map((type) {
                        final selected = _selectedType == type;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = type;
                              _generateAutoName(); // Update the name if they tap a different chip!
                              _calculateCalories();
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  selected
                                      ? AppColors.pink
                                      : AppColors.pinkLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              type,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : AppColors.pink,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 18),

                Text('Workout Name', style: _labelStyle()),
                const SizedBox(height: 6),
                _textField(_nameCtrl, 'e.g. Morning run'),
                const SizedBox(height: 14),

                Row(
                  children: [
                    // 🌟 The New Hours Field
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hours', style: _labelStyle()),
                          const SizedBox(height: 6),
                          _textField(_hoursCtrl, '0', isNumber: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 🌟 The New Mins Field
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mins', style: _labelStyle()),
                          const SizedBox(height: 6),
                          _textField(_minsCtrl, '30', isNumber: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // The Calories Box
                    Expanded(
                      flex: 2, // Gives the calories box slightly more room
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Approx. Calories Burned', style: _labelStyle()),
                          const SizedBox(height: 6),
                          _textField(_caloriesCtrl, 'e.g. 320', isNumber: true),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pink,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Save Workout',
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

  TextStyle _labelStyle() => GoogleFonts.nunito(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textMedium,
  );

  Widget _textField(
    TextEditingController ctrl,
    String hint, {
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters:
          isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
      validator: validator,
      style: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.textLight),
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
    );
  }
}
