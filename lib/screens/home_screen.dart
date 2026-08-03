import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../features/settings/presentation/providers/settings_controller.dart';
import '../features/workouts/domain/models/workout_history_item.dart';
import '../features/workouts/presentation/providers/workout_controller.dart';
import '../theme/app_theme.dart';
import '../models/exercise.dart';
import 'cardio_entry_screen.dart';
import 'free_activity_entry_screen.dart';
import 'workout_session_screen.dart';
import 'workout_history_detail_screen.dart';
import 'workout_plan_screen.dart';
import 'routine_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.onOpenWorkouts, this.onOpenProgress});

  final VoidCallback? onOpenWorkouts;
  final VoidCallback? onOpenProgress;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _temNotificacoesNaoLidas = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);
  }

  String _routineStartLabel(RoutineType type) {
    return switch (type) {
      RoutineType.strength => 'INICIAR TREINO',
      RoutineType.cardio => 'INICIAR CARDIO',
      RoutineType.mixed => 'INICIAR TREINO MISTO',
    };
  }

  IconData _routineIcon(RoutineType type) {
    return switch (type) {
      RoutineType.strength => Icons.fitness_center_rounded,
      RoutineType.cardio => Icons.directions_run_rounded,
      RoutineType.mixed => Icons.sports_gymnastics_rounded,
    };
  }

  String _obterSaudacao(String nome) {
    final hora = DateTime.now().hour;
    final nomeNormalizado = nome.trim();
    final primeiroNome = nomeNormalizado.isEmpty
        ? 'Atleta'
        : nomeNormalizado.split(RegExp(r'\s+')).first;

    if (hora < 12) {
      return 'Bom dia, $primeiroNome';
    } else if (hora < 18) {
      return 'Boa tarde, $primeiroNome';
    } else {
      return 'Boa noite, $primeiroNome';
    }
  }

  String get _dataFormatada {
    final hoje = DateTime.now();
    String data = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(hoje);
    return data[0].toUpperCase() + data.substring(1);
  }

  void _mostrarNotificacoes(BuildContext context, WorkoutController provider) {
    setState(() {
      _temNotificacoesNaoLidas = false;
    });

    final history = provider.history;
    final totalRegistros = history.length;

    String statusTreinoMsg =
        'Você ainda não concluiu nenhum treino. Que tal começar hoje?';
    String analiseRitmoMsg =
        'Complete um treino para analisarmos o seu ritmo e tempo de execução.';

    if (history.isNotEmpty) {
      final ultimoTreino = history.first;
      final diferencaDias = DateTime.now().difference(ultimoTreino.date).inDays;

      if (diferencaDias == 0) {
        statusTreinoMsg = ultimoTreino.isFreeActivityOnly
            ? 'Atividade registrada hoje. Seu dia ativo foi reconhecido pelo PULSE.'
            : ultimoTreino.isCardioOnly
            ? 'Cardio registrado hoje. Consistência também conta fora da musculação.'
            : 'Parabéns! Você treinou hoje e garantiu sua evolução.';
      } else if (diferencaDias == 1) {
        statusTreinoMsg =
            'Sua última atividade foi ontem. Hora de manter a consistência!';
      } else {
        statusTreinoMsg =
            'Já se passaram $diferencaDias dias desde o seu último registro.';
      }

      if (ultimoTreino.isFreeActivityOnly) {
        final activity = ultimoTreino.freeActivities.first;
        final replacementLabel = activity.replacedPlannedWorkout
            ? ' • substituiu o treino planejado'
            : '';
        analiseRitmoMsg =
            '${activity.displayName}: ${activity.durationMinutes} minutos • intensidade ${activity.intensity.label.toLowerCase()}$replacementLabel.';
      } else if (ultimoTreino.isCardioOnly) {
        final cardio = ultimoTreino.cardio.first;
        final distanceLabel = cardio.distanceKm == null
            ? ''
            : ' • ${cardio.distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km';
        analiseRitmoMsg =
            '${cardio.modality.label}: ${cardio.actualDurationMinutes} minutos registrados$distanceLabel.';
      }

      final partes = ultimoTreino.duration.split(':');
      final minutosDuracao = int.parse(partes[0]);
      final totalExercicios = ultimoTreino.totalExercises;

      if (!ultimoTreino.isCardioOnly && totalExercicios > 0) {
        final tempoPorExercicio = minutosDuracao / totalExercicios;

        if (minutosDuracao < 10 && totalExercicios >= 3) {
          analiseRitmoMsg =
              'Análise do último treino: Ritmo relâmpago! (${minutosDuracao}m para $totalExercicios exercícios).';
        } else if (tempoPorExercicio < 2.5) {
          analiseRitmoMsg =
              'Análise do último treino: Ritmo acelerado! (${minutosDuracao}m).';
        } else if (tempoPorExercicio > 8) {
          analiseRitmoMsg =
              'Análise do último treino: Sessão longa (${minutosDuracao}m).';
        } else {
          analiseRitmoMsg =
              'Análise do último treino: Ritmo perfeito! (${minutosDuracao}m para $totalExercicios exercícios).';
        }
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'NOTIFICAÇÕES DO SISTEMA',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Fechar',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNotificationItem(
              Icons.bolt,
              'Status de Consistência',
              statusTreinoMsg,
            ),
            const SizedBox(height: 12),
            _buildNotificationItem(
              Icons.analytics_outlined,
              'Análise de Desempenho',
              analiseRitmoMsg,
            ),
            const SizedBox(height: 12),
            _buildNotificationItem(
              Icons.military_tech,
              'Marcos Alcançados',
              'Total de $totalRegistros atividade(s) registrada(s).',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _iniciarTreinoDinamico({
    required BuildContext screenContext,
    required BuildContext sheetContext,
    required WorkoutController provider,
    required WorkoutRoutine routine,
  }) async {
    if (provider.isWorkoutActive) {
      final shouldReplace = await showDialog<bool>(
        context: screenContext,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Theme.of(screenContext).colorScheme.surface,
          title: Text(
            'Trocar Treino?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Você tem um treino ("${provider.activeRoutineName}") em andamento. Deseja substituí-lo pelo treino dinâmico?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancelar',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(screenContext).colorScheme.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Trocar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );

      if (shouldReplace != true) {
        return;
      }
    }

    if (!screenContext.mounted || !sheetContext.mounted) {
      return;
    }

    Navigator.pop(sheetContext);
    provider.startRoutine(routine, replaceActive: true);

    await Navigator.push(
      screenContext,
      MaterialPageRoute(builder: (_) => const WorkoutSessionScreen()),
    );
  }

  void _mostrarModalTreinoDinamico(
    BuildContext screenContext,
    WorkoutController provider,
  ) {
    String musculoFoco = 'Full Body';
    int quantidadeEx = 5;

    showModalBottomSheet(
      context: screenContext,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: 24,
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Treino Dinâmico ⚡',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.textPrimary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sem tempo para planejar? Escolha o foco e o tempo disponível. Nós montamos um treino aleatório para você na hora.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'MÚSCULO FOCO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          [
                                'Full Body',
                                'Peito',
                                'Costas',
                                'Pernas',
                                'Ombros',
                                'Braços',
                              ]
                              .map(
                                (m) => ChoiceChip(
                                  label: Text(
                                    m,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: musculoFoco == m
                                          ? AppColors.onPrimary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  selected: musculoFoco == m,
                                  selectedColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  backgroundColor: AppColors.background,
                                  side: BorderSide(
                                    color: musculoFoco == m
                                        ? Theme.of(context).colorScheme.primary
                                        : AppColors.border,
                                  ),
                                  onSelected: (val) =>
                                      setStateModal(() => musculoFoco = m),
                                ),
                              )
                              .toList(),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'DURAÇÃO DO TREINO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          [
                                {'label': 'Express (~20m)', 'val': 3},
                                {'label': 'Padrão (~40m)', 'val': 5},
                                {'label': 'Intenso (~60m)', 'val': 7},
                              ]
                              .map(
                                (d) => ChoiceChip(
                                  label: Text(
                                    d['label'] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: quantidadeEx == d['val']
                                          ? AppColors.onPrimary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  selected: quantidadeEx == d['val'],
                                  selectedColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  backgroundColor: AppColors.background,
                                  side: BorderSide(
                                    color: quantidadeEx == d['val']
                                        ? Theme.of(context).colorScheme.primary
                                        : AppColors.border,
                                  ),
                                  onSelected: (val) => setStateModal(
                                    () => quantidadeEx = d['val'] as int,
                                  ),
                                ),
                              )
                              .toList(),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          List<Exercise> pool = provider.allExercises.toList();

                          if (musculoFoco != 'Full Body') {
                            pool = pool.where((e) {
                              String m = e.muscle.toLowerCase();
                              if (musculoFoco == 'Peito' &&
                                  m.contains('peito')) {
                                return true;
                              }
                              if (musculoFoco == 'Costas' &&
                                  (m.contains('costas') ||
                                      m.contains('dorsal'))) {
                                return true;
                              }
                              if (musculoFoco == 'Pernas' &&
                                  (m.contains('perna') ||
                                      m.contains('quadríceps') ||
                                      m.contains('glúteo') ||
                                      m.contains('isquio') ||
                                      m.contains('panturrilha'))) {
                                return true;
                              }
                              if (musculoFoco == 'Ombros' &&
                                  m.contains('ombro')) {
                                return true;
                              }
                              if (musculoFoco == 'Braços' &&
                                  (m.contains('bíceps') ||
                                      m.contains('tríceps') ||
                                      m.contains('antebraço'))) {
                                return true;
                              }
                              return false;
                            }).toList();
                          }

                          if (pool.isEmpty) {
                            pool = provider.allExercises.toList();
                          }

                          pool.shuffle();
                          final selectedExercises = pool
                              .take(quantidadeEx)
                              .toList();

                          final routine = WorkoutRoutine(
                            id: 'dinamico_${DateTime.now().millisecondsSinceEpoch}',
                            name: 'Treino Dinâmico: $musculoFoco',
                            focus: 'Gerado Aleatoriamente',
                            groupName: 'Treinos Rápidos',
                            exercises: List<Exercise>.from(selectedExercises),
                          );

                          await _iniciarTreinoDinamico(
                            screenContext: screenContext,
                            sheetContext: ctx,
                            provider: provider,
                            routine: routine,
                          );
                        },
                        icon: const Icon(Icons.bolt),
                        label: const Text(
                          'GERAR E INICIAR TREINO',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutControllerProvider);
    final provider = ref.read(workoutControllerProvider.notifier);
    final history = workoutState.history;
    final settingsAsync = ref.watch(settingsControllerProvider);
    final userName = settingsAsync.when(
      data: (settings) => settings.profile.displayName,
      loading: () => 'Atleta',
      error: (_, _) => 'Atleta',
    );

    final agora = DateTime.now();
    final umaSemanaAtras = agora.subtract(const Duration(days: 7));
    final atividadesDaSemana = history
        .where((item) => item.date.isAfter(umaSemanaAtras))
        .toList(growable: false);
    final diasAtivosNaSemana = atividadesDaSemana
        .map((item) => DateTime(item.date.year, item.date.month, item.date.day))
        .toSet()
        .length;
    final rotinaDoDia =
        provider.nextRoutineToTrain ??
        (provider.myRoutines.isNotEmpty ? provider.myRoutines.first : null);
    final latestActivity = history.isEmpty ? null : history.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            primary: true,
            floating: true,
            snap: true,
            pinned: true,
            toolbarHeight: 56,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            backgroundColor: AppColors.background,
            elevation: 0,
            titleSpacing: 20,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/icon.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        color: AppColors.onPrimary,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'PULSE',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Abrir configurações',
                icon: const Icon(Icons.settings_outlined, size: 25),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              IconButton(
                tooltip: 'Abrir notificações',
                onPressed: () => _mostrarNotificacoes(context, provider),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    const Icon(Icons.notifications_outlined, size: 25),
                    if (_temNotificacoesNaoLidas)
                      Positioned(
                        right: -2,
                        top: -1,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.background,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              20,
              6,
              20,
              MediaQuery.viewPaddingOf(context).bottom + 20,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _obterSaudacao(userName),
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.35,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Vamos cuidar do treino de hoje?',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          _dataFormatada,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (provider.isWorkoutActive) ...[
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkoutSessionScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.surfaceLight, AppColors.surface],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.warning,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'SESSÃO EM ANDAMENTO',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.warning,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    'Continuar ${provider.activeRoutineName}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Não deixe seu descanso passar!',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(
                                  alpha: 0.12,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: AppColors.warning,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // BOTÃO DUPLICADO FOI REMOVIDO DAQUI
                  ] else if (rotinaDoDia != null) ...[
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RoutineDetailScreen(routine: rotinaDoDia),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.surfaceLight, AppColors.surface],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      provider.activeProgramName.isNotEmpty
                                          ? 'PROGRAMA: ${provider.activeProgramName.toUpperCase()}'
                                          : 'PLANO ATUAL (TOQUE PARA VER)',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    rotinaDoDia.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${rotinaDoDia.typeLabel} • ${rotinaDoDia.focus}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _routineIcon(rotinaDoDia.type),
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final started = provider.startRoutine(rotinaDoDia);

                          if (!started &&
                              provider.activeRoutineName != rotinaDoDia.name) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Você já está treinando ${provider.activeRoutineName}. Abra a ficha para confirmar a troca.',
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WorkoutSessionScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _routineStartLabel(rotinaDoDia.type),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.play_arrow, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.surfaceLight, AppColors.surface],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primaryBorder,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.help_outline,
                                color: Theme.of(context).colorScheme.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'PRECISA DE AJUDA?',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Não sabe por onde começar?',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Abra a área de Treinos para criar sua primeira ficha ou importar um programa pronto para o seu nível.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: AppColors.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.fitness_center, size: 20),
                              label: const Text(
                                'ABRIR TREINOS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              onPressed: () {
                                final openWorkouts = widget.onOpenWorkouts;
                                if (openWorkouts != null) {
                                  openWorkouts();
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const WorkoutPlanScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _HomeQuickActionCard(
                          icon: Icons.directions_run_rounded,
                          eyebrow: 'CARDIO',
                          title: 'Registrar cardio',
                          subtitle: 'Esteira, bike e mais',
                          onTap: () async {
                            final saved = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute<bool>(
                                builder: (_) => const CardioEntryScreen(),
                              ),
                            );
                            if (saved == true && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Cardio salvo no histórico com sucesso.',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HomeQuickActionCard(
                          icon: Icons.shuffle_rounded,
                          eyebrow: 'TREINO DINÂMICO ⚡',
                          title: 'Gerar agora',
                          subtitle: 'Treino rápido e aleatório',
                          emphasized: true,
                          onTap: () =>
                              _mostrarModalTreinoDinamico(context, provider),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _HomeWideActionCard(
                    icon: Icons.sports_gymnastics_rounded,
                    eyebrow: 'ATIVIDADE LIVRE',
                    title: 'CrossFit, pilates e mais',
                    subtitle:
                        'Registre uma atividade fora da ficha e mantenha seus dias ativos corretos.',
                    onTap: () async {
                      final saved = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute<bool>(
                          builder: (_) => const FreeActivityEntryScreen(),
                        ),
                      );
                      if (saved == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Atividade salva no histórico com sucesso.',
                            ),
                          ),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RESUMO SEMANAL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onOpenProgress,
                        child: Text(
                          'VER PROGRESSO',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryStat(
                          icon: Icons.fitness_center,
                          value: '$diasAtivosNaSemana',
                          label: 'Dias ativos',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryStat(
                          icon: Icons.local_fire_department,
                          value: diasAtivosNaSemana >= 3
                              ? 'Excelente'
                              : 'Em dia',
                          label: 'Ritmo',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryStat(
                          icon: Icons.calendar_today,
                          value: history.isNotEmpty
                              ? '${DateTime.now().difference(history.first.date).inDays}d'
                              : '-',
                          label: 'Última atividade',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ATIVIDADE RECENTE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _RecentActivityCard(
                    workout: latestActivity,
                    onTap: () {
                      if (latestActivity != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => WorkoutHistoryDetailScreen(
                              workout: latestActivity,
                            ),
                          ),
                        );
                        return;
                      }

                      final openWorkouts = widget.onOpenWorkouts;
                      if (openWorkouts != null) {
                        openWorkouts();
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const WorkoutPlanScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeQuickActionCard extends StatelessWidget {
  const _HomeQuickActionCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 108,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            gradient: emphasized
                ? LinearGradient(
                    colors: [AppColors.primarySoft, AppColors.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: emphasized ? null : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: emphasized ? AppColors.primaryBorder : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: emphasized ? primary : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: emphasized ? AppColors.onPrimary : primary,
                  size: 18,
                ),
              ),
              const Spacer(),
              Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.35,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeWideActionCard extends StatelessWidget {
  const _HomeWideActionCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      eyebrow,
                      style: TextStyle(
                        color: primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.workout, required this.onTap});

  final WorkoutHistoryItem? workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final item = workout;
    final isEmpty = item == null;
    late final IconData icon;
    late final String title;
    late final String subtitle;
    late final String eyebrow;

    if (item == null) {
      icon = Icons.history_toggle_off_rounded;
      title = 'Seu histórico começa aqui';
      subtitle =
          'Conclua um treino ou registre uma atividade para acompanhar sua evolução.';
      eyebrow = 'PRÓXIMO PASSO';
    } else {
      icon = item.isFreeActivityOnly
          ? Icons.sports_gymnastics_rounded
          : item.isCardioOnly
          ? Icons.directions_run_rounded
          : item.isMixedSession
          ? Icons.sports_gymnastics_rounded
          : Icons.fitness_center_rounded;
      title = item.routineName;
      subtitle = _activitySummary(item);
      eyebrow =
          'ÚLTIMA ATIVIDADE • ${DateFormat('dd/MM • HH:mm').format(item.date)}';
    }

    final accent = item?.isIncomplete == true ? AppColors.warning : primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 94),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color.alphaBlend(
                  accent.withValues(alpha: 0.10),
                  AppColors.surface,
                ),
                AppColors.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: Color.alphaBlend(
                accent.withValues(alpha: 0.25),
                AppColors.border,
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      eyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.35,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEmpty
                      ? Icons.arrow_forward_rounded
                      : Icons.chevron_right_rounded,
                  color: accent,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _activitySummary(WorkoutHistoryItem item) {
    final details = <String>[];

    if (item.isFreeActivityOnly) {
      final activity = item.freeActivities.first;
      details.add('${activity.durationMinutes} min');
      details.add('Intensidade ${activity.intensity.label.toLowerCase()}');
      if (activity.replacedPlannedWorkout) {
        details.add('Substituiu o treino planejado');
      }
    } else if (item.isCardioOnly) {
      details.add('${item.totalCardioMinutes} min de cardio');
    } else {
      details.add('${item.totalExercises} exercícios');
      details.add('${item.totalSets} séries');
      if (item.isMixedSession && item.totalCardioMinutes > 0) {
        details.add('${item.totalCardioMinutes} min cardio');
      }
    }

    if (!item.isFreeActivityOnly &&
        !item.isCardioOnly &&
        item.duration.trim().isNotEmpty) {
      details.add(item.duration);
    }

    return details.join(' • ');
  }
}

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _SummaryStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
