import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'custom_card.dart';

class StatsRow extends StatefulWidget {
  const StatsRow({super.key});

  @override
  State<StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<StatsRow> {
  @override
  void initState() {
    super.initState();
    
    AppState().addListener(_onStateChanged);
  }

  @override
  void dispose() {
    AppState().removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState();

    return Transform.translate(
      offset: const Offset(0, -20),
      child: CustomCard(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: _statItem(
                '${state.daysActive}', // Currently a hardcoded placeholder for your streak
                'Days Active',
                Icons.local_fire_department_rounded,
                AppColors.orange,
                AppColors.orangeLight,
              ),
            ),
            _verticalDivider(),
            Expanded(
              child: _statItem(
                '${state.dailySteps}', 
                'Steps',
                Icons.directions_walk_rounded,
                AppColors.pink,
                AppColors.pinkLight,
              ),
            ),
            _verticalDivider(),
            Expanded(
              child: _statItem(
                '${state.totalCaloriesConsumed}',
                'Consumed',
                Icons.restaurant_rounded,
                AppColors.teal,
                AppColors.tealLight,
              ),
            ),
            _verticalDivider(),
            Expanded(
              child: _statItem(
                '${state.totalCaloriesBurned}', 
                'Burned',
                Icons.whatshot_rounded,
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
            fontSize: 16, // slightly smaller to fit the numbers
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          l,
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMedium,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _verticalDivider() =>
      Container(width: 1, height: 60, color: AppColors.divider);
}
