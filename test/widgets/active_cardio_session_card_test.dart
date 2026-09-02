import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/domain/models/active_workout_session.dart';
import 'package:pulse/features/workouts/domain/models/cardio_log.dart';
import 'package:pulse/theme/app_theme.dart';
import 'package:pulse/widgets/active_cardio_session_card.dart';

void main() {
  testWidgets(
    'fecha editor de cardio com campo ativo sem usar controller descartado',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildPulseLightTheme(pulsePalettes[1].lightPrimary),
          home: Scaffold(
            body: ActiveCardioSessionCard(
              entry: const ActiveCardioEntry(
                id: 'cardio-1',
                modality: CardioModality.treadmill,
                plannedDurationMinutes: 20,
                plan: CardioPlan(plannedSpeedKmh: 6, plannedInclinePercent: 3),
              ),
              index: 0,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Metas: 6 km/h • 3% inclinação'), findsOneWidget);

      await tester.tap(find.text('Esteira'));
      await tester.pumpAndSettle();

      final durationField = find.widgetWithText(
        TextFormField,
        'Duração realizada',
      );
      expect(durationField, findsOneWidget);

      await tester.enterText(durationField, '15');
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Duração realizada'), findsNothing);
    },
  );
}
