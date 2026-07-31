# PULSE — Fase 12 — Correção da área inferior V1.1

## Correções

- Tela de criação manual de programa: botão `AVANÇAR E MONTAR FICHAS` acima da navegação do Android.
- Montagem das fichas: botão `SALVAR PROGRAMA COMPLETO` acima da navegação do Android.
- Gerador inteligente: botão `Gerar e revisar programa` usa a área física reservada pelo sistema.
- Prévia do programa gerado: ação inferior usa a área física reservada pelo sistema.
- Modal `Criar treino`: conteúdo rolável e margem inferior baseada na barra de navegação do aparelho.

A correção usa `MediaQuery.viewPaddingOf(context).bottom`, pois `MediaQuery.paddingOf` pode ser zerado por um `SafeArea` ancestral no modo edge-to-edge.
