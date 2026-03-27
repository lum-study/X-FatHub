import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../viewmodels/step_tracker_viewmodel.dart';

class StepTrackerScreen extends StatelessWidget {
  const StepTrackerScreen({super.key});

  // Maximum bar height for scaling (based on max daily steps)
  static const double _maxBarHeight = 100.0;

  @override
  Widget build(BuildContext context) {
    // Initialize ViewModel when screen is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<StepTrackerViewModel>();
      viewModel.init();
      
      // Check inactivity periodically (every 30 seconds)
      Timer.periodic(const Duration(seconds: 30), (timer) {
        if (!context.mounted) {
          timer.cancel();
          return;
        }
        viewModel.updateInactivityReminder();
      });
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Step Tracker'), elevation: 0),
      body: Consumer<StepTrackerViewModel>(
        builder: (context, viewModel, _) {
          // Show loading screen during initial load (before first load is complete)
          if (!viewModel.isFirstLoadComplete) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading your step data...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Show error screen if there's an error (but only after first load)
          if (viewModel.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(viewModel.errorMessage ?? 'Unknown error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: viewModel.refreshData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: viewModel.refreshData,
            color: const Color(0xFFFFA500),
            backgroundColor: const Color(0xFF1A1A1A),
            child: Container(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Column(
                children: [
                  // Main content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 24, bottom: 16),
                      child: Column(
                        children: [
                          _buildProgressCircle(viewModel),
                          const SizedBox(height: 24),
                          _buildGoalRow(context, viewModel),
                          const SizedBox(height: 18),
                          _buildCards(viewModel),
                          const SizedBox(height: 20),
                          // Chart section with minimum height to prevent sticking to header
                          Container(
                            constraints: const BoxConstraints(minHeight: 180),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildChartHeader(viewModel),
                                _buildBars(viewModel),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildResetButton(context, viewModel),
                          const SizedBox(height: 12),
                          if (viewModel.showInactivityReminder) _buildReminder(viewModel),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressCircle(StepTrackerViewModel viewModel) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer custom painted progress ring
        SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(
            painter: _CircleProgressPainter(progress: viewModel.progress),
          ),
        ),
        // Inner black circle with text
        Container(
          width: 160,
          height: 160,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x33FFA500),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                viewModel.formatSteps(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'STEPS',
                style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                viewModel.getLastUpdateTime(),
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalRow(BuildContext context, StepTrackerViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 6),
              Text(
                '${viewModel.goalSteps.toString()} Steps',
                style: const TextStyle(
                  color: Color(0xFFFFA500),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _showEditGoalDialog(context, viewModel),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit, color: Color(0xFFFFA500), size: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCards(StepTrackerViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.local_fire_department,
            value: viewModel.formatKcal(),
            label: 'Kcal',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.directions_walk,
            value: '${viewModel.formatDistance()} km',
            label: 'Distance',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFFFA500), size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartHeader(StepTrackerViewModel viewModel) {
    // Calculate average steps for the week
    final dailySteps = viewModel.stepTrackerData.dailySteps;
    final avgSteps = dailySteps.isNotEmpty
        ? (dailySteps.reduce((a, b) => a + b) / dailySteps.length).round()
        : 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: Color(0xFFAAAAAA),
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              viewModel.getDayRangeLabel(),
              style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
            ),
          ],
        ),
        Text(
          'Avg ${avgSteps.toString()}',
          style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBars(StepTrackerViewModel viewModel) {
    // Find max steps for scaling
    final int maxSteps = viewModel.stepTrackerData.dailySteps.isEmpty
        ? 1
        : (viewModel.stepTrackerData.dailySteps.reduce((a, b) => a > b ? a : b));
    final double scaleFactor = maxSteps > 0 ? _maxBarHeight / maxSteps : 1.0;

    // Get dynamic day labels
    final dayLabels = viewModel.getDynamicDayLabels();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final steps = viewModel.stepTrackerData.dailySteps[index];
          final barHeight = (steps * scaleFactor).clamp(1.0, _maxBarHeight);
          final label = dayLabels[index];
          final tooltipText = viewModel.getBarTooltip(index, steps);

          return Expanded(
            child: Column(
              children: [
                Tooltip(
                  message: tooltipText,
                  showDuration: const Duration(seconds: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFFA500), width: 1),
                  ),
                  child: Container(
                    height: barHeight,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFA500),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 10),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, StepTrackerViewModel viewModel) {
    return GestureDetector(
      onTap: () => _showResetConfirmationDialog(context, viewModel),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFFA500), width: 1.5),
          borderRadius: BorderRadius.circular(40),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.undo, color: Color(0xFFFFA500), size: 14),
            SizedBox(width: 8),
            Text(
              'Reset Data',
              style: TextStyle(
                color: Color(0xFFFFA500),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminder(StepTrackerViewModel viewModel) {
    final inactivityHours = viewModel.getInactivityHours();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border.all(color: const Color(0xFFFFA500)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_empty, color: Color(0xFFFFA500), size: 14),
          const SizedBox(width: 6),
          Text(
            'Stretch! Still for ${inactivityHours}h',
            style: const TextStyle(color: Color(0xFFFFA500), fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Show dialog to edit step goal
  void _showEditGoalDialog(BuildContext context, StepTrackerViewModel viewModel) {
    final goalController = TextEditingController(text: viewModel.goalSteps.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Edit Daily Goal',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: goalController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter daily step goal',
            hintStyle: const TextStyle(color: Color(0xFF666666)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFFA500)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF333333)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFAAAAAA)),
            ),
          ),
          TextButton(
            onPressed: () {
              final newGoal = int.tryParse(goalController.text);
              if (newGoal != null && newGoal > 0) {
                viewModel.updateGoalSteps(newGoal);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Goal updated successfully'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid number'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Color(0xFFFFA500)),
            ),
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog before resetting data
  void _showResetConfirmationDialog(BuildContext context, StepTrackerViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Reset Step Data?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will clear all recorded step data. This action cannot be undone.',
          style: TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFAAAAAA)),
            ),
          ),
          TextButton(
            onPressed: () {
              viewModel.resetData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Step data reset successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the circular progress ring
class _CircleProgressPainter extends CustomPainter {
  final double progress;

  _CircleProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background grey ring (full circle)
    final backgroundPaint = Paint()
      ..color = const Color(0xFF262626)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;

    canvas.drawArc(rect, -3.142 / 2, 2 * 3.142, false, backgroundPaint);

    // Orange progress ring
    final progressPaint = Paint()
      ..color = const Color(0xFFFFA500)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round; // rounded ends

    final sweepAngle = 2 * 3.142 * progress;
    canvas.drawArc(rect, -3.142 / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
