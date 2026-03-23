import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../theme/app_colors.dart';

class WeeklyGoalCircle extends StatelessWidget {
  final String label;
  final String percentText;
  final double percentValue;
  final Color color;

  const WeeklyGoalCircle({
    super.key,
    required this.label,
    required this.percentText,
    required this.percentValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 36,
          lineWidth: 6,
          percent: percentValue,
          center: Text(
            percentText,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          progressColor: color,
          backgroundColor: const Color(0xFFE5E7EB),
          circularStrokeCap: CircularStrokeCap.round,
          animation: true,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: AppColors.textMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}