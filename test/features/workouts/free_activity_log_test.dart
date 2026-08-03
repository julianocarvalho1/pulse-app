import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/domain/models/free_activity_log.dart';

void main() {
  test('serializa e restaura uma atividade livre', () {
    const activity = FreeActivityLog(
      type: FreeActivityType.crossfit,
      durationMinutes: 55,
      intensity: FreeActivityIntensity.intense,
      replacedPlannedWorkout: true,
      notes: 'Aula com as amigas.',
    );

    final restored = FreeActivityLog.fromMap(activity.toMap());

    expect(restored.type, FreeActivityType.crossfit);
    expect(restored.displayName, 'CrossFit');
    expect(restored.durationMinutes, 55);
    expect(restored.intensity, FreeActivityIntensity.intense);
    expect(restored.replacedPlannedWorkout, isTrue);
    expect(restored.notes, 'Aula com as amigas.');
  });

  test('usa nome personalizado apenas em esporte e outra atividade', () {
    const sport = FreeActivityLog(
      type: FreeActivityType.sport,
      durationMinutes: 60,
      intensity: FreeActivityIntensity.moderate,
      customName: 'Vôlei',
    );
    const pilates = FreeActivityLog(
      type: FreeActivityType.pilates,
      durationMinutes: 50,
      intensity: FreeActivityIntensity.light,
      customName: 'Nome ignorado',
    );

    expect(sport.displayName, 'Vôlei');
    expect(pilates.displayName, 'Pilates');
  });
}
