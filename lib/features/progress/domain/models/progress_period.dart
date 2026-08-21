enum ProgressPeriod {
  fourWeeks,
  threeMonths,
  sixMonths,
  oneYear,
  all;

  String get label {
    return switch (this) {
      ProgressPeriod.fourWeeks => '4 semanas',
      ProgressPeriod.threeMonths => '3 meses',
      ProgressPeriod.sixMonths => '6 meses',
      ProgressPeriod.oneYear => '1 ano',
      ProgressPeriod.all => 'Todo histórico',
    };
  }

  int? get dayCount {
    return switch (this) {
      ProgressPeriod.fourWeeks => 28,
      ProgressPeriod.threeMonths => 90,
      ProgressPeriod.sixMonths => 180,
      ProgressPeriod.oneYear => 365,
      ProgressPeriod.all => null,
    };
  }

  DateTime? startDate(DateTime now) {
    final days = dayCount;
    if (days == null) {
      return null;
    }

    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: days - 1));
  }
}
