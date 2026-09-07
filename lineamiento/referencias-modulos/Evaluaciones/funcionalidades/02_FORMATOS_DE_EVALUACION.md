# Funcionalidad — formatos de evaluación

Estado: Oficial  
Fecha de oficialización: 2026-09-03

## Propósito

Un formato de evaluación define la configuración que luego utiliza un período para generar las asignaciones y preguntas aplicables.

## Composición

Un formato incluye:

- Cargos objetivo.
- Asignaciones entre evaluador y evaluado.
- Competencias.
- Criterios aplicables por cargo.

## Capacidades

- Listar formatos de evaluación.
- Crear un formato.
- Consultar el detalle de un formato.
- Actualizar un formato.
- Guardar un formato como borrador.
- Finalizar un formato para dejarlo disponible para períodos.

En la interfaz esta capacidad puede presentarse como “Evaluaciones”; funcionalmente corresponde a la configuración del formato.

## Estados

- `BORRADOR`: configuración guardada que aún puede completarse.
- `ACTIVO`: formato finalizado y disponible para crear períodos.

El formato guardado como borrador debe persistir. No puede finalizarse mientras exista algún criterio sin nivel.

## Selección de cargos

1. Mostrar las áreas disponibles.
2. Mostrar dentro de cada área los cargos ordenados jerárquicamente y agrupados de manera colapsable.
3. Presentar como posibles evaluadores únicamente los cargos que tengan subordinados.
4. Permitir seleccionar cada cargo evaluador.
5. Exigir la selección explícita del alcance; elegir un evaluador no marca automáticamente a sus subordinados.
6. Mostrar todos los niveles subordinados y marcar únicamente los que correspondan al alcance elegido.
7. Desmarcar automáticamente los subordinados que queden fuera cuando el alcance disminuya.
8. Permitir seleccionar manualmente los subordinados que evaluará cada evaluador.
9. Aplicar competencias y criterios sobre todos los cargos seleccionados, no únicamente sobre los cargos evaluadores.

## Relación con períodos

- Solo un formato en estado `ACTIVO` puede utilizarse para crear un período.
- El formato aporta la configuración usada por el período y por su snapshot al publicarse.

## Origen

- `02_BACKEND.md`, secciones “Evaluaciones / formatos” y “Flujos backend”.
- `FUENTE_HISTORICA/CONTEXTO_PROYECTO_GTM.md`, sección “Evaluaciones / formatos”.
