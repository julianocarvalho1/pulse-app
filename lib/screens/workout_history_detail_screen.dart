import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';

class WorkoutHistoryDetailScreen extends StatelessWidget {
  final WorkoutHistoryItem workout;

  const WorkoutHistoryDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat("dd/MM/yyyy 'às' HH:mm").format(workout.date);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detalhes do Treino',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CABEÇALHO DO TREINO
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      // Aqui a cor dinâmica entra com opacidade
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    // O const foi removido daqui e a cor dinâmica aplicada
                    child: Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.primary, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    workout.routineName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dataFormatada,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // O context agora é passado para o método para ele saber a cor
                      _buildStatBadge(context, Icons.access_time, workout.duration, 'Duração'),
                      Container(height: 40, width: 1, color: AppColors.border),
                      _buildStatBadge(context, Icons.format_list_bulleted, '${workout.totalExercises}', 'Exercícios'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text('EXERCÍCIOS REALIZADOS',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5)),
            const SizedBox(height: 16),

            // LISTA DE EXERCÍCIOS
            if (workout.exercises.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Nenhum detalhe de exercício salvo para este treino.',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: workout.exercises.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final ex = workout.exercises[index];

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            ex.exerciseName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Container(height: 1, color: AppColors.border),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text('Série', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                  Text('Carga', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                  Text('Reps', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Lista as séries daquele exercício
                              ...ex.sets.asMap().entries.map((entry) {
                                int sIndex = entry.key;
                                ExerciseSet set = entry.value;

                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: AppColors.surfaceLight,
                                            borderRadius: BorderRadius.circular(6)
                                        ),
                                        child: Text('${sIndex + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                      Text('${set.weight} kg', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text('${set.reps}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // O método agora recebe o BuildContext para acessar o Theme.of(context)
  Widget _buildStatBadge(BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}