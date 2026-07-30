import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';

import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  bool _isAuthenticating = false;
  bool _biometriaJaTentada =
      false; // Flag para não ficar chamando a biometria em loop

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<WorkoutProvider>();

    // A INTELIGÊNCIA AQUI: Só tenta a biometria DEPOIS que o app descobrir se tem senha salva
    if (provider.usarBiometria &&
        provider.hasPassword &&
        !_biometriaJaTentada) {
      _biometriaJaTentada = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autenticarPorBiometria();
      });
    }
  }

  Future<void> _autenticarPorBiometria() async {
    if (!mounted || _isAuthenticating) {
      return;
    }

    setState(() => _isAuthenticating = true);

    bool authenticated = false;

    try {
      final canCheckBiometrics = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();

      if (canCheckBiometrics || isDeviceSupported) {
        authenticated = await auth.authenticate(
          localizedReason: 'Toque no sensor para acessar o painel',
        );
      }
    } catch (error) {
      debugPrint('Erro na biometria: $error');
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }

    if (!mounted || !authenticated) {
      return;
    }

    context.read<WorkoutProvider>().authenticateWithBiometrics();
  }

  void _tentarLogin() {
    final provider = context.read<WorkoutProvider>();
    final senhaDigitada = _senhaController.text.trim();

    if (senhaDigitada.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A senha não pode ser vazia!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final loginRealizado = provider.login(senhaDigitada);

    if (!loginRealizado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha incorreta! Acesso negado.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _tentarCadastro() {
    final provider = context.read<WorkoutProvider>();
    final senhaDigitada = _senhaController.text.trim();
    final nomeDigitado = _nomeController.text.trim();

    if (senhaDigitada.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A senha deve ter no mínimo 4 caracteres.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    provider.registerUser(nomeDigitado, senhaDigitada);
  }

  @override
  void dispose() {
    _senhaController.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final isFirstTime = !provider.hasPassword;

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
                // BRANDING COM LOGO OFICIAL
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/icon.png',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.fitness_center,
                            color: Colors.black,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'PULSE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 48),

                // TEXTOS DINÂMICOS
                Text(
                  isFirstTime ? 'CRIAR PERFIL' : 'ACESSO RESTRITO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isFirstTime
                      ? 'BEM-VINDO'
                      : (provider.userName.isEmpty
                            ? 'ATLETA'
                            : provider.userName.toUpperCase()),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isFirstTime
                      ? 'Configure seu nome e crie uma senha para proteger o seu painel de alta performance.'
                      : 'O seu painel de evolução aguarda.\nConfirme sua identidade para acessar.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // CAMPO DE NOME (Com "Crachá" Key)
                if (isFirstTime) ...[
                  TextField(
                    key: const ValueKey('campo_nome'),
                    controller: _nomeController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Como quer ser chamado?',
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 24),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // CAMPO DE SENHA (Com "Crachá" Key)
                TextField(
                  key: const ValueKey('campo_senha'),
                  controller: _senhaController,
                  obscureText: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: isFirstTime
                        ? 'Crie uma senha forte'
                        : '• • • • • •',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      letterSpacing: isFirstTime ? 1.0 : 4.0,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 24),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isFirstTime
                            ? 'COMEÇAR A TREINAR'
                            : 'DESBLOQUEAR PAINEL',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isFirstTime ? Icons.arrow_forward : Icons.lock_open,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // BIOMETRIA (Só aparece no Login)
                if (!isFirstTime && provider.usarBiometria)
                  Column(
                    children: [
                      const Text(
                        'OU',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _isAuthenticating
                            ? null
                            : _autenticarPorBiometria,
                        icon: Icon(
                          Icons.fingerprint,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        label: Text(
                          _isAuthenticating
                              ? 'VERIFICANDO...'
                              : 'USAR IMPRESSÃO DIGITAL',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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
