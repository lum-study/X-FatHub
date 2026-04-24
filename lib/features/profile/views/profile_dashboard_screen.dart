import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'settings_screen.dart';
import 'profile_edit_screen.dart';
import '../../activity_health/viewmodels/step_tracker_viewmodel.dart';
import '../../activity_health/viewmodels/hydration_viewmodel.dart';
import '../../booking/viewmodels/booking_viewmodel.dart';
import '../../booking/views/booking_history_screen.dart';

class ProfileDashboardScreen extends StatefulWidget {
  const ProfileDashboardScreen({super.key});

  @override
  State<ProfileDashboardScreen> createState() => _ProfileDashboardScreenState();
}

class _ProfileDashboardScreenState extends State<ProfileDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileViewModel = context.read<ProfileViewModel>();
      await profileViewModel.init();
      context.read<BookingViewModel>().refreshCurrentUserBookingData();
      
      await Future.delayed(const Duration(milliseconds: 300));
    });
  }

  Future<void> _handleRefresh() async {
    final profileViewModel = context.read<ProfileViewModel>();
    final bookingViewModel = context.read<BookingViewModel>();
    
    await profileViewModel.init();
    await bookingViewModel.refreshCurrentUserBookingData();
  }

  @override
  Widget build(BuildContext context) {
    final profileViewModel = context.watch<ProfileViewModel>();
    final profile = profileViewModel.profile;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.person, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Profile',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.orange),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookingHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.orange),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: profileViewModel.isLoading && profile == null
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              color: Colors.orange,
              backgroundColor: const Color(0xFF1E1E1E),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    _buildProfileHeader(profile, context),
                    const SizedBox(height: 24),

                    // Membership Section
                    const Text(
                      'Membership Status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<BookingViewModel>(
                      builder: (context, bookingVM, _) {
                        return _buildMembershipCard(bookingVM);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Weight Progress Section
                    const Text(
                      'Weight Goal Progress',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        final height = profile?.height ?? 0.0;
                        final initialWeight = profile?.initialWeight ?? 0.0;
                        final weightGoal = profile?.weightGoal ?? 0.0;
                        
                        if (height > 0 && initialWeight > 0 && weightGoal > 0) {
                          _showWeightUpdateDialog(context, profile);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please complete your Body Information first (Height, Initial & Goal Weight)'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      child: _buildWeightProgressSection(profile),
                    ),
                    const SizedBox(height: 32),

                    // Health Stats Section
                    const Text(
                      'Today\'s Activity',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats Grid
                    Consumer3<
                      StepTrackerViewModel,
                      HydrationViewModel,
                      BookingViewModel
                    >(
                      builder: (context, stepVM, hydrationVM, bookingVM, _) {
                        final stepsProgress = stepVM.goalSteps > 0 
                            ? (stepVM.steps / stepVM.goalSteps).clamp(0.0, 1.0)
                            : 0.0;
                        
                        final hydrationProgress = hydrationVM.goalInLiters > 0
                            ? (hydrationVM.consumptionInLiters / hydrationVM.goalInLiters).clamp(0.0, 1.0)
                            : 0.0;

                        final totalSessions = bookingVM.sessionsRemainingByPackage.values.fold(0, (sum, s) => sum + s);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: _buildCircularProgressCard(
                                    title: 'Steps',
                                    current: stepVM.steps.toString(),
                                    goal: stepVM.goalSteps.toString(),
                                    progress: stepsProgress,
                                    color: const Color(0xFFFFA500),
                                    icon: Icons.directions_walk,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildCircularProgressCard(
                                    title: 'Hydration',
                                    current: hydrationVM.consumptionInLiters.toStringAsFixed(1),
                                    goal: hydrationVM.goalInLiters.toStringAsFixed(1),
                                    progress: hydrationProgress,
                                    color: const Color(0xFF2196F3),
                                    icon: Icons.local_drink_outlined,
                                    unit: 'L',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Total Sessions Left',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Sessions Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Sessions Overview',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const Icon(Icons.fitness_center, color: Colors.green, size: 20),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    totalSessions.toString(),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  if (bookingVM.activePackages.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    const Divider(color: Color(0xFF333333)),
                                    const SizedBox(height: 8),
                                    ...bookingVM.activePackages.map((pkg) {
                                      final sessions = bookingVM.sessionsRemainingByPackage[pkg.id] ?? 0;
                                      final expiry = bookingVM.expiryByPackage[pkg.id];
                                      String expiryText = 'No expiry';
                                      Color expiryColor = Colors.grey[500]!;
                                      
                                      if (expiry != null) {
                                        final daysLeft = expiry.difference(DateTime.now()).inDays;
                                        if (daysLeft < 0) {
                                          expiryText = 'Expired';
                                          expiryColor = Colors.red;
                                        } else {
                                          expiryText = '$daysLeft days left';
                                          if (daysLeft < 30) {
                                            expiryColor = Colors.red;
                                          }
                                        }
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    pkg.name,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    '$sessions sessions left',
                                                    style: const TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              expiryText,
                                              style: TextStyle(
                                                color: expiryColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ] else ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'No active packages',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Account Management
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.logout,
                              color: Colors.orange,
                            ),
                            title: const Text(
                              'Sign Out',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              _showLogoutDialog(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMembershipCard(BookingViewModel bookingVM) {
    // Reward levels: Basic: 0, Silver: 2, Gold: 5, Diamond: 10
    final purchaseCount = bookingVM.userBookings.map((b) => b.packageId).toSet().length + 
                           bookingVM.activePackages.length;
    
    String level = 'Basic';
    Color levelColor = Colors.grey;
    IconData levelIcon = Icons.stars_outlined;

    if (purchaseCount >= 10) {
      level = 'Diamond';
      levelColor = const Color(0xFFB9F2FF);
      levelIcon = Icons.diamond;
    } else if (purchaseCount >= 5) {
      level = 'Gold';
      levelColor = const Color(0xFFFFD700);
      levelIcon = Icons.military_tech;
    } else if (purchaseCount >= 2) {
      level = 'Silver';
      levelColor = const Color(0xFFC0C0C0);
      levelIcon = Icons.shield;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [levelColor.withOpacity(0.2), Colors.grey[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: levelColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(levelIcon, color: levelColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tier Level',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      level,
                      style: TextStyle(
                        color: levelColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showMembershipInfo(context, level, purchaseCount),
                icon: const Icon(Icons.info_outline, color: Colors.orange, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (purchaseCount / 10).clamp(0.0, 1.0),
              backgroundColor: Colors.black26,
              color: levelColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$purchaseCount Packages purchased',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              if (purchaseCount < 10)
                Text(
                  '${(purchaseCount < 2 ? 2 : (purchaseCount < 5 ? 5 : 10)) - purchaseCount} more to next level',
                  style: TextStyle(color: levelColor.withOpacity(0.7), fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMembershipInfo(BuildContext context, String currentLevel, int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Membership Tiers', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTierRow('Basic', '0-1 Packages', 'Standard access to all facilities.', Colors.grey, currentLevel == 'Basic'),
            _buildTierRow('Silver', '2-4 Packages', 'Free access to exclusive lockers.', const Color(0xFFC0C0C0), currentLevel == 'Silver'),
            _buildTierRow('Gold', '5-9 Packages', 'Free 1x Personal Trainer session monthly.', const Color(0xFFFFD700), currentLevel == 'Gold'),
            _buildTierRow('Diamond', '10+ Packages', 'Free 2x Guest pass monthly + Priority booking.', const Color(0xFFB9F2FF), currentLevel == 'Diamond'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Widget _buildTierRow(String name, String req, String welfare, Color color, bool isCurrent) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isCurrent ? color : Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              if (isCurrent) 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                  child: const Text('CURRENT', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          Text(req, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 4),
          Text(welfare, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(profile, BuildContext context) {
    final bookingVM = Provider.of<BookingViewModel>(context, listen: false);
    final purchaseCount = bookingVM.userBookings.map((b) => b.packageId).toSet().length + 
                           bookingVM.activePackages.length;
    
    Color badgeColor = Colors.transparent;
    IconData? badgeIcon;
    if (purchaseCount >= 10) {
      badgeColor = const Color(0xFFB9F2FF);
      badgeIcon = Icons.diamond;
    } else if (purchaseCount >= 5) {
      badgeColor = const Color(0xFFFFD700);
      badgeIcon = Icons.military_tech;
    } else if (purchaseCount >= 2) {
      badgeColor = const Color(0xFFC0C0C0);
      badgeIcon = Icons.shield;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Profile picture with badge
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.withOpacity(0.2),
                  border: Border.all(color: Colors.orange, width: 3),
                  image: (profile?.profilePictureUrl != null &&
                          profile!.profilePictureUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(profile.profilePictureUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (profile?.profilePictureUrl == null ||
                        profile!.profilePictureUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 50, color: Colors.orange)
                    : null,
              ),
              if (badgeIcon != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      shape: BoxShape.circle,
                      border: Border.all(color: badgeColor, width: 2),
                    ),
                    child: Icon(badgeIcon, color: badgeColor, size: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (profile?.name?.isNotEmpty == true) ? profile!.name! : 'Unknown User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.grey),
          const SizedBox(height: 16),

          // Personal Info Section
          _buildInfoSection('Personal Information', [
            _buildInfoRow(Icons.email, 'Email', profile?.email ?? 'Not set'),
            _buildInfoRow(Icons.info_outline, 'Bio', profile?.bio?.isNotEmpty == true ? profile!.bio! : 'Not set'),
            _buildInfoRow(Icons.cake, 'Age', profile?.birthdate != null ? '${_calculateAge(profile.birthdate)} years old' : 'Not set'),
            _buildInfoRow(Icons.event, 'Birthdate', _formatBirthdate(profile?.birthdate)),
            _buildInfoRow(Icons.wc, 'Gender', _formatGender(profile?.gender)),
          ]),

          const SizedBox(height: 16),

          // Body Info Section
          _buildInfoSection('Body Information', [
            _buildInfoRow(Icons.height, 'Height', profile?.height != null ? '${profile.height} cm' : 'Not set'),
            _buildInfoRow(Icons.flag, 'Initial Weight', profile?.initialWeight != null ? '${profile.initialWeight} kg' : 'Not set'),
            _buildInfoRow(Icons.monitor_weight, 'Current Weight', profile?.currentWeight != null ? '${profile.currentWeight} kg' : 'Not set'),
            _buildInfoRow(Icons.flag_circle, 'Goal Weight', profile?.weightGoal != null ? '${profile.weightGoal} kg' : 'Not set'),
          ]),

          const SizedBox(height: 20),

          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                );
                // Refresh after returning from edit
                if (mounted) {
                  _handleRefresh();
                }
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateAge(DateTime birthdate) {
    DateTime now = DateTime.now();
    int age = now.year - birthdate.year;
    if (now.month < birthdate.month || (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }
    return age;
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  String _formatBirthdate(DateTime? birthdate) {
    if (birthdate == null) {
      return 'Not set';
    }
    final year = birthdate.year.toString().padLeft(4, '0');
    final month = birthdate.month.toString().padLeft(2, '0');
    final day = birthdate.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatGender(String? gender) {
    if (gender == null || gender.isEmpty) {
      return 'Not set';
    }
    final normalizedGender = gender.toLowerCase();
    if (normalizedGender == 'prefer not to say') return 'Prefer not to say';
    return normalizedGender[0].toUpperCase() + normalizedGender.substring(1);
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[300], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightProgressSection(profile) {
    final currentWeight = profile?.currentWeight ?? 0.0;
    final initialWeight = profile?.initialWeight ?? 0.0;
    final weightGoal = profile?.weightGoal ?? 0.0;
    final height = profile?.height ?? 0.0;

    // Calculate progress percentage (0-100)
    double progressPercent = 0.0;
    String progressText = 'Please Complete Body Information before Tracking';
    bool hasBodyData = currentWeight > 0 && weightGoal > 0 && initialWeight > 0 && height > 0;
    
    double bmi = 0.0;
    String bmiCategory = '';
    Color bmiColor = Colors.grey;

    if (hasBodyData) {
      // BMI Calculation: weight / (height/100)^2
      bmi = currentWeight / ((height / 100) * (height / 100));
      
      if (bmi < 18.5) {
        bmiCategory = 'Underweight';
        bmiColor = Colors.blue;
      } else if (bmi < 25) {
        bmiCategory = 'Normal';
        bmiColor = Colors.green;
      } else if (bmi < 30) {
        bmiCategory = 'Overweight';
        bmiColor = Colors.yellow;
      } else {
        bmiCategory = 'Obese';
        bmiColor = Colors.red;
      }

      final totalChange = (initialWeight - weightGoal).abs();
      final achieved = (initialWeight - currentWeight).abs();
      
      if (totalChange > 0) {
        progressPercent = (achieved / totalChange) * 100;
        progressPercent = progressPercent.clamp(0.0, 100.0);
        progressText = '${progressPercent.toStringAsFixed(1)}% progress to goal';
        
        if (progressPercent >= 100) {
          progressText = 'Goal achieved! ';
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasBodyData ? Colors.orange.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Opacity(
        opacity: hasBodyData ? 1.0 : 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                Icon(
                  hasBodyData ? Icons.monitor_weight_outlined : Icons.lock_outline,
                  color: hasBodyData ? Colors.orange : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (hasBodyData) ...[
              // BMI Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: bmiColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: bmiColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current BMI',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Row(
                      children: [
                        Text(
                          bmi.toStringAsFixed(1),
                          style: TextStyle(
                            color: bmiColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '($bmiCategory)',
                          style: TextStyle(
                            color: bmiColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showBMILimitsDialog(context),
                          child: Icon(Icons.info_outline, color: bmiColor, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // All three weights display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Initial Weight
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Initial',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${initialWeight.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(Icons.arrow_downward, size: 16, color: Colors.blue.withOpacity(0.7)),
                    ],
                  ),
                  // Current Weight (center, highlighted)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Current',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currentWeight.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(Icons.arrow_forward, size: 16, color: Colors.orange.withOpacity(0.7)),
                    ],
                  ),
                  // Goal Weight
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Goal',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${weightGoal.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(Icons.flag, size: 16, color: Colors.green.withOpacity(0.7)),
                    ],
                  ),
                ],
              ),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.grey, size: 30),
                      const SizedBox(height: 8),
                      Text(
                        'Body Information incomplete',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Set Height and Weight Information to unlock',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 12),

            // Progress bar
            if (hasBodyData) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (progressPercent / 100).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Progress text
            Text(
              progressText,
              style: TextStyle(
                fontSize: 12,
                color: hasBodyData ? Colors.grey[300] : Colors.red[300],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBMILimitsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('BMI Categories', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBMILimitRow('Underweight', '< 18.5', Colors.blue),
            _buildBMILimitRow('Normal', '18.5 - 24.9', Colors.green),
            _buildBMILimitRow('Overweight', '25.0 - 29.9', Colors.yellow),
            _buildBMILimitRow('Obese', '≥ 30.0', Colors.red),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Widget _buildBMILimitRow(String label, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text(range, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required String goal,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Goal: $goal',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularProgressCard({
    required String title,
    required String current,
    required String goal,
    required double progress,
    required Color color,
    required IconData icon,
    String unit = '',
  }) {
    final displayProgress = (progress * 100).clamp(0.0, 100.0);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Circular progress
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _CircleProgressPainter(progress: progress, color: color),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$current$unit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${displayProgress.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Goal text
          Text(
            'Goal: $goal$unit',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProfileViewModel>().signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showWeightUpdateDialog(BuildContext context, profile) async {
    final provider = context.read<ProfileViewModel>();
    final profileCopy = provider.profile;
    final userId = profileCopy?.id ?? '';
    final messenger = ScaffoldMessenger.of(context);

    final newWeight = await showDialog<double>(
      context: context,
      builder: (context) => WeightUpdateDialog(
        currentWeight: profile?.currentWeight,
        initialWeight: profile?.initialWeight ?? 0.0,
        weightGoal: profile?.weightGoal ?? 0.0,
      ),
    );

    if (newWeight == null) {
      return;
    }

    try {
      await provider.updateCurrentWeightOnly(newWeight);
      await provider.loadWeightHistory(userId);
    } catch (e) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update current weight: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Weight updated successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class WeightUpdateDialog extends StatefulWidget {
  final double? currentWeight;
  final double initialWeight;
  final double weightGoal;

  const WeightUpdateDialog({
    super.key,
    this.currentWeight,
    required this.initialWeight,
    required this.weightGoal,
  });

  @override
  State<WeightUpdateDialog> createState() => _WeightUpdateDialogState();
}

class _WeightUpdateDialogState extends State<WeightUpdateDialog> {
  late final TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.currentWeight?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _adjustWeight(double delta) {
    final currentVal = double.tryParse(_weightController.text) ?? 0.0;
    final newVal = (currentVal + delta).clamp(0.1, 500.0);
    setState(() {
      _weightController.text = newVal.toStringAsFixed(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text(
        'Update Current Weight',
        style: TextStyle(color: Colors.white),
      ),
      content: Row(
        children: [
          IconButton(
            onPressed: () => _adjustWeight(-0.1),
            icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
          ),
          Expanded(
            child: TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'kg',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _adjustWeight(0.1),
            icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () {
            final parsedWeight = double.tryParse(_weightController.text.trim());

            if (parsedWeight == null || parsedWeight <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid weight'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            if (widget.initialWeight > 0 && widget.weightGoal > 0) {
              final minWeight = widget.initialWeight < widget.weightGoal
                  ? widget.initialWeight
                  : widget.weightGoal;
              final maxWeight = widget.initialWeight > widget.weightGoal
                  ? widget.initialWeight
                  : widget.weightGoal;

              // Enforce strict range validation: current weight must be between initial and goal.
              if (parsedWeight < minWeight || parsedWeight > maxWeight) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Weight must be between your initial (${minWeight.toStringAsFixed(1)}kg) and goal (${maxWeight.toStringAsFixed(1)}kg).',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
            }

            Navigator.of(context).pop(parsedWeight);
          },
          child: const Text('Update', style: TextStyle(color: Colors.orange)),
        ),
      ],
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircleProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background grey ring
    final backgroundPaint = Paint()
      ..color = const Color(0xFF262626)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawArc(rect, -3.142 / 2, 2 * 3.142, false, backgroundPaint);

    // Color progress ring
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.142 * progress;
    canvas.drawArc(rect, -3.142 / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
