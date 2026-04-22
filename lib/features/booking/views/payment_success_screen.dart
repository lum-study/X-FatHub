import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfathub/features/booking/viewmodels/booking_viewmodel.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final bool isCancelled;

  const PaymentSuccessScreen({
    super.key,
    this.isCancelled = false,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
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
              Icon(
                widget.isCancelled ? Icons.cancel_outlined : Icons.check_circle,
                color: widget.isCancelled ? Colors.red : const Color(0xFFFFA500),
                size: 72,
              ),
              const SizedBox(height: 14),
              Text(
                widget.isCancelled ? 'Payment Cancelled' : 'Payment Successful',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isCancelled
                    ? 'Your payment was cancelled. No charges were made.'
                    : 'Your package has been purchased successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
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
                    Navigator.of(context).popUntil((route) => route.isFirst);
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