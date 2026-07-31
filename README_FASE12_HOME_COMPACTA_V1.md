# PULSE — Home compacta V1

## Objetivo
Exibir o treino do dia, os atalhos de cardio/treino dinâmico e o resumo semanal já na primeira abertura em aparelhos comuns, mantendo a rolagem como proteção para telas menores e fontes ampliadas.

## Alterações
- Cabeçalho da Home mais compacto.
- Saudação e data passam a compartilhar a mesma linha.
- Cartão do treino e botão de início com menor altura, sem reduzir a área de toque de forma excessiva.
- Cardio e Treino Dinâmico passam a ser atalhos lado a lado.
- Resumo semanal mais próximo dos atalhos e cartões ligeiramente menores.
- Rolagem preservada.
- Área inferior passa a usar `viewPadding` para respeitar a navegação física do Android.

## Aplicação
Copie a pasta `lib` para a raiz do projeto e substitua o arquivo existente.

## Validação
```powershell
dart format lib/screens/home_screen.dart
flutter analyze
flutter test
flutter run
```
