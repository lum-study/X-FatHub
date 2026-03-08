import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  Dashboard({super.key});

  // Hardcoded values
  final int steps = 8150;
  final int goalSteps = 10000;
  final double progress = 8150 / 10000; // ~0.815
  final int kcal = 350;
  final double distance = 6.5; // km
  final List<double> barHeights = [52, 71, 43, 89, 62, 75, 48];
  final List<String> barLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Column(
        children: [
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 24, bottom: 16),
              child: Column(
                children: [
                  _buildProgressCircle(),
                  const SizedBox(height: 24),
                  _buildGoalRow(),
                  const SizedBox(height: 18),
                  _buildCards(),
                  const SizedBox(height: 20),
                  _buildChartHeader(),
                  const SizedBox(height: 8),
                  _buildBars(),
                  const SizedBox(height: 18),
                  _buildResetButton(),
                  const SizedBox(height: 12),
                  _buildReminder(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer custom painted progress ring
        SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(
            painter: _CircleProgressPainter(progress: progress),
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
                steps.toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                ), // Formats as 8,150
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'STEPS',
                style: TextStyle(
                  color: Color(0xFFCCCCCC),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalRow() {
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
                '${goalSteps.toString()} Steps',
                style: const TextStyle(color: Color(0xFFFFA500), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.edit, color: Color(0xFFFFA500), size: 14),
        ),
      ],
    );
  }

  Widget _buildCards() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.local_fire_department,
            value: '$kcal',
            label: 'Kcal',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.directions_walk,
            value: '$distance km',
            label: 'Distance',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required IconData icon, required String value, required String label}) {
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

  Widget _buildChartHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFFAAAAAA), size: 12),
            const SizedBox(width: 4),
            const Text(
              'Last 7 Days',
              style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
            ),
          ],
        ),
        const Text(
          'Avg 6,400',
          style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBars() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        return Expanded(
          child: Column(
            children: [
              Container(
                height: barHeights[index],
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFA500),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                barLabels[index],
                style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 10),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildResetButton() {
    return Container(
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
            style: TextStyle(color: Color(0xFFFFA500), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildReminder() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border.all(color: const Color(0xFFFFA500)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_empty, color: Color(0xFFFFA500), size: 14),
          SizedBox(width: 6),
          Text(
            'Stretch! Still for 1h',
            style: TextStyle(color: Color(0xFFFFA500), fontSize: 12),
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}