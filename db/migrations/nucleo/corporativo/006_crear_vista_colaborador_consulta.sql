-- Migracion: nucleo corporativo / 006_crear_vista_colaborador_consulta
-- Motor objetivo: Microsoft SQL Server 2017
-- Alcance: proyeccion corporativa minima de colaborador para consultas de lectura.
-- Destino: instancia CO / base PERSONALMANEGEMENTCORP.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- select * from [rrhh].[vw_ColaboradorConsulta]
CREATE OR ALTER VIEW [rrhh].[vw_ColaboradorConsulta]
AS
SELECT
    [Colaborador].[IdColaboradorCorporativo],
    [Persona].[Nombres],
    [Persona].[ApellidoPaterno],
    [Persona].[ApellidoMaterno],
    LTRIM
    (
        RTRIM
        (
            CONCAT
            (
                [Persona].[Nombres], N' ', [Persona].[ApellidoPaterno],
                CASE
                    WHEN [Persona].[ApellidoMaterno] IS NULL THEN N''
                    ELSE N' ' + [Persona].[ApellidoMaterno]
                END
            )
        )
    ) AS [NombreCompleto]
FROM [rrhh].[Colaborador] AS [Colaborador]
INNER JOIN [rrhh].[Persona] AS [Persona]
    ON [Persona].[IdPersona] = [Colaborador].[IdPersona];
GO
