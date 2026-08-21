import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HowToUseScreen extends StatefulWidget {
  const HowToUseScreen({super.key});

  @override
  State<HowToUseScreen> createState() => _HowToUseScreenState();
}

class _HowToUseScreenState extends State<HowToUseScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const List<_GuideStep> _steps = <_GuideStep>[
    _GuideStep(
      icon: Icons.home_rounded,
      title: 'Comece pela tela Hoje',
      description:
          'A tela inicial reúne o próximo treino, os atalhos de registro e um resumo rápido da sua semana.',
      items: <String>[
        'Toque em Iniciar treino para abrir a próxima ficha do programa.',
        'Use Cardio, Treino dinâmico ou Atividade livre quando o dia fugir do planejado.',
        'Confira a atividade recente para confirmar se o registro foi salvo.',
      ],
      tip:
          'O PULSE mantém a próxima ficha mesmo quando uma atividade livre substitui o treino do dia.',
    ),
    _GuideStep(
      icon: Icons.fitness_center_rounded,
      title: 'Crie, importe ou compartilhe fichas',
      description:
          'Na aba Treinos, você organiza programas e fichas sem precisar montar tudo do zero.',
      items: <String>[
        'Crie uma ficha manualmente ou gere um programa inteligente.',
        'Importe a ficha do personal por texto, documento ou arquivo do PULSE.',
        'Compartilhe fichas por arquivo ou QR Code com outro usuário.',
      ],
      tip:
          'Revise exercícios, séries e descansos antes de iniciar uma ficha importada.',
    ),
    _GuideStep(
      icon: Icons.timer_rounded,
      title: 'Registre o treino série por série',
      description:
          'Durante a sessão, informe carga e repetições e conclua cada série no próprio exercício.',
      items: <String>[
        'O cronômetro automático começa ao concluir uma série.',
        'Use as orientações de RIR, cadência e técnica quando estiverem cadastradas.',
        'Salve como incompleto se precisar encerrar antes do fim.',
      ],
      tip:
          'Registrar as cargas com consistência deixa o histórico e as análises mais úteis.',
    ),
    _GuideStep(
      icon: Icons.directions_run_rounded,
      title: 'Registre atividades fora da ficha',
      description:
          'CrossFit, Pilates, funcional, dança, yoga e esportes também podem entrar no seu histórico.',
      items: <String>[
        'Escolha Atividade livre na tela Hoje.',
        'Informe duração, intensidade e uma observação opcional.',
        'Marque quando a atividade substituiu o treino planejado daquele dia.',
      ],
      tip:
          'A atividade conta como dia ativo, mas não marca uma ficha de musculação como concluída.',
    ),
    _GuideStep(
      icon: Icons.insights_rounded,
      title: 'Acompanhe o progresso',
      description:
          'A aba Progresso separa consistência, treinos, medidas e desempenho para facilitar a leitura.',
      items: <String>[
        'Mude o período para comparar semanas ou meses.',
        'Use o calendário para localizar treinos, cardio e atividades livres.',
        'Abra Analisar meu progresso para receber uma leitura resumida do período.',
      ],
      tip:
          'Aderência à ficha e consistência geral são informações diferentes — o PULSE mostra as duas.',
    ),
    _GuideStep(
      icon: Icons.auto_awesome_rounded,
      title: 'Use o Assistente PULSE',
      description:
          'O assistente ajuda a entender fichas, exercícios, substituições e tendências registradas.',
      items: <String>[
        'Com internet, a resposta pode ser mais detalhada e contextual.',
        'Sem conexão, o PULSE gera uma resposta rápida no próprio aparelho.',
        'Nenhuma substituição é aplicada sem sua confirmação.',
      ],
      tip:
          'As respostas são informativas e não substituem orientação profissional ou avaliação médica.',
    ),
    _GuideStep(
      icon: Icons.shield_outlined,
      title: 'Proteja seus dados',
      description:
          'Os registros ficam no aparelho e podem ser exportados para um backup do PULSE.',
      items: <String>[
        'Ative a proteção por biometria nas Configurações, quando disponível.',
        'Crie backups periódicos antes de trocar de aparelho ou reinstalar o app.',
        'Guarde o arquivo de backup em um local seguro e de fácil acesso.',
      ],
      tip:
          'O PULSE não possui conta na nuvem nesta versão; o backup é a sua cópia de segurança.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goTo(int index) async {
    await _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _steps.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Como usar'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'GUIA RÁPIDO',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Text(
                    '${_page + 1} de ${_steps.length}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  value: (_page + 1) / _steps.length,
                  backgroundColor: AppColors.surfaceLight,
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _steps.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) =>
                    _GuidePage(step: _steps[index]),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                MediaQuery.paddingOf(context).bottom + 14,
              ),
              child: Row(
                children: <Widget>[
                  if (_page > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _goTo(_page - 1),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Anterior'),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isLast
                          ? () => Navigator.pop(context)
                          : () => _goTo(_page + 1),
                      icon: Icon(
                        isLast
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                      label: Text(isLast ? 'Concluir' : 'Próximo'),
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

class _GuidePage extends StatelessWidget {
  const _GuidePage({required this.step});

  final _GuideStep step;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Icon(
              step.icon,
              size: 34,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            step.title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 25,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            step.description,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: step.items.indexed
                  .map((entry) {
                    final itemIndex = entry.$1;
                    final text = entry.$2;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: itemIndex == step.items.length - 1 ? 0 : 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: 27,
                            height: 27,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${itemIndex + 1}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              text,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    step.tip,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
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

class _GuideStep {
  const _GuideStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.items,
    required this.tip,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<String> items;
  final String tip;
}
