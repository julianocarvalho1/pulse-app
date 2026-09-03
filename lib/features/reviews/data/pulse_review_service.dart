import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PulseReviewGateway {
  Future<bool> isAvailable();

  Future<void> requestReview();
}

class PlayInAppReviewGateway implements PulseReviewGateway {
  PlayInAppReviewGateway({InAppReview? review})
    : _review = review ?? InAppReview.instance;

  final InAppReview _review;

  @override
  Future<bool> isAvailable() => _review.isAvailable();

  @override
  Future<void> requestReview() => _review.requestReview();
}

class PulseReviewService {
  PulseReviewService({
    PulseReviewGateway? gateway,
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _gateway = gateway ?? PlayInAppReviewGateway(),
       _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const int firstEligibleCompletion = 5;
  static const int completionsBetweenRequests = 20;
  static const Duration minimumRequestInterval = Duration(days: 120);

  static const String _completionCountKey = 'review_completed_workout_count';
  static const String _lastRequestCountKey =
      'review_last_request_completed_count';
  static const String _lastRequestAtKey = 'review_last_request_at_ms';

  final PulseReviewGateway _gateway;
  final Future<SharedPreferences> Function() _preferencesLoader;

  Future<bool> recordCompletedWorkoutAndMaybeRequest({DateTime? now}) async {
    final preferences = await _preferencesLoader();
    final completedCount = (preferences.getInt(_completionCountKey) ?? 0) + 1;
    await preferences.setInt(_completionCountKey, completedCount);

    if (completedCount < firstEligibleCompletion) {
      return false;
    }

    final lastRequestCount = preferences.getInt(_lastRequestCountKey) ?? 0;
    if (lastRequestCount > 0 &&
        completedCount - lastRequestCount < completionsBetweenRequests) {
      return false;
    }

    final currentTime = now ?? DateTime.now();
    final lastRequestAtMs = preferences.getInt(_lastRequestAtKey);
    if (lastRequestAtMs != null) {
      final lastRequestAt = DateTime.fromMillisecondsSinceEpoch(
        lastRequestAtMs,
      );
      if (currentTime.difference(lastRequestAt) < minimumRequestInterval) {
        return false;
      }
    }

    try {
      if (!await _gateway.isAvailable()) {
        return false;
      }
      await _gateway.requestReview();
      await preferences.setInt(_lastRequestCountKey, completedCount);
      await preferences.setInt(
        _lastRequestAtKey,
        currentTime.millisecondsSinceEpoch,
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('Não foi possível abrir a avaliação do Google Play: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }
}
