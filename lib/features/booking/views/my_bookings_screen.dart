import 'package:flutter/material.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildActivePackageStrip(),
              const SizedBox(height: 14),
              _buildTabs(),
              const SizedBox(height: 14),
              _buildUpcomingBooking(),
              const SizedBox(height: 10),
              _buildQRCodeReceipt(),
              const SizedBox(height: 10),
              _buildHistoryBooking(),
              const SizedBox(height: 10),
              _buildCancelledBooking(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.confirmation_number,
                color: Color(0xFFFFA500), size: 28),
            const SizedBox(width: 8),
            const Text(
              "My Bookings",
              style: TextStyle(
                color: Color(0xFFFFA500),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Icon(Icons.tune, color: Color(0xFFFFA500), size: 28),
      ],
    );
  }

  Widget _buildActivePackageStrip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1000), Color(0xFF0F0F0F)],
        ),
        border: Border.all(color: const Color(0xFFFFA500)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fitness_center,
                        color: Color(0xFFFFA500), size: 14),
                    const SizedBox(width: 5),
                    const Text(
                      "Ultimate Strength Pack",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Text(
                  "Valid Until 30 Apr 2026",
                  style: TextStyle(color: Color(0xFF888888), fontSize: 10),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 130,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.58,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA500),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "7",
                style: TextStyle(
                  color: Color(0xFFFFA500),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                "Sessions Left",
                style: TextStyle(
                  color: Color(0xFFFFA500),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          _buildTab("Upcoming", true),
          _buildTab("History", false),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFA500) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.black : const Color(0xFF666666),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingBooking() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFFFFA500)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Morning Strength",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    "Ultimate Strength Pack · Session 6/12",
                    style: TextStyle(color: Color(0xFF777777), fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1000),
                  border: Border.all(color: const Color(0xFFFFA500)),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  "UPCOMING",
                  style: TextStyle(
                    color: Color(0xFFFFA500),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMetaItem(Icons.calendar_today, "Tue, 4 Mar 2026"),
              const SizedBox(width: 14),
              _buildMetaItem(Icons.access_time, "08:00 AM"),
              const SizedBox(width: 14),
              _buildMetaItem(Icons.location_on, "Zone A"),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildActionButton("Reschedule", isOutline: true, icon: Icons.edit_calendar),
              const SizedBox(width: 8),
              _buildActionButton("Cancel", isOutline: true, color: const Color(0xFF666666), borderColor: const Color(0xFF333333)),
              const SizedBox(width: 8),
              _buildActionButton("QR", icon: Icons.qr_code, color: Colors.black, bgColor: const Color(0xFFFFA500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFFA500), size: 12),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
      ],
    );
  }

  Widget _buildActionButton(String label,
      {bool isOutline = false,
      Color? color,
      Color? borderColor,
      Color? bgColor,
      IconData? icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.transparent,
          border: isOutline
              ? Border.all(color: borderColor ?? const Color(0xFFFFA500), width: 1.5)
              : null,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color ?? (bgColor != null ? Colors.black : const Color(0xFFFFA500)), size: 12),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: color ?? (bgColor != null ? Colors.black : const Color(0xFFFFA500)),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeReceipt() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border.all(color: const Color(0xFFFFA500)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code, color: Color(0xFFFFA500), size: 14),
              SizedBox(width: 5),
              Text(
                "ENTRY QR RECEIPT",
                style: TextStyle(
                  color: Color(0xFFFFA500),
                  fontSize: 11,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 110,
            height: 110,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: CustomPaint(
              painter: QRPainter(),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "#BK-20260304-0081",
            style: TextStyle(color: Color(0xFF555555), fontSize: 11, letterSpacing: 1),
          ),
          const Text(
            "Morning Strength · 08:00 AM",
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const Text(
            "Tue, 4 Mar 2026 · Zone A · 1 person",
            style: TextStyle(color: Color(0xFF888888), fontSize: 11),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFFA500), width: 1.5),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.file_download_outlined, color: Color(0xFFFFA500), size: 16),
                SizedBox(width: 8),
                Text(
                  "Save Receipt",
                  style: TextStyle(
                    color: Color(0xFFFFA500),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryBooking() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF2A2A2A)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Evening HIIT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    "HIIT Blast Pack · Session 6/6",
                    style: TextStyle(color: Color(0xFF777777), fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1A0D),
                  border: Border.all(color: const Color(0xFF2E5C2E)),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  "DONE",
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMetaItem(Icons.calendar_today, "Fri, 27 Feb 2026"),
              const SizedBox(width: 14),
              _buildMetaItem(Icons.access_time, "06:00 PM"),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildActionButton("Receipt", icon: Icons.qr_code, color: Colors.black, bgColor: const Color(0xFFFFA500)),
              const SizedBox(width: 8),
              _buildActionButton("Review", isOutline: true, color: const Color(0xFFAAAAAA), borderColor: const Color(0xFF333333), icon: Icons.star_outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledBooking() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF2A2A2A)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Yoga Flow",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    "Single Session · Refund Pending",
                    style: TextStyle(color: Color(0xFF777777), fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0A0A),
                  border: Border.all(color: const Color(0xFF5C2222)),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  "CANCELLED",
                  style: TextStyle(
                    color: Color(0xFFE74C3C),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMetaItem(Icons.calendar_today, "Mon, 2 Mar 2026"),
              const SizedBox(width: 14),
              _buildMetaItem(Icons.access_time, "10:00 AM"),
            ],
          ),
        ],
      ),
    );
  }
}

class QRPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    const int gridCount = 21;
    final double cellSize = size.width / gridCount;

    void drawRect(int x, int y, int w, int h) {
      canvas.drawRect(
        Rect.fromLTWH(x * cellSize, y * cellSize, w * cellSize, h * cellSize),
        paint,
      );
    }

    // Top-left finder
    drawRect(1, 1, 7, 7);
    paint.color = Colors.white;
    drawRect(2, 2, 5, 5);
    paint.color = Colors.black;
    drawRect(3, 3, 3, 3);

    // Top-right finder
    drawRect(13, 1, 7, 7);
    paint.color = Colors.white;
    drawRect(14, 2, 5, 5);
    paint.color = Colors.black;
    drawRect(15, 3, 3, 3);

    // Bottom-left finder
    drawRect(1, 13, 7, 7);
    paint.color = Colors.white;
    drawRect(2, 14, 5, 5);
    paint.color = Colors.black;
    drawRect(3, 15, 3, 3);

    // Data dots (simplified based on SVG)
    drawRect(9, 1, 1, 1);
    drawRect(11, 1, 1, 1);
    drawRect(9, 3, 2, 1);
    drawRect(10, 5, 1, 2);
    drawRect(9, 8, 1, 1);
    drawRect(11, 8, 1, 1);
    drawRect(1, 9, 1, 1);
    drawRect(3, 9, 2, 1);
    drawRect(6, 9, 2, 1);
    drawRect(9, 9, 3, 1);
    drawRect(13, 9, 1, 1);
    drawRect(15, 9, 2, 1);
    drawRect(19, 9, 1, 1);
    drawRect(1, 11, 2, 1);
    drawRect(5, 11, 1, 1);
    drawRect(8, 11, 1, 1);
    drawRect(10, 11, 2, 1);
    drawRect(14, 11, 3, 1);
    drawRect(19, 11, 1, 1);
    drawRect(9, 13, 1, 1);
    drawRect(11, 13, 2, 1);
    drawRect(9, 15, 3, 1);
    drawRect(13, 15, 1, 1);
    drawRect(15, 15, 1, 2);
    drawRect(17, 15, 2, 1);
    drawRect(9, 17, 1, 1);
    drawRect(11, 17, 1, 2);
    drawRect(13, 17, 3, 1);
    drawRect(17, 17, 1, 1);
    drawRect(19, 17, 1, 2);
    drawRect(9, 19, 1, 1);
    drawRect(14, 19, 2, 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
