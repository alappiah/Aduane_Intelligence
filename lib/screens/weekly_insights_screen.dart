import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart'; // Ensure your colors are imported
import '../widgets/custom_card.dart';

class WeeklyInsightsScreen extends StatefulWidget {
  const WeeklyInsightsScreen({super.key});

  @override
  State<WeeklyInsightsScreen> createState() => _WeeklyInsightsScreenState();
}

class _WeeklyInsightsScreenState extends State<WeeklyInsightsScreen> {
  @override
  void initState() {
    super.initState();
    // 🌟 Trigger the 7-day history fetch the moment the screen opens
    Future.microtask(() => context.read<AppState>().loadWeeklyInsights());
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Weekly Insights",
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body:
          appState.isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Step History"),
                    const SizedBox(height: 10),
                    _buildStepBarChart(appState),

                    const SizedBox(height: 30),
                    _buildSectionTitle("Calorie Balance"), // 🌟 NEW SECTION
                    const SizedBox(height: 10),
                    _buildCalorieLineChart(appState),

                    const SizedBox(height: 30),
                    _buildSectionTitle("Recent Activity Log"),
                    const SizedBox(height: 10),
                    _buildActivityList(appState),
                  ],
                ),
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildCalorieLineChart(AppState appState) {
    return CustomCard(
      child: Column(
        children: [
          // 🌟 Simple Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem("Consumed", Colors.orange),
              const SizedBox(width: 20),
              _buildLegendItem("Burned", Colors.blue),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (appState.weeklyDailySummary.isEmpty)
                          return const Text("");
                        int index = value.toInt();
                        if (index < 0 ||
                            index >= appState.weeklyDailySummary.length)
                          return const Text("");
                        DateTime date = appState.weeklyDailySummary[index].date;
                        return Text(
                          ["M", "T", "W", "T", "F", "S", "S"][date.weekday - 1],
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // 🟠 Line 1: Calories Consumed
                  LineChartBarData(
                    spots:
                        appState.weeklyDailySummary.asMap().entries.map((e) {
                          return FlSpot(
                            e.key.toDouble(),
                            e.value.caloriesConsumed.toDouble(),
                          );
                        }).toList(),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.withOpacity(0.1),
                    ),
                  ),
                  // 🔵 Line 2: Calories Burned
                  LineChartBarData(
                    spots:
                        appState.weeklyDailySummary.asMap().entries.map((e) {
                          return FlSpot(
                            e.key.toDouble(),
                            e.value.caloriesBurned.toDouble(),
                          );
                        }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

Widget _buildStepBarChart(AppState appState) {
  return CustomCard(
    child: SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 20000, // Adjust based on your max goal
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  // value is the index (0-6)
                  if (appState.weeklyDailySummary.isEmpty)
                    return const Text("");
                  DateTime date =
                      appState.weeklyDailySummary[value.toInt()].date;
                  return Text(
                    ["M", "T", "W", "T", "F", "S", "S"][date.weekday - 1],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups:
              appState.weeklyDailySummary.asMap().entries.map((entry) {
                int index = entry.key;
                var data = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: data.steps.toDouble(),
                      color: AppColors.teal,
                      width: 18,
                      borderRadius: BorderRadius.circular(4),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 20000,
                        color: Colors.grey.withOpacity(0.1),
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    ),
  );
}

Widget _buildActivityList(AppState appState) {
  final history = [
    ...appState.weeklyMealHistory,
    ...appState.weeklyWorkoutHistory,
  ];

  if (history.isEmpty) {
    return const Center(child: Text("No activity recorded this week."));
  }

  return Column(
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 400,
        ), // 🌟 Limits height to 400 pixels
        child: ListView.builder(
          shrinkWrap: true, // Keep this if inside a column
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];

            if (item is MealEntry) {
              return ListTile(
                leading: const Icon(Icons.restaurant, color: Colors.orange),
                title: Text(item.name),
                subtitle: Text("${item.mealType} • ${item.calories} kcal"),
                trailing: Text(item.time),
              );
            } else if (item is WorkoutEntry) {
              return ListTile(
                leading: const Icon(Icons.fitness_center, color: Colors.blue),
                title: Text(item.name),
                subtitle: Text(
                  "${item.durationMinutes} mins • ${item.caloriesBurned} kcal burned",
                ),
                trailing: Text(item.time),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    ],
  );
}
