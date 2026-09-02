import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/domain/models/cardio_log.dart';

void main() {
  test('serializa e restaura registro de cardio', () {
    const log = CardioLog(
      modality: CardioModality.stationaryBike,
      plannedDurationMinutes: 45,
      plan: CardioPlan(
        purpose: CardioPurpose.standalone,
        format: CardioFormat.intervals,
        intensity: CardioIntensity.moderate,
        plannedResistanceLevel: 6,
        intervals: CardioIntervalPlan(
          warmUpMinutes: 5,
          effortSeconds: 45,
          recoverySeconds: 75,
          cycles: 8,
          coolDownMinutes: 4,
        ),
      ),
      actualDurationMinutes: 42,
      distanceKm: 16.4,
      averageSpeedKmh: 23.4,
      resistanceLevel: 7,
      perceivedEffort: 8,
      averageHeartRateBpm: 148,
      notes: 'Ritmo progressivo.',
    );

    final restored = CardioLog.fromMap(log.toMap());

    expect(restored.modality, CardioModality.stationaryBike);
    expect(restored.modality.label, 'Bicicleta');
    expect(restored.actualDurationMinutes, 42);
    expect(restored.plan.purpose, CardioPurpose.standalone);
    expect(restored.plan.format, CardioFormat.intervals);
    expect(restored.plan.intensity, CardioIntensity.moderate);
    expect(restored.plan.intervals?.cycles, 8);
    expect(restored.plan.plannedResistanceLevel, 6);
    expect(restored.distanceKm, 16.4);
    expect(restored.perceivedEffort, 8);
    expect(restored.averageHeartRateBpm, 148);
    expect(restored.notes, 'Ritmo progressivo.');
  });

  test('modalidade desconhecida usa Outro', () {
    expect(CardioModality.fromStorage('desconhecida'), CardioModality.other);
  });

  test('serializa cardio planejado da ficha', () {
    const planned = RoutineCardio(
      id: 'planned-1',
      modality: CardioModality.rowing,
      plannedDurationMinutes: 15,
      notes: 'Ritmo leve.',
    );

    final restored = RoutineCardio.fromMap(planned.toMap());

    expect(restored.id, 'planned-1');
    expect(restored.modality, CardioModality.rowing);
    expect(restored.plannedDurationMinutes, 15);
    expect(restored.notes, 'Ritmo leve.');
  });

  test('calcula a duração total do intervalado', () {
    const intervals = CardioIntervalPlan(
      warmUpMinutes: 5,
      effortSeconds: 30,
      recoverySeconds: 60,
      cycles: 6,
      coolDownMinutes: 5,
    );

    expect(intervals.totalDurationSeconds, 1140);
    expect(intervals.totalDurationMinutes, 19);
  });

  test(
    'plano ausente ou inválido mantém compatibilidade com cardio antigo',
    () {
      expect(CardioPlan.fromJson(null).format, CardioFormat.continuous);
      expect(
        CardioPlan.fromJson('não é json').intensity,
        CardioIntensity.selfSelected,
      );

      final restored = RoutineCardio.fromMap(<String, dynamic>{
        'id': 'legacy',
        'modality': 'treadmill',
        'plannedDurationMinutes': 20,
        'notes': '',
      });
      expect(restored.plan.purpose, CardioPurpose.postWorkout);
    },
  );
}
