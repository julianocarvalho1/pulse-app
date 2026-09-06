import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/screens/create_routine_screen.dart';

void main() {
  testWidgets('cardio dispensa divisão ABC e abre configuração de blocos', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CreateRoutineScreen())),
    );
    await tester.enterText(find.byType(TextField).first, 'Meu cardio');
    await tester.ensureVisible(find.text('Cardio'));
    await tester.tap(find.text('Cardio'));
    await tester.pumpAndSettle();
    expect(find.text('PASSO 3: DIVISÃO DO TREINO'), findsNothing);
    await tester.tap(find.text('AVANÇAR E MONTAR FICHAS'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('cardio-template-editable_intervals')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
