# PULSE — Fase 11.5: correções e polimento antes do cardio

## Alterações

- Perfil no primeiro uso: troca `Comece sua evolução` por `Nenhum treino concluído`, apresentado como estado informativo.
- Popup do exercício durante a sessão: restaura a leitura das instruções no tema claro, inclui séries/repetições, descanso e observação da ficha.
- Configurações: remove a sobrescrita que pintava a bolinha do switch com a mesma cor do trilho ativo.
- Detalhes do treino concluído: cabeçalho compacto, resumo com duração/exercícios/séries, cartões menores e linhas de séries mais legíveis.
- Carga zerada no histórico passa a aparecer como `—`, em vez de `0.0 kg`.
- Adiciona teste de widget para a nova tela de detalhes do histórico.

## Aplicação

Copie as pastas `lib` e `test` para a raiz do projeto e autorize a substituição.

Depois execute:

```powershell
dart format lib test
flutter analyze
flutter test
flutter run
```

Valide no aparelho:

1. Perfil sem treinos concluídos.
2. Popup de informações ao tocar em um exercício durante a sessão, nos temas claro e escuro.
3. Switches de voz, lembrete e proteção, confirmando que a bolinha permanece visível quando ativados.
4. Perfil > treino concluído > Detalhes do treino.
