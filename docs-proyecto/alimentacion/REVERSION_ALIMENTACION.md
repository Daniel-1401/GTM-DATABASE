# Reversión integral de Alimentación

Script fuente: `db/reversiones/revertir_alimentacion_completo.sql`.

## Alcance

El script revierte los objetos creados por las migraciones de Alimentación:

- procedimientos almacenados del esquema `alimentacion`;
- tablas, tipos tabla y esquema `alimentacion`;
- vista, tablas y esquema `proximidad` creados por el módulo;
- procedimiento, tabla y esquema `auditoria` creados por la migración `016`.

El orden de eliminación respeta las dependencias: primero procedimientos y
vistas; después tablas hijas, tablas padre y tipos tabla.

## Protección

Debe ejecutarse con SQLCMD y las variables de confirmación previstas en el
script. No modifica tablas ni schemas del núcleo GTM.

Los schemas solo se eliminan cuando no contienen objetos restantes, por lo que
los objetos ajenos al módulo se preservan.
