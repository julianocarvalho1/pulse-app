import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _editarPerfil(BuildContext context) {
    final provider = context.read<WorkoutProvider>();
    final nameController = TextEditingController(
      text: provider.userName == 'Atleta' ? '' : provider.userName,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nome de Exibição', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Como quer ser chamado?',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.black),
            onPressed: () {
              provider.setUserName(nameController.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Nome atualizado!'), backgroundColor: Theme.of(context).colorScheme.primary),
              );
            },
            child: const Text('Salvar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // NOVO: DIÁLOGO PARA REGISTRO DE PESO CORPORAL
  // ==========================================
  void _editarPesoCorporal(BuildContext context) {
    final provider = context.read<WorkoutProvider>();
    final weightController = TextEditingController(
      text: provider.userWeight > 0 ? provider.userWeight.toStringAsFixed(1) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Peso Corporal (kg)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'Ex: 78.5',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            suffixText: 'kg',
            suffixStyle: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.black),
            onPressed: () {
              double parsedWeight = double.tryParse(weightController.text.replaceAll(',', '.')) ?? 0.0;
              provider.setUserWeight(parsedWeight);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Peso registrado com sucesso!'), backgroundColor: Theme.of(context).colorScheme.primary),
              );
            },
            child: const Text('Salvar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _iniciarRestauracao(BuildContext context) async {
    final provider = context.read<WorkoutProvider>();
    bool autenticadoPorBiometria = false;

    if (provider.usarBiometria) {
      final LocalAuthentication auth = LocalAuthentication();
      try {
        final bool podeAutenticar = await auth.canCheckBiometrics || await auth.isDeviceSupported();

        if (podeAutenticar) {
          autenticadoPorBiometria = await auth.authenticate(
            localizedReason: 'Confirme sua identidade para apagar todos os dados',
          );
        }
      } on PlatformException catch (e) {
        debugPrint('Erro ao chamar biometria: $e');
      }
    }

    if (!context.mounted) return;

    if (autenticadoPorBiometria) {
      await provider.factoryReset();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aplicativo restaurado com sucesso!'), backgroundColor: Colors.redAccent),
        );
      }
    } else {
      _showPasswordResetDialog(context);
    }
  }

  void _showPasswordResetDialog(BuildContext context) {
    final senhaController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Restaurar Aplicativo?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Isso apagará todo o histórico e fichas criadas. Confirme com sua senha do aplicativo.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: senhaController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Digite sua senha',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              final provider = context.read<WorkoutProvider>();
              final senhaDigitada = senhaController.text.trim();

              if (senhaDigitada.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Digite sua senha para confirmar.'), backgroundColor: Colors.redAccent),
                );
                return;
              }

              if (provider.login(senhaDigitada)) {
                await provider.factoryReset();
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Aplicativo restaurado com sucesso!'), backgroundColor: Colors.redAccent),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Senha incorreta! Acesso negado.'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text('Apagar Tudo', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Configurações', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: Icon(Icons.badge, color: Theme.of(context).colorScheme.primary),
            title: const Text('Alterar Nome de Exibição', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(provider.userName.isEmpty ? 'Atleta' : provider.userName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () => _editarPerfil(context),
          ),
          const Divider(color: AppColors.border),

          // NOVO OPÇÃO: REGISTRO E DADO PERSISTENTE DO PESO CORPORAL
          ListTile(
            leading: Icon(Icons.monitor_weight_outlined, color: Theme.of(context).colorScheme.primary),
            title: const Text('Peso Corporal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              provider.userWeight > 0 ? '${provider.userWeight.toStringAsFixed(1)} kg' : 'Não registrado',
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () => _editarPesoCorporal(context),
          ),
          const Divider(color: AppColors.border),

          ListTile(
            leading: Icon(Icons.fingerprint, color: Theme.of(context).colorScheme.primary),
            title: const Text('Bloqueio por Biometria', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            trailing: Switch(
              value: provider.usarBiometria,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (val) {
                provider.toggleBiometria(val);
              },
            ),
          ),
          const Divider(color: AppColors.border),

          const SizedBox(height: 60),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.redAccent),
              ),
              elevation: 0,
            ),
            onPressed: () => _iniciarRestauracao(context),
            icon: const Icon(Icons.delete_forever),
            label: const Text('RESTAURAR TODOS OS DADOS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.0)),
          ),
        ],
      ),
    );
  }
}