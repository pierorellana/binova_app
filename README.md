
# BInova Mobile

Aplicación móvil Flutter de la prueba técnica Senior Front-End de BInova. Consume el API
REST versionado /v1 y conserva una arquitectura por features, contratos y capas.

## Estado actual

- Flutter/Dart con Clean Architecture por feature y Provider/ChangeNotifier.
- Onboarding, autenticación, refresh de sesión, almacenamiento seguro y biometría local.
- Dashboard server-driven, cuentas, movimientos, tarjetas, operaciones demo, insights,
  tipo de cambio, notificaciones, perfil y estados degradados.
- Logging de respuestas API sanitizado con método, ruta, status, latencia, mensaje, código
  y traceId.
- Firebase Cloud Messaging implementado únicamente para Android, con recepción en primer
  plano, segundo plano y app terminada.
- Prueba E2E crítica ejecutada correctamente en un iPhone físico.
- Pruebas de widgets, semántica y objetivos táctiles Android/iOS aprobadas.

## Requisitos

- Flutter SDK compatible con Dart >=3.5.0 <4.0.0.
- El repositorio fija Flutter 3.47.5 mediante FVM.
- Android Studio/Xcode según la plataforma de ejecución.
- Un API BInova accesible y PostgreSQL activo para el entorno local.

## Instalación y ejecución

    fvm flutter pub get
    fvm flutter test
    fvm flutter analyze

Para ejecutar con el API local:

    fvm flutter run \
      --dart-define=API_BASE_URL=http://localhost:3000/v1 \
      --dart-define=ENVIRONMENT=local

En Android Emulator, el API del equipo normalmente se expone como
http://10.0.2.2:3000/v1. En un dispositivo físico se debe usar una URL accesible por
la red del dispositivo, por ejemplo un túnel HTTPS:

    fvm flutter run \
      --dart-define=API_BASE_URL=https://9hqbzkgw-3000.use.devtunnels.ms/v1 \
      --dart-define=ENVIRONMENT=local

API_BASE_URL sobrescribe la URL compilada por defecto. Los valores soportados para
ENVIRONMENT son local, dev, test, demo y prodEvolution.

Developer Tools está disponible en debug o cuando ENVIRONMENT=demo y
ENABLE_DEMO_TOOLS=true. Permite simular red normal, lenta, offline, error de servidor
y timeout para comprobar estados degradados.

## Arquitectura

    lib/
      app/        bootstrap, routing, theme
      core/       config, network, errors, security, storage, observability, UI
      features/   auth, onboarding, home, accounts, transactions, cards,
                  operations, insights, exchange, notifications, profile

Cada feature conserva data, domain y presentation. La UI no realiza HTTP directamente:
los datasources consumen el contrato, los repositorios aplican mapeo y caché, y los
providers coordinan el estado de pantalla.

## Contrato del API

Las respuestas exitosas usan este envelope:

    {
      "data": { "id": "resource-1" },
      "message": "Operación exitosa.",
      "statusCode": 200,
      "meta": {
        "traceId": "api-...",
        "generatedAt": "2026-10-05T12:00:00.000Z",
        "nextCursor": null
      }
    }

Los errores usan data: null y agregan code y details. El contrato ejecutable está en
[context_specs/contracts/openapi.yaml](../context_specs/contracts/openapi.yaml).
X-Correlation-Id enlaza la llamada móvil con el API y meta.nextCursor soporta lecturas
paginadas.

## Firebase y push Android

La integración Android usa:

- android/app/google-services.json del proyecto Firebase binova-92083.
- lib/firebase_options.dart generado para Android.
- Firebase Core, Firebase Messaging y notificaciones locales.
- Registro y revocación de dispositivos mediante /v1/devices.
- Inbox y navegación allowlisted desde notificaciones.

En primer plano se muestra una notificación local. En segundo plano o con la app
terminada, Android usa la bandeja FCM y los taps se resuelven mediante
onMessageOpenedApp o getInitialMessage.

El token FCM no se persiste ni se escribe en logs. El payload contiene únicamente
type, notificationId, resourceType y resourceId. El archivo de cuenta de servicio de
Firebase pertenece al API, está excluido por .gitignore y nunca debe copiarse al
proyecto Flutter.

La validación manual Android fue realizada y confirmada en el dispositivo de prueba.
iOS push permanece fuera del alcance aprobado; la app no inicializa Firebase en iOS.

## Logging sanitizado

En local, debug y demo, los logs aparecen en la consola de Flutter/Dart. No se registran
cuerpos de respuesta, cuerpos de solicitud, headers de autorización, tokens,
contraseñas, saldos, PAN/CVV, números completos de cuenta/tarjeta ni claves de
idempotencia.

## Pruebas y evidencia

Pruebas rápidas:

    fvm flutter test
    fvm flutter test test/widgets_accessibility_test.dart

La suite actual cubre contrato/envelope, logging, autenticación, sesión, push, modos de
red, onboarding y widgets. El E2E crítico se ejecuta en un dispositivo físico:

    fvm flutter test integration_test/critical_flow_test.dart \
      -d 00008140-001461680A7B801C \
      --dart-define=API_BASE_URL=https://9hqbzkgw-3000.use.devtunnels.ms/v1 \
      --dart-define=ENVIRONMENT=local

Flujo E2E validado:

Login -> Home -> Productos -> Cuenta de ahorros -> Movimientos -> Detalle

La evidencia se conserva en
[context_specs/evidence/e2e-critical-flow-2026-10-05.md](../context_specs/evidence/e2e-critical-flow-2026-10-05.md)
y
[context_specs/evidence/widget-accessibility-validation-2026-10-05.md](../context_specs/evidence/widget-accessibility-validation-2026-10-05.md).

## Limitaciones actuales

- No hay workflow CI/CD publicado para análisis, tests, OpenAPI, migraciones y secret scan.
- El proveedor FX real requiere URL y credenciales externas; el adapter demo funciona sin
  esas credenciales.
- Crashlytics/Sentry, métricas persistidas, dashboards y alertas de producción no están
  configurados.
- El signing de release y el despliegue productivo quedan fuera de esta entrega.
- La recuperación de contraseña tiene únicamente la experiencia visual del prototipo;
  no existe endpoint backend.
- El E2E de transferencia con Face ID y la recuperación E2E de estados offline todavía
  no están automatizados.

La configuración pública de Firebase para Android no reemplaza el secreto de cuenta de
servicio del backend. Nunca subas claves privadas, .env ni tokens a Git.
