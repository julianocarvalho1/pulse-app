import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/reviews/data/pulse_review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('só solicita avaliação depois de cinco treinos concluídos', () async {
    final gateway = _FakeReviewGateway();
    final service = PulseReviewService(gateway: gateway);
    final now = DateTime(2026, 9, 2);

    for (var index = 0; index < 4; index++) {
      expect(
        await service.recordCompletedWorkoutAndMaybeRequest(now: now),
        isFalse,
      );
    }

    expect(
      await service.recordCompletedWorkoutAndMaybeRequest(now: now),
      isTrue,
    );
    expect(gateway.requestCount, 1);
  });

  test('respeita intervalo de tempo e quantidade de treinos', () async {
    final gateway = _FakeReviewGateway();
    final service = PulseReviewService(gateway: gateway);
    final firstRequestAt = DateTime(2026, 1, 1);

    for (var index = 0; index < 5; index++) {
      await service.recordCompletedWorkoutAndMaybeRequest(now: firstRequestAt);
    }
    for (var index = 0; index < 19; index++) {
      expect(
        await service.recordCompletedWorkoutAndMaybeRequest(
          now: firstRequestAt.add(const Duration(days: 200)),
        ),
        isFalse,
      );
    }
    expect(gateway.requestCount, 1);

    expect(
      await service.recordCompletedWorkoutAndMaybeRequest(
        now: firstRequestAt.add(const Duration(days: 200)),
      ),
      isTrue,
    );
    expect(gateway.requestCount, 2);
  });

  test('não registra tentativa quando o recurso não está disponível', () async {
    final gateway = _FakeReviewGateway(available: false);
    final service = PulseReviewService(gateway: gateway);

    for (var index = 0; index < 5; index++) {
      await service.recordCompletedWorkoutAndMaybeRequest(
        now: DateTime(2026, 9, 2),
      );
    }

    expect(gateway.requestCount, 0);
  });
}

class _FakeReviewGateway implements PulseReviewGateway {
  _FakeReviewGateway({this.available = true});

  final bool available;
  int requestCount = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async {
    requestCount++;
  }
}
