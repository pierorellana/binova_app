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

## Logs sanitizados

Al ejecutar la app en local, debug o demo, los logs aparecen en la consola de `flutter run` y en las herramientas de desarrollo de Dart. Cada respuesta registra únicamente método, ruta, status HTTP, duración, mensaje, código estable y `traceId`.

No se registran `data`, cuerpos de solicitud, headers de autorización, access/refresh tokens, contraseñas, saldos, PAN/CVV, números completos de cuenta/tarjeta ni claves de idempotencia.

## Alcance actual

La app cubre onboarding, autenticación y sesión segura, dashboard personalizado, cuentas, movimientos, operaciones demo de transferencia/pago/recarga, tarjetas, insights, tipo de cambio, inbox de notificaciones, perfil y estados degradados. FCM/push real, Crashlytics/Sentry y un flujo E2E automatizado todavía requieren integración/evidencia adicional.
