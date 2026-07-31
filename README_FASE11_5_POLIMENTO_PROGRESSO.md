# PULSE — Polimento visual de Consistência e Desempenho

## Ajustes

- Reduz o espaçamento inicial das quatro abas de Progresso de 20 para 16 px.
- Remove o seletor de período isolado no topo de Consistência.
- Adiciona o cabeçalho "Calendário de treinos" antes do calendário.
- Move o seletor de período para o cabeçalho "Resumo do período", que controla as métricas abaixo.
- Remove o seletor isolado no topo de Desempenho.
- Coloca o seletor ao lado do título "Evolução por exercício".
- Padroniza o seletor com fundo, borda, cantos arredondados e altura compacta.
- Não altera cálculos, histórico, calendário, filtros nem persistência.

## Aplicação

Copie a pasta `lib` para a raiz do projeto, substituindo o arquivo existente.

Depois execute:

```powershell
dart format lib/screens/progress_screen.dart
flutter analyze
flutter test
flutter run
```

Valide as abas Consistência, Treinos, Medidas e Desempenho em telas estreitas e largas.
