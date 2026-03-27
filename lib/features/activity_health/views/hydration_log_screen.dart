import 'package:flutter/material.dart';

class HydrationLogScreen extends StatelessWidget {
  HydrationLogScreen({super.key});

  final double consumed = 1.2; // litres
  final double goal = 2.0; // litres
  final double progress = 1.2 / 2.0; // 0.6

  final List<Map<String, String>> entries = [
    {'amount': '500ml', 'time': '11:15 AM'},
    {'amount': '250ml', 'time': '09:00 AM'},
    {'amount': '250ml', 'time': '07:30 AM'},
    {'amount': '250ml', 'time': '06:45 PM'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hydration Log'), elevation: 0),
      body: Container(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Main content (scrollable)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 24, bottom: 16),
                child: Column(
                  children: [
                    _buildHydrationCircle(),
                    const SizedBox(height: 18),
                    _buildQuickAddButtons(),
                    const SizedBox(height: 20),
                    _buildLogEntries(),
                    const SizedBox(height: 16),
                    _buildHintNote(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHydrationCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: CustomPaint(
            painter: _CircleProgressPainter(progress: progress),
          ),
        ),
        Container(
          width: 140,
          height: 140,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${consumed.toStringAsFixed(1)} L',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Consumed',
                style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 11),
              ),
              const SizedBox(height: 2),
              const Text(
                'Goal 2.0 L',
                style: TextStyle(color: Color(0xFFFFA500), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAddButtons() {
    return Row(
      children: [
        _quickAddButton('250ml'),
        const SizedBox(width: 8),
        _quickAddButton('500ml'),
        const SizedBox(width: 8),
        _quickAddButton('1L'),
      ],
    );
  }

  Widget _quickAddButton(String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFA500),
          borderRadius: BorderRadius.circular(50),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33FFA500),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: Colors.black, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogEntries() {
    return Column(
      children: entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: const Color(0xFF262626)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      entry['amount']!,
                      style: const TextStyle(
                        color: Color(0xFFFFA500),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    entry['time']!,
                    style: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.edit, color: Color(0xFFFFA500), size: 18),
                  const SizedBox(width: 15),
                  const Icon(Icons.delete, color: Color(0xFFFFA500), size: 18),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHintNote() {
    return Container(
      padding: const EdgeInsets.only(top: 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A2A), style: BorderStyle.solid),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.arrow_back, color: Color(0xFFFFA500), size: 12),
          const SizedBox(width: 6),
          Text(
            'Swipe left to delete · Tap entry to edit ',
            style: const TextStyle(color: Color(0xFF555555), fontSize: 11),
          ),
          const Icon(Icons.edit, color: Color(0xFFFFA500), size: 12),
        ],
      ),
    );
  }
}

// Reusable circular progress painter (same as left screen, but we keep it here for completeness)
class _CircleProgressPainter extends CustomPainter {
  final double progress;

  _CircleProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background grey ring
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
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.142 * progress;
    canvas.drawArc(rect, -3.142 / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
