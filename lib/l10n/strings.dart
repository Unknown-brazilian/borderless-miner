/// Idiomas suportados.
enum AppLang { en, pt }

/// Todas as strings da interface, em EN e PT. Sem codegen: cada idioma é uma
/// implementação concreta de [S]. Selecione com S.of(lang).
abstract class S {
  const S();
  static S of(AppLang lang) => lang == AppLang.pt ? const _Pt() : const _En();

  String get langCode; // rótulo do botão (idioma ATUAL)
  String get langOther; // rótulo do idioma para o qual vai trocar

  // status
  String get statusStopped;
  String get statusMining;
  String get statusConnected;
  String get statusConnecting;
  String get statusDisconnected;

  // hashrate / cores
  String get hashrateTitle;
  String coresActive(int active, int total);
  String coresAvailable(int total);

  // stat cards
  String get bestDifficulty;
  String get acceptedShares;
  String get blocksFound;
  String get poolBestShare;

  // destino
  String get rewardDestination;
  String get exampleAddrWarning;
  String get scanDestinationBtn;
  String get enterDestinationBtn;
  String get enterAddressTitle;
  String get enterAddressHint;
  String get invalidAddress;
  String get pasteBtn;
  String get cancelBtn;
  String get saveBtn;

  // controle
  String get startMining;
  String get stopMining;

  // educativo
  String get eduTitle;
  String get edu1Title;
  String get edu1Body;
  String get edu2Title;
  String get edu2Body;
  String get edu3Title;
  String get edu3Body;
  String get edu4Title;
  String get edu4Body;

  // log + rodapé
  String get logTitle;
  String get waiting;
  String get viewOnMempool;

  // QR Binance
  String get buyBitcoinTitle;
  String get qrInstruction;
  String get copyLink;
  String get openBtn;
  String get linkCopied;

  // snackbars
  String get addressCopied;
  String get destinationUpdated;

  // tela de scan
  String get scanScreenTitle;
  String get scanInvalid;
  String get scanHint;

  // mensagens de log (Stratum / Miner)
  String logConnecting(String host, int port);
  String get logConnected;
  String logSubscribeOk(String en1, int size);
  String get logAuthorized;
  String logAuthRejected(Object? e);
  String get logConnClosed;
  String get logShareAccepted;
  String logShareRejected(Object? e);
  String logSocketError(Object e);
  String logParseError(Object e);
  String logNewDifficulty(num d);
  String logNewJob(String id, bool clean);
  String logBlockFound(num diff);
  String logShareSent(String diff);
}

class _Pt extends S {
  const _Pt();
  @override String get langCode => 'PT';
  @override String get langOther => 'EN';

  @override String get statusStopped => 'Parado';
  @override String get statusMining => 'Minerando';
  @override String get statusConnected => 'Conectado';
  @override String get statusConnecting => 'Conectando…';
  @override String get statusDisconnected => 'Desconectado';

  @override String get hashrateTitle => 'HASHRATE DESTE APARELHO';
  @override String coresActive(int a, int t) => '$a de $t núcleos ativos';
  @override String coresAvailable(int t) => '$t núcleos disponíveis';

  @override String get bestDifficulty => 'MELHOR DIFICULDADE';
  @override String get acceptedShares => 'SHARES ACEITAS';
  @override String get blocksFound => 'BLOCOS ENCONTRADOS';
  @override String get poolBestShare => 'POOL: MELHOR SHARE';

  @override String get rewardDestination => 'DESTINO DO PRÊMIO';
  @override String get exampleAddrWarning =>
      '⚠️ Endereço de exemplo. Escaneie o SEU endereço antes de minerar.';
  @override String get scanDestinationBtn => 'Escanear endereço de destino';
  @override String get enterDestinationBtn => 'Digitar / colar endereço';
  @override String get enterAddressTitle => 'Endereço de destino';
  @override String get enterAddressHint => 'Cole ou digite o endereço Bitcoin';
  @override String get invalidAddress =>
      'Endereço Bitcoin inválido. Verifique e tente de novo.';
  @override String get pasteBtn => 'Colar';
  @override String get cancelBtn => 'Cancelar';
  @override String get saveBtn => 'Salvar';

  @override String get startMining => 'COMEÇAR A MINERAR';
  @override String get stopMining => 'PARAR MINERAÇÃO';

  @override String get eduTitle => 'Como funciona a mineração? 🎓';
  @override String get edu1Title => '1. O pool manda um "trabalho"';
  @override String get edu1Body =>
      'A public-pool envia um modelo de bloco (transações pendentes + cabeçalho). '
      'Seu celular monta o cabeçalho de 80 bytes.';
  @override String get edu2Title => '2. Seu celular testa números (nonces)';
  @override String get edu2Body =>
      'Para cada nonce, ele calcula SHA-256 duas vezes sobre o cabeçalho. '
      'É só tentativa e erro — bilhões de vezes por segundo nos ASICs, '
      'alguns milhares aqui.';
  @override String get edu3Title => '3. Procura um hash pequeno o suficiente';
  @override String get edu3Body =>
      'Se o resultado for menor que o alvo da REDE, você achou um bloco e ganha '
      'a recompensa inteira (~3,125 BTC + taxas), direto no seu endereço.';
  @override String get edu4Title => '4. Por que "loteria"?';
  @override String get edu4Body =>
      'A chance por aparelho é minúscula — mas é maior que zero, custa quase nada '
      'de energia e mostra que QUALQUER UM pode minerar, sem permissão.';

  @override String get logTitle => 'LOG';
  @override String get waiting => 'Aguardando…';
  @override String get viewOnMempool => 'Ver endereço no mempool.space';

  @override String get buyBitcoinTitle => 'Comprar Bitcoin (Binance)';
  @override String get qrInstruction =>
      'Aponte a câmera do SEU celular (não o que está minerando) '
      'para o QR e crie sua conta.';
  @override String get copyLink => 'Copiar link';
  @override String get openBtn => 'Abrir';
  @override String get linkCopied => 'Link copiado';

  @override String get addressCopied => 'Endereço copiado';
  @override String get destinationUpdated => 'Endereço de destino atualizado ✔';

  @override String get scanScreenTitle => 'Escanear endereço de destino';
  @override String get scanInvalid =>
      'QR lido não é um endereço Bitcoin válido.';
  @override String get scanHint =>
      'Aponte para o QR do endereço Bitcoin\npara onde o prêmio do bloco deve ir.';

  @override String logConnecting(String host, int port) =>
      'Conectando em $host:$port…';
  @override String get logConnected => 'Conectado. Assinando…';
  @override String logSubscribeOk(String en1, int size) =>
      'Subscribe OK. extranonce1=$en1, en2_size=$size';
  @override String get logAuthorized => 'Autorizado no pool ✔';
  @override String logAuthRejected(Object? e) => 'Autorização recusada: $e';
  @override String get logConnClosed => 'Conexão encerrada pelo pool.';
  @override String get logShareAccepted => 'Share ACEITA ✔';
  @override String logShareRejected(Object? e) => 'Share rejeitada: $e';
  @override String logSocketError(Object e) => 'Erro de socket: $e';
  @override String logParseError(Object e) => 'Falha ao parsear: $e';
  @override String logNewDifficulty(num d) => 'Nova dificuldade do pool: $d';
  @override String logNewJob(String id, bool clean) =>
      'Novo job $id (clean=$clean)';
  @override String logBlockFound(num diff) =>
      '🎉🎉 BLOCO ENCONTRADO! diff=$diff 🎉🎉';
  @override String logShareSent(String diff) => 'Share enviada (diff $diff)';
}

class _En extends S {
  const _En();
  @override String get langCode => 'EN';
  @override String get langOther => 'PT';

  @override String get statusStopped => 'Stopped';
  @override String get statusMining => 'Mining';
  @override String get statusConnected => 'Connected';
  @override String get statusConnecting => 'Connecting…';
  @override String get statusDisconnected => 'Disconnected';

  @override String get hashrateTitle => "THIS DEVICE'S HASHRATE";
  @override String coresActive(int a, int t) => '$a of $t cores active';
  @override String coresAvailable(int t) => '$t cores available';

  @override String get bestDifficulty => 'BEST DIFFICULTY';
  @override String get acceptedShares => 'ACCEPTED SHARES';
  @override String get blocksFound => 'BLOCKS FOUND';
  @override String get poolBestShare => 'POOL: BEST SHARE';

  @override String get rewardDestination => 'REWARD DESTINATION';
  @override String get exampleAddrWarning =>
      '⚠️ Example address. Scan YOUR address before mining.';
  @override String get scanDestinationBtn => 'Scan destination address';
  @override String get enterDestinationBtn => 'Type / paste address';
  @override String get enterAddressTitle => 'Destination address';
  @override String get enterAddressHint => 'Paste or type the Bitcoin address';
  @override String get invalidAddress =>
      'Invalid Bitcoin address. Check it and try again.';
  @override String get pasteBtn => 'Paste';
  @override String get cancelBtn => 'Cancel';
  @override String get saveBtn => 'Save';

  @override String get startMining => 'START MINING';
  @override String get stopMining => 'STOP MINING';

  @override String get eduTitle => 'How does mining work? 🎓';
  @override String get edu1Title => '1. The pool sends a "job"';
  @override String get edu1Body =>
      'public-pool sends a block template (pending transactions + header). '
      'Your phone assembles the 80-byte header.';
  @override String get edu2Title => '2. Your phone tries numbers (nonces)';
  @override String get edu2Body =>
      'For each nonce it runs SHA-256 twice over the header. '
      'Pure trial and error — billions per second on ASICs, '
      'a few thousand here.';
  @override String get edu3Title => '3. It looks for a small enough hash';
  @override String get edu3Body =>
      'If the result is below the NETWORK target, you found a block and earn '
      'the full reward (~3.125 BTC + fees), straight to your address.';
  @override String get edu4Title => '4. Why a "lottery"?';
  @override String get edu4Body =>
      'The chance per device is tiny — but greater than zero, costs almost no '
      'energy, and shows that ANYONE can mine, without permission.';

  @override String get logTitle => 'LOG';
  @override String get waiting => 'Waiting…';
  @override String get viewOnMempool => 'View address on mempool.space';

  @override String get buyBitcoinTitle => 'Buy Bitcoin (Binance)';
  @override String get qrInstruction =>
      'Point YOUR phone camera (not the mining one) '
      'at the QR and create your account.';
  @override String get copyLink => 'Copy link';
  @override String get openBtn => 'Open';
  @override String get linkCopied => 'Link copied';

  @override String get addressCopied => 'Address copied';
  @override String get destinationUpdated => 'Destination address updated ✔';

  @override String get scanScreenTitle => 'Scan destination address';
  @override String get scanInvalid => 'Scanned QR is not a valid Bitcoin address.';
  @override String get scanHint =>
      'Point at the QR of the Bitcoin address\nwhere the block reward should go.';

  @override String logConnecting(String host, int port) =>
      'Connecting to $host:$port…';
  @override String get logConnected => 'Connected. Subscribing…';
  @override String logSubscribeOk(String en1, int size) =>
      'Subscribe OK. extranonce1=$en1, en2_size=$size';
  @override String get logAuthorized => 'Authorized on pool ✔';
  @override String logAuthRejected(Object? e) => 'Authorization rejected: $e';
  @override String get logConnClosed => 'Connection closed by pool.';
  @override String get logShareAccepted => 'Share ACCEPTED ✔';
  @override String logShareRejected(Object? e) => 'Share rejected: $e';
  @override String logSocketError(Object e) => 'Socket error: $e';
  @override String logParseError(Object e) => 'Parse error: $e';
  @override String logNewDifficulty(num d) => 'New pool difficulty: $d';
  @override String logNewJob(String id, bool clean) =>
      'New job $id (clean=$clean)';
  @override String logBlockFound(num diff) =>
      '🎉🎉 BLOCK FOUND! diff=$diff 🎉🎉';
  @override String logShareSent(String diff) => 'Share sent (diff $diff)';
}
