import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

class RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const RecipeCard({super.key, required this.recipe});

  void _logMeal(BuildContext context) async {
    // ... [Your existing _logMeal code stays EXACTLY the same here!] ...
    final state = AppState();
    final userId = state.currentUserId ?? 1;

    int parseNutrition(String? val) {
      if (val == null) return 0;
      final numberString = val.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(numberString) ?? 0;
    }

    int sugar = parseNutrition(recipe['nutrition']?['sugar']);
    int sodium = parseNutrition(recipe['nutrition']?['sodium']);
    int fat = parseNutrition(recipe['nutrition']?['fat']);
    int calories = int.tryParse(recipe['calories']?.toString() ?? '') ?? 0;
    int carbs = int.tryParse(recipe['carbs']?.toString() ?? '') ?? 0;
    int protein = int.tryParse(recipe['protein']?.toString() ?? '') ?? 0;

    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    final timeString = '$hour:${now.minute.toString().padLeft(2, '0')} $period';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logging meal...'),
        duration: Duration(seconds: 1),
      ),
    );

    bool success = await ApiService.logMeal(
      userId: userId,
      name: recipe['name'] ?? 'AI Recommended Meal',
      mealType: recipe['meal_type'] ?? 'General',
      calories: calories,
      carbs: carbs,
      protein: protein,
      fats: fat,
      sodium: sodium,
      sugar: sugar,
      time: timeString,
    );

    if (success) {
      state.addMeal(
        MealEntry(
          name: recipe['name'] ?? 'AI Recommended Meal',
          mealType: recipe['meal_type'] ?? 'General',
          calories: calories,
          carbs: carbs,
          protein: protein,
          fats: fat,
          sodium: sodium,
          sugar: sugar,
          time: timeString,
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Added to your Daily Log!'),
            backgroundColor: Colors.teal.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to log meal.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  
  void _showRecipeDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take up more screen space
      backgroundColor:
          Colors.transparent, // Transparent so we can see rounded corners
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75, // Starts at 75% of screen height
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller:
                    controller, // Connects the scroll to the drag-to-dismiss
                children: [
                  // 1. Drag Handle (The little grey pill at the top)
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // 2. Title
                  Text(
                    recipe['name'] ?? 'Unknown Recipe',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. Quick Stats Row
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: Colors.orange.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe['calories'] ?? 0} kcal',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 15),
                      Icon(Icons.timer, size: 16, color: Colors.teal.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Prep Time: 30m',
                        style: TextStyle(color: Colors.grey[700]),
                      ), // Placeholder
                    ],
                  ),
                  const Divider(height: 30),

                  // 4. Ingredients Section
                  const Text(
                    "Ingredients",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    recipe['ingredients'] ?? 'Ingredients not listed.',
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 20),

                  // 5. Instructions Section
                  const Text(
                    "Instructions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    recipe['instructions'] ??
                        'Cooking instructions not available.',
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 30),

                  // Bottom spacing
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12, bottom: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  recipe['image_url'] ?? '',
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (ctx, err, stack) => Container(
                        height: 110,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
                ),
              ),

              
              Positioned(
                top: 8,
                left: 8,
                child: InkWell(
                  onTap: () => _showRecipeDetails(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        0.9,
                      ), // White for contrast
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          color: Colors.teal.shade700,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "RECIPE",
                          style: TextStyle(
                            color: Colors.teal.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Existing "LOG" BUTTON ON THE TOP RIGHT
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () => _logMeal(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade600,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_task_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "LOG",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 2. FLEXIBLE CONTENT SECTION (Stays exactly the same)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          recipe['meal_type']?.toUpperCase() ?? 'MEAL',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        recipe['name'] ?? 'Unknown',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildGridItem("Sugar", recipe['nutrition']['sugar']),
                        _buildDivider(),
                        _buildGridItem("Salt", recipe['nutrition']['sodium']),
                        _buildDivider(),
                        _buildGridItem("Fat", recipe['nutrition']['fat']),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(String label, String? value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value ?? "-",
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 15, width: 1, color: Colors.grey[300]);
  }
}
