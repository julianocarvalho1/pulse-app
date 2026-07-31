# PULSE — Auditoria da biblioteca de exercícios

## Estado encontrado

- 76 exercícios nativos.
- 10 grupos musculares:
  - Peito: 13
  - Costas: 10
  - Ombros: 9
  - Trapézio: 2
  - Bíceps: 6
  - Antebraço: 2
  - Tríceps: 9
  - Pernas: 16
  - Panturrilha: 3
  - Abdômen: 6
- 77 arquivos GIF.
- 75 mídias efetivamente associadas aos exercícios.
- 2 GIFs sem uso atual:
  - `rosca__scott.gif`
  - `rosca_scott_maquina_livre.gif`
- Os programas prontos possuíam 18 identificadores próprios (`ex_pm_*`) e nomes paralelos, como `Chest Press`, `Desenvolvimento Militar` e `Crunch Abdominal`.
- O caminho da mídia era calculado pelo nome em quatro telas diferentes, o que tornava renomeações frágeis.

## Ajustes desta entrega

- Português adotado como nome principal exibido.
- Aliases em português e inglês mantidos para busca.
- Identificadores dos 76 exercícios nativos foram preservados.
- Identificadores antigos dos programas prontos passam a ser migrados para o exercício correspondente da biblioteca.
- Fichas, histórico e sessão em andamento são normalizados sem alterar séries, repetições, descanso, observações ou cargas.
- Exercícios personalizados não são transformados automaticamente.
- Mídia passou a ser vinculada por identificador estável, não pelo texto do nome.
- Biblioteca passou a exibir seções por grupo muscular.
- Busca passou a encontrar nomes como `Chest Press`, `Bench Press`, `Hip Thrust`, `Lat Pulldown`, `Deadlift` e outros aliases.
- A expressão `Guia Oficial` foi removida da tela de programas.

## Duplicidade para a próxima entrega

`Voador Peitoral na Máquina` (`p9`) e `Crucifixo na Máquina` (`p13`) usam a mesma mídia e representam movimentos muito próximos. Eles foram mantidos separados nesta entrega para não unir dados sem validação visual e funcional. A próxima entrega pode consolidá-los com migração explícita do identificador `p13` para `p9`.

## Próximos passos planejados

1. Confirmar a consolidação de duplicidades reais.
2. Separar a definição do exercício da prescrição de séries e descanso.
3. Padronizar equipamentos e padrões de movimento.
4. Normalizar e otimizar as mídias.
5. Adicionar modalidade de cardio com registro próprio.
