import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../features/activity_health/viewmodels/step_tracker_viewmodel.dart';
import '../../features/activity_health/repositories/step_tracker_repository.dart';

/// Setup all providers for the application
/// This should be used in MultiProvider at the root level
List<ChangeNotifierProvider> appProviders = [
  // Step Tracker ViewModel
  ChangeNotifierProvider(
    create: (_) => StepTrackerViewModel(
      repository: StepTrackerRepository(),
    ),
  ),
];
