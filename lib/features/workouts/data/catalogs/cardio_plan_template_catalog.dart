import '../../domain/models/cardio_log.dart';

class CardioPlanTemplate {
  const CardioPlanTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.plan,
  });

  final String id;
  final String name;
  final String description;
  final int durationMinutes;
  final CardioPlan plan;

  RoutineCardio create({
    required String cardioId,
    CardioModality modality = CardioModality.treadmill,
  }) {
    return RoutineCardio(
      id: cardioId,
      modality: modality,
      plannedDurationMinutes:
          plan.intervals?.totalDurationMinutes ?? durationMinutes,
      plan: plan,
    );
  }
}

abstract final class CardioPlanTemplateCatalog {
  static const CardioPlanTemplate custom = CardioPlanTemplate(
    id: 'custom',
    name: 'Livre',
    description: 'Comece em branco e use o que está na sua ficha.',
    durationMinutes: 20,
    plan: CardioPlan(),
  );

  static const CardioPlanTemplate continuousLight = CardioPlanTemplate(
    id: 'continuous_light',
    name: 'Contínuo leve',
    description: 'Ritmo confortável e duração totalmente editável.',
    durationMinutes: 20,
    plan: CardioPlan(intensity: CardioIntensity.light),
  );

  static const CardioPlanTemplate continuousModerate = CardioPlanTemplate(
    id: 'continuous_moderate',
    name: 'Contínuo moderado',
    description: 'Ritmo em que conversar ainda é possível.',
    durationMinutes: 20,
    plan: CardioPlan(intensity: CardioIntensity.moderate),
  );

  static const CardioPlanTemplate editableIntervals = CardioPlanTemplate(
    id: 'editable_intervals',
    name: 'Intervalado',
    description: 'Blocos de esforço e recuperação para você ajustar.',
    durationMinutes: 19,
    plan: CardioPlan(
      format: CardioFormat.intervals,
      intervals: CardioIntervalPlan(),
    ),
  );

  static const List<CardioPlanTemplate> all = <CardioPlanTemplate>[
    custom,
    continuousLight,
    continuousModerate,
    editableIntervals,
  ];
}
