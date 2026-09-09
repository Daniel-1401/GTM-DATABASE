# Tablas del núcleo GTM

Fecha de actualización: 2026-09-08  
Motor objetivo: Microsoft SQL Server 2017

## Alcance y fuente de verdad

Este documento describe las 15 tablas vigentes del núcleo común de GTM. La fuente de verdad son las migraciones `001` a `008` en `db/migrations/nucleo/`; ante cualquier diferencia, prevalecen esas migraciones. No incluye tablas de Alimentación, Evaluaciones, Seguridad, Marcaciones, Notificaciones ni otros módulos.

Es documentación de modelo, no evidencia de que el DDL o la semilla de datos de prueba hayan sido ejecutados en una instancia.

## Vista general

| Schema | Tablas | Responsabilidad |
|---|---|---|
| `catalogo` | `TipoDocumento`, `TipoJefatura` | Clasificaciones extensibles de identidad y jefatura. |
| `rrhh` | `Persona`, `Colaborador`, `DocumentoPersona`, `RelacionLaboral`, `AsignacionOrganizacional`, `HorarioLaboral`, `VigenciaHorario`, `JefaturaRelacionLaboral` | Identidad, vida laboral, asignación, horarios y jerarquía. |
| `organizacion` | `Empresa`, `Sede`, `Area`, `Cargo` | Maestros organizacionales propios de GTM. |
| `integracion` | `CuentaMicrosoftCorporativa` | Referencia de identidad corporativa de Microsoft/Entra. |

## Catálogos

### `catalogo.TipoDocumento`

Clasifica documentos asociados a una persona. Su clave es `IdTipoDocumento`; `CodigoTipoDocumento` es único. Conserva nombre, indicador de actividad y fecha técnica de creación.

### `catalogo.TipoJefatura`

Clasifica la naturaleza de una jefatura. Su clave es `IdTipoJefatura`; `CodigoTipoJefatura` es único. Conserva nombre, indicador de actividad y fecha técnica de creación.

## Identidad e integración

### `rrhh.Persona`

Representa la identidad civil. Su clave es `IdPersona` y registra nombres, apellidos, fecha de nacimiento y marcas técnicas. No contiene cargo, área, empresa, usuario ni permisos.

### `rrhh.Colaborador`

Representa la identidad laboral estable de una persona. Su clave es `IdColaborador`; `IdPersona` es una FK única hacia `rrhh.Persona`, por lo que una persona puede originar como máximo un colaborador. `IdentificadorPublico` y `CodigoSAP` también son únicos.

### `rrhh.DocumentoPersona`

Registra documentos de una persona. Tiene FKs hacia `rrhh.Persona` y `catalogo.TipoDocumento`, número de documento, país de emisión, condición de principal y vigencia. El índice filtrado `IN_DocumentoPersona_PrincipalAbierto` limita a un documento principal abierto por persona; no se define una clave natural de persona ni se obliga a tener un documento principal.

### `integracion.CuentaMicrosoftCorporativa`

Mantiene la referencia de una cuenta corporativa por colaborador. Tiene FK a `rrhh.Colaborador`, vigencia y al menos uno de Object ID, UPN o correo corporativo. El índice filtrado `IN_CuentaMicrosoftCorporativa_Abierta` permite como máximo una cuenta abierta por colaborador. No es una tabla de usuario y no almacena credenciales, sesiones, roles ni permisos.

## Organización

### `organizacion.Empresa`

Maestro de empresas de la corporación. `IdEmpresa` es la clave y `CodigoEmpresa` es único. Conserva razón social, nombre comercial, número de identificación tributaria, estado de actividad y marcas técnicas.

### `organizacion.Sede`

Representa una sede de una empresa. Tiene FK a `organizacion.Empresa`; la combinación `IdEmpresa` + `CodigoSede` es única y `IdentificadorPublico` también es único. Registra nombre, dirección, estado y marcas técnicas.

### `organizacion.Area`

Maestro corporativo plano de áreas propias de GTM. `IdArea` es la clave y `CodigoArea` es único. Registra nombre, descripción, estado y marcas técnicas. No se modela jerarquía ni pertenencia de área a empresa.

### `organizacion.Cargo`

Maestro corporativo plano de cargos propios de GTM. `IdCargo` es la clave y `CodigoCargo` es único. Registra nombre, descripción, estado y marcas técnicas. Un cargo GTM no es sustituido por una posición o código SAP.

## Vida laboral, asignación y horario

### `rrhh.RelacionLaboral`

Conserva cada vínculo histórico entre un colaborador y una empresa. Tiene FKs a `rrhh.Colaborador` y `organizacion.Empresa`, fecha de inicio, fecha y motivo de fin. Un reingreso debe generar otra relación; el modelo permite relaciones simultáneas.

### `rrhh.AsignacionOrganizacional`

Historiza el contexto organizacional de una relación laboral. Tiene FKs a `rrhh.RelacionLaboral`, `organizacion.Sede`, `organizacion.Area` y `organizacion.Cargo`, además de `CodigoPosicionSAP` y fechas de vigencia. El código de posición SAP es obligatorio y no vacío; identifica una plaza SAP, no el cargo funcional compartido. El índice filtrado `IN_AsignacionOrganizacional_Abierta` permite una sola asignación abierta por relación laboral y `IN_AsignacionOrganizacional_PosicionSAPAbierta` impide que una misma posición SAP esté abierta en más de una asignación.

### `rrhh.HorarioLaboral`

Es el maestro local de horarios. `CodigoHorarioGTM` y `CodigoHorarioSAP` son únicos; registra tipo de turno, nombre, descripción, estado y marcas técnicas. El tipo de turno se restringe a `MANANA`, `TARDE`, `NOCHE` o `MADRUGADA`.

### `rrhh.VigenciaHorario`

Asigna un horario a una relación laboral en una fecha concreta. Tiene FKs a `rrhh.RelacionLaboral` y `rrhh.HorarioLaboral`. El índice único `IN_VigenciaHorario_RelacionFecha` permite un solo horario por relación y día; no representa ciclos ni intervalos.

## Jerarquía

### `rrhh.JefaturaRelacionLaboral`

Relaciona una relación laboral subordinada con otra que actúa como jefatura. Tiene tres FKs: relación subordinada, relación de jefatura y tipo de jefatura. Conserva prioridad y vigencia; no permite que ambas relaciones sean la misma. La prioridad está limitada a `1` o `2`, y el índice filtrado `IN_JefaturaRelacionLaboral_PrioridadAbierta` permite una fila abierta por relación subordinada y prioridad.

## Relaciones principales

```text
Persona ── 0..1 Colaborador ──< RelacionLaboral >── Empresa ──< Sede
   │              │                    │
   ├──< DocumentoPersona               ├──< AsignacionOrganizacional >── Área, Cargo, Sede
   └── TipoDocumento                   ├──< VigenciaHorario >── HorarioLaboral
                                      └──< JefaturaRelacionLaboral >── TipoJefatura

Colaborador ──< CuentaMicrosoftCorporativa
```

Las vigencias de relación laboral, asignación y jefatura usan el intervalo semiabierto `[FechaInicio, FechaFin)`; `NULL` en la fecha final significa que la fila permanece abierta.

## Límites conocidos

- No se definen procedimientos almacenados, vistas, funciones, disparadores, roles ni permisos como parte del modelo oficial.
- No se garantiza de forma declarativa la ausencia de solapamientos históricos cerrados ni la cobertura continua entre vigencias relacionadas.
- No se valida que una sede asignada pertenezca a la empresa de la relación laboral.
- No se impone una jefatura principal obligatoria ni el máximo histórico de dos jefaturas para cualquier fecha pasada.

## Referencias

- `db/migrations/nucleo/001_crear_esquemas_nucleo.sql` a `008_crear_jefaturas_relaciones_laborales.sql`.
- `docs-proyecto/er-diagram-fisico-v1.md`.
- `docs-proyecto/ESTADO_OFICIAL_OBJETOS_DB.md`.
