# Paquete de base de datos GTM

Este directorio contiene el diseño físico propuesto para Microsoft SQL Server
2017. Los archivos están listos para revisión estática; **no han sido ejecutados
contra una instancia** y no crean la base de datos física.

## Alcance

- Schemas propios: `catalogo`, `rrhh`, `organizacion` e `integracion`.
- Núcleo compartido: identidad civil y laboral, empresas, sedes, áreas, cargos,
  relaciones laborales, asignaciones, horarios, jefaturas y referencia
  Microsoft. El código SAP se conserva directamente en `rrhh.Colaborador`.
- Fuera de alcance: tablas de Seguridad, marcaciones, Alimentación,
  Evaluaciones, Declaraciones Juradas y Notificaciones.

## Secuencia reproducible

`aplicar_migraciones_nucleo.sql` es un script SQLCMD que incluye, en orden, las
migraciones `001` a `008`. Debe iniciarse desde este directorio para que las
rutas relativas de `:r` sean resolubles:

```powershell
Set-Location -LiteralPath '<workspace>\db'
sqlcmd -S '<servidor>' -d '<base-vacia-autorizada>' -b -i '.\aplicar_migraciones_nucleo.sql'
```

El comando es únicamente una guía futura. No debe ejecutarse hasta contar con:

1. aprobación humana explícita del schema;
2. aprobación separada para aplicar el DDL inicial; y
3. una base vacía del proyecto con permisos acotados, nunca `master` ni otra
   base preexistente.

Las migraciones son versionadas y deterministas para una base vacía. No son un
reconciliador de schemas ya existentes ni deben reaplicarse sobre una base que
ya registró la misma versión.

Esta primera entrega crea solo schemas, tablas, restricciones e índices. No
incluye vistas, disparadores, funciones ni procedimientos almacenados. Las
reglas que requieren comparar varias filas o tablas quedan asignadas a una fase
posterior.

## Reversión

Cada migración documenta su sección `DOWN`. Para una reversión integral existe
`reversiones/revertir_nucleo_completo.sql`. Falla cerrado salvo que se indiquen
`ConfirmarReversion=SI` y el nombre exacto `BaseDatosEsperada`, rechaza bases de
sistema y exige la huella estructural completa de `001..008`. Es destructivo y
solo es válido sobre la base del proyecto creada por este paquete.

## Validación disponible sin instancia

```powershell
.\validar_paquete.ps1
```

La validación comprueba secuencia, encabezados, límites de base/schema, ausencia
de módulos prohibidos, referencias del consolidado y guardas de reversión. No
sustituye la compilación y ejecución futura en SQL Server 2017.

## Extensión del módulo Alimentación

Las migraciones de tablas del módulo se encuentran en
`migrations/alimentacion`. Las versiones `009..012` y `017` agregan 15 tablas bajo el nombre exacto
`[alimentacion]`. No alteran las 15 tablas de `001..008` y solo referencian las
PK existentes de `organizacion.Sede`, `rrhh.Colaborador` y
`rrhh.HorarioLaboral`.

Para revisar estáticamente el paquete completo, sin conectarse a SQL Server:

```powershell
.\validar_paquete_alimentacion.ps1
```

`aplicar_migraciones_gtm_alimentacion.sql` incluye las migraciones declaradas
(`001..012` y `017`) en orden para una
futura base vacía autorizada. `reversiones/revertir_alimentacion_completo.sql`
elimina exclusivamente las 15 tablas del módulo y el schema `[alimentacion]`;
falla cerrado si no recibe confirmación, base esperada o huella completa.

Ninguno de esos scripts debe ejecutarse contra SQL Server antes de dos decisiones
distintas: aprobación humana del schema y, posteriormente, autorización expresa
para aplicar DDL sobre una base concreta. La validación local no equivale a
compilación, ejecución, prueba de concurrencia ni aprobación runtime.
