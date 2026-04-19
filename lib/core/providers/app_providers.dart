import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:xfathub/features/activity_health/viewmodels/step_tracker_viewmodel.dart';
import 'package:xfathub/features/activity_health/repositories/step_tracker_repository.dart';
import 'package:xfathub/features/activity_health/viewmodels/hydration_viewmodel.dart';
import 'package:xfathub/features/activity_health/repositories/hydration_repository.dart';
import 'package:xfathub/features/activity_health/viewmodels/activity_tracking_viewmodel.dart';
import 'package:xfathub/features/activity_health/repositories/activity_repository.dart';
import 'package:xfathub/features/booking/providers/booking_provider.dart';
import 'package:xfathub/features/home/providers/profile_provider.dart';
import 'package:xfathub/features/community/providers/community_provider.dart';

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
  ChangeNotifierProvider<ActivityTrackingViewModel>(
    create: (_) => ActivityTrackingViewModel(
      repository: ActivityRepository(),
    ),
  ),
  ChangeNotifierProvider<BookingProvider>(
    create: (_) => BookingProvider(),
  ),
  ChangeNotifierProvider<ProfileProvider>(
    create: (_) => ProfileProvider(),
  ),
  ChangeNotifierProvider<CommunityProvider>(
    create: (_) => CommunityProvider(),
  ),
];
