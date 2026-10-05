# BInova Mobile

Aplicación móvil Flutter para la prueba técnica de la plataforma financiera BInova.

## Arquitectura y dependencias

- Clean Architecture organizada por feature: `data`, `domain` y `presentation`.
- Provider + `ChangeNotifier` para estado y coordinación de UI.
- `package:http` para el contrato REST versionado `/v1`.
- `flutter_secure_storage` para la sesión local.
- `shared_preferences` para onboarding, preferencias y caché de lectura.
- `local_auth` para Face ID/biometría.
- `dart:developer` para logs técnicos sanitizados en local, debug y demo.

La capa `presentation` no realiza HTTP. Los datasources consumen el contrato del API y los repositorios aplican la política de caché/degradación.

## Requisitos y configuración

Se requiere Flutter compatible con Dart `>=3.5.0 <4.0.0`.

```bash
flutter pub get
flutter analyze
flutter test --no-pub
```

El API local escucha en `http://localhost:3000/v1`. Para un emulador Android se usa `10.0.2.2`:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:3000/v1 \
  --dart-define=ENVIRONMENT=local
```

Los valores soportados para `ENVIRONMENT` son `local`, `dev`, `test`, `demo` y `prodEvolution`. Developer Tools aparece en debug o cuando `ENVIRONMENT=demo` y `ENABLE_DEMO_TOOLS=true`; permite simular red normal, lenta, offline, error de servidor y timeout.

## Contrato del API

Las respuestas exitosas tienen esta forma:

```json
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
```

Los errores conservan `data: null` y agregan un código estable:

```json
{
  "data": null,
  "message": "La sesión expiró.",
  "statusCode": 401,
  "code": "SESSION_EXPIRED",
  "details": {},
  "meta": { "traceId": "api-...", "generatedAt": "2026-10-05T12:00:00.000Z" }
}
```

El detalle ejecutable está en [`../context_specs/contracts/openapi.yaml`](../context_specs/contracts/openapi.yaml). `meta.nextCursor` se utiliza para lecturas paginadas y `X-Correlation-Id` enlaza la llamada móvil con el API.

## Push Android

La app usa Firebase Cloud Messaging únicamente en Android. El proyecto ya incluye
android/app/google-services.json para el proyecto Firebase binova-92083 y
lib/firebase_options.dart con las opciones Android generadas desde esa configuración.
El archivo de cuenta de servicio de Firebase pertenece exclusivamente al API y nunca
debe copiarse al proyecto Flutter.

En el primer login o desbloqueo biométrico, la app solicita permiso de notificaciones,
obtiene el token FCM y registra solo el id devuelto por POST /v1/devices en el
almacenamiento local. El token FCM no se persiste ni se escribe en logs. Al cerrar
sesión se revoca el dispositivo en el API.

Los mensajes en primer plano se muestran mediante una notificación local con el canal
binova_general. En segundo plano o con la app terminada, Android muestra el mensaje
FCM en la bandeja y los taps se resuelven mediante onMessageOpenedApp o
getInitialMessage. Solo se permiten destinos conocidos: movimiento, cuenta, tarjeta,
perfil e Insights; un payload inválido vuelve a Inicio.

Para probarlo se necesita un emulador Android con Google Play Services o un dispositivo
Android, el API accesible desde ese equipo, Firebase Messaging habilitado y una sesión
iniciada. Con PUSH_TEST_ENDPOINT_ENABLED=true en el API, se puede invocar
POST /v1/notifications/test con el access token para generar una notificación segura.

La compilación iOS no inicializa Firebase en esta iteración; la configuración y
recepción push de iOS quedan fuera del alcance aprobado.

## Logs sanitizados

Al ejecutar la app en local, debug o demo, los logs aparecen en la consola de `flutter run` y en las herramientas de desarrollo de Dart. Cada respuesta registra únicamente método, ruta, status HTTP, duración, mensaje, código estable y `traceId`.

No se registran `data`, cuerpos de solicitud, headers de autorización, access/refresh tokens, contraseñas, saldos, PAN/CVV, números completos de cuenta/tarjeta ni claves de idempotencia.

## Alcance actual

La app cubre onboarding, autenticación y sesión segura, dashboard personalizado, cuentas, movimientos, operaciones demo de transferencia/pago/recarga, tarjetas, insights, tipo de cambio, inbox de notificaciones, push Android en primer y segundo plano, navegación desde notificaciones, perfil y estados degradados. Crashlytics/Sentry y un flujo E2E automatizado todavía requieren integración/evidencia adicional; la validación push en dispositivo real queda pendiente.
