import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    // Paleta de Cores Premium para Fitness
    final List<Map<String, dynamic>> premiumColors = [
      {'name': 'Ciano', 'color': const Color(0xFF00E5FF)},
      {'name': 'Verde Neon', 'color': const Color(0xFF00E676)},
      {'name': 'Laranja', 'color': const Color(0xFFFF3D00)},
      {'name': 'Amarelo', 'color': const Color(0xFFFFEA00)},
      {'name': 'Vermelho', 'color': const Color(0xFFFF1744)},
      {'name': 'Rosa', 'color': const Color(0xFFF50057)},
      {'name': 'Roxo Cyber', 'color': const Color(0xFFD500F9)},
      {'name': 'Azul Puro', 'color': const Color(0xFF2979FF)},
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Configurações', style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('COR DO APLICATIVO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.0)),
            const SizedBox(height: 16),

            // O SELETOR DE CORES
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: premiumColors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final colorInfo = premiumColors[index];
                  final Color c = colorInfo['color'];
                  final bool isSelected = themeProvider.primaryColor.value == c.value;

                  return GestureDetector(
                    onTap: () => themeProvider.setPrimaryColor(c),
                    child: Container(
                      width: 50,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)
                        ] : [],
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.black) : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            const Text('CONTA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.0)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                ),
                title: const Text('Alterar Nome', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                onTap: () {
                  final txt = TextEditingController(text: provider.userName);
                  showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text('Seu Nome', style: TextStyle(color: Colors.white)),
                        content: TextField(
                          controller: txt,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                          ),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.black),
                              onPressed: () {
                                provider.setUserName(txt.text);
                                Navigator.pop(ctx);
                              },
                              child: const Text('Salvar')
                          )
                        ],
                      )
                  );
                },
              ),
            ),

            const SizedBox(height: 32),
            const Text('SISTEMA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.0)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.fingerprint, color: Colors.white),
                    title: const Text('Usar Biometria', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Switch(
                      value: provider.usarBiometria,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) {
                        provider.toggleBiometria(val);
                      },
                    ),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                    title: const Text('Apagar Todos os Dados', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            title: const Text('Tem Certeza?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            content: const Text('Isso apagará todo o seu histórico, fichas e medidas. Não tem volta!', style: TextStyle(color: AppColors.textSecondary)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                  onPressed: () {
                                    provider.factoryReset();
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                                            (route) => false
                                    );
                                  },
                                  child: const Text('Apagar Tudo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                              )
                            ],
                          )
                      );
                    },
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