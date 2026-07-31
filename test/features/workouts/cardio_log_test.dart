import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/domain/models/cardio_log.dart';

void main() {
  test('serializa e restaura registro de cardio', () {
    const log = CardioLog(
      modality: CardioModality.stationaryBike,
      plannedDurationMinutes: 45,
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
}
