import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/exercises/domain/repdb_exercise_mapping.dart';
import '../theme/app_theme.dart';

class AboutPulseScreen extends StatelessWidget {
  const AboutPulseScreen({super.key});

  static final Uri _repDbUrl = Uri.parse(RepDbExerciseMapping.attributionUrl);

  Future<void> _openRepDb(BuildContext context) async {
    final opened = await launchUrl(
      _repDbUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o site do RepDB.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sobre o PULSE'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.paddingOf(context).bottom + 30,
        ),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[AppColors.primarySoft, AppColors.surface],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Column(
              children: <Widget>[
                Icon(
                  Icons.fitness_center_rounded,
                  size: 42,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 14),
                const Text(
                  'PULSE',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  'Versão 1.0.0',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Text(
                  'Treinos, progresso e assistência inteligente em um aplicativo que mantém você no controle.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'CRÉDITOS E LICENÇAS',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
              side: BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              leading: Icon(
                Icons.accessibility_new_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text(
                RepDbExerciseMapping.attributionText,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Dados e ilustrações das posições inicial e final dos exercícios. Uso gratuito com atribuição.',
              ),
              trailing: const Icon(Icons.open_in_new_rounded, size: 20),
              onTap: () => _openRepDb(context),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'As demonstrações são informativas e não substituem a orientação de um profissional de educação física. Interrompa o exercício diante de dor ou mal-estar.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
