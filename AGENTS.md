# Estándar para stored procedures API

Estas reglas aplican a todo stored procedure nuevo o modificado que sea
consumido por el backend. Los requisitos funcionales y las referencias
particulares de cada caso de uso se indicarán en su prompt de trabajo.

## Contrato y consistencia

- Respetar `docs-proyecto/alimentacion/Stores Procedures/000_contrato_resultados_y_errores.md`.
- Terminar la firma con `@Codigo NVARCHAR(50) OUTPUT` y
  `@Mensaje NVARCHAR(500) OUTPUT`.
- Iniciar con `SET NOCOUNT ON`, `SET XACT_ABORT ON`, `@Codigo = N'OK'` y
  `@Mensaje = NULL`.
- Usar únicamente códigos de salida aprobados y mensajes seguros; nunca
  exponer detalles internos de SQL, secretos, tokens o datos de terceros.
- No inventar tablas, columnas, índices, estados, transiciones ni reglas de
  negocio. Si falta una capacidad física indispensable, documentar el límite y
  detenerse antes de alterar el modelo sin autorización explícita.

## Seguridad y transacciones

- El backend es la autoridad de autenticación y autorización; los clientes no
  acceden directamente a SQL Server.
- Validar los parámetros que pertenecen al contrato del procedure.
- Las mutaciones deben ejecutarse dentro de una transacción `TRY/CATCH`, con
  bloqueos y control de concurrencia proporcionales a su operación.
- Antes de retornar por un error funcional dentro de una transacción, ejecutar
  `ROLLBACK` solo si `XACT_STATE() <> 0`.
- En un error inesperado, registrar el detalle mediante el mecanismo de
  auditoría existente y devolver exclusivamente `INTERNAL_ERROR` con el
  mensaje seguro estándar.
- Las lecturas no deben modificar estado ni abrir transacciones innecesarias.

## Entrega y calidad

- Crear o actualizar el contrato Markdown correspondiente en
  `docs-proyecto/alimentacion/Stores Procedures/`.
- El contrato debe describir propósito, firma, parámetros, recordsets, códigos
  de salida, mensajes seguros y reglas relevantes de la operación.
- Mantener compatibilidad con SQL Server 2017 y las convenciones de formato de
  los procedures existentes.
- No ejecutar DDL ni DML contra una instancia real salvo autorización expresa.
- Antes de entregar, ejecutar `git diff --check` y reportar los archivos
  modificados y las verificaciones realizadas.
