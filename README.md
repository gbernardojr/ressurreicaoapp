# App Ressurreição

Aplicativo Flutter de consulta de mensalidades, boletos e entes queridos do Grupo Ressurreição.

## Requisitos

- Flutter 3.41.6 (ou stable compatível)
- Android SDK 36
- Xcode e CocoaPods para builds iOS

## Configuração

A URL e a chave publishable do Supabase ficam em `lib/config/app_config.dart`.

A chave publishable é pública e pode ficar no repositório. Nunca inclua a chave `service_role` no app.

## Executar localmente

```bash
flutter pub get
flutter run
```

## Build

```bash
flutter build apk --release
flutter build appbundle --release
```

Identificadores do app:

- Android: `br.com.cemiteriodaressurreicao.app`
- iOS: `br.com.cemiteriodaressurreicao.app`

## Codemagic

O arquivo `codemagic.yaml` define o workflow `android-release`, que executa análise, testes e gera APK + AAB.

O build assina com a chave de debug enquanto `android/key.properties` não existir. Para publicar na Play Store:

1. Gere o keystore de upload.
2. Cadastre no Codemagic as variáveis `CM_KEYSTORE` (base64 do keystore), `CM_KEYSTORE_PASSWORD`, `CM_KEY_PASSWORD` e `CM_KEY_ALIAS`.
3. O workflow cria `android/key.properties` automaticamente antes do build.

O build iOS ainda requer configuração de assinatura e certificados no Codemagic.
