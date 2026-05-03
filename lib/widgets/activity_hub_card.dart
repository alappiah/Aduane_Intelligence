import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart'; // Adjust these paths to match your project
import '../theme/app_colors.dart';
import 'custom_card.dart';

class ActivityHubCard extends StatelessWidget {
  const ActivityHubCard({super.key});

  @override
  Widget build(BuildContext context) {
    // We use context.watch so the card rebuilds when steps or meals change
    final appState = context.watch<AppState>();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Activity Hub",
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () => _showMilestoneSheet(context, appState),
                child: Text("View All", style: TextStyle(color: AppColors.teal)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStat(
                Icons.emoji_events, 
                "${appState.achievements.length}", // This requires an 'achievements' list in your AppState
                "Badges"
              ),
              _buildQuickStat(
                Icons.restaurant, 
                "${appState.meals.length}", 
                "Meals"
              ),
              _buildQuickStat(
                Icons.fitness_center, 
                "${appState.workouts.length}", 
                "Workouts"
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.teal, size: 28),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  void _showMilestoneSheet(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 5, width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300, 
                borderRadius: BorderRadius.circular(10)
              ),
            ),
            Text(
              "Your Trophies", 
              style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const Divider(),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.all(20),
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  // check if the key exists in the appState list
                  _buildAchievementIcon(
                    "first_steps", 
                    "First Steps", 
                    "Walk 1,000 steps", 
                    appState.achievements.contains("first_steps")
                  ),
                  _buildAchievementIcon(
                    "market_navigator", 
                    "Market Navigator", 
                    "Walk 5,000 steps", 
                    appState.achievements.contains("market_navigator")
                  ),
                  _buildAchievementIcon(
                    "kejetia_king", 
                    "Kejetia King", 
                    "Walk 15,000 steps", 
                    appState.achievements.contains("kejetia_king")
                  ),
                  _buildAchievementIcon(
                    "calorie_crusader", 
                    "Calorie Crusader", 
                    "Hit daily goal", 
                    appState.achievements.contains("calorie_crusader")
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementIcon(String key, String title, String desc, bool isEarned) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isEarned ? Colors.amber.withOpacity(0.2) : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isEarned ? Icons.emoji_events : Icons.lock_outline,
            color: isEarned ? Colors.amber.shade700 : Colors.grey.shade400,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isEarned ? FontWeight.bold : FontWeight.normal,
            color: isEarned ? Colors.black : Colors.grey,
          ),
        ),
        Text(
          desc,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9, color: Colors.grey),
        ),
      ],
    );
  }
}