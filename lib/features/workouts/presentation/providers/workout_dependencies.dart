import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/workout_repository_impl.dart';
import '../../data/services/workout_feedback_service.dart';
import '../../domain/repositories/workout_repository.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepositoryImpl(),
);

final workoutFeedbackServiceProvider = Provider<WorkoutFeedbackService>((ref) {
  final service = DeviceWorkoutFeedbackService();

  ref.onDispose(() {
    unawaited(service.dispose());
  });

  return service;
});
