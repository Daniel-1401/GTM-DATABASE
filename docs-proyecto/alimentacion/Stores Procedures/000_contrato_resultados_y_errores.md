# Contrato estándar de resultados y errores para SP API

Este documento es obligatorio para los procedimientos almacenados expuestos al
backend. Los SP internos que no formen parte de una API deben declararse como
internos y no compartir este prefijo de contrato.

## Firma obligatoria

Todo SP API termina su firma con:

```sql
@Codigo NVARCHAR(50) OUTPUT,
@Mensaje NVARCHAR(500) OUTPUT
```

Al inicio debe ejecutar `SET NOCOUNT ON`, `SET XACT_ABORT ON`, asignar
`@Codigo = N'OK'` y `@Mensaje = NULL`.

## Resultado funcional

Los recordsets existentes mantienen sus columnas y orden. El backend determina
el resultado de la operación mediante los parámetros output:

| Tipo de resultado | Códigos permitidos |
|---|---|
| Lectura exitosa | `OK` |
| Creación exitosa | `CREATED` |
| Actualización o eliminación exitosa | `UPDATED` o `SUCCESS` |
| Repetición idempotente exitosa | `IDEMPOTENT_REPLAY` |
| Error funcional | Código de la familia permitida por el contrato del SP |
| Error inesperado | `INTERNAL_ERROR` |

En un error funcional el SP no devuelve un recordset de datos. Los mensajes son
seguros, legibles y no incluyen objetos SQL, errores nativos, secretos, tokens,
QR, evidencia BLE ni claves de idempotencia.

## Códigos funcionales permitidos

Se usan únicamente los códigos definidos por la plataforma: `BAD_REQUEST`,
`VALIDATION_ERROR`, `INVALID_REQUEST`, `INVALID_FILTER`,
`INVALID_IDEMPOTENCY_KEY`, `UNAUTHORIZED`, `AUTH_REQUIRED`,
`INVALID_IDENTITY`, `FORBIDDEN`, `ROLE_FORBIDDEN`,
`APPLICATION_FORBIDDEN`, `OWNERSHIP_FORBIDDEN`, `SITE_FORBIDDEN`, `NOT_OWNER`,
`NOT_FOUND`, `PLAN_NOT_FOUND`, `MENU_NOT_FOUND`, `RESERVATION_NOT_FOUND`,
`QR_NOT_FOUND`, `VALIDATION_NOT_FOUND`, `DELIVERY_VALIDATION_NOT_FOUND`,
`CONFLICT`, `PLAN_VERSION_CONFLICT`, `IDEMPOTENCY_CONFLICT`,
`UNIQUE_CONFLICT`, `STATE_CONFLICT`, `PLAN_ALREADY_EXISTS`,
`MENU_ALREADY_EXISTS`, `RESERVATION_ALREADY_EXISTS`,
`ACTIVE_RESERVATION_EXISTS`, `ACTIVE_QR_EXISTS`, `ALREADY_DELIVERED`,
`UNPROCESSABLE`, `BUSINESS_RULE_VIOLATION`, `INVALID_PLAN_STATE`,
`PLAN_CONSOLIDATED`, `AFFECTED_RESERVATIONS_CONFIRMATION_REQUIRED`,
`SERVICE_NOT_AVAILABLE`, `RESERVATIONS_CLOSED`, `QR_INVALID`, `QR_EXPIRED`,
`QR_REVOKED`, `QR_ALREADY_USED`, `BEACON_NOT_ELIGIBLE`,
`DELIVERY_VALIDATION_EXPIRED`, `UNAVAILABLE`, `DEPENDENCY_UNAVAILABLE`,
`CONFIGURATION_UNAVAILABLE` y `DATABASE_UNAVAILABLE`.

## Transacciones y errores inesperados

Las mutaciones se ejecutan en `TRY/CATCH`. Antes de terminar por un error de
negocio dentro de una transacción se hace `ROLLBACK` solo si `XACT_STATE() <> 0`.
El `CATCH` aplica la misma regla, registra internamente el detalle conforme a la
política de auditoría y devuelve exclusivamente:

```sql
SET @Codigo = N'INTERNAL_ERROR';
SET @Mensaje = N'No fue posible completar la operación.';
```

Los nuevos SP API deben documentar su firma, todos sus códigos posibles,
mensajes seguros, recordsets y reglas transaccionales siguiendo esta plantilla.
