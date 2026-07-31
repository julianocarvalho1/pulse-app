import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/progress/domain/models/body_measurement_entry.dart';

void main() {
  test('converte avaliação corporal para mapa do banco e restaura', () {
    final entry = BodyMeasurementEntry(
      id: 'measurement-1',
      recordedAt: DateTime(2026, 7, 30, 12, 30),
      weightKg: 75.5,
      chestCm: 101,
      waistCm: 82.5,
    );

    final restored = BodyMeasurementEntry.fromDatabaseMap(
      entry.toDatabaseMap(),
    );

    expect(restored.id, entry.id);
    expect(restored.recordedAt, entry.recordedAt);
    expect(restored.weightKg, 75.5);
    expect(restored.chestCm, 101);
    expect(restored.waistCm, 82.5);
    expect(restored.hasAnyValue, isTrue);
  });
}
