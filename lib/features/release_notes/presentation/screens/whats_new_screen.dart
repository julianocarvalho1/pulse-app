import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../data/release_notes_local_service.dart';

class WhatsNewScreen extends StatelessWidget {
  const WhatsNewScreen({super.key});

  static const List<_ReleaseNote> _notes = <_ReleaseNote>[
    _ReleaseNote(
      icon: Icons.trending_up_rounded,
      title: 'Progressão mais fiel à ficha',
      description:
          'As sugestões respeitam o limite de repetições e explicam o motivo da recomendação.',
    ),
    _ReleaseNote(
      icon: Icons.sticky_note_2_outlined,
      title: 'Anotações durante o treino',
      description:
          'Registre contexto por exercício, como máquina diferente ou carga não comparável.',
    ),
    _ReleaseNote(
      icon: Icons.timer_outlined,
      title: 'Core e séries por tempo',
      description:
          'Novas sessões extras e cronômetro para pranchas, isometrias e circuitos.',
    ),
    _ReleaseNote(
      icon: Icons.directions_run_rounded,
      title: 'Cardio planejado de verdade',
      description:
          'Escolha finalidade, intensidade, metas e blocos contínuos ou intervalados.',
    ),
    _ReleaseNote(
      icon: Icons.local_fire_department_outlined,
      title: 'Aquecimento separado do trabalho',
      description:
          'Séries de aquecimento têm alvo e descanso próprios e não alteram volume, recordes ou progressão.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Text(
          'Novidades do PULSE',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          18,
          8,
          18,
          MediaQuery.paddingOf(context).bottom + 110,
        ),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 30,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Versão ${ReleaseNotesLocalService.currentRelease}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mais controle, sem mudar sua ficha sozinho.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ..._notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReleaseNoteCard(note: note),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: FilledButton(
            key: const Key('close-whats-new'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CONTINUAR'),
          ),
        ),
      ),
    );
  }
}

class _ReleaseNoteCard extends StatelessWidget {
  const _ReleaseNoteCard({required this.note});

  final _ReleaseNote note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              note.icon,
              color: Theme.of(context).colorScheme.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  note.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  note.description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReleaseNote {
  const _ReleaseNote({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
