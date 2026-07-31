# PULSE — Auditoria da biblioteca de exercícios

## Estado após a deduplicação

- 75 exercícios nativos canônicos.
- 10 grupos musculares.
- 77 arquivos GIF mantidos nesta etapa.
- 75 mídias associadas aos exercícios canônicos.
- 2 GIFs continuam sem uso atual:
  - `rosca__scott.gif`
  - `rosca_scott_maquina_livre.gif`

## Duplicidade consolidada

`Crucifixo na Máquina` (`p13`) foi consolidado em `Voador Peitoral na Máquina` (`p9`).

A decisão foi baseada em três sinais presentes no projeto:

1. os dois itens usavam a mesma mídia `peck_deck_voador.gif`;
2. ambos estavam classificados como isolamento de peito em máquina;
3. as instruções exibidas nas telas eram as mesmas.

O nome antigo permanece como alias de busca. Na inicialização, fichas, histórico e sessão em andamento com `p13` passam a usar `p9`. Séries, repetições, descanso, observações, cargas e posição na ficha são preservados.

Caso uma ficha antiga contenha os dois itens, as duas posições são mantidas para não descartar prescrições diferentes. Ambas passam a apontar para a mesma identidade canônica e o usuário pode remover uma delas ao editar a ficha.

## Estrutura canônica introduzida

A biblioteca agora diferencia explicitamente:

- `ExerciseDefinition`: identidade, nome, músculo principal, descrição-base, modalidade, aliases e mídia;
- `ExercisePrescription`: repetições, descanso, instrução ajustada, bi-set e observação da ficha.

O modelo legado `Exercise` continua sendo usado na persistência e nas telas como adaptador de compatibilidade. Isso evita uma migração destrutiva do banco atual, mas a fonte canônica da biblioteca já não depende da prescrição de uma ficha.

## Próximos passos

1. Padronizar equipamento e padrão de movimento nas definições.
2. Normalizar e otimizar as mídias.
3. Criar fallback visual para mídia ausente.
4. Adicionar modalidade de cardio e registro próprio.
