# Fase 11.5 — Consistência e calendário unificados

## Alterações

- O calendário completo agora fica dentro da aba **Progresso > Consistência**.
- A antiga navegação para uma segunda tela foi removida.
- É possível navegar entre meses diretamente na aba.
- Ao tocar em um dia, os treinos daquele dia aparecem logo abaixo.
- Treinos concluídos, incompletos, cardio e sessões mistas usam o mesmo histórico.
- Sequência atual, melhor sequência, métricas e volume semanal continuam na mesma tela.
- O conteúdo inferior continua protegido pela área segura já aplicada à aba Progresso.

## Verificações automáticas

O arquivo `.github/workflows/flutter_checks.yml` executa no GitHub Actions:

1. `flutter pub get`
2. verificação de formatação
3. `flutter analyze`
4. `flutter test`

A automação roda em pushes para `main` e `refactor/riverpod-architecture`, além de pull requests.

## Aplicação

Copie para a raiz do projeto:

- `lib`
- `.github`
- `README_FASE11_5_CONSISTENCIA_CALENDARIO.md`

Depois execute localmente:

```powershell
dart format lib test
flutter analyze
flutter test
flutter run
```
