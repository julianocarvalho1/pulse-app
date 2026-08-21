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

  test('identifica pesagem isolada sem tratar como avaliação corporal', () {
    final weighing = BodyMeasurementEntry(
      id: 'weight-only',
      recordedAt: DateTime(2026, 7, 31, 8),
      weightKg: 78.4,
    );
    final assessment = BodyMeasurementEntry(
      id: 'assessment',
      recordedAt: DateTime(2026, 7, 31, 9),
      weightKg: 78.4,
      waistCm: 84,
    );

    expect(weighing.isWeightOnly, isTrue);
    expect(weighing.hasBodyMeasurements, isFalse);
    expect(assessment.isWeightOnly, isFalse);
    expect(assessment.hasBodyMeasurements, isTrue);
  });

  test('pesagem não preenche medidas corporais ausentes', () {
    final weighing = BodyMeasurementEntry(
      id: 'weight-only',
      recordedAt: DateTime(2026, 8, 7, 8),
      weightKg: 77.9,
    );

    expect(weighing.valueFor(BodyMeasurementType.weight), 77.9);
    expect(weighing.valueFor(BodyMeasurementType.waist), isNull);
    expect(weighing.valueFor(BodyMeasurementType.leftArm), isNull);
  });

  test('avaliação corporal pode ser salva sem peso', () {
    final assessment = BodyMeasurementEntry(
      id: 'body-only',
      recordedAt: DateTime(2026, 8, 7, 9),
      waistCm: 83,
      hipsCm: 98,
    );

    expect(assessment.hasAnyValue, isTrue);
    expect(assessment.weightKg, isNull);
    expect(assessment.isWeightOnly, isFalse);
    expect(assessment.hasBodyMeasurements, isTrue);
  });
}
