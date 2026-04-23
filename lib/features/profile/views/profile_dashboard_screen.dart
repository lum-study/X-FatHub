import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'settings_screen.dart';
import 'profile_edit_screen.dart';
import '../../activity_health/viewmodels/step_tracker_viewmodel.dart';
import '../../activity_health/viewmodels/hydration_viewmodel.dart';
import '../../booking/viewmodels/booking_viewmodel.dart';

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

  @override
  Widget build(BuildContext context) {
    final profileViewModel = context.watch<ProfileViewModel>();
    final profile = profileViewModel.profile;

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Health Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
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
      body: profileViewModel.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  _buildProfileHeader(profile),
                  const SizedBox(height: 24),

                  // Weight Progress Section - Always show
                  GestureDetector(
                    onTap: () => _showWeightUpdateDialog(context, profile),
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
                      // Calculate progress (0.0 - 1.0)
                      final stepsProgress = stepVM.goalSteps > 0 
                          ? (stepVM.steps / stepVM.goalSteps).clamp(0.0, 1.0)
                          : 0.0;
                      
                      final hydrationProgress = hydrationVM.goalInLiters > 0
                          ? (hydrationVM.consumptionInLiters / hydrationVM.goalInLiters).clamp(0.0, 1.0)
                          : 0.0;

                      return Column(
                        children: [
                          // Steps & Hydration in row with circular progress
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Steps Card with Circle
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
                              // Hydration Card with Circle
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
                          const SizedBox(height: 16),
                          // Sessions Card
                          Container(
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
                                      'Sessions Left',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Icon(Icons.fitness_center, color: Colors.green, size: 20),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  bookingVM.sessionsRemaining.toString(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  bookingVM.nextExpiryDate == null ? 'No pack' : 'Active package',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
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
    );
  }

  Widget _buildProfileHeader(profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Profile picture is view-only on dashboard.
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
          const SizedBox(height: 16),

          const SizedBox(height: 20),
          const Divider(color: Colors.grey),
          const SizedBox(height: 16),

          // Personal Info Section
          _buildInfoSection('Personal Information', [
            _buildInfoRow(Icons.person, 'Name', profile?.name ?? 'Not set'),
            _buildInfoRow(Icons.email, 'Email', profile?.email ?? 'Not set'),
            _buildInfoRow(Icons.info_outline, 'Bio', profile?.bio?.isNotEmpty == true ? profile!.bio! : 'Not set'),
            _buildInfoRow(Icons.cake, 'Age', profile?.age != null ? '${profile.age} years old' : 'Not set'),
            _buildInfoRow(Icons.event, 'Birthdate', _formatBirthdate(profile?.birthdate)),
            _buildInfoRow(Icons.wc, 'Gender', _formatGender(profile?.gender)),
            _buildInfoRow(Icons.height, 'Height', profile?.height != null ? '${profile.height} cm' : 'Not set'),
          ]),

          const SizedBox(height: 16),

          // Weight Info Section
          _buildInfoSection('Weight Information', [
            _buildInfoRow(Icons.flag, 'Initial Weight', profile?.initialWeight != null ? '${profile.initialWeight} kg' : 'Not set'),
            _buildInfoRow(Icons.monitor_weight, 'Current Weight', profile?.currentWeight != null ? '${profile.currentWeight} kg' : 'Not set'),
            _buildInfoRow(Icons.flag_circle, 'Goal Weight', profile?.weightGoal != null ? '${profile.weightGoal} kg' : 'Not set'),
          ]),

          const SizedBox(height: 20),

          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                );
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

    // Calculate progress percentage (0-100)
    double progressPercent = 0.0;
    String progressText = 'Add weight and goal to start tracking';
    bool hasWeightData = currentWeight > 0 && weightGoal > 0 && initialWeight > 0;

    if (hasWeightData) {
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
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weight Goal Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Icon(Icons.monitor_weight_outlined, color: Colors.orange),
            ],
          ),
          const SizedBox(height: 16),

          // All three weights display
          if (hasWeightData)
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
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'Click profile to add weight',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 12),

          // Progress bar
          if (hasWeightData) ...[
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
              color: Colors.grey[300],
              fontWeight: FontWeight.w500,
            ),
          ),
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
    final weightController = TextEditingController(
      text: profile?.currentWeight?.toString() ?? '',
    );

    // Store everything we need BEFORE showing dialog
    final provider = context.read<ProfileViewModel>();
    final profileCopy = provider.profile;
    final initialWeight = profileCopy?.initialWeight ?? 0.0;
    final weightGoal = profileCopy?.weightGoal ?? 0.0;
    final userId = profileCopy?.id ?? '';
    final messenger = ScaffoldMessenger.of(context);

    final newWeight = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Update Current Weight',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter weight in kg',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final parsedWeight = double.tryParse(weightController.text.trim());

              if (parsedWeight == null || parsedWeight <= 0) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid weight'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Validation using stored values (not context).
              if (initialWeight > 0 && weightGoal > 0) {
                final minWeight = initialWeight < weightGoal
                    ? initialWeight
                    : weightGoal;
                final maxWeight = initialWeight > weightGoal
                    ? initialWeight
                    : weightGoal;

                if (parsedWeight < minWeight || parsedWeight > maxWeight) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Weight must be between ${minWeight.toStringAsFixed(1)} kg and ${maxWeight.toStringAsFixed(1)} kg',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              }

              Navigator.of(dialogContext).pop(parsedWeight);
            },
            child: const Text('Update', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    weightController.dispose();

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

