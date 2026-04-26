import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfathub/features/booking/viewmodels/booking_viewmodel.dart';
import 'package:xfathub/routes/main_navigation_screen.dart';

class PaymentCancelScreen extends StatefulWidget {
  const PaymentCancelScreen({super.key});

  @override
  State<PaymentCancelScreen> createState() => _PaymentCancelScreenState();
}

class _PaymentCancelScreenState extends State<PaymentCancelScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<BookingViewModel>();
      vm.refreshPackagesPage();
      vm.refreshCurrentUserBookingData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.cancel_outlined,
                color: Colors.red,
                size: 72,
              ),
              const SizedBox(height: 14),
              const Text(
                'Payment Failed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your payment was cancelled or failed. No charges were made.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
              ),
              const Spacer(),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA500),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    // Navigate back to the home route (MainNavigationScreen)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    // Switch to Packages tab (Index 1)
                    MainNavigationScreen.switchToTab(1);
                  },
                  child: const Text(
                    'Go to Packages',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
