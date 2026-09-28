-- Semilla de datos de prueba: cargos de la instancia hija UO GI.
-- Motor objetivo: Microsoft SQL Server 2017.
-- Fuente: db/csv_data/posiciones.csv.
-- Empresa referencia: Golden / IdEmpresaReferencia = 1.
-- Carga la jefatura directa definida por id_posicion_reporta.
-- Las relaciones se crean vigentes desde 2026-01-01.

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @IdEmpresaReferencia INT = 1;

IF NOT EXISTS
(
    SELECT 1
    FROM [organizacion].[EmpresaReferencia]
    WHERE [IdEmpresaReferencia] = @IdEmpresaReferencia
      AND [CodigoEmpresa] = N'GI'
      AND [RazonSocial] = N'Golden Investment S.A.'
)
    THROW 51000, N'No se encontró la empresa referencia Golden con IdEmpresaReferencia = 1.', 1;

DECLARE @Posiciones TABLE
(
    [IdPosicionFuente] INT NOT NULL PRIMARY KEY,
    [NombreCargo] NVARCHAR(150) NOT NULL,
    [IdPosicionReporta] INT NULL
);

INSERT INTO @Posiciones
(
    [IdPosicionFuente],
    [NombreCargo],
    [IdPosicionReporta]
)
VALUES
    (1, N'DIRECTORIO / JUNTA DIRECTIVA', NULL),
    (2, N'GERENTE GENERAL', 1),
    (3, N'GERENTE DE CAMARAS', 2),
    (4, N'GERENTE DE OPERACIONES', 2),
    (5, N'GERENTE CORPORATIVO DE LOGÍSTICA', 2),
    (6, N'GERENTE DE AUDITORIA', 2),
    (7, N'GERENTE DE CUMPLIMIENTO', 2),
    (8, N'GERENTE DE ADMINISTRACION', 2),
    (9, N'GERENTE DE ANALISIS Y ESTADISTICA', 2),
    (10, N'GERENTE DE CONTABILIDAD', 2),
    (11, N'GERENTE DE FINANZAS Y TESORERÍA', 2),
    (12, N'GERENTE DE GESTION DEL TALENTO Y MAGIA', 2),
    (13, N'GERENTE DE TI', 2),
    (14, N'GERENTE LEGAL', 2),
    (15, N'SUPERVISOR DE CAMARAS', 3),
    (16, N'SUPERVISOR GENERAL', 4),
    (17, N'GERENTE DE CASINO', 4),
    (18, N'JEFE DE CAJA Y BOVEDA', 4),
    (19, N'JEFE DE TRAGAMONEDAS', 4),
    (20, N'JEFE DE HOUSEKEEPING', 4),
    (22, N'AUDITOR DE CAMARAS', 15),
    (23, N'OPERADOR DE CAMARAS', 15),
    (24, N'SUPERVISOR DE RECEPCION', 16),
    (25, N'RECEPCIONISTA', 24),
    (26, N'AUXILIAR ADMINISTRATIVO', 17),
    (27, N'JEFE DE CASINO', 17),
    (28, N'SUPERVISOR ESPECIAL DE CASINO', 27),
    (31, N'SUPERVISOR DE CASINO', 27),
    (32, N'TALLADOR', 31),
    (33, N'JEFE DE CAJA TGM', 18),
    (34, N'SUPERVISOR DE BOVEDA', 18),
    (35, N'SUPERVISOR DE CAJA TGM', 33),
    (36, N'AUXILIAR DE CAJA', 35),
    (37, N'CAJERO (A)', 36),
    (38, N'CONTROL OPERATIVO', 34),
    (39, N'SUB JEFE DE TRAGAMONEDAS', 19),
    (40, N'SUPERVISOR GENERAL TGM', 39),
    (41, N'SUPERVISOR DE TGM', 40),
    (42, N'ESPECIALISTA EN EXPERIENCIA DEL INVITADO', 41),
    (43, N'AUXILIAR DE HOUSEKEEPING', 20),
    (44, N'MANTENIMIENTO GENERAL', 20),
    (45, N'JEFE DE TRANSPORTES', 5),
    (46, N'JEFE DE LOGISTICA', 5),
    (47, N'COMPRADOR SENIOR', 45),
    (48, N'ANALISTA DE COMPRAS', 47),
    (49, N'ASISTENTE DE COMPRAS', 48),
    (50, N'CONDUCTOR OPERACIONES', 49),
    (51, N'SUPERVISOR DE ALMACEN', 101),
    (52, N'ASISTENTE DE ALMACEN', 51),
    (53, N'AUXILIAR DE ALMACEN', 52),
    (54, N'COORDINADOR DE AUDITORIA', 6),
    (55, N'SUPERVISOR DE AUDITORIA', 54),
    (56, N'AUXILIAR DE CUMPLIMIENTO', 7),
    (57, N'ANALISTA DE PROCESOS', 8),
    (58, N'ANALISTA DE ACTIVOS', 8),
    (59, N'ANALISTA DE PRECIOS', 8),
    (60, N'ASISTENTE DE ADMINISTRACION', 59),
    (61, N'PRACTICANTE DE INVENTARIO', 60),
    (62, N'JEFE DE ANALISIS Y ESTADISTICA', 9),
    (63, N'ANALISTA DE ANALISIS Y ESTADISTICA', 62),
    (64, N'ASISTENTE DE ANALISIS Y ESTADISTICA', 63),
    (65, N'CONTADOR (A)', 10),
    (66, N'SUPERVISOR DE CONTABILIDAD', 65),
    (67, N'ANALISTA DE CONTABILIDAD', 66),
    (68, N'ASISTENTE DE CONTABILIDAD', 67),
    (69, N'ANALISTA DE FINANZAS Y TESORERIA', 11),
    (70, N'ASISTENTE DE FINANZAS Y TESORERIA', 69),
    (71, N'AUXILIAR DE FINANZAS Y TESORERIA', 70),
    (72, N'JEFE DE GESTIÓN DEL TALENTO Y MAGIA', 12),
    (74, N'ANALISTA DE SELECCION DEL TALENTO Y MAGIA', 72),
    (75, N'AUXILIAR DE GESTION DEL TALENTO Y MAGIA', 74),
    (76, N'ANALISTA SR. DE REMUNERACIONES DEL TALENTO', 72),
    (77, N'ASISTENTE DE GESTION DEL TALENTO Y MAGIA', 76),
    (78, N'ANALISTA DE GESTIÓN DEL TALENTO Y MAGIA', 72),
    (79, N'ASISTENTA SOCIAL DEL TALENTO Y MAGIA', 72),
    (82, N'JEFE DE PROYECTOS SAP', 13),
    (83, N'COORDINADOR GENERAL SERV.CORPORATIVOS TI', 13),
    (84, N'ADMINISTRADOR DE INFRAESTRUCTURA NIVEL 3', 83),
    (85, N'ADMINISTRADOR DE NETWORKING NIVEL 3', 83),
    (86, N'ADMINISTRADOR DE ADV. NIVEL 2', 83),
    (87, N'ADMINISTRADOR DE SEGURIDAD NIVEL 1', 83),
    (88, N'COORDINADOR DE TI', 13),
    (89, N'SOPORTE TECNICO NIVEL 2', 88),
    (90, N'SOPORTE TECNICO NIVEL 1', 88),
    (91, N'JEFE DE BI', 13),
    (92, N'PROGRAMADOR NIVEL 3', 91),
    (93, N'DATA ANALYST NIVEL 3', 91),
    (94, N'PROGRAMADOR NIVEL 2', 91),
    (95, N'DATA ANALYST NIVEL 2', 91),
    (96, N'DATA ANALYST NIVEL 1', 91),
    (97, N'ASISTENTE DE GERENCIA LEGAL', 14),
    (98, N'JEFE DE AREA LEGAL', 14),
    (99, N'ASISTENTE LEGAL', 98),
    (100, N'PRACTICANTE DE LEGAL', 99),
    (101, N'JEFE DE ALMACEN', 45),
    (102, N'JEFE DE MARKETING', 2),
    (103, N'COORDINADOR(A) DE MARKETING', 102),
    (104, N'COORDINADORA DE ARTE', 102),
    (105, N'ASISTENTE DE MEDIOS', 104),
    (106, N'ASISTENTE DE MARKETING', 104),
    (107, N'AUXILIAR DE MARKETING', 106);

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO [organizacion].[Cargo]
    (
        [IdEmpresaReferencia],
        [CodigoCargo],
        [NombreCargo],
        [Descripcion]
    )
    SELECT
        @IdEmpresaReferencia,
        N'GI-CARGO-' + CONVERT(NVARCHAR(20), [posicion].[IdPosicionFuente]),
        [posicion].[NombreCargo],
        N''
    FROM @Posiciones AS [posicion]
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM [organizacion].[Cargo] AS [existente]
        WHERE [existente].[IdEmpresaReferencia] = @IdEmpresaReferencia
          AND [existente].[CodigoCargo] =
              N'GI-CARGO-' + CONVERT(NVARCHAR(20), [posicion].[IdPosicionFuente])
    );

    IF EXISTS
    (
        SELECT 1
        FROM @Posiciones AS [posicion]
        WHERE [posicion].[IdPosicionReporta] IS NOT NULL
          AND NOT EXISTS
          (
              SELECT 1
              FROM @Posiciones AS [jefeFuente]
              WHERE [jefeFuente].[IdPosicionFuente] = [posicion].[IdPosicionReporta]
          )
    )
        THROW 51001, N'El archivo de posiciones contiene una jefatura no definida.', 1;

    INSERT INTO [organizacion].[CargoJefatura]
    (
        [IdEmpresaReferencia],
        [IdCargoSubordinado],
        [IdCargoJefe],
        [FechaInicio],
        [FechaFin]
    )
    SELECT
        @IdEmpresaReferencia,
        [cargoSubordinado].[IdCargo],
        [cargoJefe].[IdCargo],
        CONVERT(DATE, '2026-01-01'),
        NULL
    FROM @Posiciones AS [posicion]
    INNER JOIN [organizacion].[Cargo] AS [cargoSubordinado]
        ON [cargoSubordinado].[IdEmpresaReferencia] = @IdEmpresaReferencia
       AND [cargoSubordinado].[CodigoCargo] =
           N'GI-CARGO-' + CONVERT(NVARCHAR(20), [posicion].[IdPosicionFuente])
    INNER JOIN [organizacion].[Cargo] AS [cargoJefe]
        ON [cargoJefe].[IdEmpresaReferencia] = @IdEmpresaReferencia
       AND [cargoJefe].[CodigoCargo] =
           N'GI-CARGO-' + CONVERT(NVARCHAR(20), [posicion].[IdPosicionReporta])
    WHERE [posicion].[IdPosicionReporta] IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1
          FROM [organizacion].[CargoJefatura] AS [existente]
          WHERE [existente].[IdEmpresaReferencia] = @IdEmpresaReferencia
            AND [existente].[IdCargoSubordinado] = [cargoSubordinado].[IdCargo]
            AND [existente].[FechaFin] IS NULL
      );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
