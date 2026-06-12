# Prompt para o Claude Code (terminal)

Cole o texto abaixo no Claude Code, dentro da pasta onde você descompactou o
projeto (a pasta que contém `pubspec.yaml`, `lib/` e `native/`).

---

Você está num projeto Flutter chamado **Borderless Miner**: um minerador solo de
Bitcoin (modo loteria) para celulares Android antigos, que aponta para a pool
`public-pool.io`. O código já está escrito em `lib/` e `native/`. Sua tarefa é
finalizar a configuração do Android, garantir que compila e gerar o APK release.

Contexto do que o app faz (não reescreva isso, só garanta que funciona):
- Núcleo de hashing SHA-256d em C (`native/miner.c`), chamado via `dart:ffi`
  (`lib/mining/native_miner.dart`), gerando `libminer.so`.
- Mineração multicore: um isolate por núcleo (`lib/mining/miner.dart`).
- Cliente Stratum V1 sobre TCP para `public-pool.io:3333`
  (`lib/mining/stratum_client.dart`).
- Dashboard no estilo da public-pool (`lib/ui/dashboard_screen.dart`).
- QR code do link de afiliado da Binance (`lib/ui/widgets/buy_bitcoin_qr.dart`).
- Leitura por câmera do QR do **endereço de destino** do prêmio, com validação
  bech32/base58check (`lib/ui/scan_address_screen.dart`,
  `lib/services/btc_address.dart`, `lib/services/address_store.dart`).
- App **bilíngue PT/EN** com troca de idioma em tempo real (`lib/l10n/`).

Faça, na ordem:

1. Rode `flutter create .` para gerar as pastas de plataforma (NÃO sobrescreva
   `lib/`, `native/` nem `pubspec.yaml`). Depois `flutter pub get`.

2. No `android/app/build.gradle` (ou `build.gradle.kts`), dentro do bloco
   `android { ... }`, adicione o build nativo e a versão do NDK:
   ```
   ndkVersion = "26.1.10909125"   // ou a versão de NDK instalada
   externalNativeBuild {
       cmake {
           path = file("../../native/CMakeLists.txt")
       }
   }
   ```
   E ajuste `minSdk` para `21` (cobrir celulares antigos) e
   `targetSdk`/`compileSdk` para a versão estável atual.

3. No `android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>` e antes
   de `<application>`, adicione as permissões:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.WAKE_LOCK"/>
   <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
   <uses-permission android:name="android.permission.CAMERA"/>
   <uses-feature android:name="android.hardware.camera" android:required="false"/>
   ```

4. Rode `flutter analyze`. Corrija TODOS os erros de compilação que aparecerem
   (ajuste de imports, APIs de `mobile_scanner`/`qr_flutter`/`wakelock_plus`
   conforme a versão resolvida no `pubspec.lock`, etc.). Não mude a lógica de
   mineração nem a montagem do cabeçalho de bloco em `native/miner.c` ou
   `lib/mining/` — ela já foi validada contra o hash do bloco gênese.

5. Gere o APK release:
   ```
   flutter build apk --release
   ```
   Se quiser APKs menores por arquitetura, use também
   `flutter build apk --release --split-per-abi`.

6. Verifique que a biblioteca nativa foi empacotada. Rode:
   ```
   unzip -l build/app/outputs/flutter-apk/app-release.apk | grep libminer.so
   ```
   Deve aparecer `lib/arm64-v8a/libminer.so` e `lib/armeabi-v7a/libminer.so`.
   Se não aparecer, o `externalNativeBuild`/CMake não está ligado — conserte e
   recompile.

7. No final, me diga: o caminho do APK gerado, o tamanho, e o resultado do
   `flutter analyze`. Se um aparelho estiver conectado (`flutter devices`),
   ofereça instalar com `flutter install`.

Observações:
- Antes de minerar de verdade, o endereço de destino deve ser o do usuário —
  ou trocando `bitcoinAddress` em `lib/config.dart`, ou escaneando um QR no app.
  O app já avisa em vermelho quando ainda está no endereço de exemplo.
- Não suba o projeto com nenhum segredo. O link da Binance é público (afiliado).
