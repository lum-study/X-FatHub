import 'package:flutter/material.dart';

class BookAndPayScreen extends StatelessWidget {
  const BookAndPayScreen({super.key});

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
              _buildBackRow(context),
              const SizedBox(height: 14),
              _buildSelectedPackageBanner(),
              const SizedBox(height: 14),
              _buildSectionTitle(Icons.calendar_month, "Select Date"),
              const SizedBox(height: 14),
              _buildDatePicker(),
              const SizedBox(height: 14),
              _buildSectionTitle(Icons.access_time, "Select Time"),
              const SizedBox(height: 14),
              _buildTimeGrid(),
              const SizedBox(height: 14),
              _buildSectionTitle(Icons.receipt_long, "Order Summary"),
              const SizedBox(height: 14),
              _buildOrderSummary(),
              const SizedBox(height: 14),
              _buildSectionTitle(Icons.credit_card, "Payment Method"),
              const SizedBox(height: 14),
              _buildPaymentMethods(),
              const SizedBox(height: 20),
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackRow(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Row(
        children: [
          const Icon(Icons.chevron_left, color: Color(0xFFFFA500), size: 24),
          const SizedBox(width: 10),
          const Text(
            "Book a Session",
            style: TextStyle(
              color: Color(0xFFFFA500),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPackageBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1000), Color(0xFF0F0F0F)],
        ),
        border: Border.all(color: const Color(0xFFFFA500)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fitness_center, color: Color(0xFFFFA500), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ultimate Strength Pack",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  "RM 199",
                  style: TextStyle(
                    color: Color(0xFFFFA500),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  "12 Sessions · Full Gym Access",
                  style: TextStyle(color: Color(0xFF777777), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFFA500), size: 14),
        const SizedBox(width: 5),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 11,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    final dates = [
      {"day": "MON", "num": "3"},
      {"day": "TUE", "num": "4"},
      {"day": "WED", "num": "5"},
      {"day": "THU", "num": "6"},
      {"day": "FRI", "num": "7"},
      {"day": "SAT", "num": "8"},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: dates.map((d) {
          final bool isSelected = d["num"] == "4";
          return Container(
            margin: const EdgeInsets.only(right: 7),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFA500) : const Color(0xFF0D0D0D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? const Color(0xFFFFA500) : const Color(0xFF2A2A2A),
              ),
            ),
            child: Column(
              children: [
                Text(
                  d["day"]!,
                  style: TextStyle(
                    color: isSelected ? Colors.black : const Color(0xFF666666),
                    fontSize: 10,
                  ),
                ),
                Text(
                  d["num"]!,
                  style: TextStyle(
                    color: isSelected ? Colors.black : const Color(0xFFAAAAAA),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeGrid() {
    final times = [
      {"time": "06:00 AM", "status": "taken"},
      {"time": "07:00 AM", "status": "available"},
      {"time": "08:00 AM", "status": "selected"},
      {"time": "10:00 AM", "status": "available"},
      {"time": "12:00 PM", "status": "taken"},
      {"time": "03:00 PM", "status": "available"},
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: times.length,
      itemBuilder: (context, index) {
        final t = times[index];
        final bool isSelected = t["status"] == "selected";
        final bool isTaken = t["status"] == "taken";

        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFFA500)
                : (isTaken ? const Color(0xFF0A0A0A) : const Color(0xFF111111)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFA500)
                  : (isTaken ? const Color(0xFF1A1A1A) : const Color(0xFF2A2A2A)),
            ),
          ),
          child: Text(
            t["time"]!,
            style: TextStyle(
              color: isSelected
                  ? Colors.black
                  : (isTaken ? const Color(0xFF333333) : const Color(0xFFAAAAAA)),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border.all(color: const Color(0xFF2A2A2A)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _buildPayRow("Package", "Ultimate Strength Pack"),
          const SizedBox(height: 8),
          _buildPayRow("Date", "Tue, 4 Mar 2026"),
          const SizedBox(height: 8),
          _buildPayRow("Time", "08:00 AM"),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Color(0xFF2A2A2A), height: 1, thickness: 1),
          ),
          _buildPayRow("Subtotal", "RM 199.00"),
          const SizedBox(height: 8),
          _buildPayRow("SST (8%)", "RM 15.92"),
          const SizedBox(height: 8),
          _buildPayRow("Total", "RM 214.92", isOrange: true),
        ],
      ),
    );
  }

  Widget _buildPayRow(String label, String val, {bool isOrange = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
        Text(
          val,
          style: TextStyle(
            color: isOrange ? const Color(0xFFFFA500) : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    final methods = [
      {"name": "Card", "icon": Icons.credit_card},
      {"name": "Apple Pay", "icon": Icons.apple},
      {"name": "e-Wallet", "icon": Icons.account_balance_wallet},
      {"name": "FPX", "icon": Icons.account_balance},
    ];
    return Row(
      children: methods.map((m) {
        final bool isSelected = m["name"] == "Card";
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1A1000) : const Color(0xFF111111),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? const Color(0xFFFFA500) : const Color(0xFF2A2A2A),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  m["icon"] as IconData,
                  color: isSelected ? const Color(0xFFFFA500) : const Color(0xFF555555),
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  m["name"] as String,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFFFA500) : const Color(0xFF777777),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA500),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA500).withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, color: Colors.black, size: 16),
          SizedBox(width: 8),
          Text(
            "Confirm & Pay RM 214.92",
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
