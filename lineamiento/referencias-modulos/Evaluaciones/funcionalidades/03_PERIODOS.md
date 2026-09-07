# Funcionalidad — períodos de evaluación

Estado: Oficial  
Fecha de oficialización: 2026-09-03

## Reglas

- Son obligatorios el título, la descripción, la fecha de inicio, la fecha de fin y el formato de evaluación.
- La fecha de fin debe ser igual o posterior a la fecha de inicio.
- Crear un período no lo publica.
- Todo período recién creado queda en estado `STAGE`.
- Solo pueden crearse períodos usando evaluaciones en estado `ACTIVO`.
- Un período solo puede editarse o eliminarse mientras permanece en `STAGE`.
- Puede existir más de un período para la misma evaluación.
- Se permiten períodos con fechas solapadas.
- La fecha de fin es inclusiva hasta el final del día.
- Generar un PDF bajo demanda no publica el período.
- Publicar requiere confirmación del usuario.
- Publicar genera un snapshot y habilita el PDF oficial.
- El seguimiento de un período publicado utiliza su snapshot.
- Un período publicado no puede publicarse nuevamente.
- Un período publicado solo puede anularse cuando su estado lo permita.
- El estado `FINALIZADO` se alcanza automáticamente cuando todas las asignaciones activas fueron completadas.
- La fecha y hora oficial para calcular estados se obtiene desde SQL Server.
- Todos los cálculos temporales utilizan la zona horaria `America/Lima`.
- Antes de publicarse puede cambiarse el formato de evaluación asociado.
- La eliminación disponible en `STAGE` conserva trazabilidad mediante una eliminación lógica.
- El listado admite filtros y paginación. Sin filtros ni paginación devuelve los cuatro períodos no eliminados más recientes por fecha de creación descendente.

## Sincronización automática de estados

- Los períodos en `STAGE`, `FINALIZADO` o `ANULADO` no cambian por sincronización temporal.
- Un período publicado queda `FINALIZADO` cuando todas sus asignaciones activas están completadas.
- Antes de la fecha de inicio permanece `ACTIVO`.
- Dentro del rango inclusivo queda `EN_PROGRESO`.
- Después de la fecha final inclusiva queda `VENCIDO`.

## Acciones por estado

| Publicación | Estado | Acciones disponibles |
|---|---|---|
| `STAGE` | `ACTIVO` | Editar, publicar, eliminar y ver PDF no oficial. |
| `PUBLICADO` | `ACTIVO` | Anular y ver PDF oficial. |
| `PUBLICADO` | `EN_PROGRESO` | Anular, ver avance y ver PDF oficial. |
| `PUBLICADO` | `VENCIDO` | Anular, ver avance y ver PDF oficial. |
| `PUBLICADO` | `FINALIZADO` | Ver resultados y ver PDF oficial. |
| `PUBLICADO` | `ANULADO` | Ver PDF oficial. |

## Publicación

La publicación solo procede para un período no eliminado en `STAGE + ACTIVO`, asociado con una evaluación `ACTIVO`, y después de la confirmación del usuario.

En una única operación transaccional el servidor debe:

1. Revalidar los datos del período y la evaluación asociada.
2. Validar cargos, competencias, criterios y preguntas.
3. Crear los snapshots de configuración y personas.
4. Crear las asignaciones.
5. Cambiar `EstadoPublicacion` a `PUBLICADO`.
6. Calcular el estado inicial usando la fecha y hora de SQL Server en `America/Lima`.

Si falla cualquier paso, la publicación completa se revierte. Tras una respuesta exitosa, el cliente puede solicitar por separado el PDF oficial.

## PDF de resumen

- Puede solicitarse para cualquier período no eliminado y no modifica estados.
- No se guarda en base de datos ni en filesystem.
- En `STAGE` utiliza la configuración viva e incluye la marca `DOCUMENTO NO OFICIAL - PERIODO NO PUBLICADO`.
- En `PUBLICADO` utiliza exclusivamente el snapshot e incluye la marca `DOCUMENTO OFICIAL - PERIODO PUBLICADO`.
- La publicación y la generación del PDF son operaciones independientes: primero se publica y, tras el éxito, se solicita el PDF.
- La presentación del archivo en el cliente no queda fijada por este lineamiento.

Contenido mínimo:

1. Título y marca de oficialidad.
2. Nombre, descripción, fechas y evaluación seleccionada.
3. Resumen por área y cargo evaluador.
4. Cargos evaluados por cada evaluador.
5. Competencias, criterios y preguntas correspondientes.
6. Fecha oficial de generación y usuario que solicita el resumen.

## Origen

- `00_INDICE_Y_SECUENCIA_AGENTE.md`.
- `01_FRONTEND.md`, sección “Períodos”.
- `FUENTE_HISTORICA/CONTEXTO_PROYECTO_GTM.md`, sección “Períodos”.
- `FUENTE_HISTORICA/PLAN_PERIODOS_EVALUACIONES.md`.
