import '../../features/settings/domain/pulse_settings.dart';

class WeightUnitConverter {
  const WeightUnitConverter._();

  static const double poundsPerKilogram = 2.2046226218;

  static String unitLabel(MeasurementSystem system) {
    return system == MeasurementSystem.metric ? 'kg' : 'lbs';
  }

  static double fromKilograms(double kilograms, MeasurementSystem system) {
    return system == MeasurementSystem.metric
        ? kilograms
        : kilograms * poundsPerKilogram;
  }

  static double toKilograms(double displayedWeight, MeasurementSystem system) {
    return system == MeasurementSystem.metric
        ? displayedWeight
        : displayedWeight / poundsPerKilogram;
  }

  static String displayTextFromKilogramsText(
    String kilogramsText,
    MeasurementSystem system,
  ) {
    final parsed = _parse(kilogramsText);
    if (parsed == null) {
      return kilogramsText;
    }

    return _format(fromKilograms(parsed, system), maxDecimals: 2);
  }

  static String convertDisplayText(
    String displayedText, {
    required MeasurementSystem from,
    required MeasurementSystem to,
  }) {
    final kilograms = parseDisplayedWeightToKilograms(displayedText, from);
    if (kilograms == null) {
      return displayedText;
    }

    return _format(fromKilograms(kilograms, to), maxDecimals: 2);
  }

  static String kilogramsTextFromDisplayText(
    String displayedText,
    MeasurementSystem system,
  ) {
    final parsed = _parse(displayedText);
    if (parsed == null) {
      return displayedText;
    }

    return _format(toKilograms(parsed, system), maxDecimals: 2);
  }

  static double? parseDisplayedWeightToKilograms(
    String displayedText,
    MeasurementSystem system,
  ) {
    final parsed = _parse(displayedText);
    return parsed == null ? null : toKilograms(parsed, system);
  }

  static double? _parse(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  static String _format(double value, {required int maxDecimals}) {
    final fixed = value.toStringAsFixed(maxDecimals);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
