import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../state/app_state.dart';

// 🌟 Public function to trigger the sheet
void showLogMealSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _LogMealSheet(),
  );
}

class _LogMealSheet extends StatefulWidget {
  const _LogMealSheet();

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
  String _selectedMealType = 'Breakfast';
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _carbsCtrl.dispose();
    _proteinCtrl.dispose();
    _fatsCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    final time = '$hour:${now.minute.toString().padLeft(2, '0')} $period';

    AppState().addMeal(MealEntry(
      name: _nameCtrl.text.trim(),
      mealType: _selectedMealType,
      calories: int.tryParse(_calCtrl.text) ?? 0,
      carbs: int.tryParse(_carbsCtrl.text) ?? 0,
      protein: int.tryParse(_proteinCtrl.text) ?? 0,
      fats: int.tryParse(_fatsCtrl.text) ?? 0,
      time: time,
    ));

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Meal logged!', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
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
                // Handle
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
                      child: const Icon(Icons.restaurant_rounded, color: AppColors.teal, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text('Log a Meal', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  ],
                ),
                const SizedBox(height: 24),

                // Meal type chips
                Text('Meal Type', style: _labelStyle()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _mealTypes.map((type) {
                    final selected = _selectedMealType == type;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedMealType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.teal : AppColors.tealLight,
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
                _textField(_nameCtrl, 'e.g. Grilled Chicken Salad', validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 14),

                Text('Calories (kcal) *', style: _labelStyle()),
                const SizedBox(height: 6),
                _textField(_calCtrl, 'e.g. 450', isNumber: true, validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 14),

                Text('Macros (optional)', style: _labelStyle()),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _textField(_carbsCtrl, 'Carbs (g)', isNumber: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _textField(_proteinCtrl, 'Protein (g)', isNumber: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _textField(_fatsCtrl, 'Fats (g)', isNumber: true)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Save Meal', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle() => GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMedium);

  Widget _textField(TextEditingController ctrl, String hint, {bool isNumber = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
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
    );
  }
}