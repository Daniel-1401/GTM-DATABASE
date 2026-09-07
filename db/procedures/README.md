# Stored procedures de Alimentacion

Este directorio queda reservado para el paquete procedural versionado contra el
schema `[alimentacion]`. La fuente contractual es
`hub-gtm/docs-proyecto/STORED_PROCEDURES_REQUERIDOS.md`.

La generacion de los 22 procedimientos requiere implementar sus transacciones,
autorizacion por contexto verificado, idempotencia, concurrencia y recordsets;
no se aceptan stubs que devuelvan exito sin persistir el resultado. Esta entrega
deja corregido y validado el schema base para esa implementacion. No se ejecuta
DDL ni se conecta a SQL Server.
