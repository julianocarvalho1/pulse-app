import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController(); // Usado apenas no cadastro
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WorkoutProvider>();
      if (provider.usarBiometria && provider.hasPassword) {
        _autenticarPorBiometria();
      }
    });
  }

  Future<void> _autenticarPorBiometria() async {
    setState(() => _isAuthenticating = true);
    bool authenticated = false;
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      if (!canAuthenticate) return;
      authenticated = await auth.authenticate(localizedReason: 'Toque no sensor para acessar o painel');
    } catch (e) {
      debugPrint('Erro na biometria: $e');
    }
    setState(() => _isAuthenticating = false);
    if (authenticated && mounted) {
      _entrarNoApp();
    }
  }

  void _tentarLogin() {
    final provider = context.read<WorkoutProvider>();
    final senhaDigitada = _senhaController.text.trim();

    if (senhaDigitada.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A senha não pode ser vazia!'), backgroundColor: Colors.redAccent));
      return;
    }

    if (provider.login(senhaDigitada)) {
      _entrarNoApp();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha incorreta! Acesso negado.'), backgroundColor: Colors.redAccent));
    }
  }

  void _tentarCadastro() {
    final provider = context.read<WorkoutProvider>();
    final senhaDigitada = _senhaController.text.trim();
    final nomeDigitado = _nomeController.text.trim();

    if (senhaDigitada.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A senha deve ter no mínimo 4 caracteres.'), backgroundColor: Colors.redAccent));
      return;
    }

    provider.registerUser(nomeDigitado, senhaDigitada);
    _entrarNoApp();
  }

  void _entrarNoApp() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final isFirstTime = !provider.hasPassword; // Se não tem senha, é primeiro acesso (ou reset)

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // BRANDING
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.primary, size: 24),
                        const SizedBox(width: 12),
                        const Text('PULSE', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4.0, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60),

                // TEXTOS DINÂMICOS (Muda se for cadastro ou login)
                Text(
                  isFirstTime ? 'CRIAR PERFIL' : 'ACESSO RESTRITO',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary, letterSpacing: 2.0),
                ),
                const SizedBox(height: 8),
                Text(
                  isFirstTime ? 'BEM-VINDO' : (provider.userName.isEmpty ? 'ATLETA' : provider.userName.toUpperCase()),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0),
                ),
                const SizedBox(height: 16),
                Text(
                  isFirstTime ? 'Configure seu nome e crie uma senha para proteger o seu painel de alta performance.' : 'O seu painel de alta performance aguarda.\nConfirme sua identidade para iniciar.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 48),

                // CAMPO DE NOME (Só aparece no primeiro acesso)
                if (isFirstTime) ...[
                  TextField(
                    controller: _nomeController,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Digite o seu nome',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 24),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // CAMPO DE SENHA
                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: isFirstTime ? 'Crie uma senha forte' : '• • • • • •',
                    hintStyle: TextStyle(color: AppColors.textSecondary, letterSpacing: isFirstTime ? 1.0 : 4.0),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 24),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
                  ),
                ),
                const SizedBox(height: 24),

                // BOTÃO PRINCIPAL
                ElevatedButton(
                  onPressed: isFirstTime ? _tentarCadastro : _tentarLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isFirstTime ? 'COMEÇAR A TREINAR' : 'DESBLOQUEAR PAINEL', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      const SizedBox(width: 8),
                      Icon(isFirstTime ? Icons.arrow_forward : Icons.lock_open, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // BIOMETRIA (Só aparece no Login)
                if (!isFirstTime && provider.usarBiometria)
                  Column(
                    children: [
                      const Text('OU', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _isAuthenticating ? null : _autenticarPorBiometria,
                        icon: Icon(Icons.fingerprint, color: Theme.of(context).colorScheme.primary, size: 28),
                        label: Text(
                          _isAuthenticating ? 'VERIFICANDO...' : 'USAR IMPRESSÃO DIGITAL',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.0),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
  }
}