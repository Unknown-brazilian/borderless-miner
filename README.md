# ₿ Borderless Miner — Lottery Solo Miner para celulares velhos

Minerador Bitcoin **solo** (modo loteria) que roda em celulares Android antigos,
apontando para a **public-pool.io**. Reaproveita aparelhos que iriam pro lixo,
gasta pouca energia e serve como **ferramenta educativa**: mostra na prática como
funciona a mineração e que qualquer pessoa pode minerar, sem pedir permissão.

> Se um bloco for encontrado, a recompensa inteira (~3,125 BTC + taxas) vai
> **direto para o seu endereço** — a public-pool é sem custódia e sem taxa.

**Bilíngue (PT/EN):** detecta o idioma do aparelho no 1º uso, tem um botão de
troca (PT/EN) na barra superior e salva a preferência. Strings em `lib/l10n/`.

**Núcleo de hashing em C (via `dart:ffi`) + multicore (um isolate por núcleo).**

**Endereço de destino por QR:** o celular minerador escaneia, pela câmera, o QR
de um endereço Bitcoin (ou URI `bitcoin:...`). O endereço é validado (checksum
bech32/bech32m e base58check) e salvo no aparelho — assim o prêmio do bloco vai
para a carteira que você escolher, sem digitar nada.

---

## ⚠️ Expectativa honesta (deixe isso claro no vídeo/app)

Isto é **loteria**, não rendimento:

- Com o núcleo nativo + midstate, cada núcleo de celular faz da ordem de
  **centenas de kH/s a ~1 MH/s**. Somando os núcleos, alguns **MH/s**. Um
  Antminer S19 faz **~100–250 TH/s** — ainda cerca de **um milhão de vezes mais**.
- A chance de um celular achar um bloco continua **astronômica** (perto de zero
  numa vida inteira). Mas é **maior que zero**, custa quase nada de energia, e
  esse é o ponto: *qualquer um pode participar da rede sem permissão*.
- O valor é **educativo + simbólico + reaproveitamento de e-waste**, não ROI.

---

## 🔌 Pool configurada

| | |
|---|---|
| Stratum V1 | `public-pool.io:3333` |
| Usuário | `<seu endereço BTC>.<worker>` |
| Senha | `x` |
| API do dashboard | `https://public-pool.io:40557/api` |

Edite só o **`lib/config.dart`**: troque `bitcoinAddress` pelo seu endereço
(`bc1...`). O link de afiliado da Binance também fica lá e vira um **QR code** na
tela (para escanear com OUTRO celular, não o que está minerando).

---

## 🛠️ Build (Debian 13 + Flutter)

```bash
cd borderless_miner
flutter create .            # gera android/ ios/ etc. (não sobrescreve lib/)
flutter pub get
```

### 1) Ligar o núcleo nativo em C (NDK/CMake)

Adicione ao `android/app/build.gradle`, dentro do bloco `android { ... }`:

```gradle
android {
    // ... (namespace, compileSdk, etc.)
    ndkVersion "26.1.10909125"   // ou a versão de NDK instalada

    externalNativeBuild {
        cmake {
            path "../../native/CMakeLists.txt"
        }
    }
}
```

Isso compila `native/miner.c` para todas as ABIs (arm64-v8a, armeabi-v7a, …) e
empacota o `libminer.so` no APK. O Dart o carrega com
`DynamicLibrary.open('libminer.so')` (já implementado em `lib/mining/native_miner.dart`).

> Se faltar o NDK, instale pelo Android Studio (SDK Manager → SDK Tools → NDK).

### 2) Permissões — `android/app/src/main/AndroidManifest.xml`

Dentro de `<manifest>`, antes de `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>
```

A câmera é usada só para **escanear o QR do endereço de destino**. O
`mobile_scanner` pede a permissão em tempo de execução. (No iOS, adicione
`NSCameraUsageDescription` ao `Info.plist`.)

### 3) Celulares bem antigos

No `android/app/build.gradle`, abaixe `minSdkVersion` (ex.: `21` = Android 5.0).

### 4) Compilar

```bash
flutter build apk --release   # build/app/outputs/flutter-apk/app-release.apk
# ou: flutter run --release   (com o aparelho no USB)
```

---

## 🧮 Multicore

Ao iniciar, o app sobe **um isolate por núcleo** (`Platform.numberOfProcessors`).
Cada isolate:

- carrega o `libminer.so` (FFI) e tem seus próprios buffers nativos;
- usa um **extranonce2 aleatório diferente**, então cada núcleo busca num espaço
  independente (sem trabalho duplicado);
- chama `mine_batch(...)` em lotes de 200k nonces e reporta hashrate/melhor
  dificuldade de volta ao `Miner`, que **soma** os núcleos para a UI.

Quer limitar núcleos (para esquentar menos)? Chame `miner.start(threadCount: 2)`.

---

## 🔋 Segurança e cuidado com o aparelho (e-waste)

Mineração roda a CPU a 100% por horas. Em celulares velhos:

- **Sempre no carregador** e, se possível, **sem a bateria** (ou bateria
  saudável). Bateria velha de lítio sob carga + calor pode **inchar** — risco real
  de incêndio. Se inchar, **pare na hora**.
- Lugar **ventilado**, longe de pano/sofá/cama. Não cubra.
- Se esquentar demais, reduza os núcleos (`threadCount`).

---

## 🔬 Como o hashing nativo foi validado

`native/miner.c` foi compilado e testado contra o **hash real do bloco gênese**
do Bitcoin (`000000000019d6…ce26f`) — bateu exatamente, confirmando a montagem do
cabeçalho e a ordem de bytes (a parte que mais quebra minerador caseiro).

Otimizações já aplicadas: **midstate** (1º bloco SHA-256 calculado uma vez por
job → ~33% menos trabalho por hash) e `-O3 -ftree-vectorize`.

---

## 🗂️ Estrutura

```
native/
├── miner.c                      # SHA-256d + midstate + mine_batch  (C)
└── CMakeLists.txt               # build NDK -> libminer.so
lib/
├── config.dart                  # endereço, pool, link Binance  <- EDITE AQUI
├── theme.dart
├── main.dart
├── l10n/
│   ├── strings.dart             # textos PT + EN
│   └── l10n.dart                # troca/persistência de idioma (`tr.*`)
├── mining/
│   ├── sha256d.dart             # helpers de bytes/endianness + merkle (Dart)
│   ├── native_miner.dart        # ponte FFI com o libminer.so
│   ├── job.dart                 # job do mining.notify
│   ├── stratum_client.dart      # Stratum V1 sobre TCP
│   ├── mining_isolate.dart      # 1 isolate: monta cabeçalho + chama o C
│   └── miner.dart               # multicore: N isolates + agrega stats
├── services/
│   ├── pool_api.dart            # API da public-pool (dashboard)
│   ├── btc_address.dart         # validação bech32/bech32m + base58check
│   └── address_store.dart       # salva o endereço de destino (shared_preferences)
├── models/format.dart
└── ui/
    ├── dashboard_screen.dart    # dashboard estilo public-pool
    ├── scan_address_screen.dart # câmera p/ ler o QR do endereço de destino
    └── widgets/
        ├── stat_card.dart
        └── buy_bitcoin_qr.dart  # QR code do link da Binance
```

---

Feito para o **Borderless Freedom / BitBelgica**. Bitcoin, não "crypto". 🟧
