import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../theme/app_colors.dart';

class DailyGoalCircle extends StatelessWidget {
  final String label;
  final String percentText;
  final double percentValue;
  final Color color;
  final bool isBudgetMode; // 🌟 The new switch to change its behavior!

  const DailyGoalCircle({
    super.key,
    required this.label,
    required this.percentText,
    required this.percentValue,
    required this.color,
    this.isBudgetMode = false, // Defaults to a standard "Accumulation" goal
  });

  @override
  Widget build(BuildContext context) {
    final bool is100Percent = percentValue >= 1.0;
    final bool isNearingLimit = percentValue >= 0.85 && percentValue < 1.0;

    // 🌟 1. Determine Dynamic Color
    Color activeColor = color;
    if (isBudgetMode) {
      if (is100Percent) {
        activeColor = Colors.redAccent; // Danger! Over Budget!
      } else if (isNearingLimit) {
        activeColor = Colors.orange; // Warning! Nearing Limit!
      }
    }

    // 🌟 2. Determine Bottom Label Text
    String bottomLabel = label;
    if (isBudgetMode) {
      if (is100Percent)
        bottomLabel = 'Over Budget';
      else if (isNearingLimit)
        bottomLabel = 'Nearing Limit';
    } else {
      if (is100Percent) bottomLabel = 'Goal Reached!';
    }

    // 🌟 3. Determine Center Widget (Trophy vs Warning vs Text)
    Widget centerWidget;
    if (!isBudgetMode && is100Percent) {
      // Trophy for hitting step goal!
      centerWidget = Icon(
        Icons.emoji_events_rounded,
        color: activeColor,
        size: 28,
      );
    } else if (isBudgetMode && is100Percent) {
      // Warning icon for blowing past the calorie limit!
      centerWidget = Icon(Icons.warning_rounded, color: activeColor, size: 28);
    } else {
      // Standard percentage text
      centerWidget = Text(
        percentText,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
      );
    }

    return Column(
      children: [
        CircularPercentIndicator(
          radius: 36,
          lineWidth: 6,
          percent: percentValue.clamp(0.0, 1.0), // Prevents crashes if > 100%
          center: centerWidget,
          progressColor: activeColor,
          backgroundColor: const Color(0xFFE5E7EB),
          circularStrokeCap: CircularStrokeCap.round,
          animation: true,
          animateFromLastPercent:
              true, // Makes it fill smoothly as data changes
        ),
        const SizedBox(height: 8),
        Text(
          bottomLabel,
          style: GoogleFonts.nunito(
            fontSize: 11,
            // Only bold/color the text if they hit a milestone or warning
            color:
                (is100Percent || (isBudgetMode && isNearingLimit))
                    ? activeColor
                    : AppColors.textMedium,
            fontWeight:
                (is100Percent || (isBudgetMode && isNearingLimit))
                    ? FontWeight.w800
                    : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
