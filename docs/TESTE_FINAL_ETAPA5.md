# PULSE — roteiro de teste final

Use este roteiro em pelo menos um aparelho Android real antes de gerar uma nova versão.

## 1. Instalação e abertura

- Abrir o app após instalação limpa.
- Confirmar a transição contínua entre a tela nativa e a splash do PULSE.
- Concluir o onboarding e reiniciar o app.
- Validar tema claro, escuro e automático.

## 2. Tela Hoje

- Iniciar a próxima ficha.
- Registrar cardio.
- Registrar treino dinâmico.
- Registrar atividade livre comum e atividade que substitui o treino planejado.
- Confirmar a atualização da atividade recente e do resumo semanal.

## 3. Treinos

- Criar uma ficha manualmente.
- Gerar um programa inteligente.
- Importar ficha do personal.
- Exportar e importar arquivo `.pulse`.
- Compartilhar e ler QR Code.
- Editar, duplicar e excluir uma ficha de teste.

## 4. Sessão de treino

- Registrar carga e repetições em todas as séries.
- Validar cronômetro automático, ajuste de tempo e aviso por voz.
- Abrir detalhes do exercício e Assistente PULSE.
- Salvar uma sessão incompleta e concluir outra sessão.
- Confirmar histórico, volume e próxima ficha.

## 5. Progresso

- Conferir Consistência, Treinos, Medidas e Desempenho.
- Alterar o período analisado.
- Abrir o calendário e localizar cada tipo de atividade.
- Registrar, editar e remover uma medida corporal de teste.
- Executar a análise inteligente com internet e sem internet.

## 6. Perfil, segurança e dados

- Alterar foto e dados pessoais.
- Alterar preferências, tema, cor e unidades.
- Testar biometria quando disponível.
- Exportar um backup, apagar dados de teste e restaurar o arquivo.
- Abrir `Como usar o PULSE` e percorrer as sete etapas.
- Abrir `Privacidade e assistência` e testar o botão de suporte.

## 7. Verificação técnica

Execute no PowerShell:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
git status
```

O resultado esperado é análise sem problemas, todos os testes aprovados e nenhuma alteração inesperada.
