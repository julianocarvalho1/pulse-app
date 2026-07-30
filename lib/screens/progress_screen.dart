import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../features/workouts/domain/models/workout_history_item.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_line_chart.dart';
import 'workout_history_detail_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _tab = 0;
  final List<String> _tabs = const [
    'Consistência',
    'Treinos',
    'Medidas',
    'Desempenho',
  ];

  Map<String, double> _medidas = {
    'Peso': 0.0,
    'Ombros': 0.0,
    'Tórax': 0.0,
    'Cintura': 0.0,
    'Quadril': 0.0,
    'Braço Esq.': 0.0,
    'Braço Dir.': 0.0,
    'Antebraço Esq.': 0.0,
    'Antebraço Dir.': 0.0,
    'Coxa Esq.': 0.0,
    'Coxa Dir.': 0.0,
    'Panturrilha Esq.': 0.0,
    'Panturrilha Dir.': 0.0,
  };

  String _medidaSelecionadaParaGrafico = 'Peso';

  String _periodoMedidas = '6 meses';
  String _periodoGeral = '6 meses';
  final List<String> _opcoesDePeriodo = [
    '1 mês',
    '3 meses',
    '6 meses',
    '1 ano',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROGRESSO',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),

          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              separatorBuilder: (context, index) => const SizedBox(width: 20),
              itemBuilder: (context, i) => _tabItem(_tabs[i], i),
            ),
          ),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 20),

          _buildTabContent(),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tab) {
      case 1:
        return _buildTreinos(context);
      case 2:
        return _buildMedidas(context);
      case 3:
        return _buildDesempenho(context);
      case 0:
      default:
        return _buildConsistencia(context);
    }
  }

  Widget _buildConsistencia(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final history = provider.history;
    final now = DateTime.now();

    final treinosEsteMes = history
        .where((h) => h.date.month == now.month && h.date.year == now.year)
        .toList();

    int totalTreinos = treinosEsteMes.length;
    int totalMinutos = 0;
    double volumeTotal = 0;

    for (var t in treinosEsteMes) {
      final partes = t.duration.split(':');
      if (partes.length == 3) {
        totalMinutos +=
            (int.tryParse(partes[0]) ?? 0) * 60 +
            (int.tryParse(partes[1]) ?? 0);
      } else if (partes.length == 2) {
        totalMinutos += int.tryParse(partes[0]) ?? 0;
      }

      for (var ex in t.exercises) {
        for (var set in ex.sets) {
          volumeTotal += set.reps * set.weight;
        }
      }
    }

    int calorias = totalMinutos * 7;
    int horas = totalMinutos ~/ 60;
    int minsRestantes = totalMinutos % 60;
    String duracaoStr = horas > 0
        ? '${horas}h ${minsRestantes}m'
        : '${minsRestantes}m';
    String volumeStr = volumeTotal >= 1000
        ? '${(volumeTotal / 1000).toStringAsFixed(1)} ton'
        : '${volumeTotal.toStringAsFixed(0)} kg';

    double pesoAtual = _medidas['Peso'] ?? 0.0;
    String pesoStr = pesoAtual > 0
        ? '${pesoAtual.toStringAsFixed(1)} kg'
        : '-- kg';
    String subtituloPeso = pesoAtual > 0
        ? 'Atualizado recentemente'
        : 'Atualize seu peso nas Medidas';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCalendarioCheckin(context, history, now),

        const SizedBox(height: 24),
        const Text(
          'METAS E ESTATÍSTICAS (ESTE MÊS)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _statCard(
                Icons.fitness_center,
                totalTreinos.toString(),
                'Treinos',
                'Meta: 20',
                totalTreinos / 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                Icons.access_time,
                duracaoStr,
                'Duração',
                'Meta: 20h',
                (horas + (minsRestantes / 60)) / 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                Icons.local_fire_department,
                calorias.toString(),
                'Calorias',
                'Meta: 8.000',
                calorias / 8000,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                Icons.bar_chart,
                volumeStr,
                'Volume',
                'Meta: 50 ton',
                volumeTotal / 50000,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'EVOLUÇÃO DE PESO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),

                  PopupMenuButton<String>(
                    color: AppColors.surfaceLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onSelected: (String resultado) {
                      setState(() {
                        _periodoGeral = resultado;
                      });
                    },
                    itemBuilder: (BuildContext context) {
                      return _opcoesDePeriodo.map((String opcao) {
                        return PopupMenuItem<String>(
                          value: opcao,
                          child: Text(
                            opcao,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Últimos $_periodoGeral',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                pesoStr,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtituloPeso,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              MiniLineChart(
                values: _gerarDadosSimulados('Peso', _periodoGeral),
                height: 120,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarioCheckin(
    BuildContext context,
    List<WorkoutHistoryItem> history,
    DateTime now,
  ) {
    const meses = [
      'JANEIRO',
      'FEVEREIRO',
      'MARÇO',
      'ABRIL',
      'MAIO',
      'JUNHO',
      'JULHO',
      'AGOSTO',
      'SETEMBRO',
      'OUTUBRO',
      'NOVEMBRO',
      'DEZEMBRO',
    ];
    final mesAtualStr = meses[now.month - 1];

    final int diasNoMes = DateUtils.getDaysInMonth(now.year, now.month);
    final int primeiroDiaDaSemana = DateTime(now.year, now.month, 1).weekday;

    final int deslocamento = primeiroDiaDaSemana == 7 ? 0 : primeiroDiaDaSemana;
    final int totalCelulas = diasNoMes + deslocamento;
    final int linhas = (totalCelulas / 7).ceil();

    Set<int> diasTreinados = {};
    for (var h in history) {
      if (h.date.year == now.year && h.date.month == now.month) {
        diasTreinados.add(h.date.day);
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$mesAtualStr ${now.year}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${diasTreinados.length} TREINOS',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
                .map(
                  (dia) => SizedBox(
                    width: 32,
                    child: Center(
                      child: Text(
                        dia,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 7 * linhas,
            itemBuilder: (context, index) {
              if (index < deslocamento || index >= deslocamento + diasNoMes) {
                return const SizedBox();
              }

              int diaCorrente = index - deslocamento + 1;
              bool treinou = diasTreinados.contains(diaCorrente);
              bool ehHoje = diaCorrente == now.day;

              return Container(
                decoration: BoxDecoration(
                  color: treinou
                      ? Theme.of(context).colorScheme.primary
                      : (ehHoje ? AppColors.surfaceLight : Colors.transparent),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ehHoje && !treinou
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    diaCorrente.toString(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: treinou || ehHoje
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: treinou
                          ? Colors.black
                          : (ehHoje
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMedidas(BuildContext context) {
    String labelInicio = 'Início';
    String labelMeio = 'Meio';
    if (_periodoMedidas == '1 mês') {
      labelInicio = 'Semana 1';
      labelMeio = 'Semana 2';
    }
    if (_periodoMedidas == '3 meses') {
      labelInicio = 'Mês -3';
      labelMeio = 'Mês -1';
    }
    if (_periodoMedidas == '6 meses') {
      labelInicio = 'Semestre ant.';
      labelMeio = 'Trimestre ant.';
    }
    if (_periodoMedidas == '1 ano') {
      labelInicio = 'Ano passado';
      labelMeio = 'Semestre ant.';
    }

    double valorAtual = _medidas[_medidaSelecionadaParaGrafico] ?? 0.0;
    String unidade = _medidaSelecionadaParaGrafico == 'Peso' ? 'kg' : 'cm';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ÚLTIMA AVALIAÇÃO: ${DateFormat('dd/MM').format(DateTime.now())}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            TextButton.icon(
              onPressed: _abrirEditorMedidas,
              icon: Icon(
                Icons.add,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: Text(
                'ATUALIZAR',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildMedidasRow('Peso', 'Ombros'),
        _buildMedidasRow('Tórax', 'Cintura'),
        _buildMedidasRow('Quadril', 'Panturrilha Esq.'),
        _buildMedidasRow('Braço Esq.', 'Braço Dir.'),
        _buildMedidasRow('Antebraço Esq.', 'Antebraço Dir.'),
        _buildMedidasRow('Coxa Esq.', 'Coxa Dir.'),

        const SizedBox(height: 16),

        const Text(
          'EVOLUÇÃO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _medidaSelecionadaParaGrafico,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  PopupMenuButton<String>(
                    color: AppColors.surfaceLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onSelected: (String resultado) {
                      setState(() {
                        _periodoMedidas = resultado;
                      });
                    },
                    itemBuilder: (BuildContext context) {
                      return _opcoesDePeriodo.map((String opcao) {
                        return PopupMenuItem<String>(
                          value: opcao,
                          child: Text(
                            opcao,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Últimos $_periodoMedidas',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              Text(
                valorAtual > 0
                    ? 'Último registro: $valorAtual $unidade'
                    : 'Sem registros na ficha',
                style: TextStyle(
                  fontSize: 14,
                  color: valorAtual == 0
                      ? AppColors.textSecondary
                      : Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              MiniLineChart(
                values: _gerarDadosSimulados(
                  _medidaSelecionadaParaGrafico,
                  _periodoMedidas,
                ),
                height: 120,
              ),

              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    labelInicio,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    labelMeio,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Text(
                    'Hoje',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<double> _gerarDadosSimulados(String medida, String periodo) {
    double valorAtual = _medidas[medida] ?? 0.0;
    if (valorAtual == 0.0) return [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

    int pontos = 7;
    if (periodo == '1 mês') pontos = 4;
    if (periodo == '3 meses') pontos = 6;
    if (periodo == '1 ano') pontos = 12;

    List<double> dados = [];
    for (int i = pontos - 1; i >= 0; i--) {
      if (medida == 'Cintura' || medida == 'Peso') {
        dados.add(valorAtual + (i * 0.3));
      } else {
        dados.add(valorAtual - (i * 0.3));
      }
    }
    return dados;
  }

  Widget _buildMedidasRow(String m1, String m2) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: _medidaCard(
              m1,
              '${_medidas[m1]} ${m1 == 'Peso' ? 'kg' : 'cm'}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _medidaCard(
              m2,
              '${_medidas[m2]} ${m2 == 'Peso' ? 'kg' : 'cm'}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _medidaCard(String label, String value) {
    bool isSelected = _medidaSelecionadaParaGrafico == label;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() {
              _medidaSelecionadaParaGrafico = label;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _abrirEditorMedidas() {
    final controllers = _medidas.map(
      (key, value) => MapEntry(
        key,
        TextEditingController(text: value == 0.0 ? '' : value.toString()),
      ),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Atualizar Medidas',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _medidas.keys.map((key) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: controllers[key],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: '$key (${key == 'Peso' ? 'kg' : 'cm'})',
                      labelStyle: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              setState(() {
                for (var key in _medidas.keys) {
                  String txt = controllers[key]!.text.replaceAll(',', '.');
                  if (txt.isNotEmpty) {
                    _medidas[key] = double.tryParse(txt) ?? _medidas[key]!;
                  }
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text(
              'SALVAR',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreinos(BuildContext context) {
    final history = context.watch<WorkoutProvider>().history;

    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: const [
            Icon(Icons.history, size: 48, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'Nenhum treino registrado.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Finalize uma sessão de treino para que ela apareça aqui no seu histórico.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = history[index];
        final dataFormatada = DateFormat("dd/MM/yyyy").format(item.date);

        return Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 28,
            ),
          ),
          onDismissed: (direction) {
            context.read<WorkoutProvider>().deleteHistoryItem(item.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Treino excluído do histórico!'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Material(
            color:
                Colors.transparent, // Deixa a cor do Container brilhar por trás
            child: InkWell(
              borderRadius: BorderRadius.circular(
                14,
              ), // Respeita a borda arredondada
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WorkoutHistoryDetailScreen(workout: item),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface, // O fundo agora fica aqui
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.routineName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dataFormatada,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.duration,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.totalExercises} exercícios',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesempenho(BuildContext context) {
    final history = context.watch<WorkoutProvider>().history;

    Map<String, Map<String, dynamic>> personalRecords = {};

    for (var workout in history) {
      for (var exercise in workout.exercises) {
        for (var set in exercise.sets) {
          if (set.weight > 0) {
            final currentRecord = personalRecords[exercise.exerciseName];

            if (currentRecord == null || set.weight > currentRecord['weight']) {
              personalRecords[exercise.exerciseName] = {
                'weight': set.weight,
                'date': workout.date,
              };
            }
          }
        }
      }
    }

    final prList = personalRecords.entries.toList();
    prList.sort((a, b) => b.value['weight'].compareTo(a.value['weight']));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECORDES PESSOAIS (PR)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Suas maiores cargas registradas. Continue superando seus limites!',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        if (prList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: const [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhum recorde ainda.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'Conclua treinos registrando os pesos utilizados para que seus recordes apareçam aqui automaticamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          )
        else
          ...prList.map((record) {
            final exerciseName = record.key;
            final weight = record.value['weight'] as double;
            final date = record.value['date'] as DateTime;

            String weightStr = weight % 1 == 0
                ? weight.toStringAsFixed(0)
                : weight.toStringAsFixed(1);
            String dateStr = DateFormat("dd MMM").format(date);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events, color: Colors.amber),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exerciseName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Alcançado em $dateStr',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$weightStr kg',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _tabItem(String label, int index) {
    final active = _tab == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _statCard(
    IconData icon,
    String value,
    String label,
    String sub,
    double progress,
  ) {
    double safeProgress = progress > 1.0 ? 1.0 : progress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: safeProgress,
              backgroundColor: AppColors.surfaceLight,
              color: Theme.of(context).colorScheme.primary,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            sub,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
