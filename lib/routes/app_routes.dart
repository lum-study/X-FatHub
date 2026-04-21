import 'main_navigation_screen.dart';
import '../features/booking/views/payment_success_screen.dart';

class AppRoutes {
  static const home = "/";
  static const paymentSuccess = "/payment/success";
  static const paymentCancel = "/payment/cancel";

  static final routes = {
    home: (context) => const MainNavigationScreen(),
    paymentSuccess: (context) => const PaymentSuccessScreen(),
    paymentCancel: (context) => const PaymentSuccessScreen(isCancelled: true),
  };
}
