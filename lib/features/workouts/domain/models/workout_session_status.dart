enum WorkoutSessionStatus {
  completed,
  incomplete,
  cancelled;

  String get storageValue => name;

  static WorkoutSessionStatus fromStorage(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();

    return switch (normalized) {
      'incomplete' => WorkoutSessionStatus.incomplete,
      'cancelled' => WorkoutSessionStatus.cancelled,
      _ => WorkoutSessionStatus.completed,
    };
  }
}
