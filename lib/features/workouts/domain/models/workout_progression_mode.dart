enum WorkoutProgressionMode {
  followPlan,
  withinRange,
  repsThenLoad;

  String get label => switch (this) {
    WorkoutProgressionMode.followPlan => 'Seguir a ficha',
    WorkoutProgressionMode.withinRange => 'Dentro da faixa',
    WorkoutProgressionMode.repsThenLoad => 'Repetições e depois carga',
  };

  String get description => switch (this) {
    WorkoutProgressionMode.followPlan =>
      'Repete exatamente os alvos cadastrados, sem sugerir progressão automática.',
    WorkoutProgressionMode.withinRange =>
      'Ajuda a avançar somente dentro da faixa de repetições definida na ficha.',
    WorkoutProgressionMode.repsThenLoad =>
      'Completa o topo da faixa antes de considerar o menor aumento de carga disponível.',
  };

  static WorkoutProgressionMode fromStorage(Object? value) {
    final name = value?.toString() ?? '';
    return WorkoutProgressionMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => WorkoutProgressionMode.withinRange,
    );
  }
}
