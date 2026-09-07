# Evaluaciones — roles y permisos

Estado: Oficial  
Fecha de oficialización: 2026-09-03

## Reglas generales

- El acceso al módulo requiere una sesión autenticada.
- Cada opción se presenta y habilita según los permisos del usuario.
- La autorización visual no reemplaza la validación del servicio REST.
- Una respuesta de acceso denegado no debe confirmar ni conservar una operación como exitosa.

## Matriz oficial

| Funcionalidad | Roles autorizados |
|---|---|
| Preguntas | `SUPERADMIN`, `SUPERUSUARIO`, `Admin_RRHH` |
| Períodos | `SUPERADMIN`, `SUPERUSUARIO`, `Admin_RRHH` |
| Reportes | `SUPERADMIN`, `SUPERUSUARIO`, `Admin_RRHH` |
| Mis Evaluaciones | `SUPERADMIN`, `SUPERUSUARIO`, `Evaluador_RRHH` |

## Origen

- `01_FRONTEND.md`, sección “Auth, guards y permisos”.

La matriz fue confirmada por el responsable documental el 2026-09-03.
