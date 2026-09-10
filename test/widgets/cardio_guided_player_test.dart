import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/widgets/cardio_guided_player.dart';
import 'package:pulse/features/workouts/domain/models/cardio_log.dart';

void main() {
  testWidgets('transição automática, pausa no fundo e voz seguem o relógio', (
    tester,
  ) async {
    final watch = _ManualStopwatch();
    final spoken = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
          call,
        ) async {
          if (call.method == 'speak') spoken.add(call.arguments.toString());
          return 1;
        });
    await tester.pumpWidget(
      MaterialApp(
        home: CardioGuidedPlayer(
          stopwatch: watch,
          plan: const CardioPlan(
            format: CardioFormat.intervals,
            intervals: CardioIntervalPlan(
              warmUpMinutes: 0,
              coolDownMinutes: 0,
              effortSeconds: 2,
              recoverySeconds: 3,
              cycles: 1,
            ),
          ),
          minutes: 1,
          modality: CardioModality.walking,
        ),
      ),
    );
    await tester.ensureVisible(find.text('Avisos de voz'));
    await tester.tap(find.text('Avisos de voz'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Iniciar / continuar'));
    await tester.tap(find.text('Iniciar / continuar'));
    await tester.pump();
    watch.milliseconds = 2100;
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await tester.drag(find.byType(ListView).first, const Offset(0, 800));
    await tester.pump();
    expect(find.text('Recuperação · ciclo 1 de 1'), findsWidgets);
    expect(spoken.any((text) => text.contains('Recuperação')), isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Iniciar / continuar'), findsOneWidget);
    await tester.tap(find.text('Iniciar / continuar'));
    watch.milliseconds = 5000;
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    expect(find.text('Cardio finalizado'), findsOneWidget);
    expect(find.textContaining('Realizado: 0:05'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  test('intervalado expande somente esforço e recuperação', () {
    final stages = cardioStages(
      const CardioPlan(
        format: CardioFormat.intervals,
        intervals: CardioIntervalPlan(),
      ),
      19,
    );
    expect(stages.length, 14);
    expect(stages.first.label, 'Aquecimento');
    expect(stages.last.label, 'Desaceleração');
    expect(stages.fold<int>(0, (sum, stage) => sum + stage.seconds), 19 * 60);
    expect(stages.where((stage) => stage.effort).length, 6);
  });
  test('contínuo e etapas zero preservam duração do plano', () {
    expect(cardioStages(const CardioPlan(), 5).single.seconds, 300);
    final stages = cardioStages(
      const CardioPlan(
        format: CardioFormat.intervals,
        intervals: CardioIntervalPlan(
          warmUpMinutes: 0,
          coolDownMinutes: 0,
          cycles: 2,
          effortSeconds: 10,
          recoverySeconds: 0,
        ),
      ),
      1,
    );
    expect(stages.length, 2);
    expect(stages.fold<int>(0, (sum, stage) => sum + stage.seconds), 20);
  });
  testWidgets(
    'inicia pausa avança e pede revisão sem concluir automaticamente',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'),
            (_) async => 1,
          );
      await tester.pumpWidget(
        MaterialApp(
          home: CardioGuidedPlayer(
            stopwatch: _ManualStopwatch(),
            plan: const CardioPlan(
              format: CardioFormat.intervals,
              intervals: CardioIntervalPlan(),
            ),
            minutes: 19,
            modality: CardioModality.treadmill,
          ),
        ),
      );
      expect(find.text('Aquecimento'), findsWidgets);
      await tester.tap(find.text('Iniciar / continuar'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Pausar'), findsOneWidget);
      await tester.tap(find.text('Pausar'));
      await tester.pump();
      await tester.tap(find.text('Pular etapa'));
      await tester.pump();
      expect(find.text('Esforço · ciclo 1 de 6'), findsWidgets);
      expect(find.textContaining('Realizado: 0:00'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('ENCERRAR E REVISAR'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('ENCERRAR E REVISAR'));
      await tester.pumpAndSettle();
      expect(find.text('Encerrar cardio guiado?'), findsOneWidget);
      await tester.tap(find.text('CONTINUAR AQUI'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}

class _ManualStopwatch implements Stopwatch {
  int milliseconds = 0;
  @override
  bool isRunning = false;
  @override
  int get elapsedMilliseconds => milliseconds;
  @override
  int get elapsedMicroseconds => milliseconds * 1000;
  @override
  Duration get elapsed => Duration(milliseconds: milliseconds);
  @override
  int get elapsedTicks => milliseconds;
  @override
  int get frequency => 1000;
  @override
  void start() {
    isRunning = true;
  }

  @override
  void stop() {
    isRunning = false;
  }

  @override
  void reset() {
    milliseconds = 0;
  }
}
