# PULSE — Fase 12: gerador local de programas V1

## Escopo desta entrega

- Questionário para objetivo, nível, tipo, dias, duração e estrutura disponível.
- Prioridades musculares e lista de exercícios evitados.
- Triagem simples que bloqueia geração diante de dor ou restrição não avaliada.
- Geração local e determinística, sem API externa.
- Templates de 2 a 5 dias.
- Programas de musculação, cardio ou mistos.
- Validação obrigatória antes da prévia.
- Revisão completa antes de salvar.
- Persistência usando a biblioteca de fichas já existente.

## Limites intencionais

- O gerador não diagnostica, não prescreve reabilitação e não contorna dor.
- Cargas não são definidas automaticamente.
- Técnicas avançadas não são adicionadas nesta versão.
- O motor usa somente exercícios existentes no catálogo do PULSE.
- IA externa não participa da geração.

## Validação

Execute:

```powershell
dart format lib test
flutter analyze
flutter test
flutter run
```

Teste no aparelho:

1. Treinos → Criar treino → Gerar programa inteligente.
2. Gere planos de musculação, cardio e mistos.
3. Teste de 2 a 5 dias e diferentes durações.
4. Marque um exercício como evitado e confirme que ele não aparece.
5. Marque a triagem como “Sim” e confirme o bloqueio.
6. Revise, salve e confirme as fichas na aba Treinos.
7. Edite uma ficha gerada e inicie uma sessão.
