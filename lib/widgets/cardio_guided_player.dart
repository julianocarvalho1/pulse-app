import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../features/workouts/domain/models/cardio_log.dart';

class CardioStage {
  const CardioStage(this.label, this.seconds, this.effort);
  final String label;
  final int seconds;
  final bool effort;
}

List<CardioStage> cardioStages(CardioPlan plan, int minutes) {
  final stages = <CardioStage>[];
  final intervals = plan.intervals;
  if (plan.isInterval && intervals != null) {
    stages.add(CardioStage('Aquecimento', intervals.warmUpMinutes * 60, false));
    for (var i = 1; i <= intervals.cycles; i++) {
      stages.add(
        CardioStage(
          'Esforço · ciclo $i de ${intervals.cycles}',
          intervals.effortSeconds,
          true,
        ),
      );
      stages.add(
        CardioStage(
          'Recuperação · ciclo $i de ${intervals.cycles}',
          intervals.recoverySeconds,
          false,
        ),
      );
    }
    stages.add(
      CardioStage('Desaceleração', intervals.coolDownMinutes * 60, false),
    );
  } else {
    stages.add(CardioStage('Cardio contínuo', minutes * 60, true));
  }
  return stages.where((stage) => stage.seconds > 0).toList();
}

/// Returns elapsed active seconds, never the skipped portion of a stage.
class CardioGuidedPlayer extends StatefulWidget {
  const CardioGuidedPlayer({
    super.key,
    required this.plan,
    required this.minutes,
    required this.modality,
    this.stopwatch,
  });
  final CardioPlan plan;
  final int minutes;
  final CardioModality modality;
  final Stopwatch? stopwatch;
  @override
  State<CardioGuidedPlayer> createState() => _CardioGuidedPlayerState();
}

class _CardioGuidedPlayerState extends State<CardioGuidedPlayer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final List<CardioStage> _stages;
  late final AnimationController _animation;
  final FlutterTts _tts = FlutterTts();
  Timer? _timer;
  late final Stopwatch _watch;
  int _index = 0;
  int _stageMs = 0;
  int _actualMs = 0;
  int _lastMs = 0;
  bool _running = false;
  bool _voice = false;
  bool _talk = false;
  bool _backgroundPaused = false;
  int _speechGeneration = 0;
  bool get _finished => _index >= _stages.length;

  @override
  void initState() {
    super.initState();
    _watch = widget.stopwatch ?? Stopwatch();
    WidgetsBinding.instance.addObserver(this);
    _stages = cardioStages(widget.plan, widget.minutes);
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  Future<void> _say(String text) async {
    if (!_voice || !mounted) return;
    final generation = ++_speechGeneration;
    try {
      await _tts.stop();
      await _tts.setLanguage('pt-BR');
      await _tts.setSpeechRate(0.5);
      if (mounted && _voice && generation == _speechGeneration) {
        await _tts.speak(text);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _voice = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Voz indisponível. Os alertas visuais continuam ativos.',
            ),
          ),
        );
      }
    }
  }

  void _announce() {
    if (_finished) {
      _say('Cardio finalizado. Confira e salve seu registro.');
      return;
    }
    final stage = _stages[_index];
    if (_running) {
      final fast =
          stage.effort && widget.plan.intensity == CardioIntensity.vigorous;
      _animation.duration = Duration(milliseconds: fast ? 650 : 1200);
      _animation.repeat();
    }
    var message =
        '${stage.label}. Siga a intensidade prevista para esta etapa.';
    if (_talk && stage.effort) {
      message += ' ${widget.plan.intensity.talkTestDescription}';
    }
    _say(message);
  }

  void _tick() {
    if (!_running || _finished) return;
    final now = _watch.elapsedMilliseconds;
    var delta = now - _lastMs;
    _lastMs = now;
    final previous = _index;
    while (delta > 0 && !_finished) {
      final step = math.min(delta, _stages[_index].seconds * 1000 - _stageMs);
      _stageMs += step;
      _actualMs += step;
      delta -= step;
      if (_stageMs >= _stages[_index].seconds * 1000) {
        _index++;
        _stageMs = 0;
      }
    }
    if (_finished) {
      _running = false;
      _watch.stop();
      _animation.stop();
    }
    if (mounted) setState(() {});
    if (previous != _index) _announce();
  }

  void _pause() {
    _tick();
    _watch.stop();
    _animation.stop();
    _running = false;
    _speechGeneration++;
    _tts.stop().catchError((_) => 0);
    if (mounted) setState(() {});
  }

  void _toggle() {
    if (_running) {
      _pause();
      return;
    }
    if (_finished) return;
    setState(() {
      _running = true;
      _backgroundPaused = false;
    });
    _lastMs = _watch.elapsedMilliseconds;
    _watch.start();
    _animation.repeat();
    _announce();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _running) {
      _pause();
      _backgroundPaused = true;
    }
  }

  Future<void> _leave() async {
    _pause();
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encerrar cardio guiado?'),
        content: const Text(
          'O tempo realizado será levado ao registro para você revisar e salvar. Etapas puladas não contam como tempo realizado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CONTINUAR AQUI'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('REVISAR REGISTRO'),
          ),
        ],
      ),
    );
    if (save == true && mounted) Navigator.pop(context, _actualMs ~/ 1000);
  }

  @override
  void dispose() {
    _speechGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _watch.stop();
    _animation.dispose();
    _tts.stop().catchError((_) => 0);
    super.dispose();
  }

  String _clock(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final stage = _finished ? null : _stages[_index];
    final total = _stages.fold<int>(0, (sum, item) => sum + item.seconds);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.modality.label),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _leave,
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                stage?.label ?? 'Cardio finalizado',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                stage == null
                    ? '✓'
                    : _clock(((stage.seconds * 1000 - _stageMs) / 1000).ceil()),
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Realizado: ${_clock(_actualMs ~/ 1000)} · Plano: ${_clock(total)}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: _animation,
                builder: (_, child) => CustomPaint(
                  size: const Size(double.infinity, 110),
                  painter: _CardioFigure(
                    _animation.value,
                    color,
                    widget.modality,
                    stage?.effort == true &&
                        widget.plan.intensity == CardioIntensity.vigorous,
                  ),
                ),
              ),
              const Text(
                'Ilustração da atividade; não indica velocidade nem técnica.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_stages.isNotEmpty)
                SizedBox(
                  height: 14,
                  child: Row(
                    children: List.generate(
                      _stages.length,
                      (i) => Expanded(
                        flex: _stages[i].seconds,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: LinearProgressIndicator(
                            minHeight: 14,
                            value: i < _index
                                ? 1
                                : i == _index
                                ? _stageMs / (_stages[i].seconds * 1000)
                                : 0,
                            color: color,
                            backgroundColor: color.withValues(alpha: .15),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: _finished ? null : _toggle,
                    icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                    label: Text(_running ? 'Pausar' : 'Iniciar / continuar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _finished
                        ? null
                        : () {
                            _tick();
                            if (_finished) return;
                            setState(() {
                              _index++;
                              _stageMs = 0;
                            });
                            if (_finished) _pause();
                            _announce();
                          },
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Pular etapa'),
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('Avisos de voz'),
                value: _voice,
                onChanged: (value) {
                  setState(() => _voice = value);
                  if (value) {
                    _say('Avisos de voz ativados.');
                  } else {
                    _tts.stop().catchError((_) => 0);
                  }
                },
              ),
              SwitchListTile(
                title: const Text('Incluir orientação do teste da fala'),
                value: _talk,
                onChanged: (value) => setState(() => _talk = value),
              ),
              Text(
                _backgroundPaused
                    ? 'Pausado ao sair do app. Toque em continuar.'
                    : 'Nesta versão, o guia pausa ao bloquear a tela ou sair do app. Ao sair desta tela, revise e salve o tempo realizado.',
              ),
              const SizedBox(height: 12),
              ExpansionTile(
                title: const Text('Etapas do plano'),
                children: _stages
                    .asMap()
                    .entries
                    .map(
                      (item) => ListTile(
                        selected: item.key == _index,
                        title: Text(item.value.label),
                        trailing: Text(_clock(item.value.seconds)),
                      ),
                    )
                    .toList(),
              ),
              FilledButton(
                onPressed: _leave,
                child: const Text('ENCERRAR E REVISAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardioFigure extends CustomPainter {
  _CardioFigure(this.phase, this.color, this.modality, this.vigorous);
  final double phase;
  final Color color;
  final CardioModality modality;
  final bool vigorous;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final x = size.width / 2;
    final swing = math.sin(phase * 2 * math.pi) * (vigorous ? 22 : 12);
    final cycling =
        modality.name.toLowerCase().contains('bike') ||
        modality.name.toLowerCase().contains('cycl');
    if (modality == CardioModality.other) {
      canvas.drawCircle(Offset(x, 55), 22 + swing.abs() / 2, paint);
      return;
    }
    if (modality == CardioModality.rowing) {
      canvas.drawCircle(Offset(x + swing / 3, 25), 9, paint);
      canvas.drawLine(Offset(x + swing / 3, 36), Offset(x - 10, 66), paint);
      canvas.drawLine(Offset(x - 10, 66), Offset(x + 30, 90), paint);
      canvas.drawLine(
        Offset(x + swing / 3, 42),
        Offset(x + 30 + swing, 52),
        paint,
      );
      canvas.drawLine(Offset(x - 40, 98), Offset(x + 60, 98), paint);
      return;
    }
    canvas.drawCircle(Offset(x, 18), 9, paint);
    canvas.drawLine(Offset(x, 29), Offset(x, 61), paint);
    canvas.drawLine(Offset(x, 38), Offset(x - 20, 51 + swing / 3), paint);
    canvas.drawLine(Offset(x, 38), Offset(x + 20, 51 - swing / 3), paint);
    canvas.drawLine(Offset(x, 61), Offset(x - 13 - swing, 94), paint);
    canvas.drawLine(Offset(x, 61), Offset(x + 13 + swing, 94), paint);
    if (cycling) {
      canvas.drawCircle(Offset(x - 30, 88), 17, paint);
      canvas.drawCircle(Offset(x + 30, 88), 17, paint);
      canvas.drawLine(Offset(x - 30, 88), Offset(x + 30, 88), paint);
    }
    canvas.drawLine(Offset(x - 65, 108), Offset(x + 65, 108), paint);
  }

  @override
  bool shouldRepaint(covariant _CardioFigure oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.color != color ||
      oldDelegate.vigorous != vigorous;
}
