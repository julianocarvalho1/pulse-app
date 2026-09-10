# Próxima ficha após treino incompleto

Ao salvar uma sessão incompleta de um programa ativo com duas ou mais
fichas, o usuário escolhe seguir para a próxima ou manter a atual.
A escolha afeta apenas a sugestão da tela inicial. O histórico permanece
incompleto e a progressão continua usando os registros reais.

Treinos completos avançam automaticamente na ordem salva do programa.
Sessões avulsas não mudam a sequência do programa ativo. Pausar não salva
como finalizado; descartar não avança. Manter significa nova sessão da
mesma ficha, não retomada apenas dos exercícios pendentes.

## Teste físico

1. No programa ABC, iniciar A e registrar ao menos uma série, deixando
   outras séries ou o cardio pendentes.
2. Finalizar, confirmar salvamento incompleto e escolher seguir para B.
   A tela inicial deve sugerir B; o histórico de A deve continuar incompleto.
3. Fechar e reabrir o app: B deve continuar sugerido.
4. Iniciar B, registrar uma série, finalizar incompleto e escolher manter B.
   A tela inicial deve continuar sugerindo B, inclusive após reabrir.
5. Na pergunta, escolher voltar ao treino: nada deve ser finalizado.
6. Completar uma ficha inteira: não deve perguntar, e deve sugerir a próxima.
7. Na última ficha do programa, avançar deve voltar à primeira.
8. Verificar botões legíveis com nomes longos e fonte maior no Android.

## Persistência

Banco v13 adiciona `workout_history.next_routine_id` nullable, sem apagar
registros. Histórico antigo mantém o comportamento anterior. A escolha
é incluída no backup. Se a ficha escolhida for excluída, a sugestão volta
à regra baseada no histórico válido. Apagar o registro que guarda a escolha
também remove aquela decisão da sequência.

Esta alteração não foi publicada na Google Play.
