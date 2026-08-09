import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/exercises/domain/exercise_catalog.dart';
import 'package:pulse/features/exercises/presentation/widgets/exercise_media_view.dart';
import 'package:pulse/models/exercise.dart';

void main() {
  testWidgets('alterna entre as poses oficiais de início e final', (
    tester,
  ) async {
    final exercise = exerciseDatabase.firstWhere((item) => item.id == 'p1');
    final media = ExerciseCatalog.repDbMediaFor(exercise)!;

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 200,
          height: 200,
          child: ExerciseMediaView(exercise: exercise, showPoseLabel: true),
        ),
      ),
    );

    expect(
      find.byKey(ValueKey<String>('exercise-media-${media.startAssetPath}')),
      findsOneWidget,
    );
    expect(find.text('Início'), findsOneWidget);
    await tester.pump();
    expect(find.byIcon(Icons.image_not_supported_outlined), findsNothing);

    await tester.pump(const Duration(milliseconds: 1400));

    expect(
      find.byKey(ValueKey<String>('exercise-media-${media.peakAssetPath}')),
      findsOneWidget,
    );
    expect(find.text('Final'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('mantém fallback local apenas para exercício personalizado', (
    tester,
  ) async {
    const exercise = Exercise(
      id: 'custom_media_test',
      name: 'Movimento personalizado',
      muscle: 'Outros',
      description: 'Exercício criado pelo usuário.',
      reps: '3x 10',
      rest: '1 min',
    );
    final fallbackPath = ExerciseCatalog.mediaPathFor(exercise);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 80,
          height: 80,
          child: ExerciseMediaView(exercise: exercise),
        ),
      ),
    );

    expect(ExerciseCatalog.repDbMediaFor(exercise), isNull);
    expect(
      find.byKey(ValueKey<String>('exercise-media-$fallbackPath')),
      findsOneWidget,
    );
  });
}
