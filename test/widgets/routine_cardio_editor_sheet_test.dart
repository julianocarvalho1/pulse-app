import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/workouts/domain/models/cardio_log.dart';
import 'package:pulse/theme/app_theme.dart';
import 'package:pulse/widgets/routine_cardio_editor_sheet.dart';

void main() {
  testWidgets('modelo intervalado é editável e salva o plano estruturado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final palette = pulsePalettes.first;
    AppColors.configure(Brightness.light, primaryColor: palette.lightPrimary);
    RoutineCardio? saved;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildPulseLightTheme(palette.lightPrimary),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  saved = await showRoutineCardioEditorSheet(
                    context,
                    cardioId: 'cardio-test',
                    initialPurpose: CardioPurpose.standalone,
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('cardio-template-editable_intervals')),
    );
    await tester.pumpAndSettle();

    expect(find.text('BLOCOS DO INTERVALADO'), findsOneWidget);
    expect(find.text('Duração calculada: 19 min'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('cardio-cycles')));
    await tester.enterText(find.byKey(const Key('cardio-cycles')), '4');
    await tester.pump();
    expect(find.text('Duração calculada: 16 min'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('save-cardio-plan')));
    await tester.tap(find.byKey(const Key('save-cardio-plan')));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.id, 'cardio-test');
    expect(saved!.plannedDurationMinutes, 16);
    expect(saved!.plan.purpose, CardioPurpose.standalone);
    expect(saved!.plan.format, CardioFormat.intervals);
    expect(saved!.plan.intervals?.cycles, 4);
  });
}
