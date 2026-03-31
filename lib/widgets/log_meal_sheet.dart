import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../state/app_state.dart';
import '../services/api_service.dart'; // 🌟 1. Import your ApiService

// 🌟 2. Update to accept the user payload
void showLogMealSheet(BuildContext context, Map<String, dynamic> user) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    showDragHandle: true,
    builder: (_) => _LogMealSheet(user: user), // Pass it down
  );
}

class _LogMealSheet extends StatefulWidget {
  final Map<String, dynamic> user; // 🌟 3. Accept it in the widget
  const _LogMealSheet({super.key, required this.user});

  @override
  State<_LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends State<_LogMealSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _fatsCtrl = TextEditingController();
  final _sodiumCtrl = TextEditingController();
  final _sugarCtrl = TextEditingController();

  String _selectedMealType = 'Breakfast';
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _carbsCtrl.dispose();
    _proteinCtrl.dispose();
    _fatsCtrl.dispose();
    _sodiumCtrl.dispose();
    _sugarCtrl.dispose();
    super.dispose();
  }

  // 🌟 4. Make _submit async so we can await the API call!
  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    final time = '$hour:${now.minute.toString().padLeft(2, '0')} $period';

    // Parse the values safely
    final name = _nameCtrl.text.trim();
    final calories = int.tryParse(_calCtrl.text) ?? 0;
    final carbs = int.tryParse(_carbsCtrl.text) ?? 0;
    final protein = int.tryParse(_proteinCtrl.text) ?? 0;
    final fats = int.tryParse(_fatsCtrl.text) ?? 0;
    final sodium = int.tryParse(_sodiumCtrl.text) ?? 0;
    final sugar = int.tryParse(_sugarCtrl.text) ?? 0;

    // 🌟 5. Fire the API call first!
    bool success = await ApiService.logMeal(
      userId: widget.user['id'], // Get the ID from the passed user map
      name: name,
      mealType: _selectedMealType,
      calories: calories,
      carbs: carbs,
      protein: protein,
      fats: fats,
      sodium: sodium,
      sugar: sugar,
      time: time,
    );

    // If it fails, show an error and stop
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to log meal to server.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    // 🌟 6. If the API succeeds, update the local UI!
    AppState().addMeal(
      MealEntry(
        name: name,
        mealType: _selectedMealType,
        calories: calories,
        carbs: carbs,
        protein: protein,
        fats: fats,
        sodium: sodium,
        sugar: sugar,
        time: time,
      ),
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Meal logged!',
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
                      Icons.restaurant_rounded,
                      color: AppColors.teal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Log a Meal',
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Meal type chips
              Text('Meal Type', style: _labelStyle()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    _mealTypes.map((type) {
                      final selected = _selectedMealType == type;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedMealType = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                selected ? AppColors.teal : AppColors.tealLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            type,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : AppColors.teal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 18),

              Text('Food Name *', style: _labelStyle()),
              const SizedBox(height: 6),
              _textField(
                _nameCtrl,
                'e.g. Banku and Grilled Tilapia',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              Text('Calories (kcal) *', style: _labelStyle()),
              const SizedBox(height: 6),
              _textField(
                _calCtrl,
                'e.g. 450',
                isNumber: true,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              Text('Macros (optional)', style: _labelStyle()),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _textField(_carbsCtrl, 'Carbs (g)', isNumber: true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _textField(
                      _proteinCtrl,
                      'Protein (g)',
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _textField(_fatsCtrl, 'Fats (g)', isNumber: true),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 🌟 The New Medical Fields
              Text('Medical Tracking (optional)', style: _labelStyle()),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _textField(
                      _sodiumCtrl,
                      'Sodium (mg)',
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _textField(_sugarCtrl, 'Sugar (g)', isNumber: true),
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
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Save Meal',
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
