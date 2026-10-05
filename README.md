# BInova

Aplicación móvil Flutter para la prueba técnica de Banco Internacional.

## Arquitectura

- Clean Architecture por feature: `data`, `domain`, `presentation`.
- Provider + `ChangeNotifier` para estado de UI.
- `http` para el contrato REST versionado `/v1`.
- `flutter_secure_storage` para sesiones.
- Caché local con `SharedPreferences` siguiendo la política de 60 segundos.
- `local_auth` para Face ID/biometría; Firebase/FCM queda para la fase final.

## Configuración

```powershell
dart pub get
dart analyze
```

La URL se configura con defines de compilación:

```powershell
flutter run --dart-define=API_BASE_URL=https://api.demo.binova.local/v1 --dart-define=ENVIRONMENT=demo
```

Developer Tools aparece solo en debug o cuando el ambiente es `demo` y se
compila con `--dart-define=ENABLE_DEMO_TOOLS=true`. Permite demostrar normal,
slow, offline, server error y timeout sin alterar la API ni la red física.

Sin `--dart-define`, el entorno `local` usa `http://10.0.2.2:3000/v1` en el
emulador Android y `http://localhost:3000/v1` en iOS Simulator, escritorio y
web. Puedes sobrescribirlo con `API_BASE_URL` cuando sea necesario.

Para iOS se requiere `NSFaceIDUsageDescription`, ya incluido en
`ios/Runner/Info.plist`. Para Android, el proyecto usa `minSdk 23`, `compileSdk 36`
y `NDK 27.0.12077973` por los plugins de almacenamiento seguro y biometría.

## Verificación

```powershell
flutter test --no-pub
flutter build apk --debug
```

El backend debe responder con los envelopes definidos en
`../context/contracts/openapi.yaml`. No se deben usar tokens, PAN, CVV, saldos
ni PII en logs.
