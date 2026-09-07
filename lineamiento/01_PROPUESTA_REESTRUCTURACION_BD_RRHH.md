# Propuesta de reestructuracion de BD GTM para plataforma RRHH

Fecha: 2026-07-07

Estado: documento de planificacion aislado.

Este documento concentra las decisiones y propuestas de reestructuracion de la
base de datos GTM para una plataforma modular de RRHH. No es un script SQL, no
representa implementacion aplicada y no modifica el avance actual del proyecto.

## Premisas confirmadas

- GTM sera una plataforma modular para RRHH.
- Estamos nuevamente en fase de planificacion, por lo que se puede replantear la
  base de datos completa si conviene.
- El modulo de seguridad no pertenece a GTM.
- Usuarios, roles, permisos, menus, sesiones, tokens y passwords viven en otra
  instancia del servidor.
- GTM no debe crear tablas de seguridad.
- GTM no debe enlazar `RRHH.Colaborador` con `IdUsuario`.
- La instancia externa de seguridad es la responsable de enlazar su usuario con
  la tabla maestra de colaboradores de GTM.
- GTM debe exponer o mantener una clave estable del colaborador para que
  seguridad pueda referenciarla.
- Los modulos funcionales de GTM deben operar con `IdColaborador`, no con
  `IdUsuario`.
- SAP u otros sistemas externos no deben ser la fuente conceptual del
  colaborador; deben tratarse como integraciones o identificadores externos.

## Tabla eje del sistema

La tabla principal alrededor de la cual debe girar GTM es:

```text
RRHH.Colaborador
```

La razon es funcional: los procesos RRHH no giran alrededor del usuario del
sistema, sino del colaborador como sujeto laboral.

Se recomienda separar identidad civil y relacion laboral:

```text
RRHH.Persona
  -> RRHH.Colaborador
```

- `RRHH.Persona`: identidad natural/civil.
- `RRHH.Colaborador`: ficha laboral de esa persona dentro de la empresa.

Esta separacion evita que datos personales, contratos, cargos y procesos RRHH
queden mezclados en una sola tabla.

## Principio de relacion con seguridad externa

GTM no guarda esta relacion:

```text
RRHH.Colaborador -> Seguridad.Usuario
```

La relacion debe vivir fuera de GTM:

```text
Seguridad.Usuario -> GTM.RRHH.Colaborador
```

La instancia de seguridad puede referenciar:

- `RRHH.Colaborador.IdColaborador`, si tiene acceso confiable al identificador
  interno.
- `RRHH.Colaborador.CodigoColaborador`, si se prefiere un codigo funcional
  estable y portable.

Para GTM, el contrato ideal es que el frontend o backend reciban desde seguridad
el colaborador autenticado:

```json
{
  "usuarioId": 123,
  "roles": ["Admin_RRHH"],
  "idColaborador": 45,
  "codigoColaborador": "COL-00045"
}
```

GTM puede ignorar `usuarioId` para reglas funcionales y trabajar con
`idColaborador`.

## Schemas recomendados

| Schema | Responsabilidad |
| --- | --- |
| `RRHH` | Persona, colaborador, vinculo laboral, asignaciones, legajo y datos propios de RRHH. |
| `Organizacion` | Empresa, sede, unidad organizacional, cargo y jerarquia. |
| `Catalogo` | Catalogos transversales reutilizables. |
| `Integracion` | Sistemas externos, codigos externos, staging y lotes de carga. |
| `Evaluacion` | Banco de preguntas, formatos, periodos, snapshots y respuestas. |
| `Auditoria` | Cambios sensibles y trazabilidad funcional. |

Schemas que no deben existir en GTM:

- `Seguridad`
- `Usuario`
- `Rol`
- `Permiso`
- `Sesion`

## Modelo inicial recomendado

### RRHH.Persona

Identidad natural/civil de una persona.

Campos sugeridos:

- `IdPersona`
- `CodigoPersona`
- `Nombres`
- `ApellidoPaterno`
- `ApellidoMaterno`
- `NombreCompleto`
- `FechaNacimiento`
- `Sexo`
- `Estado`
- auditoria: `FechaCreacion`, `UsuarioCreacion`, `FechaModificacion`, `UsuarioModificacion`

Notas:

- No guardar aqui cargo, area ni usuario.
- Una persona puede o no ser colaborador.
- Una persona podria tener mas de una relacion laboral en el tiempo.

### RRHH.PersonaDocumento

Documentos de identidad.

Campos sugeridos:

- `IdPersonaDocumento`
- `IdPersona`
- `TipoDocumento`
- `NumeroDocumento`
- `PaisEmision`
- `EsPrincipal`
- `Estado`

Reglas:

- Debe existir al menos un documento principal cuando el colaborador este activo.
- Controlar duplicados por tipo y numero de documento.

### RRHH.PersonaContacto

Correos, telefonos y direcciones.

Campos sugeridos:

- `IdPersonaContacto`
- `IdPersona`
- `TipoContacto`
- `Valor`
- `EsPrincipal`
- `Estado`

Tipos esperados:

- correo laboral
- correo personal
- telefono movil
- telefono fijo
- direccion

### RRHH.Colaborador

Ficha laboral principal.

Campos sugeridos:

- `IdColaborador`
- `IdPersona`
- `CodigoColaborador`
- `FechaIngreso`
- `EstadoLaboral`
- `Estado`
- auditoria

Estados laborales iniciales:

- `ACTIVO`
- `CESADO`
- `SUSPENDIDO`
- `LICENCIA`
- `PREINGRESO`

Reglas:

- Esta es la tabla eje del sistema.
- Los modulos funcionales deben referenciar `IdColaborador`.
- No debe contener `IdUsuario`.
- Debe tener un `CodigoColaborador` estable para integraciones.

### RRHH.ColaboradorVinculoLaboral

Relacion laboral o contractual.

Campos sugeridos:

- `IdColaboradorVinculoLaboral`
- `IdColaborador`
- `TipoVinculo`
- `TipoContrato`
- `FechaInicio`
- `FechaFin`
- `MotivoFin`
- `Estado`

Uso:

- Contratos.
- Reingresos.
- Cambios de modalidad laboral.
- Trazabilidad historica del vinculo.

### RRHH.ColaboradorAsignacion

Asignacion organizacional historica.

Campos sugeridos:

- `IdColaboradorAsignacion`
- `IdColaborador`
- `IdEmpresa`
- `IdSede`
- `IdUnidadOrganizacional`
- `IdCargo`
- `IdJefeColaborador`
- `FechaInicio`
- `FechaFin`
- `EsPrincipal`
- `Estado`

Reglas recomendadas:

- Un colaborador puede tener varias asignaciones historicas.
- Puede evaluarse permitir varias asignaciones activas.
- Si se permiten varias activas, solo una debe ser principal.
- La jerarquia formal por cargo debe vivir en `Organizacion.Cargo`.
- La dependencia directa real puede vivir en `IdJefeColaborador`.

### RRHH.ColaboradorIdentificadorExterno

Identificadores funcionales de sistemas externos, excepto seguridad.

Campos sugeridos:

- `IdColaboradorIdentificadorExterno`
- `IdColaborador`
- `SistemaOrigen`
- `CodigoExterno`
- `Estado`

Ejemplos:

- `SAP`
- `SAP_HCM`
- `PLANILLA`
- `BIOMETRICO`

No usar esta tabla para guardar `IdUsuario` de seguridad.

## Organizacion

### Organizacion.Empresa

Entidad legal o empresa operativa.

Campos sugeridos:

- `IdEmpresa`
- `CodigoEmpresa`
- `RazonSocial`
- `NombreComercial`
- `Ruc`
- `Estado`

### Organizacion.Sede

Ubicacion fisica o centro operativo.

Campos sugeridos:

- `IdSede`
- `IdEmpresa`
- `CodigoSede`
- `Nombre`
- `Direccion`
- `Estado`

### Organizacion.UnidadOrganizacional

Area, gerencia, departamento, jefatura o unidad interna.

Campos sugeridos:

- `IdUnidadOrganizacional`
- `IdUnidadOrganizacionalPadre`
- `IdEmpresa`
- `CodigoUnidad`
- `Nombre`
- `TipoUnidad`
- `RutaJerarquia`
- `NivelJerarquia`
- `Estado`

Nota:

- El proyecto actual ya usa `hierarchyid`; conviene conservar esa decision.

### Organizacion.Cargo

Cargo interno del organigrama.

Campos sugeridos:

- `IdCargo`
- `IdCargoPadre`
- `IdUnidadOrganizacional`
- `CodigoCargo`
- `Nombre`
- `Descripcion`
- `RutaJerarquia`
- `NivelJerarquia`
- `Estado`

Decision:

- El cargo es maestro interno.
- SAP solo aporta codigo externo si aplica.
- No usar `CodigoCargoSAP` como columna principal conceptual; migrarla a un
  identificador externo o conservarla temporalmente por compatibilidad.

## Evaluacion en la nueva estructura

El modulo `Evaluacion` debe consumir colaboradores desde `RRHH`.

Cambio conceptual recomendado:

| Actual | Propuesto |
| --- | --- |
| `PersonalSap.Persona` | `RRHH.Persona` + `RRHH.Colaborador` |
| `PersonalSap.PersonaCargo` | `RRHH.ColaboradorAsignacion` |
| `CodigoPersonaSAP` | `RRHH.ColaboradorIdentificadorExterno` |
| `CampanaEvaluacionPersona` | `CampanaEvaluacionColaborador` |
| `IdUsuario` en snapshot | No usar para reglas funcionales |

La logica de snapshot se mantiene porque es correcta:

- Al publicar un periodo, se debe congelar el colaborador participante.
- Se deben congelar nombres, cargo, unidad, jerarquia y preguntas aplicables.
- Cambios posteriores en maestro RRHH no deben alterar periodos publicados.

### Evaluacion.CampanaEvaluacionColaborador

Snapshot recomendado para reemplazar conceptualmente a
`CampanaEvaluacionPersona`.

Campos sugeridos:

- `IdCampanaEvaluacionColaborador`
- `IdCampanaEvaluacion`
- `IdColaborador`
- `CodigoColaborador`
- `NombresSnapshot`
- `ApellidosSnapshot`
- `NombreCompletoSnapshot`
- `NumeroDocumentoSnapshot`
- `IdCargo`
- `CodigoCargoSnapshot`
- `NombreCargoSnapshot`
- `IdUnidadOrganizacional`
- `NombreUnidadOrganizacionalSnapshot`
- `RutaJerarquiaCargo`
- `NivelJerarquiaCargo`
- `Estado`

### Evaluacion.CampanaEvaluacionAsignacion

Debe relacionar evaluador y evaluado por snapshot:

- `IdEvaluadorCampanaColaborador`
- `IdEvaluadoCampanaColaborador`

No debe depender de usuario de seguridad.

## Integracion

### Integracion.SistemaExterno

Catalogo de sistemas externos.

Ejemplos:

- `SAP`
- `PLANILLA`
- `BIOMETRICO`
- `SEGURIDAD`

Nota:

- `SEGURIDAD` puede existir como sistema conocido, pero GTM no guarda la tabla
  puente usuario-colaborador.
- La referencia usuario-colaborador vive en la instancia de seguridad.

### Integracion.ImportacionLote

Control de cargas.

Campos sugeridos:

- `IdImportacionLote`
- `SistemaOrigen`
- `TipoEntidad`
- `NombreArchivo`
- `HashArchivo`
- `Estado`
- `TotalRegistros`
- `TotalErrores`
- auditoria

## Auditoria

### Auditoria.CambioEntidad

Registro funcional de cambios sensibles.

Campos sugeridos:

- `IdCambioEntidad`
- `SchemaEntidad`
- `NombreEntidad`
- `IdEntidad`
- `Operacion`
- `Campo`
- `ValorAnterior`
- `ValorNuevo`
- `FechaCambio`
- `UsuarioAccion`
- `OrigenAccion`

Nota:

- `UsuarioAccion` puede guardar texto o identificador enviado por la capa que
  ejecuta la accion, pero no implica administrar usuarios en GTM.

## Reglas transversales de diseno

- Todo modulo RRHH debe referenciar `IdColaborador`.
- No usar `IdUsuario` como clave funcional de GTM.
- No crear FKs hacia la instancia de seguridad.
- No guardar roles ni permisos en GTM.
- Mantener historicos por fecha de vigencia.
- Evitar sobrescribir datos historicos; cerrar vigencias y abrir nuevas filas.
- Mantener snapshots en procesos publicados o cerrados.
- Separar datos maestros, datos transaccionales, snapshots e integraciones.
- Evitar que SAP sea fuente conceptual del modelo.

## Preguntas pendientes de decision

1. `CodigoColaborador`: debe generarlo GTM o venir de un sistema externo?
2. Se permitiran multiples asignaciones activas por colaborador?
3. Si hay multiples asignaciones activas, que modulos usan solo la principal?
4. Seguridad referenciara `IdColaborador` o `CodigoColaborador`?
5. La instancia de seguridad consultara GTM por API o por acceso directo a BD?
6. RRHH administrara altas manuales o solo importaciones?
7. Habra colaboradores externos, practicantes, proveedores o solo planilla?
8. Se requiere legajo/documentos en esta primera fase?
9. Se debe conservar compatibilidad temporal con `PersonalSap.*`?

## Ruta sugerida de trabajo

1. Aprobar las premisas de seguridad externa.
2. Aprobar `RRHH.Colaborador` como tabla eje.
3. Definir claves estables: `IdColaborador` y `CodigoColaborador`.
4. Definir tabla inicial de organizacion: empresa, sede, unidad, cargo.
5. Definir tabla inicial de RRHH: persona, colaborador, asignacion, vinculo.
6. Definir contrato con seguridad externa.
7. Redisenar evaluaciones para consumir `IdColaborador`.
8. Planificar migracion desde `PersonalSap.*`.
9. Recien despues crear scripts SQL versionados.

## Fuera de alcance de este documento

- Scripts SQL ejecutables.
- Cambios al backend.
- Cambios al frontend.
- Migraciones reales.
- Ejecucion contra base de datos.
- Implementacion de seguridad.
