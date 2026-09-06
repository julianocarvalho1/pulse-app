import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../theme/app_theme.dart';

class RoutineTypeSelector extends StatelessWidget {
  const RoutineTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.addContent = false,
  });

  final RoutineType value;
  final ValueChanged<RoutineType> onChanged;
  final bool addContent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          addContent ? 'TOQUE PARA ADICIONAR À FICHA' : 'TIPO DE TREINO',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: RoutineType.values
              .map((type) {
                final selected = value == type;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: type == RoutineType.mixed ? 0 : 8,
                    ),
                    child: Material(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onChanged(type),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 72),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                _iconFor(type),
                                size: 21,
                                color: selected
                                    ? AppColors.onPrimary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 5),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  type.label,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: selected
                                        ? AppColors.onPrimary
                                        : AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 8),
        Text(
          addContent
              ? 'Cardio abre as opções contínuo e intervalado. O conteúdo atual é mantido.'
              : value.description,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  static IconData _iconFor(RoutineType type) {
    return switch (type) {
      RoutineType.strength => Icons.fitness_center_rounded,
      RoutineType.cardio => Icons.directions_run_rounded,
      RoutineType.mixed => Icons.sports_gymnastics_rounded,
    };
  }
}
