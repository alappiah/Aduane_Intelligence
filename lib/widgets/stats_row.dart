import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'custom_card.dart';

class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    return Transform.translate(
      offset: const Offset(0, -20),
      child: CustomCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: _statItem(
                '28',
                'Days Active',
                Icons.local_fire_department_rounded,
                AppColors.orange,
                AppColors.orangeLight,
              ),
            ),
            _verticalDivider(),
            Expanded(
              child: _statItem(
                '${state.workouts.length}',
                'Workouts',
                Icons.fitness_center_rounded,
                AppColors.pink,
                AppColors.pinkLight,
              ),
            ),
            _verticalDivider(),
            Expanded(
              child: _statItem(
                '${state.totalCaloriesBurned}',
                'kCal Out',
                Icons.trending_down_rounded,
                AppColors.teal,
                AppColors.tealLight,
              ),
            ),
            _verticalDivider(),
            Expanded(
              child: _statItem(
                '84%',
                'Avg Goal',
                Icons.track_changes_rounded,
                AppColors.purple,
                AppColors.purpleLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String v, String l, IconData i, Color c, Color bg) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(i, color: c, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          v,
          style: GoogleFonts.nunito(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        Text(
          l,
          style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textMedium),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _verticalDivider() =>
      Container(width: 1, height: 60, color: AppColors.divider);
}