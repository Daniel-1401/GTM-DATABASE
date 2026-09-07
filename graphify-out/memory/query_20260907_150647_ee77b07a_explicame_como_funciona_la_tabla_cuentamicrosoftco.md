---
type: "query"
date: "2026-09-07T15:06:47.469163+00:00"
question: "explicame como funciona la tabla CuentaMicrosoftCorporativa"
contributor: "graphify"
outcome: "useful"
source_nodes: ["003_crear_personas_colaboradores_e_identidad_microsoft.sql", "Colaborador Entity", "GTM Core Requirements"]
---

# Q: explicame como funciona la tabla CuentaMicrosoftCorporativa

## Answer

Expanded from original query via vocab: [colaborador, identidad, microsoft, persona, vigencias]. CuentaMicrosoftCorporativa guarda referencias externas de Microsoft por colaborador, con Object ID, UPN o correo, vigencia histórica, una sola fila abierta por colaborador y sin modelar autenticacion, roles o permisos. La obligatoriedad de tener cuenta es conceptual y no queda impuesta por una FK desde Colaborador.

## Outcome

- Signal: useful

## Source Nodes

- 003_crear_personas_colaboradores_e_identidad_microsoft.sql
- Colaborador Entity
- GTM Core Requirements