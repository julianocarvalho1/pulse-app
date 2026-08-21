import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class PrivacyAiInfoScreen extends StatelessWidget {
  const PrivacyAiInfoScreen({super.key});

  static final Uri _privacyPolicy = Uri.parse(
    'https://julianocarvalho1.github.io/pulse-app/politica-de-privacidade/',
  );

  static final Uri _supportEmail = Uri(
    scheme: 'mailto',
    path: 'pulse.appp@gmail.com',
    queryParameters: <String, String>{
      'subject': 'Suporte ou resposta do Assistente PULSE',
    },
  );

  Future<void> _openSupportEmail(BuildContext context) async {
    final opened = await launchUrl(_supportEmail);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o aplicativo de e-mail.'),
        ),
      );
    }
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final opened = await launchUrl(
      _privacyPolicy,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir a política de privacidade.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacidade e assistência'),
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
          _hero(context),
          const SizedBox(height: 16),
          const _InfoCard(
            icon: Icons.phone_android_rounded,
            title: 'Dados armazenados no aparelho',
            body:
                'Treinos, histórico, medidas, preferências e foto de perfil ficam salvos localmente. Nesta versão, o PULSE não cria uma conta na nuvem nem sincroniza automaticamente entre aparelhos.',
          ),
          const SizedBox(height: 12),
          const _InfoCard(
            icon: Icons.auto_awesome_rounded,
            title: 'Como o Assistente PULSE funciona',
            body:
                'Com internet, o aplicativo pode enviar ao serviço online apenas a estrutura técnica necessária para responder: exercícios, séries, repetições e descanso. Nome, foto, observações livres, anotações de saúde e métricas de progresso não são incluídos. A análise de progresso é feita no aparelho.',
          ),
          const SizedBox(height: 12),
          const _InfoCard(
            icon: Icons.flag_outlined,
            title: 'Controle de uso e relatos',
            body:
                'Uma identificação aleatória da instalação limita o uso da cota online sem criar uma conta. Você pode relatar problemas nas respostas online dentro do próprio assistente; a resposta, o motivo e o comentário opcional são registrados para análise.',
          ),
          const SizedBox(height: 12),
          const _InfoCard(
            icon: Icons.offline_bolt_rounded,
            title: 'Resposta local de reserva',
            body:
                'Sem internet ou quando o serviço online não estiver disponível, o PULSE continua funcionando com uma resposta rápida gerada no próprio aparelho.',
          ),
          const SizedBox(height: 12),
          const _InfoCard(
            icon: Icons.health_and_safety_outlined,
            title: 'Limites das orientações',
            body:
                'As respostas são informativas. O PULSE não diagnostica lesões, não prescreve tratamento e não substitui médico, fisioterapeuta, nutricionista ou profissional de educação física. Interrompa a atividade diante de dor aguda, tontura ou mal-estar.',
          ),
          const SizedBox(height: 12),
          const _InfoCard(
            icon: Icons.rule_rounded,
            title: 'Você mantém o controle',
            body:
                'O Assistente PULSE não altera uma ficha sem confirmação. Substituições são limitadas à biblioteca do aplicativo e devem ser revisadas antes de serem aplicadas.',
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _openSupportEmail(context),
            icon: const Icon(Icons.mail_outline_rounded),
            label: const Text('Falar com o suporte'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _openPrivacyPolicy(context),
            icon: const Icon(Icons.privacy_tip_outlined),
            label: const Text('Ler política de privacidade'),
          ),
          const SizedBox(height: 10),
          Text(
            'Contato: pulse.appp@gmail.com',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Transparência sem complicação',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Veja o que fica no aparelho, o que pode ser processado online e quais são os limites do Assistente PULSE.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
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
              icon,
              size: 21,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
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
