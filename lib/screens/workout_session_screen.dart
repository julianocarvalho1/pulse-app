import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';
import 'exercises_screen.dart';

class SessionStateCache {
  static Map<int, List<bool>> setsStatus = {};
  static Map<int, List<String>> weights = {};
  static Map<int, List<String>> reps = {};

  static void clear() {
    setsStatus.clear();
    weights.clear();
    reps.clear();
  }
}

class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({super.key});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  final Map<int, List<TextEditingController>> _weightControllers = {};
  final Map<int, List<TextEditingController>> _repsControllers = {};
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (var controllers in _weightControllers.values) {
      for (var c in controllers) c.dispose();
    }
    for (var controllers in _repsControllers.values) {
      for (var c in controllers) c.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  int _getSetsCount(String repsString) {
    final parts = repsString.toLowerCase().split('x');
    if (parts.length > 1) {
      return int.tryParse(parts[0].trim()) ?? 3;
    }
    final match = RegExp(r'\d+').firstMatch(repsString);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 3;
    }
    return 3;
  }

  String _getSmartTarget(String repsString, int setIndex) {
    String target = repsString.toLowerCase();
    if (target.contains('x')) {
      target = target.split('x').last.trim();
    }

    if (target.contains('-')) {
      List<String> parts = target.split('-');
      int setsCount = _getSetsCount(repsString);
      if (parts.length == setsCount && setIndex < parts.length) {
        return parts[setIndex].trim();
      }
    }
    return target;
  }

  String _getImagePath(String exerciseName) {
    String cleanName = exerciseName.toLowerCase().trim();
    final Map<String, String> aliases = {
      'crucifixo com halteres': 'crucifixo_reto',
      'crucifixo maquina': 'peck_deck_voador',
      'encolhimento no smith': 'encolhimento_na_barra_smith',
      'elevacao frontal com barra': 'elevacao_frontal_com_barra_anilha',
      'pull-down na polia': 'pull_down_na_polia',
      'passada / afundo': 'passada_afundo',
      'puxada na frente': 'puxada_frontal_aberta',
      'remada curvada': 'remada_curvada_com_barra',
      'rosca direta': 'rosca_direta_com_barra',
      'agachamento': 'agachamento_livre',
      'leg press': 'leg_press_45',
      'cadeira extensora': 'cadeira_extensora',
      'crunch abdominal': 'abdominal_supra',
      'rosca scott': 'rosca_scott_maquina_livre',
      'desenvolvimento militar': 'desenvolvimento_com_barra',
      'chest press': 'supino_reto_com_barra',
      'remada sentada': 'remada_baixa_sentada',
      'remada baixa': 'remada_baixa_sentada',
    };
    String nameForAlias = cleanName
        .replaceAll(RegExp(r'[áàâã]'), 'a')
        .replaceAll(RegExp(r'[éèê]'), 'e')
        .replaceAll(RegExp(r'[íìî]'), 'i')
        .replaceAll(RegExp(r'[óòôõ]'), 'o')
        .replaceAll(RegExp(r'[úùû]'), 'u')
        .replaceAll('ç', 'c');

    if (aliases.containsKey(nameForAlias))
      return 'assets/images/${aliases[nameForAlias]}.gif';

    cleanName = cleanName.replaceAll('-', '_');
    cleanName = cleanName.replaceAll('/', '_');
    cleanName = cleanName.replaceAll(RegExp(r'[áàâã]'), 'a');
    cleanName = cleanName.replaceAll(RegExp(r'[éèê]'), 'e');
    cleanName = cleanName.replaceAll(RegExp(r'[íìî]'), 'i');
    cleanName = cleanName.replaceAll(RegExp(r'[óòôõ]'), 'o');
    cleanName = cleanName.replaceAll(RegExp(r'[úùû]'), 'u');
    cleanName = cleanName.replaceAll('ç', 'c');
    cleanName = cleanName.replaceAll(RegExp(r'[^a-z0-9_\s]'), '');
    cleanName = cleanName.trim().replaceAll(RegExp(r'\s+'), '_');
    cleanName = cleanName.replaceAll('__', '_');
    return 'assets/images/$cleanName.gif';
  }

  Map<String, dynamic> _getDetailedInfo(String id) {
    List<String> steps = [];
    String secondary = '';

    if (id.startsWith('p')) {
      secondary = 'Tríceps Braquial e Deltóide Anterior (Ombro)';
      if (id == 'p1' || id == 'p3' || id == 'p6') {
        steps = [
          'Plante os pés firmemente no chão e mantenha a curvatura natural da lombar.',
          'Retraia as escápulas (junte os ossos das costas) para estufar o peito e proteger os ombros.',
          'Desça a barra controladamente até encostar levemente no peito.',
          'Empurre de forma explosiva, sem esticar (travar) os cotovelos 100% no topo.',
        ];
      } else if (id == 'p2' || id == 'p4') {
        steps = [
          'Use os joelhos para chutar os halteres para a posição inicial.',
          'Mantenha os cotovelos em um ângulo de 45 a 60 graus em relação ao tronco (não abra totalmente em cruz).',
          'Desça até sentir um alongamento profundo no peitoral.',
          'Suba aproximando os halteres, focando em "esmagar" o peito no topo.',
        ];
      } else if (id == 'p7' || id == 'p8' || id == 'p9' || id == 'p13') {
        secondary = 'Deltóide Anterior (Isolamento de Peitoral)';
        steps = [
          'Mantenha os cotovelos com uma leve flexão e "travados" nessa posição durante todo o movimento.',
          'Abra os braços controlando o peso, focando em alongar as fibras do peitoral.',
          'Feche os braços imaginando que está abraçando um tronco de árvore grosso.',
          'Faça uma pausa de 1 segundo na contração máxima (mãos juntas).',
        ];
      } else if (id == 'p10' || id == 'p11') {
        steps = [
          'Incline o tronco levemente para frente mantendo o core contraído.',
          'Puxe os cabos com os cotovelos levemente flexionados.',
          'Cruze levemente as mãos no final do movimento para contração máxima.',
          'Retorne controlando o peso da polia sem deixar que ela puxe seu corpo.',
        ];
      } else {
        steps = [
          'Ajuste o banco ou máquina para alinhar as manoplas com o meio do peito.',
          'Empurre o peso estufando o peito.',
          'Volte controladamente resistindo à carga.',
        ];
      }
    } else if (id.startsWith('c')) {
      secondary = 'Bíceps, Braquial e Músculos do Antebraço';
      if (id == 'c1' || id == 'c2') {
        steps = [
          'Ajuste o rolo de apoio para travar bem as coxas e evitar que o corpo suba.',
          'Pegue na barra, estufe o peito e incline o tronco ligeiramente para trás (cerca de 15 graus).',
          'Inicie o movimento puxando os ombros para baixo e depois traga a barra na direção do peitoral superior.',
          'Suba controlando o peso até alongar as dorsais completamente, sem soltar os ombros no topo.',
        ];
      } else if (id == 'c3' || id == 'c4' || id == 'c7') {
        secondary = 'Lombar (Eretores da Espinha), Bíceps e Trapézio';
        steps = [
          'Mantenha a coluna perfeitamente neutra e o abdômen rígido.',
          'Incline o tronco à frente (entre 45 e 90 graus).',
          'Puxe o peso em direção ao umbigo/quadril, focando em "dar uma cotovelada para trás".',
          'Retorne esticando os braços e sentindo as escápulas se abrirem.',
        ];
      } else if (id == 'c5' || id == 'c6') {
        steps = [
          'Sente-se com postura ereta e pés apoiados.',
          'Puxe a carga retraindo as costas (juntando as escápulas).',
          'Mantenha os cotovelos próximos ao corpo se quiser focar na grande dorsal.',
          'Estique os braços resistindo ao peso da máquina.',
        ];
      } else if (id == 'c9' || id == 'c10') {
        secondary = 'Tríceps (Cabeça Longa) e Ombro Posterior';
        steps = [
          'Mantenha os braços esticados (com mínima flexão no cotovelo).',
          'Puxe a barra/corda até a linha do quadril focando apenas nas costas.',
          'Mantenha o tronco estático; não use o peso do corpo para puxar.',
        ];
      } else {
        steps = [
          'Inicie o movimento contraindo as costas antes de dobrar os braços.',
          'Puxe controladamente.',
          'Alongue na volta.',
        ];
      }
    } else if (id.startsWith('o') || id.startsWith('t')) {
      secondary = 'Tríceps (nos desenvolvimentos) ou Trapézio Superior';
      if (id == 'o1' || id == 'o2' || id == 'o3') {
        steps = [
          'Sente-se com a coluna bem apoiada no banco.',
          'Mantenha os cotovelos levemente à frente da linha dos ombros (plano escapular).',
          'Empurre o peso acima da cabeça até quase esticar os braços.',
          'Desça controladamente até as mãos chegarem na altura do queixo/orelhas.',
        ];
      } else if (id == 'o4' || id == 'o5') {
        secondary = 'Foco em Deltóide Medial (Lateral do Ombro)';
        steps = [
          'Mantenha os cotovelos com uma leve flexão.',
          'Incline o corpo 5 graus para frente.',
          'Eleve os braços focando em liderar o movimento pelo cotovelo (e não pelas mãos).',
          'Suba até a altura dos ombros e desça freando a carga.',
        ];
      } else if (id == 'o8') {
        secondary = 'Rombóides e Trapézio Médio';
        steps = [
          'Incline o tronco para frente até quase 90 graus.',
          'Com os braços semi-esticados, abra os halteres lateralmente e para trás.',
          'Concentre-se em esmagar a parte de trás do ombro, sem usar impulso.',
        ];
      } else if (id.startsWith('t')) {
        secondary = 'Músculos do Pescoço';
        steps = [
          'Segure a carga com os braços relaxados.',
          'Eleve os ombros em direção às orelhas o mais alto possível.',
          'Segure a contração por 1 segundo no topo.',
          'Desça lentamente até alongar o trapézio. Não faça movimentos rotacionais.',
        ];
      } else {
        steps = [
          'Mantenha a postura ereta.',
          'Levante a carga com controle.',
          'Não utilize impulso das costas ou pernas.',
        ];
      }
    } else if (id.startsWith('b')) {
      secondary = 'Músculos Braquiorradiais e Estabilizadores do Punho';
      if (id == 'b1' || id == 'b2' || id == 'b6') {
        steps = [
          'Mantenha os cotovelos absolutamente colados às costelas. Eles não devem ir para frente ou para trás.',
          'Contraia o bíceps subindo a carga até a altura do peito superior.',
          'Evite balançar o tronco (roubar).',
          'Desça a carga até estender o braço (cerca de 95% de extensão).',
        ];
      } else if (id == 'b4' || id == 'b5' || id == 'b9') {
        steps = [
          'Apoie firmemente a axila/tríceps no banco ou coxa.',
          'Foque totalmente na contração, pois o ombro está estabilizado.',
          'Não estique o cotovelo 100% na descida no banco Scott para evitar lesões.',
          'Faça o movimento cadenciado (2 segundos para subir, 3 para descer).',
        ];
      } else if (id == 'b3' || id == 'b7') {
        secondary = 'Braquial Anterior (Gera volume no braço)';
        steps = [
          'Mantenha a pegada neutra (polegares para cima) ou invertida.',
          'Suba a carga mantendo os pulsos travados e retos.',
          'Desça controladamente focando no antebraço.',
        ];
      } else {
        steps = [
          'Trave os cotovelos.',
          'Flexione o braço contraindo o bíceps.',
          'Retorne à posição inicial.',
        ];
      }
    } else if (id.startsWith('tr')) {
      secondary = 'Ombros (como estabilizadores) e Core';
      if (id == 'tr1' || id == 'tr2' || id == 'tr10') {
        steps = [
          'Incline o corpo ligeiramente à frente e flexione um pouco os joelhos.',
          'Trave os cotovelos na linha da cintura.',
          'Empurre o cabo para baixo usando apenas a força do tríceps.',
          'Se usar corda, puxe as pontas para fora no final do movimento para contração extrema.',
        ];
      } else if (id == 'tr3' || id == 'tr4' || id == 'tr5' || id == 'tr6') {
        steps = [
          'Mantenha os cotovelos apontados para o teto ou para frente, o mais fechados possível.',
          'Desça a carga na direção da testa ou nuca.',
          'Estique os braços esmagando o tríceps.',
          'Esse ângulo trabalha intensamente a cabeça longa do tríceps.',
        ];
      } else {
        steps = [
          'Mantenha os braços próximos ao corpo.',
          'Estenda os cotovelos empurrando o peso.',
          'Retorne controlando a fase excêntrica.',
        ];
      }
    } else if (id.startsWith('pe')) {
      if (id == 'pe1' || id == 'pe2' || id == 'pe3') {
        secondary = 'Glúteos, Isquiotibiais, Lombar e Core';
        steps = [
          'Posicione os pés na largura dos ombros com as pontas levemente voltadas para fora.',
          'Mantenha o peito estufado, olhar à frente e respire fundo enrijecendo o abdômen.',
          'Desça como se fosse sentar em uma cadeira invisível, quebrando a paralela se a mobilidade permitir.',
          'Suba fazendo força no calcanhar e na borda externa do pé, sem deixar os joelhos entrarem (valgo).',
        ];
      } else if (id == 'pe4' || id == 'pe5') {
        secondary = 'Glúteos e Isquiotibiais';
        steps = [
          'Apoie perfeitamente a lombar no banco. Se o quadril descolar na descida, a carga ou a descida estão incorretas.',
          'Coloque os pés na plataforma na largura dos ombros.',
          'Desça a máquina até os joelhos ficarem próximos a 90 graus ou tocarem o peito.',
          'Empurre, mas NÃO trave (não estique até travar a articulação) os joelhos no topo para manter a tensão no músculo.',
        ];
      } else if (id == 'pe6' || id == 'pe13' || id == 'pe14') {
        secondary = 'Músculos Estabilizadores da Pelve';
        steps = [
          'Sente-se e ajuste a máquina para que o eixo de rotação fique alinhado com a articulação (joelho ou quadril).',
          'Trave bem as costas no encosto.',
          'Execute o movimento com explosão na ida e freie lentamente na volta.',
          'Evite que as placas de peso batam entre as repetições.',
        ];
      } else if (id == 'pe15') {
        secondary = 'Glúteos, Isquiotibiais e Estabilizadores do Core';
        steps = [
          'Dê um passo largo à frente mantendo o tronco ereto e o olhar para frente.',
          'Desça verticalmente até o joelho de trás quase tocar o chão.',
          'O joelho da frente deve ficar alinhado, sem passar excessivamente da ponta do pé.',
          'Empurre o chão com o calcanhar da perna da frente para retornar (afundo) ou dar o próximo passo (passada).',
        ];
      } else if (id == 'pe7' ||
          id == 'pe8' ||
          id == 'pe9' ||
          id == 'pe10' ||
          id == 'pe11' ||
          id == 'pe19') {
        secondary = 'Lombar, Glúteos e Panturrilhas';
        steps = [
          'No Stiff/Terra: Mantenha as pernas semi-esticadas e desça empurrando o quadril para trás, coluna sempre reta.',
          'Nas Flexoras: Ajuste o rolo na linha do calcanhar.',
          'Puxe/Suba o peso esmagando a parte de trás da coxa.',
          'Desça focando em alongar os isquiotibiais.',
        ];
      } else if (id == 'pe12') {
        secondary = 'Isquiotibiais e Lombar';
        steps = [
          'Apoie as escápulas no banco e posicione os pés de forma que a canela fique vertical no topo do movimento.',
          'Coloque a barra na dobra do quadril.',
          'Empurre o chão com os calcanhares e eleve o quadril até alinhar corpo, joelho e ombros.',
          'Contraia os glúteos com força máxima por 1 segundo no topo.',
        ];
      } else if (id.startsWith('pe16') ||
          id.startsWith('pe17') ||
          id.startsWith('pe18')) {
        secondary = 'Músculos dos Pés e Tornozelos';
        steps = [
          'Apoie a ponta dos pés (metatarsos) no degrau/plataforma.',
          'Desça o calcanhar o máximo possível, alongando a panturrilha por 2 segundos.',
          'Suba até ficar na ponta dos pés, contraindo forte no topo por 1 segundo.',
          'Panturrilhas precisam de alongamento e contração completa para crescer.',
        ];
      } else {
        steps = [
          'Execute o movimento respeitando o limite da sua mobilidade articular.',
          'Mantenha a postura.',
          'Controle a fase de descida.',
        ];
      }
    } else if (id.startsWith('ab')) {
      secondary = 'Músculos do Core e Transverso Abdominal';
      if (id == 'ab5') {
        steps = [
          'Apoie antebraços e pontas dos pés no chão.',
          'Mantenha o corpo em uma linha reta perfeita: não levante o quadril nem deixe a lombar afundar.',
          'Puxe o umbigo para dentro e respire de forma curta.',
          'Contraia glúteos e abdômen intensamente durante todo o tempo.',
        ];
      } else {
        steps = [
          'O segredo do abdômen não é o pescoço: foque em aproximar a linha das costelas da linha do quadril.',
          'Mantenha a lombar travada no chão ou banco.',
          'Suba soltando todo o ar dos pulmões (para maximizar a contração).',
          'Desça inspirando e controlando a descida, sem relaxar o músculo no chão.',
        ];
      }
    } else {
      steps = [
        'Ajuste o equipamento.',
        'Controle o movimento.',
        'Mantenha a respiração constante.',
      ];
      secondary = 'Geral';
    }

    return {'steps': steps, 'secondary': secondary};
  }

  void _initializeSets() {
    final exercises = context.read<WorkoutProvider>().currentWorkoutExercises;
    for (int i = 0; i < exercises.length; i++) {
      if (!SessionStateCache.setsStatus.containsKey(i)) {
        int setsCount = _getSetsCount(exercises[i].reps);
        SessionStateCache.setsStatus[i] = List.generate(
          setsCount,
          (_) => false,
        );
        SessionStateCache.weights[i] = List.generate(setsCount, (_) => '');
        SessionStateCache.reps[i] = List.generate(setsCount, (_) => '');
      }

      if (!_weightControllers.containsKey(i)) {
        _weightControllers[i] = [];
        _repsControllers[i] = [];

        for (int j = 0; j < SessionStateCache.setsStatus[i]!.length; j++) {
          var wCtrl = TextEditingController(
            text: SessionStateCache.weights[i]![j],
          );
          wCtrl.addListener(() {
            SessionStateCache.weights[i]![j] = wCtrl.text;
          });
          _weightControllers[i]!.add(wCtrl);

          var rCtrl = TextEditingController(
            text: SessionStateCache.reps[i]![j],
          );
          rCtrl.addListener(() {
            SessionStateCache.reps[i]![j] = rCtrl.text;
          });
          _repsControllers[i]!.add(rCtrl);
        }
      }
    }
  }

  String _formatTime(int totalSeconds) {
    int m = totalSeconds ~/ 60;
    int s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _getLastWeight(String exerciseId) {
    final history = context.read<WorkoutProvider>().history;
    for (var session in history) {
      for (var ex in session.exercises) {
        if (ex.exerciseId == exerciseId && ex.sets.isNotEmpty) {
          return '${ex.sets.first.weight} kg';
        }
      }
    }
    return '-';
  }

  void _showMusicSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escolha seu aplicativo de áudio 🎧',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.play_circle_filled,
                color: Colors.redAccent,
                size: 28,
              ),
              title: const Text(
                'YouTube Music',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openMusicApp(
                  'vnd.youtube.music://',
                  'https://music.youtube.com',
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.music_note,
                color: Colors.green,
                size: 28,
              ),
              title: const Text(
                'Spotify',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openMusicApp('spotify://', 'https://open.spotify.com');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.graphic_eq,
                color: Colors.cyanAccent,
                size: 28,
              ),
              title: const Text(
                'Deezer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openMusicApp('deezer://', 'https://www.deezer.com');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.apple,
                color: Colors.pinkAccent,
                size: 28,
              ),
              title: const Text(
                'Apple Music',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openMusicApp('music://', 'https://music.apple.com');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.queue_music,
                color: Colors.orangeAccent,
                size: 28,
              ),
              title: const Text(
                'Amazon Music',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openMusicApp('amznmp3://', 'https://music.amazon.com');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _openMusicApp(String appUrl, String webUrl) async {
    try {
      final Uri appUri = Uri.parse(appUrl);
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri);
      } else {
        await launchUrl(
          Uri.parse(webUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao abrir o reprodutor de música.'),
          ),
        );
      }
    }
  }

  void _confirmExit(WorkoutProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text(
          'Pausar ou Encerrar?',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        content: const Text(
          'Deseja minimizar para continuar depois ou encerrar definitivamente e descartar o progresso de hoje?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(
              'Minimizar',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              provider.cancelWorkout();
              SessionStateCache.clear();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text(
              'Descartar Treino',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  bool _allSetsCompleted() {
    if (SessionStateCache.setsStatus.isEmpty) return false;
    for (var sets in SessionStateCache.setsStatus.values) {
      if (sets.contains(false)) return false;
    }
    return true;
  }

  // ==========================================================
  // NOVO SISTEMA DE FINALIZAÇÃO (Pop-up com Campo de Anotações)
  // ==========================================================
  void _confirmFinish(WorkoutProvider provider) {
    List<ExerciseLog> workoutLogs = [];
    final exercises = provider.currentWorkoutExercises;

    for (int i = 0; i < exercises.length; i++) {
      List<ExerciseSet> setsCompleted = [];

      for (int j = 0; j < SessionStateCache.setsStatus[i]!.length; j++) {
        if (SessionStateCache.setsStatus[i]![j]) {
          double weight =
              double.tryParse(
                _weightControllers[i]![j].text.replaceAll(',', '.'),
              ) ??
              0.0;
          int reps = int.tryParse(_repsControllers[i]![j].text) ?? 0;

          if (reps == 0) {
            String target = _getSmartTarget(exercises[i].reps, j);
            final match = RegExp(r'\d+').firstMatch(target);
            if (match != null) reps = int.parse(match.group(0)!);
          }
          setsCompleted.add(ExerciseSet(reps: reps, weight: weight));
        }
      }

      if (setsCompleted.isNotEmpty) {
        workoutLogs.add(
          ExerciseLog(
            exerciseId: exercises[i].id,
            exerciseName: exercises[i].name,
            sets: setsCompleted,
          ),
        );
      }
    }

    if (!_allSetsCompleted()) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text(
            'Calma lá!',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Notei que você não marcou todas as séries. Vai desistir no meio do caminho ou esqueceu de marcar?',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Anotações sobre a falha/desistência (Opcional)',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Voltar',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                provider.finishWorkout(
                  _formatTime(provider.workoutDuration.value),
                  isIncomplete: true,
                  logs: workoutLogs,
                  notes: _notesController.text,
                );
                SessionStateCache.clear();
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ficha salva como incompleta no histórico.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              child: const Text(
                'Arregar e Salvar',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text(
          'Finalizar Treino?',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Excelente trabalho! Deseja encerrar a sessão e salvar no histórico?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Como foi o treino? (Opcional)',
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              provider.finishWorkout(
                _formatTime(provider.workoutDuration.value),
                isIncomplete: false,
                logs: workoutLogs,
                notes: _notesController.text,
              );
              SessionStateCache.clear();
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Treino concluído e salvo com sucesso!'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: const Text(
              'Salvar Treino',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputForm(
    BuildContext context,
    TextEditingController controller,
    String hint, {
    bool isReps = false,
  }) {
    return SizedBox(
      height: 32,
      child: TextField(
        controller: controller,
        keyboardType: isReps
            ? TextInputType.number
            : const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final exercises = provider.currentWorkoutExercises;
    _initializeSets();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmExit(provider);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _confirmExit(provider),
          ),
          title: Text(
            provider.activeRoutineName,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.music_note,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: _showMusicSelector,
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'TEMPO TOTAL',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ValueListenableBuilder<int>(
                    valueListenable: provider.workoutDuration,
                    builder: (context, duration, child) {
                      return Text(
                        _formatTime(duration),
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: exercises.isEmpty
                  ? Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          side: const BorderSide(color: AppColors.border),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ExercisesScreen(isSelecting: true),
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar Exercício'),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: exercises
                          .length, // <-- Alterado de exercises.length + 1 para exercises.length
                      itemBuilder: (context, index) {
                        final ex = exercises[index];
                        final sets = SessionStateCache.setsStatus[index]!;

                        final bool isLinked =
                            ex.isSuperset && index < exercises.length - 1;
                        final bool isPreviousLinked =
                            index > 0 && exercises[index - 1].isSuperset;

                        return Container(
                          margin: EdgeInsets.only(bottom: isLinked ? 0 : 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(isPreviousLinked ? 0 : 14),
                              bottom: Radius.circular(isLinked ? 0 : 14),
                            ),
                            border: Border(
                              top: BorderSide(
                                color: isPreviousLinked
                                    ? Colors.transparent
                                    : AppColors.border,
                              ),
                              left: const BorderSide(color: AppColors.border),
                              right: const BorderSide(color: AppColors.border),
                              bottom: BorderSide(
                                color: isLinked
                                    ? Colors.transparent
                                    : AppColors.border,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isPreviousLinked)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.15),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.link,
                                        size: 16,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'BI-SET (FAÇA JUNTO COM O ACIMA)',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              InkWell(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(
                                    isPreviousLinked ? 0 : 14,
                                  ),
                                ),
                                onTap: () {
                                  final details = _getDetailedInfo(ex.id);
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => Dialog(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: SingleChildScrollView(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Container(
                                                  color: Theme.of(
                                                    context,
                                                  ).scaffoldBackgroundColor,
                                                  width: double.infinity,
                                                  constraints:
                                                      const BoxConstraints(
                                                        maxHeight: 250,
                                                      ),
                                                  child: Image.asset(
                                                    _getImagePath(ex.name),
                                                    fit: BoxFit.contain,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => const Center(
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .image_not_supported,
                                                                size: 36,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                              SizedBox(
                                                                height: 8,
                                                              ),
                                                              Text(
                                                                'Imagem indisponível',
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              Center(
                                                child: Text(
                                                  ex.name,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Center(
                                                child: Text(
                                                  ex.muscle.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              const Text(
                                                'MÚSCULOS SECUNDÁRIOS:',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                details['secondary'],
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              const Text(
                                                'COMO EXECUTAR:',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              ...List.generate(
                                                (details['steps'] as List)
                                                    .length,
                                                (i) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 8.0,
                                                        ),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          '${i + 1}.',
                                                          style: TextStyle(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            details['steps'][i],
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 13,
                                                                  color: Colors
                                                                      .white,
                                                                  height: 1.3,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(height: 24),
                                              SizedBox(
                                                width: double.infinity,
                                                child: TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child: Text(
                                                    'FECHAR',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(9),
                                      child: Image.asset(
                                        _getImagePath(ex.name),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Center(
                                                  child: Text(
                                                    '${index + 1}',
                                                    style: TextStyle(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    ex.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ex.description,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),

                                        if (ex.customNote.isNotEmpty) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.amber.withValues(
                                                  alpha: 0.3,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.push_pin,
                                                  size: 10,
                                                  color: Colors.amber,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    ex.customNote,
                                                    style: const TextStyle(
                                                      color: Colors.amber,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                        ],

                                        Text(
                                          'Última carga: ${_getLastWeight(ex.id)}',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.help_outline,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const Divider(color: AppColors.border, height: 1),

                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  top: 12,
                                  bottom: 4,
                                ),
                                child: Row(
                                  children: const [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Série',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Center(
                                        child: Text(
                                          'Carga (kg)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Center(
                                        child: Text(
                                          'Reps',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Icon(
                                          Icons.check,
                                          size: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 8,
                                  bottom: 12,
                                ),
                                child: Column(
                                  children: [
                                    ...List.generate(sets.length, (setIndex) {
                                      bool isCompleted = sets[setIndex];
                                      String smartTarget = _getSmartTarget(
                                        ex.reps,
                                        setIndex,
                                      );

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4.0,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                '${setIndex + 1}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: isCompleted
                                                      ? Theme.of(
                                                          context,
                                                        ).colorScheme.primary
                                                      : Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                    ),
                                                child: _buildInputForm(
                                                  context,
                                                  _weightControllers[index]![setIndex],
                                                  'kg',
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                    ),
                                                child: _buildInputForm(
                                                  context,
                                                  _repsControllers[index]![setIndex],
                                                  '$smartTarget',
                                                  isReps: true,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Transform.scale(
                                                  scale: 1.0,
                                                  child: Checkbox(
                                                    value: isCompleted,
                                                    activeColor: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    checkColor: Colors.black,
                                                    side: const BorderSide(
                                                      color: AppColors.border,
                                                      width: 1.5,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    onChanged: (val) {
                                                      setState(() {
                                                        SessionStateCache
                                                                .setsStatus[index]![setIndex] =
                                                            val ?? false;
                                                        if (val == true) {
                                                          FocusScope.of(
                                                            context,
                                                          ).unfocus();
                                                          provider
                                                              .startRestTimer(
                                                                ex.rest,
                                                              );
                                                        }
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: const Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  if (provider.isResting)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.timer,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'DESCANSO',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _formatTime(provider.restSeconds),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => provider.stopRestTimer(),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Descanso Inteligente Ativado',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Icon(
                          Icons.auto_awesome,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _confirmFinish(provider),
                      child: const Text(
                        'FINALIZAR E SALVAR',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
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
