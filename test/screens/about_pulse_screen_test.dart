import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/exercises/domain/repdb_exercise_mapping.dart';
import 'package:pulse/screens/about_pulse_screen.dart';

void main() {
  testWidgets('exibe a atribuição obrigatória do RepDB', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutPulseScreen()));

    expect(find.text('Sobre o PULSE'), findsOneWidget);
    expect(find.text(RepDbExerciseMapping.attributionText), findsOneWidget);
    expect(find.textContaining('Uso gratuito com atribuição'), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
  });
}
