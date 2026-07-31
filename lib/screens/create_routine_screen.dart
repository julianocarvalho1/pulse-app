import 'package:flutter/material.dart';
// Precisamos importar o modelo para o app reconhecer o "WorkoutRoutine"
import '../models/exercise.dart';
import 'program_builder_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/routine_type_selector.dart';

// ============================================================
//  TELA: SETUP DO PROGRAMA (PASSO 1)
// ============================================================

class CreateRoutineScreen extends StatefulWidget {
  // O parâmetro fantasma voltou para não quebrar as outras telas!
  final WorkoutRoutine? routineToEdit;

  const CreateRoutineScreen({super.key, this.routineToEdit});

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  final _nameController = TextEditingController();
  final _focusController = TextEditingController();

  // A divisão padrão será ABC
  String _selectedSplit = 'ABC';
  RoutineType _selectedRoutineType = RoutineType.strength;

  // Opções de divisão de treino disponíveis
  final List<String> _splits = ['Full Body', 'AB', 'ABC', 'ABCD', 'ABCDE'];

  @override
  void initState() {
    super.initState();
    // Se a tela for aberta no modo "Editar", já preenchemos os dados
    if (widget.routineToEdit != null) {
      _nameController.text = widget.routineToEdit!.groupName.isNotEmpty
          ? widget.routineToEdit!.groupName
          : widget.routineToEdit!.name;
      _focusController.text = widget.routineToEdit!.focus;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, dê um nome para o seu programa de treino.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final programName = _nameController.text.trim();
    final programFocus = _focusController.text.trim().isEmpty
        ? 'Geral'
        : _focusController.text.trim();

    // Navega para a Tela 2 levando os dados do setup
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProgramBuilderScreen(
          programName: programName,
          programFocus: programFocus,
          splitType: _selectedSplit,
          defaultRoutineType: _selectedRoutineType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.routineToEdit != null ? 'EDITAR PROGRAMA' : 'NOVO PROGRAMA',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone central decorativo
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_document,
                  color: Theme.of(context).colorScheme.primary,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // DADOS DO PROGRAMA
            Text(
              'PASSO 1: DADOS GERAIS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                labelText: 'Nome do Programa (ex: Foco Emagrecimento)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _focusController,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Objetivo Principal (ex: Hipertrofia, Cardio)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'PASSO 2: TIPO PADRÃO DAS FICHAS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 14),
            RoutineTypeSelector(
              value: _selectedRoutineType,
              onChanged: (value) {
                setState(() => _selectedRoutineType = value);
              },
            ),
            const SizedBox(height: 32),

            // DIVISÃO DO TREINO
            Text(
              'PASSO 3: DIVISÃO DO TREINO',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Como você quer organizar seus dias na academia?',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _splits.map((split) {
                final isSelected = _selectedSplit == split;
                return ChoiceChip(
                  label: Text(
                    split,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : AppColors.border,
                  ),
                  showCheckmark: false,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedSplit = split;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.viewPaddingOf(context).bottom + 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _nextStep,
          child: const Text(
            'AVANÇAR E MONTAR FICHAS',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
      ),
    );
  }
}
