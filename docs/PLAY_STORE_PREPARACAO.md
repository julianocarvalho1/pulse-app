# PULSE — preparação para publicação

## Identidade Android definida

- `applicationId`: `com.julianocarvalho.pulse`
- `namespace`: `com.julianocarvalho.pulse`
- Essa identidade deve ser preservada na primeira listagem do PULSE e em todas as atualizações futuras.

## Bloqueios técnicos restantes

1. O build `release` ainda usa a assinatura de depuração.
   - Antes de gerar o pacote de produção, criar e configurar uma chave de assinatura segura.
   - Não incluir senhas ou o arquivo da chave no Git.

2. A versão atual no `pubspec.yaml` é `1.0.0+1`.
   - O número após `+` precisa ser maior que o da versão já enviada ao Play Console.

## Conteúdo e transparência

- Publicar uma política de privacidade em endereço público.
- Informar o e-mail de suporte: `pulse.appp@gmail.com`.
- Revisar no Play Console as declarações de dados, saúde e recursos generativos.
- Explicar que o PULSE não substitui acompanhamento médico ou profissional.
- Manter a descrição do processamento online alinhada à tela `Privacidade e assistência`.

## Material da loja

- Nome do aplicativo: `PULSE`.
- Descrição curta e descrição completa.
- Ícone em alta resolução.
- Imagem de destaque.
- Capturas das telas Hoje, Treinos, Sessão, Progresso e Assistente PULSE.
- Categoria, classificação etária e dados de contato.

## Antes de gerar o AAB

- Executar o roteiro de teste final.
- Confirmar backup e restauração em aparelho real.
- Confirmar Worker e resposta local de reserva.
- Atualizar `version` no `pubspec.yaml`.
- Configurar assinatura de produção.
- Gerar com `flutter build appbundle --release`.
- Instalar e testar uma versão release antes do envio.

## Itens que não devem ser alterados sem confirmação

- `applicationId` `com.julianocarvalho.pulse`, agora definido como identidade permanente do PULSE.
- chave de assinatura de uma versão já publicada.
- formato dos backups sem migração e compatibilidade com arquivos antigos.
