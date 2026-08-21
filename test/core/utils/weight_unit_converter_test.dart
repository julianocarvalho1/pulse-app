import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/utils/weight_unit_converter.dart';
import 'package:pulse/features/settings/domain/pulse_settings.dart';

void main() {
  test('mantém peso em kg no sistema métrico', () {
    expect(
      WeightUnitConverter.displayTextFromKilogramsText(
        '20',
        MeasurementSystem.metric,
      ),
      '20',
    );
    expect(
      WeightUnitConverter.kilogramsTextFromDisplayText(
        '20',
        MeasurementSystem.metric,
      ),
      '20',
    );
  });

  test('converte kg para lbs na exibição', () {
    expect(
      WeightUnitConverter.displayTextFromKilogramsText(
        '20',
        MeasurementSystem.imperial,
      ),
      '44.09',
    );
  });

  test('converte lbs de volta para kg antes de salvar', () {
    final kilograms = WeightUnitConverter.parseDisplayedWeightToKilograms(
      '44.09',
      MeasurementSystem.imperial,
    );

    expect(kilograms, closeTo(20, 0.01));
    expect(
      WeightUnitConverter.kilogramsTextFromDisplayText(
        '44.09',
        MeasurementSystem.imperial,
      ),
      '20',
    );
  });

  test('converte texto entre sistemas sem alterar o peso real', () {
    expect(
      WeightUnitConverter.convertDisplayText(
        '20',
        from: MeasurementSystem.metric,
        to: MeasurementSystem.imperial,
      ),
      '44.09',
    );
    expect(
      WeightUnitConverter.convertDisplayText(
        '44.09',
        from: MeasurementSystem.imperial,
        to: MeasurementSystem.metric,
      ),
      '20',
    );
  });
}
