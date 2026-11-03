# Alias de acceso y fallback

La app permite iniciar sesión con un alias o con el correo completo. El alias
no es un correo derivado: es una identidad propia guardada en
`usuarios/{uid}.usuario` y en `aliases/{alias}`.

## Camino preferido: Cloud Function

- Función `resolveAlias` con App Check en enforcement.
- Límite de intentos por IP y por alias.
- Respuesta homogénea exista o no el alias.
- Devuelve el correo; Firebase Auth valida la contraseña.
- La recuperación de contraseña pide siempre el correo completo.

## Fallback de beta (sin Blaze)

Mientras el proyecto no tenga Blaze se permite `aliases/{alias}.get()` con:

```text
aliases/{alias}
  uid: string
  email: string
  alias: string
  createdAt: timestamp
```

Reglas: `allow get: if true`, `allow list: if false`, creación/borrado solo por
el propietario del alias.

Esta ruta expone el correo a quien conozca el alias. Es una deuda aceptada solo
para beta cerrada.

## Salida obligatoria

Condición de salida:

1. Cloud Function desplegada con App Check.
2. Rate limit probado por IP y alias.
3. Migración de usuarios existentes completada.
4. 7 días consecutivos de logins por alias sin incidentes críticos.

Fecha límite: **2026-12-31**. Si no se cumple, el login por alias se desactiva
y se exige correo completo hasta terminar la migración.

## Migración

`tool/migrate_aliases.mjs` propone el alias desde la parte local del correo,
resuelve colisiones con sufijo y escribe el alias en `usuarios/{uid}` y
`aliases/{alias}`. Requiere una credencial de servicio con acceso a Firestore.
