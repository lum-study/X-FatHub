import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'settings_screen.dart';
import 'profile_edit_screen.dart';
import '../../activity_health/viewmodels/step_tracker_viewmodel.dart';
import '../../activity_health/viewmodels/hydration_viewmodel.dart';
import '../../activity_health/viewmodels/activity_tracking_viewmodel.dart';
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
      
      // Initialize health tracking data on dashboard load
      // This ensures data is fetched from Supabase immediately after login
      if (mounted) {
        context.read<StepTrackerViewModel>().init();
        context.read<HydrationViewModel>().init();
        context.read<BookingViewModel>().refreshCurrentUserBookingData();
      }
      
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
            icon: const Icon(Icons.history, color: Colors.orange),
            tooltip: 'My Bookings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BookingHistoryScreen()),
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
          // Profile Picture with edit button
          GestureDetector(
            onTap: () => _showImagePicker(context),
            child: Stack(
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
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Name
          Text(
            profile?.name ?? 'Guest User',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          
          // Email
          Text(
            profile?.email ?? 'No email',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          
          // Bio
          if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile.bio!,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
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
    
    double progress = 0.0;
    double weightLost = 0.0;
    
    if (initialWeight > 0 && weightGoal > 0 && currentWeight > 0) {
      final totalToLose = (initialWeight - weightGoal).abs();
      if (totalToLose > 0) {
        weightLost = (initialWeight - currentWeight).abs();
        progress = (weightLost / totalToLose).clamp(0.0, 1.0);
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weight Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Goal: ${weightGoal.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWeightStat('Initial', '${initialWeight.toStringAsFixed(1)} kg'),
              _buildWeightStat('Current', '${currentWeight.toStringAsFixed(1)} kg'),
              _buildWeightStat('Progress', '${(progress * 100).toInt()}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
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
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CustomPaint(
                  painter: _CircleProgressPainter(
                    progress: progress,
                    color: color,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    current,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    Text(
                      unit,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Goal: $goal$unit',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.orange),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  if (mounted) {
                    await context.read<ProfileViewModel>().uploadProfilePicture(image.path);
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.orange),
              title: const Text('Take a Photo', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final image = await picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  if (mounted) {
                    await context.read<ProfileViewModel>().uploadProfilePicture(image.path);
                  }
                }
              },
            ),
          ],
        ),
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
              // Clean up all health tracking data on logout
              context.read<ProfileViewModel>().signOutWithCleanup(
                context.read<StepTrackerViewModel>(),
                context.read<HydrationViewModel>(),
                context.read<ActivityTrackingViewModel>(),
              );
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showWeightUpdateDialog(BuildContext context, profile) {
    final weightController = TextEditingController(
      text: profile?.currentWeight?.toString() ?? '',
    );

    // Store everything we need BEFORE showing dialog
    final provider = context.read<ProfileViewModel>();
    final profileCopy = provider.profile;
    final initialWeight = profileCopy?.initialWeight ?? 0.0;
    final weightGoal = profileCopy?.weightGoal ?? 0.0;
    final userId = profileCopy?.id ?? '';

    showDialog(
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
            onPressed: () {
              weightController.dispose();
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (weightController.text.isNotEmpty) {
                final newWeight = double.tryParse(weightController.text);
                
                // Validation using stored values (not context)
                if (initialWeight > 0 && weightGoal > 0) {
                  final minWeight = initialWeight < weightGoal ? initialWeight : weightGoal;
                  final maxWeight = initialWeight > weightGoal ? initialWeight : weightGoal;
                  
                  if (newWeight == null || newWeight < minWeight || newWeight > maxWeight) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('Weight must be between ${minWeight.toStringAsFixed(1)} kg and ${maxWeight.toStringAsFixed(1)} kg'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                }
                
                if (newWeight != null && newWeight > 0) {
                  // Use stored provider reference
                  await provider.updateProfile(currentWeight: newWeight);
                  await provider.loadWeightHistory(userId);
                  
                  // Close dialog first
                  Navigator.of(dialogContext).pop();
                  weightController.dispose();
                  
                  // Then show success using original context
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Weight updated successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid weight'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Update', style: TextStyle(color: Colors.orange)),
          ),
        ],
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
