import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/release_notes/presentation/screens/whats_new_screen.dart';

void main() {
  testWidgets('resume as novidades e permite continuar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WhatsNewScreen()));

    expect(find.text('Novidades do PULSE'), findsOneWidget);
    expect(find.text('Versão 1.4.1'), findsOneWidget);
    expect(find.text('Cardio guiado'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Intervalos mais claros'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Intervalos mais claros'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Você escolhe a próxima ficha'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Você escolhe a próxima ficha'), findsOneWidget);
    expect(find.byKey(const Key('close-whats-new')), findsOneWidget);
  });

  testWidgets('fecha a tela pelo botão continuar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const WhatsNewScreen()),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Novidades do PULSE'), findsOneWidget);

    await tester.tap(find.byKey(const Key('close-whats-new')));
    await tester.pumpAndSettle();

    expect(find.text('Novidades do PULSE'), findsNothing);
    expect(find.text('Abrir'), findsOneWidget);
  });
}
