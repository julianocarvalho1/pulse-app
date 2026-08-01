import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../data/services/pulse_workout_file_service.dart';
import '../../domain/models/pulse_workout_file.dart';

Future<void> showPulseWorkoutShareSheet(
  BuildContext context,
  PulseWorkoutDocument document,
) async {
  final action = await showModalBottomSheet<_PulseShareAction>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewPaddingOf(sheetContext).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Compartilhar ${document.contentType.label.toLowerCase()}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'O arquivo .pulse preserva exercícios, séries, repetições, descansos, observações e cardio.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _ShareTile(
            icon: Icons.share_outlined,
            title: 'Compartilhar arquivo',
            subtitle: 'Envie por WhatsApp, e-mail ou outro aplicativo.',
            onTap: () => Navigator.pop(sheetContext, _PulseShareAction.share),
          ),
          const SizedBox(height: 10),
          _ShareTile(
            icon: Icons.file_download_outlined,
            title: 'Salvar arquivo',
            subtitle: 'Escolha uma pasta para guardar o arquivo .pulse.',
            onTap: () => Navigator.pop(sheetContext, _PulseShareAction.save),
          ),
        ],
      ),
    ),
  );

  if (action == null || !context.mounted) {
    return;
  }

  final service = const PulseWorkoutFileService();
  try {
    if (action == _PulseShareAction.share) {
      await service.shareDocument(document);
      return;
    }

    final saved = await service.saveDocument(document);
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arquivo do PULSE salvo com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } on PulseWorkoutFileException catch (error) {
    if (context.mounted) {
      _showError(context, error.message);
    }
  } catch (_) {
    if (context.mounted) {
      _showError(context, 'Não foi possível criar o arquivo. Tente novamente.');
    }
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.redAccent,
    ),
  );
}

enum _PulseShareAction { share, save }

class _ShareTile extends StatelessWidget {
  const _ShareTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
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
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
