import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../features/settings/presentation/providers/settings_controller.dart';
import '../features/workouts/presentation/providers/workout_controller.dart';
import '../theme/app_theme.dart';
import '../models/exercise.dart';
import 'workout_session_screen.dart';
import 'workout_plan_screen.dart';
import 'routine_detail_screen.dart';
import 'settings_screen.dart';
import 'progress_calendar_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

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

  String _obterSaudacao(String nome) {
    final hora = DateTime.now().hour;
    final nomeFormatado = nome.toUpperCase();
    if (hora < 12) {
      return 'BOM DIA, $nomeFormatado!';
    } else if (hora < 18) {
      return 'BOA TARDE, $nomeFormatado!';
    } else {
      return 'BOA NOITE, $nomeFormatado!';
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
    final totalTreinos = history.length;

    String statusTreinoMsg =
        'Você ainda não concluiu nenhum treino. Que tal começar hoje?';
    String analiseRitmoMsg =
        'Complete um treino para analisarmos o seu ritmo e tempo de execução.';

    if (history.isNotEmpty) {
      final ultimoTreino = history.first;
      final diferencaDias = DateTime.now().difference(ultimoTreino.date).inDays;

      if (diferencaDias == 0) {
        statusTreinoMsg =
            'Parabéns! Você treinou hoje e garantiu sua evolução.';
      } else if (diferencaDias == 1) {
        statusTreinoMsg =
            'Seu último treino foi ontem. Hora de manter a consistência!';
      } else {
        statusTreinoMsg =
            'Já se passaram $diferencaDias dias desde o seu último registro.';
      }

      final partes = ultimoTreino.duration.split(':');
      final minutosDuracao = int.parse(partes[0]);
      final totalExercicios = ultimoTreino.totalExercises;

      if (totalExercicios > 0) {
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
              'Total de $totalTreinos treino(s) registrado(s).',
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
                  style: const TextStyle(
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
          title: const Text(
            'Trocar Treino?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Você tem um treino ("${provider.activeRoutineName}") em andamento. Deseja substituí-lo pelo treino dinâmico?',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(screenContext).colorScheme.primary,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Trocar',
                style: TextStyle(fontWeight: FontWeight.w800),
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
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Treino Dinâmico ⚡',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sem tempo para planejar? Escolha o foco e o tempo disponível. Nós montamos um treino aleatório para você na hora.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'MÚSCULO FOCO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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
                                        ? Colors.black
                                        : Colors.white,
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
                  const Text(
                    'DURAÇÃO DO TREINO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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
                                        ? Colors.black
                                        : Colors.white,
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
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.black,
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
                            if (musculoFoco == 'Peito' && m.contains('peito')) {
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
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
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
    final treinosNaSemana = history
        .where((item) => item.date.isAfter(umaSemanaAtras))
        .length;
    final exerciciosNaSemana = history
        .where((item) => item.date.isAfter(umaSemanaAtras))
        .fold(0, (sum, item) => sum + item.totalExercises);

    final rotinaDoDia =
        provider.nextRoutineToTrain ??
        (provider.myRoutines.isNotEmpty ? provider.myRoutines.first : null);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text(
              'Sair do App?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: const Text(
              'Deseja realmente fechar o aplicativo?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Sair',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
        if (shouldExit ?? false) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              primary: false,
              floating: true,
              snap: true,
              pinned: false,
              toolbarHeight: 64,
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
                        child: const Icon(
                          Icons.fitness_center,
                          color: Colors.black,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'PULSE',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings, size: 26),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                GestureDetector(
                  onTap: () => _mostrarNotificacoes(context, provider),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20.0, left: 8.0),
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_outlined, size: 26),
                        if (_temNotificacoesNaoLidas)
                          Positioned(
                            right: 0,
                            top: 14,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.background,
                                  width: 2,
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
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.paddingOf(context).bottom + 32,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _obterSaudacao(userName),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pronto para mais um treino?',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _dataFormatada,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

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
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.surfaceLight,
                                AppColors.surface,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.orangeAccent,
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
                                        color: Colors.orangeAccent.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'SESSÃO EM ANDAMENTO',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.orangeAccent,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Continuar ${provider.activeRoutineName}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
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
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.orangeAccent.withValues(
                                    alpha: 0.15,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.orangeAccent,
                                  size: 30,
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
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.surfaceLight,
                                AppColors.surface,
                              ],
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        provider.activeProgramName.isNotEmpty
                                            ? 'PROGRAMA: ${provider.activeProgramName.toUpperCase()}'
                                            : 'PLANO ATUAL (TOQUE PARA VER)',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      rotinaDoDia.name,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Foco: ${rotinaDoDia.focus}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.fitness_center,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'O SEU TREINO DE HOJE É',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
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
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  rotinaDoDia.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final started = provider.startRoutine(rotinaDoDia);

                            if (!started &&
                                provider.activeRoutineName !=
                                    rotinaDoDia.name) {
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
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'INICIAR TREINO',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.play_arrow, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.surfaceLight, AppColors.surface],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.5),
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w800,
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
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Fique tranquilo! Preparamos um catálogo com fichas prontas para iniciantes, intermediários e avançados.\n\nEscolha o seu nível e importe uma ficha para iniciar sua jornada.',
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
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.search, size: 20),
                                label: const Text(
                                  'EXPLORAR CATÁLOGO',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                onPressed: () {
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

                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () =>
                          _mostrarModalTreinoDinamico(context, provider),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.15),
                              AppColors.surface,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TREINO DINÂMICO ⚡',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Sem tempo para planejar?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Nós geramos um treino aleatório para você agora mesmo.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.shuffle,
                                color: Colors.black,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'RESUMO SEMANAL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProgressCalendarScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'HISTÓRICO DE TREINOS 📅',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryStat(
                            icon: Icons.fitness_center,
                            value: '$treinosNaSemana',
                            label: 'Concluídos',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SummaryStat(
                            icon: Icons.local_fire_department,
                            value: treinosNaSemana >= 3
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
                            label: 'Último treino',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SummaryStat(
                            icon: Icons.checklist,
                            value: '$exerciciosNaSemana',
                            label: 'Exercícios',
                          ),
                        ),
                      ],
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
