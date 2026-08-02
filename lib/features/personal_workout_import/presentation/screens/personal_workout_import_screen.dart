import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../data/services/docx_personal_workout_reader.dart';
import '../../data/services/plain_text_personal_workout_reader.dart';
import '../../data/services/pdf_personal_workout_reader.dart';
import '../../domain/models/personal_workout_import.dart';
import '../../domain/services/personal_workout_import_parser.dart';
import 'personal_workout_import_review_screen.dart';

class PersonalWorkoutImportScreen extends StatefulWidget {
  const PersonalWorkoutImportScreen({super.key});

  @override
  State<PersonalWorkoutImportScreen> createState() =>
      _PersonalWorkoutImportScreenState();
}

class _PersonalWorkoutImportScreenState
    extends State<PersonalWorkoutImportScreen> {
  final TextEditingController _textController = TextEditingController();
  final PersonalWorkoutImportParser _parser =
      const PersonalWorkoutImportParser();
  final DocxPersonalWorkoutReader _docxReader =
      const DocxPersonalWorkoutReader();
  final PlainTextPersonalWorkoutReader _plainTextReader =
      const PlainTextPersonalWorkoutReader();
  final PdfPersonalWorkoutReader _pdfReader = const PdfPersonalWorkoutReader();

  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    if (_isLoading) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['docx', 'pdf', 'txt', 'csv'],
      withData: false,
    );
    final file = result?.files.single;
    final path = file?.path;

    if (file == null || path == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final extension = (file.extension ?? '').toLowerCase();
      final PersonalWorkoutImportDraft draft;
      if (extension == 'docx') {
        final blocks = await _docxReader.readFile(path);
        draft = _parser.parseDocument(blocks: blocks, sourceLabel: file.name);
      } else if (extension == 'pdf') {
        final text = await _pdfReader.readFile(path);
        draft = _parser.parseText(text: text, sourceLabel: file.name);
      } else {
        final text = await _plainTextReader.readFile(path);
        draft = _parser.parseText(text: text, sourceLabel: file.name);
      }

      if (draft.routines.isEmpty ||
          (draft.exerciseCount == 0 && draft.cardioCount == 0)) {
        throw FormatException(
          draft.classificationMessage.isNotEmpty
              ? draft.classificationMessage
              : 'Nenhuma ficha preenchida foi reconhecida. Tente outro arquivo, cole o texto ou confira os títulos e prescrições.',
        );
      }

      if (!mounted) {
        return;
      }
      await _openReview(draft);
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error.message.toString());
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError('Não foi possível ler esse arquivo. Detalhes: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _analyzeText() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) {
      _showError('Cole o conteúdo da ficha antes de analisar.');
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isLoading = true);

    try {
      final draft = _parser.parseText(text: text);
      if (draft.routines.isEmpty ||
          (draft.exerciseCount == 0 && draft.cardioCount == 0)) {
        _showError(
          draft.classificationMessage.isNotEmpty
              ? draft.classificationMessage
              : 'Nenhuma ficha preenchida foi reconhecida nesse texto.',
        );
        return;
      }
      await _openReview(draft);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openReview(PersonalWorkoutImportDraft draft) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => PersonalWorkoutImportReviewScreen(draft: draft),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _showFormatGuide() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        title: const Text(
          'Formatos aceitos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _FormatGuideSection(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Melhor resultado',
                  text:
                      'DOCX com tabelas. Esse formato preserva títulos, colunas, observações e bi-sets com maior precisão.',
                ),
                SizedBox(height: 16),
                _FormatGuideSection(
                  icon: Icons.text_snippet_outlined,
                  title: 'Texto, TXT e CSV',
                  text:
                      'Pode copiar do Word, Excel ou Bloco de Notas. O PULSE reconhece Treino A, Treino 1, Série A, Dia 1 e dias da semana. O formato abaixo é recomendado, mas não obrigatório.',
                ),
                SizedBox(height: 10),
                _FormatExample(),
                SizedBox(height: 16),
                _FormatGuideSection(
                  icon: Icons.auto_awesome_motion_outlined,
                  title: 'Estruturas avançadas',
                  text:
                      'São reconhecidos bi-sets com “+”, alternativas com “\\” ou “ / ”, prescrições como 2x12/2x10/1x8, máximo, passos, tempo, RIR e técnicas. Itens ambíguos ficam marcados para revisão.',
                ),
                SizedBox(height: 16),
                _FormatGuideSection(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'PDF',
                  text:
                      'PDF com texto pode funcionar. O PULSE também identifica modelos vazios e materiais didáticos para evitar importações incorretas. Arquivos com fontes incompatíveis devem ser enviados como DOCX, TXT ou CSV.',
                ),
                SizedBox(height: 16),
                _FormatGuideSection(
                  icon: Icons.document_scanner_outlined,
                  title: 'Ainda não compatível',
                  text:
                      'PDF digitalizado, fotografia e captura de tela precisam de OCR. Essa leitura visual será adicionada em uma etapa futura.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Importar ficha do personal',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.viewPaddingOf(context).bottom + 32,
          ),
          children: [
            _IntroCard(isLoading: _isLoading),
            const SizedBox(height: 18),
            _ImportOptionCard(
              icon: Icons.description_outlined,
              title: 'Selecionar arquivo',
              subtitle:
                  'Aceita DOCX, PDF com texto extraível, TXT e CSV. A leitura acontece no aparelho e nada é enviado para a internet.',
              actionLabel: 'Escolher arquivo',
              onPressed: _isLoading ? null : _pickFile,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _showFormatGuide,
                icon: const Icon(Icons.help_outline_rounded, size: 19),
                label: const Text('Ver formatos aceitos e exemplos'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OU COLE O TEXTO',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _textController,
              minLines: 9,
              maxLines: 16,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                alignLabelWithHint: true,
                labelText: 'Conteúdo da ficha',
                hintText:
                    'Treino A — Peito e tríceps\nSupino reto — 4x8-12 — 60s\nEsteira — 20 minutos',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isLoading ? null : _analyzeText,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Analisar texto'),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nada é salvo automaticamente. O PULSE mostra uma revisão para confirmar exercícios, séries, repetições, descanso, bi-sets e cardio.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.assignment_ind_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading ? 'Analisando ficha...' : 'Ficha do personal',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Importe DOCX, PDF com texto extraível, TXT, CSV ou cole o conteúdo. O PULSE tenta reconhecer formatos variados e sempre mostra uma revisão.',
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

class _FormatGuideSection extends StatelessWidget {
  const _FormatGuideSection({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
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
    );
  }
}

class _FormatExample extends StatelessWidget {
  const _FormatExample();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'TREINO A — PEITO E TRÍCEPS\n'
        'Supino reto    4    8 a 12\n'
        'Tríceps na polia    3    10 a 12',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          height: 1.45,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _ImportOptionCard extends StatelessWidget {
  const _ImportOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.file_open_outlined),
              label: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}
