# Auditoría estática DB-NUCLEO-002

Fecha: 2026-09-04

Motor objetivo: Microsoft SQL Server 2017

Evidencia: archivos locales; sin conexión, compilación ni ejecución en motor.

## Resultado por migración

| Migración | Resultado de auditoría | Decisión / corrección |
|---|---|---|
| 001 | Conforme para revisión | Crea solo los cuatro schemas propios; no crea ni selecciona una base. |
| 002 | Conforme para revisión | Catálogos extensibles sin seeds que resuelvan PM diferidas. |
| 003 | Conforme con límites declarados | Persona–Colaborador 1:0..1, documentos y cuenta Microsoft; no hay usuario, rol, permiso, token ni FK externa. PM-01/02/03/14 siguen abiertas. |
| 004 | Corregida | Se retiró completamente `integracion.CentroCostoSAP`; la migración conserva solo los maestros GTM de organización. |
| 005 | Conforme con el alcance actualizado | Reingresos y relaciones simultáneas son filas distintas; se retiró `integracion.ReferenciaEmpleadoSAP`. |
| 006 | Conforme con el alcance actualizado | Crea la asignación con sede, área y cargo; se retiraron la FK de centro de costo y `integracion.ReferenciaPosicionSAP`. |
| 007 | Corregida materialmente | `CodigoHorarioSAP` queda directamente en el maestro; `VigenciaHorario` asigna un código por relación laboral y fecha, sin ciclos ni rangos. |
| 008 | Conforme con límites declarados | Restringe prioridad a 1/2 y una fila abierta por prioridad. El máximo histórico sin solapamiento y PM-12 siguen pendientes. |

## Controles ejecutados

- Comparación SHA-256: las once referencias modulares copiadas en
  `lineamiento/referencias-modulos` coinciden con sus fuentes actuales en
  `Lineamientos/Alimentacion` y `Lineamientos/Evaluaciones`.
- Consulta Graphify inicial: orientó hacia núcleo común, SQL Server, seguridad y
  roles; todas las conclusiones fueron contrastadas con los archivos reales.
- `db/validar_paquete.ps1`: valida 8 migraciones en secuencia, encabezados,
  consolidado, ausencia de objetos procedurales, PM-08/PM-11 y guardas de
  rollback. El resultado final se registra en el cierre de DB-NUCLEO-002-CORR-1.

## Riesgos y validaciones pendientes

1. No existe evidencia de compilación ni `migrate up` en SQL Server 2017 porque
   el checkpoint de aplicación DDL no fue otorgado.
2. Las PM-01..PM-17 continúan diferidas salvo la decisión expresa de usar
   `CodigoSAP` en Colaborador y no crear tablas SAP. PM-11 excluye el detalle de horarios.
3. `STACK.md` y `requirements.md` aún contienen la redacción histórica “DB Agent
   no autorizado”; `approvals-log.md` registra después la autorización expresa
   para iniciar solo el diseño. El DB Agent no modificó artefactos de propiedad
   Analyst.
4. Los nombres de base, collation, estrategia de backup, despliegue, migración
   desde `PersonalSap.*` y permisos técnicos no están definidos ni forman parte
   de estos scripts.
5. Antes de backend corresponde Review Agent y aprobación humana del schema.
   Antes de ejecutar DDL corresponde un checkpoint humano separado.
6. Por alcance expreso, no se crean vistas, disparadores ni procedimientos.
   Contención temporal entre tablas, cobertura continua, anti-solapamiento
   histórico y validación de cambios del padre quedan pendientes y no se
   presentan como integridad implementada.

## Cierre de findings DB-NUCLEO-002-CORR-1

- La guarda procedural de `RelacionLaboral` y la validación de cobertura total
  no se incorporan en esta fase: el usuario restringió el paquete a tablas y
  ambos requisitos quedan pendientes, visibles y sin cobertura fingida.
- `NombreCentroCosto` fue eliminado de `004` para no resolver PM-08.
- Las antiguas migraciones `009/010` y todos los disparadores fueron retirados.
- El warning runtime continúa correctamente abierto en el DoD.
- El rollback ahora exige confirmación, nombre exacto de base, rechaza bases de
  sistema y verifica las 15 tablas esperadas antes de iniciar la transacción.

## Cierre de findings DB-NUCLEO-002-CORR-2

- `CU_Colaborador_CodigoSAP` materializa únicamente la unicidad. Junto con
  `NOT NULL` y `RV_Colaborador_CodigoSAPNoVacio` exige presencia, contenido y no
  duplicidad, pero no impide actualizaciones ni garantiza inmutabilidad.
- La estabilidad de `CodigoSAP` queda diferida bajo el alcance actual,
  que excluye objetos programables y no resuelve PM-01 por supuesto.
- El comentario DOWN de `001` quedó alineado con la secuencia vigente
  `001..008`.
- La evidencia runtime en SQL Server 2017 permanece pendiente hasta el
  checkpoint humano de ejecución DDL.
