import 'package:capstone_frontend/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../state/app_state.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/stats_row.dart';
import '../widgets/personal_info_card.dart';
import '../widgets/weekly_goals_card.dart';
import '../widgets/settings_card.dart';
import '../widgets/logout_button.dart';

class DashboardScreen extends StatefulWidget {
  final bool standalone;
  final Map<String, dynamic> user; // Real data from Backend

  const DashboardScreen({
    super.key,
    this.standalone = false,
    required this.user,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Listen to changes in AppState (meals, workouts, etc)
    AppState().addListener(_onStateChange);
  }

  @override
  void dispose() {
    AppState().removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  StatsRow(),
                  const SizedBox(height: 16),
                  WeeklyGoalsCard(),
                  const SizedBox(height: 16),
                  SettingsCard(),
                  const SizedBox(height: 16),
                  PersonalInfoCard(user: widget.user),
                  const SizedBox(height: 16),
                  _buildAchievementsCard(),
                  const SizedBox(height: 16),
                  const LogoutButton(),
                  const SizedBox(
                    height: 100,
                  ), // Extra space for floating nav bar
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEADER (Combined Backend Data) ──────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    // 🌟 Use widget.user for identity, fallback to Sarah if null
    final String name = widget.user['firstName'] ?? AppState().profile.name;
    final String email = widget.user['email'] ?? AppState().profile.email;
    final String initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final String today = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.standalone)
                    _headerIcon(
                      Icons.arrow_back_ios_new_rounded,
                      () => Navigator.pop(context),
                    )
                  else
                    Text(
                      'My Profile',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  _headerIcon(
                    Icons.edit_outlined,
                    () => showEditProfileSheet(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                today,
                style: GoogleFonts.nunito(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 14),
              _buildAvatar(initials),
              const SizedBox(height: 14),
              Text(
                name,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                email,
                style: GoogleFonts.nunito(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              // _premiumBadge(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── RECENT ACTIVITY (Dynamic from AppState) ────────────────────────────────

  Widget _buildRecentActivity() {
    final state = AppState();
    if (state.meals.isEmpty && state.workouts.isEmpty)
      return const SizedBox.shrink();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Activity',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          // Show the most recent meal
          if (state.meals.isNotEmpty)
            _activityTile(
              Icons.restaurant,
              AppColors.teal,
              state.meals.first.name,
              state.meals.first.time,
              '${state.meals.first.calories} cal',
            ),
          if (state.workouts.isNotEmpty) ...[
            _divider(),
            _activityTile(
              Icons.flash_on,
              AppColors.orange,
              state.workouts.first.name,
              state.workouts.first.time,
              '${state.workouts.first.caloriesBurned} cal',
            ),
          ],
        ],
      ),
    );
  }

  // ─── SUB-WIDGETS & HELPERS ──────────────────────────────────────────────────

  Widget _activityTile(
    IconData icon,
    Color color,
    String title,
    String time,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String initials) {
    return Stack(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.tealLight,
            child: Text(
              initials,
              style: GoogleFonts.nunito(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.teal,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: _circleIcon(Icons.camera_alt_rounded, 14),
        ),
      ],
    );
  }

  Widget _headerIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _circleIcon(IconData icon, double size) {
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size, color: AppColors.teal),
    );
  }

  // Widget _premiumBadge() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
  //     decoration: BoxDecoration(
  //       color: Colors.white.withOpacity(0.2),
  //       borderRadius: BorderRadius.circular(20),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         const Icon(Icons.stars_rounded, color: Colors.white, size: 16),
  //         const SizedBox(width: 6),
  //         Text(
  //           'Aduane Premium',
  //           style: GoogleFonts.nunito(
  //             color: Colors.white,
  //             fontSize: 12,
  //             fontWeight: FontWeight.w700,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // --- Reused components from your original code ---

  // Widget _infoRow(IconData i, Color c, Color bg, String l, String v) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 10),
  //     child: Row(
  //       children: [
  //         Container(
  //           width: 40,
  //           height: 40,
  //           decoration: BoxDecoration(
  //             color: bg,
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           child: Icon(i, color: c, size: 20),
  //         ),
  //         const SizedBox(width: 14),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 l,
  //                 style: GoogleFonts.nunito(
  //                   fontSize: 12,
  //                   color: AppColors.textMedium,
  //                 ),
  //               ),
  //               Text(
  //                 v,
  //                 style: GoogleFonts.nunito(
  //                   fontSize: 14,
  //                   fontWeight: FontWeight.w700,
  //                   color: AppColors.textDark,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         const Icon(
  //           Icons.chevron_right_rounded,
  //           color: AppColors.textLight,
  //           size: 20,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildAchievementsCard() => CustomCard(
    child: Text(
      "Achievements Coming Soon",
      style: GoogleFonts.nunito(color: AppColors.textMedium),
    ),
  );
  Widget _divider() =>
      Divider(color: AppColors.divider, height: 1, thickness: 1);
}
