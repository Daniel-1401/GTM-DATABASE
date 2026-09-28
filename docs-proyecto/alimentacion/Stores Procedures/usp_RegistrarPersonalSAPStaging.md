# Contrato: integracion.usp_RegistrarPersonalSAPStaging

## Propósito

Recibe desde el backend uno o varios eventos SAP v1 ya deserializados y los conserva, sin promoción hacia las tablas maestras, en `integracion.PersonalSAPStaging`.

## Firma

```sql
[integracion].[usp_RegistrarPersonalSAPStaging]
    @Eventos [integracion].[TVP_RecepcionPersonalSAP] READONLY,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
```

`@Eventos` representa una o varias filas. Cada una contiene la envoltura aprobada (`IdEventoOrigen`, tipo, versión, fecha, secuencia, fuente y posición Kafka), `PayloadOriginal` y los 63 campos SAP normalizados. Los 63 campos son `NVARCHAR(MAX) NULL`, sin conversión de dominio.

## Resultado

En éxito devuelve un recordset de una fila y tres columnas, en este orden: `TotalRecibidos`, `Insertados`, `DuplicadosIdempotentes`.

| Código | Mensaje seguro | Cuándo ocurre |
|---|---|---|
| `CREATED` | Los eventos SAP fueron registrados. | Se insertó al menos un evento nuevo. |
| `IDEMPOTENT_REPLAY` | Los eventos SAP ya fueron recibidos. | Todas las filas ya existían o se repetían dentro del lote. |
| `VALIDATION_ERROR` | El lote de eventos SAP no cumple el contrato de recepcion. | El lote es vacío, falla la envoltura SAP v1, el transporte Kafka, el payload JSON requerido o contiene una colisión interna incompatible. |
| `INTERNAL_ERROR` | No fue posible completar la operacion. | Error inesperado. No devuelve recordset de datos. |

## Reglas relevantes

- Exige `eventType = sap.personal.actualizado`, `schemaVersion = 1`, `source = SAP`, identificador de evento, fecha, secuencia, topic, partición, offset y un `PayloadOriginal` no vacío y JSON válido mediante `ISJSON`. El payload se conserva como evidencia; el mapeo de los 63 campos procede exclusivamente del TVP, sin `OPENJSON`.
- La tabla es append-only. Nunca actualiza ni promueve datos a `Persona`, `Colaborador`, `Empresa` ni entidades UO.
- La idempotencia se evalúa por `IdEventoOrigen` y, de forma independiente, por `KafkaTopic + KafkaPartition + KafkaOffset`. Solo filas exactamente equivalentes dentro de un mismo TVP se deduplican; si cualquiera de esos identificadores se asocia a una posición Kafka, payload o cualquier atributo distinto, el lote se rechaza con `VALIDATION_ERROR` antes de abrir la transacción.
- La inserción se ejecuta con transacción `TRY/CATCH`, `XACT_ABORT` y bloqueos `UPDLOCK, HOLDLOCK` para proteger los dos identificadores únicos frente a consumidores concurrentes, sin cambiar el nivel de aislamiento de la sesión pooled. Si una carrera alcanza una restricción única, solo devuelve `IDEMPOTENT_REPLAY` tras rollback cuando todas las identidades del lote ya existen; cualquier otra violación conserva el flujo auditado de `INTERNAL_ERROR`.

## Auditoría de errores

La migración corporativa crea `auditoria.ErrorProcedimiento` y el procedure interno `auditoria.usp_RegistrarErrorProcedimiento`. Ante un error inesperado, el CATCH conserva primero número, estado, línea y detalle nativo; después intenta registrarlos sin dejar que un fallo de auditoría altere la respuesta API. El backend recibe únicamente `INTERNAL_ERROR` y el mensaje seguro estándar.
