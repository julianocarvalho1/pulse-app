import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';

// ============================================================
// TELA: DETALHE DO EXERCÍCIO (COM BIOMECÂNICA DINÂMICA)
// ============================================================

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  final bool isSelecting;

  const ExerciseDetailScreen({super.key, required this.exercise, this.isSelecting = false});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  int _tab = 0;

  // ====================================================================
  // TRADUTOR DE IMAGENS OFICIAL (Correção Definitiva)
  // ====================================================================
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
      'triceps na polia': 'triceps_pulley_reta_v',
      'rosca scott': 'rosca_scott_maquina_livre',
      'desenvolvimento militar': 'desenvolvimento_com_barra',
      'chest press': 'supino_reto_com_barra',
      'remada sentada': 'remada_baixa_sentada',
      'remada baixa': 'remada_baixa_sentada',
    };

    String nameForAlias = cleanName.replaceAll(RegExp(r'[áàâã]'), 'a')
        .replaceAll(RegExp(r'[éèê]'), 'e')
        .replaceAll(RegExp(r'[íìî]'), 'i')
        .replaceAll(RegExp(r'[óòôõ]'), 'o')
        .replaceAll(RegExp(r'[úùû]'), 'u')
        .replaceAll('ç', 'c');

    if (aliases.containsKey(nameForAlias)) {
      return 'assets/images/${aliases[nameForAlias]}.gif';
    }

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

  // ====================================================================
  // INTELIGÊNCIA: DICIONÁRIO DE BIOMECÂNICA AVANÇADA
  // ====================================================================
  Map<String, dynamic> _getDetailedInfo() {
    String id = widget.exercise.id;
    List<String> steps = [];
    String secondary = '';
    List<String> variations = ['Execução Unilateral', 'Uso de Halteres/Barra', 'Variação de Máquina/Polia'];

    if (id.startsWith('p')) {
      secondary = 'Tríceps Braquial e Deltóide Anterior (Ombro)';
      if (id == 'p1' || id == 'p3' || id == 'p6') {
        steps = ['Plante os pés firmemente no chão e mantenha a curvatura natural da lombar.', 'Retraia as escápulas (junte os ossos das costas) para estufar o peito e proteger os ombros.', 'Desça a barra controladamente até encostar levemente no peito.', 'Empurre de forma explosiva, sem esticar (travar) os cotovelos 100% no topo.'];
      } else if (id == 'p2' || id == 'p4') {
        steps = ['Use os joelhos para chutar os halteres para a posição inicial.', 'Mantenha os cotovelos em um ângulo de 45 a 60 graus em relação ao tronco (não abra totalmente em cruz).', 'Desça até sentir um alongamento profundo no peitoral.', 'Suba aproximando os halteres, focando em "esmagar" o peito no topo.'];
      } else if (id == 'p7' || id == 'p8' || id == 'p9' || id == 'p13') {
        secondary = 'Deltóide Anterior (Isolamento de Peitoral)';
        steps = ['Mantenha os cotovelos com uma leve flexão e "travados" nessa posição durante todo o movimento.', 'Abra os braços controlando o peso, focando em alongar as fibras do peitoral.', 'Feche os braços imaginando que está abraçando um tronco de árvore grosso.', 'Faça uma pausa de 1 segundo na contração máxima (mãos juntas).'];
      } else if (id == 'p10' || id == 'p11') {
        steps = ['Incline o tronco levemente para frente mantendo o core contraído.', 'Puxe os cabos com os cotovelos levemente flexionados.', 'Cruze levemente as mãos no final do movimento para contração máxima.', 'Retorne controlando o peso da polia sem deixar que ela puxe seu corpo.'];
      } else {
        steps = ['Ajuste o banco ou máquina para alinhar as manoplas com o meio do peito.', 'Empurre o peso estufando o peito.', 'Volte controladamente resistindo à carga.'];
      }
    }
    else if (id.startsWith('c')) {
      secondary = 'Bíceps, Braquial e Músculos do Antebraço';
      if (id == 'c1' || id == 'c2') {
        steps = ['Ajuste o rolo de apoio para travar bem as coxas e evitar que o corpo suba.', 'Pegue na barra, estufe o peito e incline o tronco ligeiramente para trás (cerca de 15 graus).', 'Inicie o movimento puxando os ombros para baixo e depois traga a barra na direção do peitoral superior.', 'Suba controlando o peso até alongar as dorsais completamente, sem soltar os ombros no topo.'];
      } else if (id == 'c3' || id == 'c4' || id == 'c7') {
        secondary = 'Lombar (Eretores da Espinha), Bíceps e Trapézio';
        steps = ['Mantenha a coluna perfeitamente neutra e o abdômen rígido.', 'Incline o tronco à frente (entre 45 e 90 graus).', 'Puxe o peso em direção ao umbigo/quadril, focando em "dar uma cotovelada para trás".', 'Retorne esticando os braços e sentindo as escápulas se abrirem.'];
      } else if (id == 'c5' || id == 'c6') {
        steps = ['Sente-se com postura ereta e pés apoiados.', 'Puxe a carga retraindo as costas (juntando as escápulas).', 'Mantenha os cotovelos próximos ao corpo se quiser focar na grande dorsal.', 'Estique os braços resistindo ao peso da máquina.'];
      } else if (id == 'c9' || id == 'c10') {
        secondary = 'Tríceps (Cabeça Longa) e Ombro Posterior';
        steps = ['Mantenha os braços esticados (com mínima flexão no cotovelo).', 'Puxe a barra/corda até a linha do quadril focando apenas nas costas.', 'Mantenha o tronco estático; não use o peso do corpo para puxar.'];
      } else {
        steps = ['Inicie o movimento contraindo as costas antes de dobrar os braços.', 'Puxe controladamente.', 'Alongue na volta.'];
      }
    }
    else if (id.startsWith('o') || id.startsWith('t')) {
      secondary = 'Tríceps (nos desenvolvimentos) ou Trapézio Superior';
      if (id == 'o1' || id == 'o2' || id == 'o3') {
        steps = ['Sente-se com a coluna bem apoiada no banco.', 'Mantenha os cotovelos levemente à frente da linha dos ombros (plano escapular).', 'Empurre o peso acima da cabeça até quase esticar os braços.', 'Desça controladamente até as mãos chegarem na altura do queixo/orelhas.'];
      } else if (id == 'o4' || id == 'o5') {
        secondary = 'Foco em Deltóide Medial (Lateral do Ombro)';
        steps = ['Mantenha os cotovelos com uma leve flexão.', 'Incline o corpo 5 graus para frente.', 'Eleve os braços focando em liderar o movimento pelo cotovelo (e não pelas mãos).', 'Suba até a altura dos ombros e desça freando a carga.'];
      } else if (id == 'o8') {
        secondary = 'Rombóides e Trapézio Médio';
        steps = ['Incline o tronco para frente até quase 90 graus.', 'Com os braços semi-esticados, abra os halteres lateralmente e para trás.', 'Concentre-se em esmagar a parte de trás do ombro, sem usar impulso.'];
      } else if (id.startsWith('t')) {
        secondary = 'Músculos do Pescoço';
        steps = ['Segure a carga com os braços relaxados.', 'Eleve os ombros em direção às orelhas o mais alto possível.', 'Segure a contração por 1 segundo no topo.', 'Desça lentamente até alongar o trapézio. Não faça movimentos rotacionais.'];
      } else {
        steps = ['Mantenha a postura ereta.', 'Levante a carga com controle.', 'Não utilize impulso das costas ou pernas.'];
      }
    }
    else if (id.startsWith('b')) {
      secondary = 'Músculos Braquiorradiais e Estabilizadores do Punho';
      if (id == 'b1' || id == 'b2' || id == 'b6') {
        steps = ['Mantenha os cotovelos absolutamente colados às costelas. Eles não devem ir para frente ou para trás.', 'Contraia o bíceps subindo a carga até a altura do peito superior.', 'Evite balançar o tronco (roubar).', 'Desça a carga até estender o braço (cerca de 95% de extensão).'];
      } else if (id == 'b4' || id == 'b5' || id == 'b9') {
        steps = ['Apoie firmemente a axila/tríceps no banco ou coxa.', 'Foque totalmente na contração, pois o ombro está estabilizado.', 'Não estique o cotovelo 100% na descida no banco Scott para evitar lesões.', 'Faça o movimento cadenciado (2 segundos para subir, 3 para descer).'];
      } else if (id == 'b3' || id == 'b7') {
        secondary = 'Braquial Anterior (Gera volume no braço)';
        steps = ['Mantenha a pegada neutra (polegares para cima) ou invertida.', 'Suba a carga mantendo os pulsos travados e retos.', 'Desça controladamente focando no antebraço.'];
      } else {
        steps = ['Trave os cotovelos.', 'Flexione o braço contraindo o bíceps.', 'Retorne à posição inicial.'];
      }
    }
    else if (id.startsWith('tr')) {
      secondary = 'Ombros (como estabilizadores) e Core';
      if (id == 'tr1' || id == 'tr2' || id == 'tr10') {
        steps = ['Incline o corpo ligeiramente à frente e flexione um pouco os joelhos.', 'Trave os cotovelos na linha da cintura.', 'Empurre o cabo para baixo usando apenas a força do tríceps.', 'Se usar corda, puxe as pontas para fora no final do movimento para contração extrema.'];
      } else if (id == 'tr3' || id == 'tr4' || id == 'tr5' || id == 'tr6') {
        steps = ['Mantenha os cotovelos apontados para o teto ou para frente, o mais fechados possível.', 'Desça a carga na direção da testa ou nuca.', 'Estique os braços esmagando o tríceps.', 'Esse ângulo trabalha intensamente a cabeça longa do tríceps.'];
      } else {
        steps = ['Mantenha os braços próximos ao corpo.', 'Estenda os cotovelos empurrando o peso.', 'Retorne controlando a fase excêntrica.'];
      }
    }
    else if (id.startsWith('pe')) {
      if (id == 'pe1' || id == 'pe2' || id == 'pe3') {
        secondary = 'Glúteos, Isquiotibiais, Lombar e Core';
        steps = ['Posicione os pés na largura dos ombros com as pontas levemente voltadas para fora.', 'Mantenha o peito estufado, olhar à frente e respire fundo enrijecendo o abdômen.', 'Desça como se fosse sentar em uma cadeira invisível, quebrando a paralela se a mobilidade permitir.', 'Suba fazendo força no calcanhar e na borda externa do pé, sem deixar os joelhos entrarem (valgo).'];
      } else if (id == 'pe4' || id == 'pe5') {
        secondary = 'Glúteos e Isquiotibiais';
        steps = ['Apoie perfeitamente a lombar no banco. Se o quadril descolar na descida, a carga ou a descida estão incorretas.', 'Coloque os pés na plataforma na largura dos ombros.', 'Desça a máquina até os joelhos ficarem próximos a 90 graus ou tocarem o peito.', 'Empurre, mas NÃO trave (não estique até travar a articulação) os joelhos no topo para manter a tensão no músculo.'];
      } else if (id == 'pe6' || id == 'pe13' || id == 'pe14') {
        secondary = 'Músculos Estabilizadores da Pelve';
        steps = ['Sente-se e ajuste a máquina para que o eixo de rotação fique alinhado com a articulação (joelho ou quadril).', 'Trave bem as costas no encosto.', 'Execute o movimento com explosão na ida e freie lentamente na volta.', 'Evite que as placas de peso batam entre as repetições.'];
      } else if (id == 'pe15') { // NOVO: PASSADA/AFUNDO BIOMECÂNICA
        secondary = 'Glúteos, Isquiotibiais e Estabilizadores do Core';
        steps = ['Dê um passo largo à frente mantendo o tronco ereto e o olhar para frente.', 'Desça verticalmente até o joelho de trás quase tocar o chão.', 'O joelho da frente deve ficar alinhado, sem passar excessivamente da ponta do pé.', 'Empurre o chão com o calcanhar da perna da frente para retornar (afundo) ou dar o próximo passo (passada).'];
      } else if (id == 'pe7' || id == 'pe8' || id == 'pe9' || id == 'pe10' || id == 'pe11' || id == 'pe19') {
        secondary = 'Lombar, Glúteos e Panturrilhas';
        steps = ['No Stiff/Terra: Mantenha as pernas semi-esticadas e desça empurrando o quadril para trás, coluna sempre reta.', 'Nas Flexoras: Ajuste o rolo na linha do calcanhar.', 'Puxe/Suba o peso esmagando a parte de trás da coxa.', 'Desça focando em alongar os isquiotibiais.'];
      } else if (id == 'pe12') {
        secondary = 'Isquiotibiais e Lombar';
        steps = ['Apoie as escápulas no banco e posicione os pés de forma que a canela fique vertical no topo do movimento.', 'Coloque a barra na dobra do quadril.', 'Empurre o chão com os calcanhares e eleve o quadril até alinhar corpo, joelho e ombros.', 'Contraia os glúteos com força máxima por 1 segundo no topo.'];
      } else if (id.startsWith('pe16') || id.startsWith('pe17') || id.startsWith('pe18')) {
        secondary = 'Músculos dos Pés e Tornozelos';
        steps = ['Apoie a ponta dos pés (metatarsos) no degrau/plataforma.', 'Desça o calcanhar o máximo possível, alongando a panturrilha por 2 segundos.', 'Suba até ficar na ponta dos pés, contraindo forte no topo por 1 segundo.', 'Panturrilhas precisam de alongamento e contração completa para crescer.'];
      } else {
        steps = ['Execute o movimento respeitando o limite da sua mobilidade articular.', 'Mantenha a postura.', 'Controle a fase de descida.'];
      }
    }
    else if (id.startsWith('ab')) {
      secondary = 'Músculos do Core e Transverso Abdominal';
      if (id == 'ab5') {
        steps = ['Apoie antebraços e pontas dos pés no chão.', 'Mantenha o corpo em uma linha reta perfeita: não levante o quadril nem deixe a lombar afundar.', 'Puxe o umbigo para dentro e respire de forma curta.', 'Contraia glúteos e abdômen intensamente durante todo o tempo.'];
      } else {
        steps = ['O segredo do abdômen não é o pescoço: foque em aproximar a linha das costelas da linha do quadril.', 'Mantenha a lombar travada no chão ou banco.', 'Suba soltando todo o ar dos pulmões (para maximizar a contração).', 'Desça inspirando e controlando a descida, sem relaxar o músculo no chão.'];
      }
    } else {
      steps = ['Ajuste o equipamento.', 'Controle o movimento.', 'Mantenha a respiração constante.'];
      secondary = 'Geral';
    }

    return {
      'steps': steps,
      'secondary': secondary,
      'variations': variations,
    };
  }

  void _showExerciseConfigDialog(BuildContext context, Exercise ex, WorkoutProvider provider, {WorkoutRoutine? targetRoutine}) {
    final repsCtrl = TextEditingController(text: ex.reps);
    final restCtrl = TextEditingController(text: ex.rest);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
        title: const Text('Configurar Exercício', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ex.name, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: repsCtrl,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Séries e Repetições (ex: 3x 10-12)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: restCtrl,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Tempo de Descanso (ex: 60 seg)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
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
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.black),
            onPressed: () {
              final customizedEx = Exercise(
                id: ex.id,
                name: ex.name,
                muscle: ex.muscle,
                description: ex.description,
                reps: repsCtrl.text.trim().isEmpty ? ex.reps : repsCtrl.text.trim(),
                rest: restCtrl.text.trim().isEmpty ? ex.rest : restCtrl.text.trim(),
              );

              if (targetRoutine != null) {
                final updatedExercises = List<Exercise>.from(targetRoutine.exercises)..add(customizedEx);
                provider.updateRoutine(
                  targetRoutine.id,
                  targetRoutine.name,
                  targetRoutine.focus,
                  targetRoutine.groupName,
                  updatedExercises,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${ex.name} adicionado ao ${targetRoutine.name}!'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                provider.addExerciseToWorkout(customizedEx);
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${ex.name} adicionado ao treino ativo!'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Confirmar e Salvar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRoutineSelector(BuildContext context, Exercise ex, WorkoutProvider provider) {
    final routines = provider.myRoutines;

    if (routines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você ainda não tem nenhuma ficha criada para receber este exercício.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Adicionar em qual ficha?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: routines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final routine = routines[index];
                      final folderText = routine.groupName.isNotEmpty ? 'Programa: ${routine.groupName}' : 'Ficha Avulsa';

                      return ListTile(
                        tileColor: Theme.of(context).colorScheme.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.folder_open, color: Theme.of(context).colorScheme.primary, size: 20),
                        ),
                        title: Text(routine.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                        subtitle: Text(folderText, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12)),
                        trailing: const Icon(Icons.add_circle_outline, color: AppColors.textSecondary),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showExerciseConfigDialog(context, ex, provider, targetRoutine: routine);
                        },
                      );
                    },
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      widget.exercise.name.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          _getImagePath(widget.exercise.name),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, size: 36, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Imagem indisponível', style: TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _tabItem('Como fazer', 0),
                        _tabItem('Músculos', 1),
                        _tabItem('Variações', 2),
                      ],
                    ),
                    Container(height: 1, color: AppColors.border),
                    const SizedBox(height: 18),

                    _buildTabContent(),

                    const SizedBox(height: 24),
                    const Text('SÉRIES E DESCANSO SUGERIDOS',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: _infoChip(widget.exercise.reps, true)),
                        const SizedBox(width: 10),
                        Expanded(child: _infoChip(widget.exercise.rest, false)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final provider = context.read<WorkoutProvider>();

                          if (widget.isSelecting) {
                            _showExerciseConfigDialog(context, widget.exercise, provider);
                          } else {
                            _showRoutineSelector(context, widget.exercise, provider);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text('ADICIONAR AO TREINO',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5)),
                            SizedBox(width: 8),
                            Icon(Icons.add_circle_outline, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(String label, int index) {
    final active = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 24),
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
                color: active ? Theme.of(context).colorScheme.primary : Colors.transparent,
                width: 2),
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

  Widget _buildTabContent() {
    switch (_tab) {
      case 1:
        return _musclesContent();
      case 2:
        return _variationsContent();
      default:
        return _stepsContent();
    }
  }

  Widget _stepsContent() {
    final info = _getDetailedInfo();
    final List<String> steps = info['steps'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.exercise.description,
          style: const TextStyle(fontSize: 14.5, height: 1.4, color: Colors.white70),
        ),
        const SizedBox(height: 20),
        ...List.generate(steps.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${i + 1}',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(steps[i],
                        style: const TextStyle(fontSize: 14.5, height: 1.35))),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _musclesContent() {
    final info = _getDetailedInfo();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MÚSCULOS TRABALHADOS',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5)),
        const SizedBox(height: 14),
        _muscleRow('Primário', widget.exercise.muscle),
        const SizedBox(height: 10),
        _muscleRow('Secundário', info['secondary']),
      ],
    );
  }

  Widget _muscleRow(String tag, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8)),
          child: Text(tag,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  Widget _variationsContent() {
    final info = _getDetailedInfo();
    final List<String> variations = info['variations'];

    return Column(
      children: variations
          .map((v) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(Icons.swap_horiz,
                size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text(v, style: const TextStyle(fontSize: 14.5)),
          ],
        ),
      ))
          .toList(),
    );
  }

  Widget _infoChip(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? Theme.of(context).colorScheme.primary : AppColors.border),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? Theme.of(context).colorScheme.primary : Colors.white)),
    );
  }
}