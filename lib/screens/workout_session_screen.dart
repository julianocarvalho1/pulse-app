import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../features/pulse_ai/domain/models/pulse_ai_models.dart';
import '../features/pulse_ai/presentation/screens/pulse_ai_context_screen.dart';
import '../features/settings/domain/pulse_settings.dart';
import '../features/settings/presentation/providers/settings_controller.dart';
import '../core/utils/weight_unit_converter.dart';
import '../features/workouts/domain/models/active_workout_session.dart';
import '../features/workouts/domain/models/advanced_workout_prescription.dart';
import '../features/workouts/domain/services/exercise_alternative_service.dart';
import '../features/workouts/domain/models/cardio_log.dart';
import '../features/workouts/domain/models/exercise_log.dart';
import '../features/workouts/domain/models/workout_set.dart';
import '../features/workouts/presentation/providers/workout_controller.dart';
import '../features/workouts/presentation/state/workout_state.dart';
import '../models/exercise.dart';
import '../features/exercises/presentation/widgets/exercise_media_view.dart';
import '../theme/app_theme.dart';
import '../widgets/active_cardio_session_card.dart';
import 'exercises_screen.dart';

class SessionStateCache {
  static Map<int, List<bool>> setsStatus = {};
  static Map<int, List<String>> weights = {};
  static Map<int, List<String>> reps = {};
  static String? sessionKey;
  static MeasurementSystem? measurementSystem;

  static void clear() {
    setsStatus.clear();
    weights.clear();
    reps.clear();
    sessionKey = null;
    measurementSystem = null;
  }
}

enum _WorkoutExitAction { minimize, discard }

enum _AlternativeUse { sessionOnly, saveToRoutine }

class _FinishDialogResult {
  const _FinishDialogResult(this.notes);

  final String notes;
}

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  const WorkoutSessionScreen({super.key});

  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  final Map<int, List<TextEditingController>> _weightControllers = {};
  final Map<int, List<TextEditingController>> _repsControllers = {};
  final TextEditingController _notesController = TextEditingController();

  Timer? _sessionSaveDebounce;
  bool _notesInitialized = false;
  bool _isSubmittingFinish = false;
  bool _isExitDialogOpen = false;
  bool _isFinishDialogOpen = false;
  bool _isAlternativeFlowOpen = false;
  bool _isRouteClosing = false;

  @override
  void initState() {
    super.initState();
    _notesController.addListener(_scheduleSessionSave);
  }

  @override
  void dispose() {
    _isRouteClosing = true;
    _notesController.removeListener(_scheduleSessionSave);
    for (final controllers in _weightControllers.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    for (final controllers in _repsControllers.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    _sessionSaveDebounce?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  int _getSetsCount(String repsString) {
    final parts = repsString.toLowerCase().split('x');
    if (parts.length > 1) {
      return int.tryParse(parts[0].trim()) ?? 3;
    }
    final match = RegExp(r'\d+').firstMatch(repsString);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 3;
    }
    return 3;
  }

  String _getSmartTarget(String repsString, int setIndex) {
    String target = repsString.toLowerCase();
    if (target.contains('x')) {
      target = target.split('x').last.trim();
    }

    if (target.contains('-')) {
      List<String> parts = target.split('-');
      int setsCount = _getSetsCount(repsString);
      if (parts.length == setsCount && setIndex < parts.length) {
        return parts[setIndex].trim();
      }
    }
    return target;
  }

  Map<String, dynamic> _getDetailedInfo(String id) {
    List<String> steps = [];
    String secondary = '';

    if (id.startsWith('p')) {
      secondary = 'Tríceps Braquial e Deltóide Anterior (Ombro)';
      if (id == 'p1' || id == 'p3' || id == 'p6') {
        steps = [
          'Plante os pés firmemente no chão e mantenha a curvatura natural da lombar.',
          'Retraia as escápulas (junte os ossos das costas) para estufar o peito e proteger os ombros.',
          'Desça a barra controladamente até encostar levemente no peito.',
          'Empurre de forma explosiva, sem esticar (travar) os cotovelos 100% no topo.',
        ];
      } else if (id == 'p2' || id == 'p4') {
        steps = [
          'Use os joelhos para chutar os halteres para a posição inicial.',
          'Mantenha os cotovelos em um ângulo de 45 a 60 graus em relação ao tronco (não abra totalmente em cruz).',
          'Desça até sentir um alongamento profundo no peitoral.',
          'Suba aproximando os halteres, focando em "esmagar" o peito no topo.',
        ];
      } else if (id == 'p7' || id == 'p8' || id == 'p9') {
        secondary = 'Deltóide Anterior (Isolamento de Peitoral)';
        steps = [
          'Mantenha os cotovelos com uma leve flexão e "travados" nessa posição durante todo o movimento.',
          'Abra os braços controlando o peso, focando em alongar as fibras do peitoral.',
          'Feche os braços imaginando que está abraçando um tronco de árvore grosso.',
          'Faça uma pausa de 1 segundo na contração máxima (mãos juntas).',
        ];
      } else if (id == 'p10' || id == 'p11') {
        steps = [
          'Incline o tronco levemente para frente mantendo o core contraído.',
          'Puxe os cabos com os cotovelos levemente flexionados.',
          'Cruze levemente as mãos no final do movimento para contração máxima.',
          'Retorne controlando o peso da polia sem deixar que ela puxe seu corpo.',
        ];
      } else {
        steps = [
          'Ajuste o banco ou máquina para alinhar as manoplas com o meio do peito.',
          'Empurre o peso estufando o peito.',
          'Volte controladamente resistindo à carga.',
        ];
      }
    } else if (id.startsWith('c')) {
      secondary = 'Bíceps, Braquial e Músculos do Antebraço';
      if (id == 'c1' || id == 'c2') {
        steps = [
          'Ajuste o rolo de apoio para travar bem as coxas e evitar que o corpo suba.',
          'Pegue na barra, estufe o peito e incline o tronco ligeiramente para trás (cerca de 15 graus).',
          'Inicie o movimento puxando os ombros para baixo e depois traga a barra na direção do peitoral superior.',
          'Suba controlando o peso até alongar as dorsais completamente, sem soltar os ombros no topo.',
        ];
      } else if (id == 'c3' || id == 'c4' || id == 'c7') {
        secondary = 'Lombar (Eretores da Espinha), Bíceps e Trapézio';
        steps = [
          'Mantenha a coluna perfeitamente neutra e o abdômen rígido.',
          'Incline o tronco à frente (entre 45 e 90 graus).',
          'Puxe o peso em direção ao umbigo/quadril, focando em "dar uma cotovelada para trás".',
          'Retorne esticando os braços e sentindo as escápulas se abrirem.',
        ];
      } else if (id == 'c5' || id == 'c6') {
        steps = [
          'Sente-se com postura ereta e pés apoiados.',
          'Puxe a carga retraindo as costas (juntando as escápulas).',
          'Mantenha os cotovelos próximos ao corpo se quiser focar na grande dorsal.',
          'Estique os braços resistindo ao peso da máquina.',
        ];
      } else if (id == 'c9' || id == 'c10') {
        secondary = 'Tríceps (Cabeça Longa) e Ombro Posterior';
        steps = [
          'Mantenha os braços esticados (com mínima flexão no cotovelo).',
          'Puxe a barra/corda até a linha do quadril focando apenas nas costas.',
          'Mantenha o tronco estático; não use o peso do corpo para puxar.',
        ];
      } else {
        steps = [
          'Inicie o movimento contraindo as costas antes de dobrar os braços.',
          'Puxe controladamente.',
          'Alongue na volta.',
        ];
      }
    } else if (id.startsWith('o') || id.startsWith('t')) {
      secondary = 'Tríceps (nos desenvolvimentos) ou Trapézio Superior';
      if (id == 'o1' || id == 'o2' || id == 'o3') {
        steps = [
          'Sente-se com a coluna bem apoiada no banco.',
          'Mantenha os cotovelos levemente à frente da linha dos ombros (plano escapular).',
          'Empurre o peso acima da cabeça até quase esticar os braços.',
          'Desça controladamente até as mãos chegarem na altura do queixo/orelhas.',
        ];
      } else if (id == 'o4' || id == 'o5') {
        secondary = 'Foco em Deltóide Medial (Lateral do Ombro)';
        steps = [
          'Mantenha os cotovelos com uma leve flexão.',
          'Incline o corpo 5 graus para frente.',
          'Eleve os braços focando em liderar o movimento pelo cotovelo (e não pelas mãos).',
          'Suba até a altura dos ombros e desça freando a carga.',
        ];
      } else if (id == 'o8') {
        secondary = 'Rombóides e Trapézio Médio';
        steps = [
          'Incline o tronco para frente até quase 90 graus.',
          'Com os braços semi-esticados, abra os halteres lateralmente e para trás.',
          'Concentre-se em esmagar a parte de trás do ombro, sem usar impulso.',
        ];
      } else if (id.startsWith('t')) {
        secondary = 'Músculos do Pescoço';
        steps = [
          'Segure a carga com os braços relaxados.',
          'Eleve os ombros em direção às orelhas o mais alto possível.',
          'Segure a contração por 1 segundo no topo.',
          'Desça lentamente até alongar o trapézio. Não faça movimentos rotacionais.',
        ];
      } else {
        steps = [
          'Mantenha a postura ereta.',
          'Levante a carga com controle.',
          'Não utilize impulso das costas ou pernas.',
        ];
      }
    } else if (id.startsWith('b')) {
      secondary = 'Músculos Braquiorradiais e Estabilizadores do Punho';
      if (id == 'b1' || id == 'b2' || id == 'b6') {
        steps = [
          'Mantenha os cotovelos absolutamente colados às costelas. Eles não devem ir para frente ou para trás.',
          'Contraia o bíceps subindo a carga até a altura do peito superior.',
          'Evite balançar o tronco (roubar).',
          'Desça a carga até estender o braço (cerca de 95% de extensão).',
        ];
      } else if (id == 'b4' || id == 'b5' || id == 'b9') {
        steps = [
          'Apoie firmemente a axila/tríceps no banco ou coxa.',
          'Foque totalmente na contração, pois o ombro está estabilizado.',
          'Não estique o cotovelo 100% na descida no banco Scott para evitar lesões.',
          'Faça o movimento cadenciado (2 segundos para subir, 3 para descer).',
        ];
      } else if (id == 'b3' || id == 'b7') {
        secondary = 'Braquial Anterior (Gera volume no braço)';
        steps = [
          'Mantenha a pegada neutra (polegares para cima) ou invertida.',
          'Suba a carga mantendo os pulsos travados e retos.',
          'Desça controladamente focando no antebraço.',
        ];
      } else {
        steps = [
          'Trave os cotovelos.',
          'Flexione o braço contraindo o bíceps.',
          'Retorne à posição inicial.',
        ];
      }
    } else if (id.startsWith('tr')) {
      secondary = 'Ombros (como estabilizadores) e Core';
      if (id == 'tr1' || id == 'tr2' || id == 'tr10') {
        steps = [
          'Incline o corpo ligeiramente à frente e flexione um pouco os joelhos.',
          'Trave os cotovelos na linha da cintura.',
          'Empurre o cabo para baixo usando apenas a força do tríceps.',
          'Se usar corda, puxe as pontas para fora no final do movimento para contração extrema.',
        ];
      } else if (id == 'tr3' || id == 'tr4' || id == 'tr5' || id == 'tr6') {
        steps = [
          'Mantenha os cotovelos apontados para o teto ou para frente, o mais fechados possível.',
          'Desça a carga na direção da testa ou nuca.',
          'Estique os braços esmagando o tríceps.',
          'Esse ângulo trabalha intensamente a cabeça longa do tríceps.',
        ];
      } else {
        steps = [
          'Mantenha os braços próximos ao corpo.',
          'Estenda os cotovelos empurrando o peso.',
          'Retorne controlando a fase excêntrica.',
        ];
      }
    } else if (id.startsWith('pe')) {
      if (id == 'pe1' || id == 'pe2' || id == 'pe3') {
        secondary = 'Glúteos, Isquiotibiais, Lombar e Core';
        steps = [
          'Posicione os pés na largura dos ombros com as pontas levemente voltadas para fora.',
          'Mantenha o peito estufado, olhar à frente e respire fundo enrijecendo o abdômen.',
          'Desça como se fosse sentar em uma cadeira invisível, quebrando a paralela se a mobilidade permitir.',
          'Suba fazendo força no calcanhar e na borda externa do pé, sem deixar os joelhos entrarem (valgo).',
        ];
      } else if (id == 'pe4' || id == 'pe5') {
        secondary = 'Glúteos e Isquiotibiais';
        steps = [
          'Apoie perfeitamente a lombar no banco. Se o quadril descolar na descida, a carga ou a descida estão incorretas.',
          'Coloque os pés na plataforma na largura dos ombros.',
          'Desça a máquina até os joelhos ficarem próximos a 90 graus ou tocarem o peito.',
          'Empurre, mas NÃO trave (não estique até travar a articulação) os joelhos no topo para manter a tensão no músculo.',
        ];
      } else if (id == 'pe6' || id == 'pe13' || id == 'pe14') {
        secondary = 'Músculos Estabilizadores da Pelve';
        steps = [
          'Sente-se e ajuste a máquina para que o eixo de rotação fique alinhado com a articulação (joelho ou quadril).',
          'Trave bem as costas no encosto.',
          'Execute o movimento com explosão na ida e freie lentamente na volta.',
          'Evite que as placas de peso batam entre as repetições.',
        ];
      } else if (id == 'pe15') {
        secondary = 'Glúteos, Isquiotibiais e Estabilizadores do Core';
        steps = [
          'Dê um passo largo à frente mantendo o tronco ereto e o olhar para frente.',
          'Desça verticalmente até o joelho de trás quase tocar o chão.',
          'O joelho da frente deve ficar alinhado, sem passar excessivamente da ponta do pé.',
          'Empurre o chão com o calcanhar da perna da frente para retornar (afundo) ou dar o próximo passo (passada).',
        ];
      } else if (id == 'pe7' ||
          id == 'pe8' ||
          id == 'pe9' ||
          id == 'pe10' ||
          id == 'pe11' ||
          id == 'pe19') {
        secondary = 'Lombar, Glúteos e Panturrilhas';
        steps = [
          'No Stiff/Terra: Mantenha as pernas semi-esticadas e desça empurrando o quadril para trás, coluna sempre reta.',
          'Nas Flexoras: Ajuste o rolo na linha do calcanhar.',
          'Puxe/Suba o peso esmagando a parte de trás da coxa.',
          'Desça focando em alongar os isquiotibiais.',
        ];
      } else if (id == 'pe12') {
        secondary = 'Isquiotibiais e Lombar';
        steps = [
          'Apoie as escápulas no banco e posicione os pés de forma que a canela fique vertical no topo do movimento.',
          'Coloque a barra na dobra do quadril.',
          'Empurre o chão com os calcanhares e eleve o quadril até alinhar corpo, joelho e ombros.',
          'Contraia os glúteos com força máxima por 1 segundo no topo.',
        ];
      } else if (id.startsWith('pe16') ||
          id.startsWith('pe17') ||
          id.startsWith('pe18')) {
        secondary = 'Músculos dos Pés e Tornozelos';
        steps = [
          'Apoie a ponta dos pés (metatarsos) no degrau/plataforma.',
          'Desça o calcanhar o máximo possível, alongando a panturrilha por 2 segundos.',
          'Suba até ficar na ponta dos pés, contraindo forte no topo por 1 segundo.',
          'Panturrilhas precisam de alongamento e contração completa para crescer.',
        ];
      } else {
        steps = [
          'Execute o movimento respeitando o limite da sua mobilidade articular.',
          'Mantenha a postura.',
          'Controle a fase de descida.',
        ];
      }
    } else if (id.startsWith('ab')) {
      secondary = 'Músculos do Core e Transverso Abdominal';
      if (id == 'ab5') {
        steps = [
          'Apoie antebraços e pontas dos pés no chão.',
          'Mantenha o corpo em uma linha reta perfeita: não levante o quadril nem deixe a lombar afundar.',
          'Puxe o umbigo para dentro e respire de forma curta.',
          'Contraia glúteos e abdômen intensamente durante todo o tempo.',
        ];
      } else {
        steps = [
          'O segredo do abdômen não é o pescoço: foque em aproximar a linha das costelas da linha do quadril.',
          'Mantenha a lombar travada no chão ou banco.',
          'Suba soltando todo o ar dos pulmões (para maximizar a contração).',
          'Desça inspirando e controlando a descida, sem relaxar o músculo no chão.',
        ];
      }
    } else {
      steps = [
        'Ajuste o equipamento.',
        'Controle o movimento.',
        'Mantenha a respiração constante.',
      ];
      secondary = 'Geral';
    }

    return {'steps': steps, 'secondary': secondary};
  }

  void _initializeSets(MeasurementSystem measurementSystem) {
    final workoutState = ref.read(workoutControllerProvider);
    final provider = ref.read(workoutControllerProvider.notifier);
    final exercises = workoutState.currentWorkoutExercises;
    final restoredSession = provider.activeSession;
    final currentSessionKey =
        restoredSession?.startedAt.toIso8601String() ??
        workoutState.activeRoutineName;

    if (SessionStateCache.sessionKey != currentSessionKey) {
      SessionStateCache.clear();
      SessionStateCache.sessionKey = currentSessionKey;
      SessionStateCache.measurementSystem = measurementSystem;
    } else if (SessionStateCache.measurementSystem != null &&
        SessionStateCache.measurementSystem != measurementSystem) {
      final previousSystem = SessionStateCache.measurementSystem!;
      for (final entry in SessionStateCache.weights.entries) {
        final exerciseIndex = entry.key;
        final values = entry.value;
        for (var setIndex = 0; setIndex < values.length; setIndex++) {
          final converted = WeightUnitConverter.convertDisplayText(
            values[setIndex],
            from: previousSystem,
            to: measurementSystem,
          );
          values[setIndex] = converted;
          final controllers = _weightControllers[exerciseIndex];
          if (controllers != null && setIndex < controllers.length) {
            controllers[setIndex].text = converted;
          }
        }
      }
      SessionStateCache.measurementSystem = measurementSystem;
    } else {
      SessionStateCache.measurementSystem ??= measurementSystem;
    }

    if (!_notesInitialized) {
      _notesInitialized = true;
      _notesController.text = restoredSession?.notes ?? '';
    }

    for (int i = 0; i < exercises.length; i++) {
      final restoredExercise =
          restoredSession != null &&
              i < restoredSession.exercises.length &&
              restoredSession.exercises[i].exercise.id == exercises[i].id
          ? restoredSession.exercises[i]
          : null;

      if (!SessionStateCache.setsStatus.containsKey(i)) {
        final setsCount =
            restoredExercise?.sets.length ?? _getSetsCount(exercises[i].reps);

        SessionStateCache.setsStatus[i] = List<bool>.generate(
          setsCount,
          (setIndex) => restoredExercise?.sets[setIndex].isCompleted ?? false,
        );

        SessionStateCache.weights[i] = List<String>.generate(
          setsCount,
          (setIndex) => WeightUnitConverter.displayTextFromKilogramsText(
            restoredExercise?.sets[setIndex].weightText ?? '',
            measurementSystem,
          ),
        );

        SessionStateCache.reps[i] = List<String>.generate(
          setsCount,
          (setIndex) => restoredExercise?.sets[setIndex].repsText ?? '',
        );
      }

      if (!_weightControllers.containsKey(i)) {
        _weightControllers[i] = [];
        _repsControllers[i] = [];

        for (int j = 0; j < SessionStateCache.setsStatus[i]!.length; j++) {
          final weightController = TextEditingController(
            text: SessionStateCache.weights[i]![j],
          );

          weightController.addListener(() {
            SessionStateCache.weights[i]![j] = weightController.text;
            _scheduleSessionSave();
          });

          _weightControllers[i]!.add(weightController);

          final repsController = TextEditingController(
            text: SessionStateCache.reps[i]![j],
          );

          repsController.addListener(() {
            SessionStateCache.reps[i]![j] = repsController.text;
            _scheduleSessionSave();
          });

          _repsControllers[i]!.add(repsController);
        }
      }
    }
  }

  void _scheduleSessionSave() {
    if (!mounted) {
      return;
    }

    _sessionSaveDebounce?.cancel();
    _sessionSaveDebounce = Timer(
      const Duration(milliseconds: 350),
      _persistSessionNow,
    );
  }

  void _persistSessionNow() {
    if (!mounted) {
      return;
    }

    final measurementSystem =
        ref.read(settingsControllerProvider).asData?.value.measurementSystem ??
        MeasurementSystem.metric;
    final storedWeights = SessionStateCache.weights.map(
      (exerciseIndex, values) => MapEntry(
        exerciseIndex,
        values
            .map(
              (value) => WeightUnitConverter.kilogramsTextFromDisplayText(
                value,
                measurementSystem,
              ),
            )
            .toList(growable: false),
      ),
    );

    ref
        .read(workoutControllerProvider.notifier)
        .saveActiveSessionProgress(
          setsStatus: SessionStateCache.setsStatus,
          weights: storedWeights,
          reps: SessionStateCache.reps,
          notes: _notesController.text,
        );
  }

  String _formatTime(int totalSeconds) {
    int m = totalSeconds ~/ 60;
    int s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildExerciseInfoMetric(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 5),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  Widget _advancedPrescriptionChip(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: primary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onTap != null) ...<Widget>[
            const SizedBox(width: 3),
            Icon(Icons.chevron_right_rounded, size: 13, color: primary),
          ],
        ],
      ),
    );
    if (onTap == null) {
      return content;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: content,
    );
  }

  Future<void> _chooseExerciseAlternative({
    required WorkoutController provider,
    required WorkoutState workoutState,
    required int exerciseIndex,
    required Exercise current,
  }) async {
    final alternatives = current.advancedPrescription.alternatives;
    if (alternatives.isEmpty || _isAlternativeFlowOpen) {
      return;
    }

    _isAlternativeFlowOpen = true;
    try {
      final selected = await showModalBottomSheet<ExerciseAlternative>(
        context: context,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.paddingOf(sheetContext).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Trocar exercício',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'A prescrição, as cargas digitadas e as séries concluídas serão preservadas.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              for (final alternative in alternatives)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: AppColors.border),
                    ),
                    leading: Icon(
                      Icons.swap_horiz_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      alternative.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: alternative.muscle.trim().isEmpty
                        ? null
                        : Text(alternative.muscle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.pop(sheetContext, alternative),
                  ),
                ),
            ],
          ),
        ),
      );

      await _waitForTransientUiToSettle();
      if (selected == null || !mounted || _isRouteClosing) {
        return;
      }

      final matchingRoutines = workoutState.myRoutines
          .where((routine) => routine.name == workoutState.activeRoutineName)
          .toList(growable: false);
      final routine = matchingRoutines.length == 1
          ? matchingRoutines.single
          : null;
      final canSaveToRoutine =
          routine != null &&
          (exerciseIndex < routine.exercises.length ||
              routine.exercises.any((exercise) => exercise.id == current.id));

      final use = await showDialog<_AlternativeUse>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Usar ${selected.name}?'),
          content: Text(
            canSaveToRoutine
                ? 'Escolha se a troca vale somente para este treino ou também para a ficha.'
                : 'Esta troca ficará somente neste treino. Não foi possível identificar uma única ficha para atualizar.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, _AlternativeUse.sessionOnly),
              child: const Text('SÓ NESTE TREINO'),
            ),
            if (canSaveToRoutine)
              FilledButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, _AlternativeUse.saveToRoutine),
                child: const Text('SALVAR NA FICHA'),
              ),
          ],
        ),
      );

      await _waitForTransientUiToSettle();
      if (use == null || !mounted || _isRouteClosing) {
        return;
      }

      _persistSessionNow();
      final replacement = const ExerciseAlternativeService().buildReplacement(
        current: current,
        selected: selected,
        catalog: provider.allExercises,
      );
      provider.replaceExerciseInActiveWorkout(exerciseIndex, replacement);

      if (use == _AlternativeUse.saveToRoutine && routine != null) {
        final routineExercises = List<Exercise>.from(routine.exercises);
        var routineExerciseIndex = exerciseIndex;
        if (routineExerciseIndex >= routineExercises.length ||
            routineExercises[routineExerciseIndex].id != current.id) {
          routineExerciseIndex = routineExercises.indexWhere(
            (exercise) => exercise.id == current.id,
          );
        }
        if (routineExerciseIndex >= 0) {
          routineExercises[routineExerciseIndex] = replacement;
          provider.updateRoutine(
            routine.id,
            routine.name,
            routine.focus,
            routine.groupName,
            routineExercises,
            newCardio: routine.cardio,
          );
        }
      }

      if (!mounted || _isRouteClosing) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            use == _AlternativeUse.saveToRoutine
                ? '${replacement.name} foi salvo nesta ficha.'
                : '${replacement.name} será usado somente neste treino.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      _isAlternativeFlowOpen = false;
    }
  }

  void _showMusicSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escolha seu aplicativo de áudio 🎧',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.play_circle_filled,
                color: Colors.redAccent,
                size: 28,
              ),
              title: Text(
                'YouTube Music',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openMusicApp(
                  'vnd.youtube.music://',
                  'https://music.youtube.com',
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.music_note,
                color: Colors.green,
                size: 28,
              ),
              title: Text(
                'Spotify',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openMusicApp('spotify://', 'https://open.spotify.com');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.graphic_eq,
                color: Colors.cyanAccent,
                size: 28,
              ),
              title: Text(
                'Deezer',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openMusicApp('deezer://', 'https://www.deezer.com');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.apple,
                color: Colors.pinkAccent,
                size: 28,
              ),
              title: Text(
                'Apple Music',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openMusicApp('music://', 'https://music.apple.com');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.queue_music,
                color: Colors.orangeAccent,
                size: 28,
              ),
              title: Text(
                'Amazon Music',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openMusicApp('amznmp3://', 'https://music.amazon.com');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _openMusicApp(String appUrl, String webUrl) async {
    try {
      final Uri appUri = Uri.parse(appUrl);
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri);
      } else {
        await launchUrl(
          Uri.parse(webUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao abrir o reprodutor de música.'),
          ),
        );
      }
    }
  }

  Future<void> _waitForTransientUiToSettle() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;

    if (mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 90));
    }
  }

  Future<void> _confirmExit(WorkoutController provider) async {
    if (!mounted ||
        _isRouteClosing ||
        _isSubmittingFinish ||
        _isExitDialogOpen ||
        _isFinishDialogOpen) {
      return;
    }

    _isExitDialogOpen = true;
    await _waitForTransientUiToSettle();

    if (!mounted) {
      return;
    }

    final action = await showDialog<_WorkoutExitAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        title: Text(
          'Pausar ou Encerrar?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Deseja minimizar para continuar depois ou encerrar definitivamente e descartar o progresso de hoje?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_WorkoutExitAction.minimize),
            child: Text(
              'Minimizar',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.primary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () =>
                Navigator.of(dialogContext).pop(_WorkoutExitAction.discard),
            child: const Text(
              'Descartar Treino',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (mounted) {
      _isExitDialogOpen = false;
    }

    if (!mounted || action == null) {
      return;
    }

    // O diálogo e o teclado precisam sair completamente antes de alterar o
    // provider ou remover a tela que contém os campos da sessão.
    await _waitForTransientUiToSettle();

    if (!mounted || _isRouteClosing) {
      return;
    }

    _isRouteClosing = true;
    _sessionSaveDebounce?.cancel();

    if (action == _WorkoutExitAction.minimize) {
      _persistSessionNow();
    } else {
      await provider.cancelWorkout();
      SessionStateCache.clear();
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  bool _allSetsCompleted() {
    if (SessionStateCache.setsStatus.isEmpty) {
      return false;
    }

    for (final sets in SessionStateCache.setsStatus.values) {
      if (sets.contains(false)) {
        return false;
      }
    }

    return true;
  }

  int _completedSetsCount() {
    return SessionStateCache.setsStatus.values.fold<int>(
      0,
      (total, sets) => total + sets.where((isCompleted) => isCompleted).length,
    );
  }

  List<ExerciseLog> _buildWorkoutLogs(WorkoutController provider) {
    final workoutLogs = <ExerciseLog>[];
    final exercises = provider.currentWorkoutExercises;
    final measurementSystem =
        ref.read(settingsControllerProvider).asData?.value.measurementSystem ??
        MeasurementSystem.metric;

    for (
      var exerciseIndex = 0;
      exerciseIndex < exercises.length;
      exerciseIndex++
    ) {
      final setsCompleted = <ExerciseSet>[];
      final statuses =
          SessionStateCache.setsStatus[exerciseIndex] ?? const <bool>[];

      for (var setIndex = 0; setIndex < statuses.length; setIndex++) {
        if (!statuses[setIndex]) {
          continue;
        }

        final weight =
            WeightUnitConverter.parseDisplayedWeightToKilograms(
              _weightControllers[exerciseIndex]![setIndex].text,
              measurementSystem,
            ) ??
            0;
        var reps =
            int.tryParse(_repsControllers[exerciseIndex]![setIndex].text) ?? 0;

        if (reps == 0) {
          final target = _getSmartTarget(
            exercises[exerciseIndex].reps,
            setIndex,
          );
          final match = RegExp(r'\d+').firstMatch(target);
          reps = match == null ? 0 : int.parse(match.group(0)!);
        }

        setsCompleted.add(ExerciseSet(reps: reps, weight: weight));
      }

      if (setsCompleted.isNotEmpty) {
        workoutLogs.add(
          ExerciseLog(
            exerciseId: exercises[exerciseIndex].id,
            exerciseName: exercises[exerciseIndex].name,
            sets: setsCompleted,
          ),
        );
      }
    }

    return workoutLogs;
  }

  List<CardioLog> _buildCardioLogs(WorkoutController provider) {
    final entries =
        provider.activeSession?.cardio ?? const <ActiveCardioEntry>[];
    return entries
        .where((entry) => entry.isCompleted && entry.actualDurationMinutes > 0)
        .map((entry) => entry.toLog())
        .toList(growable: false);
  }

  int _completedCardioCount(WorkoutController provider) {
    return provider.activeSession?.cardio
            .where((entry) => entry.isCompleted)
            .length ??
        0;
  }

  bool _allCardioCompleted(WorkoutController provider) {
    final entries =
        provider.activeSession?.cardio ?? const <ActiveCardioEntry>[];
    return entries.isEmpty || entries.every((entry) => entry.isCompleted);
  }

  Future<void> _showNoCompletedSetsDialog(WorkoutController provider) async {
    if (!mounted || _isFinishDialogOpen || _isRouteClosing) {
      return;
    }

    _isFinishDialogOpen = true;
    await _waitForTransientUiToSettle();

    if (!mounted) {
      return;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        title: Text(
          'Nenhuma atividade concluída',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Para salvar no histórico, conclua pelo menos uma série ou uma atividade de cardio. Você pode continuar o treino ou descartá-lo.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Continuar treino',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Descartar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (mounted) {
      _isFinishDialogOpen = false;
    }

    if (!mounted || shouldDiscard != true) {
      return;
    }

    await _waitForTransientUiToSettle();

    if (!mounted || _isRouteClosing) {
      return;
    }

    _isRouteClosing = true;
    _sessionSaveDebounce?.cancel();
    await provider.cancelWorkout();
    SessionStateCache.clear();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _finishAndClose({
    required WorkoutController provider,
    required List<ExerciseLog> logs,
    required List<CardioLog> cardio,
    required bool isIncomplete,
    required String notes,
  }) async {
    if (_isSubmittingFinish || _isRouteClosing || !mounted) {
      return;
    }

    _isSubmittingFinish = true;
    _sessionSaveDebounce?.cancel();
    final duration = _formatTime(ref.read(workoutDurationProvider));
    final successColor = Theme.of(context).colorScheme.primary;
    final messenger = ScaffoldMessenger.of(context);

    final saved = await provider.finishWorkout(
      duration,
      isIncomplete: isIncomplete,
      logs: logs,
      cardio: cardio,
      notes: notes,
    );

    if (!mounted) {
      return;
    }

    if (!saved) {
      _isSubmittingFinish = false;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar o treino. Tente novamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _isRouteClosing = true;
    SessionStateCache.clear();
    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isIncomplete
              ? 'Treino salvo como incompleto.'
              : 'Treino concluído e salvo com sucesso!',
        ),
        backgroundColor: isIncomplete ? Colors.orange : successColor,
      ),
    );
  }

  Future<void> _confirmFinish(WorkoutController provider) async {
    if (!mounted ||
        _isSubmittingFinish ||
        _isRouteClosing ||
        _isFinishDialogOpen ||
        _isExitDialogOpen) {
      return;
    }

    _persistSessionNow();

    final workoutLogs = _buildWorkoutLogs(provider);
    final cardioLogs = _buildCardioLogs(provider);
    final completedSets = _completedSetsCount();
    final completedCardio = _completedCardioCount(provider);
    final activeSession = provider.activeSession;
    final hasStrength = activeSession?.exercises.isNotEmpty ?? false;
    final hasCardio = activeSession?.cardio.isNotEmpty ?? false;
    final allStrengthCompleted = !hasStrength || _allSetsCompleted();
    final allCardioCompleted = _allCardioCompleted(provider);

    if (workoutLogs.isEmpty && cardioLogs.isEmpty) {
      await _showNoCompletedSetsDialog(provider);
      return;
    }

    final isIncomplete = !allStrengthCompleted || !allCardioCompleted;
    var draftNotes = _notesController.text;

    _isFinishDialogOpen = true;
    await _waitForTransientUiToSettle();

    if (!mounted) {
      return;
    }

    final result = await showDialog<_FinishDialogResult>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        title: Text(
          isIncomplete ? 'Salvar treino incompleto?' : 'Finalizar treino?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isIncomplete) ...[
                Text(
                  [
                    if (hasStrength) '$completedSets séries concluídas',
                    if (hasCardio)
                      '$completedCardio cardio concluído${completedCardio == 1 ? '' : 's'}',
                  ].join(' • '),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'As atividades pendentes não serão registradas e o treino ficará marcado como incompleto.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ] else
                Text(
                  hasCardio
                      ? 'Todas as etapas planejadas foram concluídas. Confirme para salvar a sessão no histórico.'
                      : 'Todas as séries foram concluídas. Confirme para salvar a sessão no histórico.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: draftNotes,
                onChanged: (value) => draftNotes = value,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: isIncomplete
                      ? 'Anotação sobre o treino (opcional)'
                      : 'Como foi o treino? (opcional)',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: Theme.of(dialogContext).scaffoldBackgroundColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(dialogContext).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              isIncomplete ? 'Continuar treino' : 'Cancelar',
              style: TextStyle(
                color: isIncomplete
                    ? Theme.of(dialogContext).colorScheme.primary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isIncomplete
                  ? Colors.orange
                  : Theme.of(dialogContext).colorScheme.primary,
              foregroundColor: isIncomplete
                  ? Colors.black
                  : AppColors.onPrimary,
            ),
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(_FinishDialogResult(draftNotes)),
            child: Text(
              isIncomplete ? 'Salvar como incompleto' : 'Salvar treino',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (mounted) {
      _isFinishDialogOpen = false;
    }

    if (!mounted || result == null) {
      return;
    }

    // O provider só é encerrado depois que a rota do diálogo deixou a árvore.
    await _waitForTransientUiToSettle();

    if (!mounted || _isRouteClosing) {
      return;
    }

    await _finishAndClose(
      provider: provider,
      logs: workoutLogs,
      cardio: cardioLogs,
      isIncomplete: isIncomplete,
      notes: result.notes,
    );
  }

  Widget _buildInputForm(
    BuildContext context,
    TextEditingController controller,
    String hint, {
    bool isReps = false,
  }) {
    return SizedBox(
      height: 30,
      child: TextField(
        controller: controller,
        keyboardType: isReps
            ? TextInputType.number
            : const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  void _handleSetChanged({
    required WorkoutController provider,
    required List<Exercise> exercises,
    required int exerciseIndex,
    required int setIndex,
    required bool isCompleted,
  }) {
    setState(() {
      SessionStateCache.setsStatus[exerciseIndex]![setIndex] = isCompleted;

      if (!isCompleted) {
        return;
      }

      final repsController = _repsControllers[exerciseIndex]![setIndex];
      if (repsController.text.trim().isEmpty) {
        final sessionSets = provider.activeSession?.exercises;
        final prescribedTarget =
            sessionSets != null &&
                exerciseIndex < sessionSets.length &&
                setIndex < sessionSets[exerciseIndex].sets.length
            ? sessionSets[exerciseIndex].sets[setIndex].targetText
            : '';
        final smartTarget = prescribedTarget.trim().isNotEmpty
            ? prescribedTarget
            : _getSmartTarget(exercises[exerciseIndex].reps, setIndex);
        final match = RegExp(r'\d+').firstMatch(smartTarget);
        if (match != null) {
          repsController.text = match.group(0)!;
        }
      }

      if (setIndex > 0) {
        final weightController = _weightControllers[exerciseIndex]![setIndex];
        final previousWeight = _weightControllers[exerciseIndex]![setIndex - 1]
            .text
            .trim();
        if (weightController.text.trim().isEmpty && previousWeight.isNotEmpty) {
          weightController.text = previousWeight;
        }
      }
    });

    _sessionSaveDebounce?.cancel();
    _persistSessionNow();

    if (!isCompleted) {
      return;
    }

    FocusScope.of(context).unfocus();
    final outcome = provider.startRestAfterSet(
      exerciseIndex,
      setIndex: setIndex,
    );

    if (outcome == RestStartOutcome.skippedForSuperset &&
        exerciseIndex + 1 < exercises.length) {
      final nextExerciseName = exercises[exerciseIndex + 1].name;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Bi-set: siga direto para $nextExerciseName, sem descanso.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
    } else if (outcome == RestStartOutcome.waitingForSupersetPair) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Conclua a mesma série do primeiro exercício do bi-set antes do descanso.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutControllerProvider);
    final settings =
        ref.watch(settingsControllerProvider).asData?.value ??
        PulseSettings.defaults();
    final measurementSystem = settings.measurementSystem;
    final weightUnit = WeightUnitConverter.unitLabel(measurementSystem);
    final sessionProgress = ref.watch(workoutSessionProgressProvider);
    final provider = ref.read(workoutControllerProvider.notifier);
    final exercises = workoutState.currentWorkoutExercises;
    final activeCardio =
        workoutState.activeSession?.cardio ?? const <ActiveCardioEntry>[];
    final completedCardio = activeCardio
        .where((entry) => entry.isCompleted)
        .length;
    final totalSteps = sessionProgress.totalSets + activeCardio.length;
    final completedSteps = sessionProgress.completedSets + completedCardio;
    final combinedFraction = totalSteps == 0
        ? 0.0
        : (completedSteps / totalSteps).clamp(0, 1).toDouble();
    final combinedPercentage = (combinedFraction * 100).round();
    _initializeSets(measurementSystem);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        unawaited(_confirmExit(provider));
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => unawaited(_confirmExit(provider)),
          ),
          title: Text(
            workoutState.activeRoutineName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          actions: [
            Consumer(
              builder: (context, ref, child) {
                final duration = ref.watch(workoutDurationProvider);

                return Center(
                  child: Container(
                    margin: const EdgeInsets.only(right: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 15,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(duration),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Abrir música',
              icon: Icon(
                Icons.music_note,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: _showMusicSelector,
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(0, 7, 0, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              activeCardio.isEmpty
                                  ? '${sessionProgress.completedSets}/${sessionProgress.totalSets} séries'
                                  : '$completedSteps/$totalSteps etapas',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${activeCardio.isEmpty ? sessionProgress.percentage : combinedPercentage}%',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: activeCardio.isEmpty
                                ? sessionProgress.fraction
                                : combinedFraction,
                            minHeight: 6,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: exercises.isEmpty && activeCardio.isEmpty
                  ? Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          side: BorderSide(color: AppColors.border),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ExercisesScreen(isSelecting: true),
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar Exercício'),
                      ),
                    )
                  : ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      key: ValueKey<String>(
                        'workout-list-${workoutState.activeSession?.startedAt.millisecondsSinceEpoch ?? workoutState.activeRoutineName}',
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: exercises.length + activeCardio.length,
                      itemBuilder: (context, index) {
                        if (index >= exercises.length) {
                          final cardioIndex = index - exercises.length;
                          final entry = activeCardio[cardioIndex];
                          return ActiveCardioSessionCard(
                            key: ValueKey<String>('active-cardio-${entry.id}'),
                            entry: entry,
                            index: cardioIndex,
                            onChanged: provider.updateActiveCardio,
                          );
                        }

                        final ex = exercises[index];
                        final sets = SessionStateCache.setsStatus[index]!;

                        final bool startsSuperset =
                            ex.isSuperset && index < exercises.length - 1;
                        final bool continuesSuperset =
                            index > 0 && exercises[index - 1].isSuperset;
                        final bool isSupersetPair =
                            startsSuperset || continuesSuperset;
                        final progression = ref.watch(
                          exerciseProgressionProvider(ex),
                        );

                        return Container(
                          key: ValueKey<String>(
                            '${workoutState.activeRoutineName}-${ex.id}-$index',
                          ),
                          margin: EdgeInsets.only(
                            bottom: startsSuperset ? 2 : 14,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(continuesSuperset ? 4 : 14),
                              bottom: Radius.circular(startsSuperset ? 4 : 14),
                            ),
                            border: Border.all(
                              color: isSupersetPair
                                  ? Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.55)
                                  : AppColors.border,
                              width: isSupersetPair ? 1.25 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (startsSuperset || continuesSuperset)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(
                                        continuesSuperset ? 3 : 13,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.link,
                                        size: 16,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          startsSuperset
                                              ? 'BI-SET 1/2 — FAÇA COM O PRÓXIMO'
                                              : 'BI-SET 2/2 — CONTINUAÇÃO SEM PAUSA',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              InkWell(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(
                                    continuesSuperset ? 4 : 14,
                                  ),
                                  bottom: Radius.circular(
                                    startsSuperset ? 4 : 14,
                                  ),
                                ),
                                onTap: () {
                                  final details = _getDetailedInfo(ex.id);
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => Dialog(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: SingleChildScrollView(
                                        keyboardDismissBehavior:
                                            ScrollViewKeyboardDismissBehavior
                                                .onDrag,
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Container(
                                                  color: Theme.of(
                                                    context,
                                                  ).scaffoldBackgroundColor,
                                                  width: double.infinity,
                                                  constraints:
                                                      const BoxConstraints(
                                                        maxHeight: 250,
                                                      ),
                                                  child: ExerciseMediaView(
                                                    exercise: ex,
                                                    fit: BoxFit.contain,
                                                    showPoseLabel: true,
                                                    placeholderBuilder:
                                                        (
                                                          context,
                                                        ) => const Center(
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .image_not_supported,
                                                                size: 36,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                              SizedBox(
                                                                height: 8,
                                                              ),
                                                              Text(
                                                                'Imagem indisponível',
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              Center(
                                                child: Text(
                                                  ex.name,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w800,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Center(
                                                child: Text(
                                                  ex.muscle.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(
                                                  14,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primarySoft,
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color:
                                                        AppColors.primaryBorder,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child:
                                                          _buildExerciseInfoMetric(
                                                            context,
                                                            icon: Icons
                                                                .repeat_rounded,
                                                            label:
                                                                'Séries e reps',
                                                            value: ex.reps,
                                                          ),
                                                    ),
                                                    Container(
                                                      width: 1,
                                                      height: 38,
                                                      color: AppColors
                                                          .primaryBorder,
                                                    ),
                                                    Expanded(
                                                      child:
                                                          _buildExerciseInfoMetric(
                                                            context,
                                                            icon: Icons
                                                                .timer_outlined,
                                                            label: 'Descanso',
                                                            value: ex.rest,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              Text(
                                                'MÚSCULOS SECUNDÁRIOS:',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                details['secondary'],
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'COMO EXECUTAR:',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              ...List.generate(
                                                (details['steps'] as List)
                                                    .length,
                                                (i) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 8.0,
                                                        ),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          '${i + 1}.',
                                                          style: TextStyle(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            details['steps'][i],
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              color: AppColors
                                                                  .textPrimary,
                                                              height: 1.4,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                              if (ex.customNote
                                                  .trim()
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 16),
                                                Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppColors.surfaceLight,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: AppColors.border,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .sticky_note_2_outlined,
                                                        size: 18,
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'OBSERVAÇÃO DA FICHA',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                color: AppColors
                                                                    .textSecondary,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Text(
                                                              ex.customNote,
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                                color: AppColors
                                                                    .textPrimary,
                                                                height: 1.35,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 16),
                                              SizedBox(
                                                width: double.infinity,
                                                child: OutlinedButton.icon(
                                                  onPressed: () {
                                                    Navigator.pop(ctx);
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute<void>(
                                                        builder: (_) => PulseAiContextScreen(
                                                          appBarTitle:
                                                              'Assistente PULSE',
                                                          heroTitle:
                                                              'Explicando o exercício',
                                                          heroSubtitle: ex.name,
                                                          icon: Icons
                                                              .fitness_center_rounded,
                                                          request: PulseAiRequest(
                                                            mode: PulseAiAssistantMode
                                                                .explainExercise,
                                                            exercise: ex,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.auto_awesome_rounded,
                                                  ),
                                                  label: const Text(
                                                    'EXPLICAR COM O ASSISTENTE PULSE',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              SizedBox(
                                                width: double.infinity,
                                                child: TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child: Text(
                                                    'FECHAR',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(9),
                                      child: ExerciseMediaView(
                                        exercise: ex,
                                        fit: BoxFit.cover,
                                        placeholderBuilder: (context) => Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    ex.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ex.description,
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),

                                        if (ex.customNote.isNotEmpty) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.amber.withValues(
                                                  alpha: 0.3,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.push_pin,
                                                  size: 10,
                                                  color: Colors.amber,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    ex.customNote,
                                                    style: const TextStyle(
                                                      color: Colors.amber,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                        ],

                                        Text(
                                          'Último: ${progression.lastPerformance}',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          progression.nextTarget,
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.help_outline,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              if (!ex.advancedPrescription.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    10,
                                  ),
                                  child: Wrap(
                                    spacing: 7,
                                    runSpacing: 6,
                                    children: <Widget>[
                                      if (ex
                                              .advancedPrescription
                                              .primaryPrescription
                                              ?.sets
                                              .any(
                                                (set) =>
                                                    set.technique.label !=
                                                    'Nenhuma',
                                              ) ??
                                          false)
                                        _advancedPrescriptionChip(
                                          context,
                                          Icons.bolt_rounded,
                                          'Técnica avançada',
                                        ),
                                      if (ex
                                              .advancedPrescription
                                              .primaryPrescription
                                              ?.sets
                                              .any(
                                                (set) => set.cadence
                                                    .trim()
                                                    .isNotEmpty,
                                              ) ??
                                          false)
                                        _advancedPrescriptionChip(
                                          context,
                                          Icons.speed_rounded,
                                          'Cadência definida',
                                        ),
                                      if (ex
                                          .advancedPrescription
                                          .alternatives
                                          .isNotEmpty)
                                        _advancedPrescriptionChip(
                                          context,
                                          Icons.swap_horiz_rounded,
                                          '${ex.advancedPrescription.alternatives.length} alternativa${ex.advancedPrescription.alternatives.length == 1 ? '' : 's'}',
                                          onTap: () =>
                                              _chooseExerciseAlternative(
                                                provider: provider,
                                                workoutState: workoutState,
                                                exerciseIndex: index,
                                                current: ex,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                              Divider(color: AppColors.border, height: 1),

                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  right: 8,
                                  top: 12,
                                  bottom: 4,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 38,
                                      child: Center(
                                        child: Text(
                                          'Série',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          'Carga ($weightUnit)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          'Reps',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    SizedBox(
                                      width: 30,
                                      child: Center(
                                        child: Icon(
                                          Icons.check,
                                          size: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  right: 8,
                                  bottom: 8,
                                ),
                                child: Column(
                                  children: [
                                    ...List.generate(sets.length, (setIndex) {
                                      bool isCompleted = sets[setIndex];
                                      final prescribedSet =
                                          workoutState.activeSession != null &&
                                              index <
                                                  workoutState
                                                      .activeSession!
                                                      .exercises
                                                      .length &&
                                              setIndex <
                                                  workoutState
                                                      .activeSession!
                                                      .exercises[index]
                                                      .sets
                                                      .length
                                          ? workoutState
                                                .activeSession!
                                                .exercises[index]
                                                .sets[setIndex]
                                          : null;
                                      var smartTarget =
                                          prescribedSet?.targetText.trim() ??
                                          '';
                                      if (smartTarget.isEmpty) {
                                        smartTarget = _getSmartTarget(
                                          ex.reps,
                                          setIndex,
                                        );
                                      }
                                      if (prescribedSet?.targetRir != null) {
                                        smartTarget =
                                            '$smartTarget • RIR ${prescribedSet!.targetRir}';
                                      }

                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: setIndex == sets.length - 1
                                              ? 0
                                              : 5,
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 38,
                                              child: Center(
                                                child: Text(
                                                  '${setIndex + 1}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    color: isCompleted
                                                        ? Theme.of(
                                                            context,
                                                          ).colorScheme.primary
                                                        : AppColors.textPrimary,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: _buildInputForm(
                                                context,
                                                _weightControllers[index]![setIndex],
                                                weightUnit,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildInputForm(
                                                context,
                                                _repsControllers[index]![setIndex],
                                                smartTarget,
                                                isReps: true,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            SizedBox(
                                              width: 30,
                                              height: 30,
                                              child: Checkbox(
                                                value: isCompleted,
                                                activeColor: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                checkColor: AppColors.onPrimary,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    const VisualDensity(
                                                      horizontal: -4,
                                                      vertical: -4,
                                                    ),
                                                side: BorderSide(
                                                  color: AppColors.border,
                                                  width: 1.5,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                onChanged: (val) {
                                                  _handleSetChanged(
                                                    provider: provider,
                                                    exercises: exercises,
                                                    exerciseIndex: index,
                                                    setIndex: setIndex,
                                                    isCompleted: val ?? false,
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  children: [
                    if (workoutState.isResting)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'DESCANSO',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => provider.addRestSeconds(-15),
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(30, 30),
                                    padding: EdgeInsets.zero,
                                    foregroundColor: AppColors.textSecondary,
                                  ),
                                  child: const Text('-15'),
                                ),
                                Text(
                                  _formatTime(workoutState.restSeconds),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => provider.addRestSeconds(15),
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(30, 30),
                                    padding: EdgeInsets.zero,
                                    foregroundColor: AppColors.textSecondary,
                                  ),
                                  child: const Text('+15'),
                                ),
                              ],
                            ),
                            const SizedBox(width: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox.square(
                                  dimension: 32,
                                  child: IconButton(
                                    key: const Key('restPauseResumeButton'),
                                    tooltip: workoutState.isRestPaused
                                        ? 'Continuar descanso'
                                        : 'Pausar descanso',
                                    onPressed: workoutState.isRestPaused
                                        ? provider.resumeRestTimer
                                        : provider.pauseRestTimer,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 32,
                                      height: 32,
                                    ),
                                    iconSize: 19,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    icon: Icon(
                                      workoutState.isRestPaused
                                          ? Icons.play_arrow_rounded
                                          : Icons.pause_rounded,
                                    ),
                                  ),
                                ),
                                SizedBox.square(
                                  dimension: 32,
                                  child: IconButton(
                                    key: const Key('skipRestButton'),
                                    tooltip: 'Pular descanso',
                                    onPressed: provider.stopRestTimer,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 32,
                                      height: 32,
                                    ),
                                    iconSize: 19,
                                    color: Colors.redAccent,
                                    icon: const Icon(Icons.skip_next_rounded),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Cronômetro automático ativado',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.timer_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: workoutState.isFinishing
                            ? null
                            : () => unawaited(_confirmFinish(provider)),
                        child: Text(
                          workoutState.isFinishing
                              ? 'SALVANDO...'
                              : 'FINALIZAR E SALVAR',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
