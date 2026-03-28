import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:xfathub/features/activity_health/viewmodels/step_tracker_viewmodel.dart';
import 'package:xfathub/features/activity_health/repositories/step_tracker_repository.dart';
import 'package:xfathub/features/activity_health/viewmodels/hydration_viewmodel.dart';
import 'package:xfathub/features/activity_health/repositories/hydration_repository.dart';
import 'package:xfathub/features/booking/providers/booking_provider.dart';

/// Setup all providers for the application
List<SingleChildWidget> appProviders = [
  ChangeNotifierProvider<StepTrackerViewModel>(
    create: (_) => StepTrackerViewModel(
      repository: StepTrackerRepository(),
    ),
  ),
  ChangeNotifierProvider<HydrationViewModel>(
    create: (_) => HydrationViewModel(
      repository: HydrationRepository(),
    ),
  ),
  ChangeNotifierProvider<BookingProvider>(
    create: (_) => BookingProvider(),
  ),
];
