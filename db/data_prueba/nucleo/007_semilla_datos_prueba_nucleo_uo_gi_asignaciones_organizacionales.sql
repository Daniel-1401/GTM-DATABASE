-- Semilla de datos de prueba: asignaciones organizacionales de Golden Investment.
-- Motor objetivo: Microsoft SQL Server 2017.
-- Fuentes: db/csv_data/colaborador.csv, posiciones.csv y areas.csv.
-- Empresa operativa y empleadora: Golden Investment S.A. (GI).
-- Sede operativa: Golden Palace (codigo 01).
-- Requiere ejecutar las semillas 003 (organizacion) y 006 (relaciones laborales).

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @CodigoEmpresa NVARCHAR(10) = N'GI';
DECLARE @CodigoSede NVARCHAR(30) = N'01';
DECLARE @NombreSede NVARCHAR(150) = N'Golden Palace';

DECLARE @IdEmpresaReferencia INT =
(
    SELECT [IdEmpresaReferencia]
    FROM [organizacion].[EmpresaReferencia]
    WHERE [CodigoEmpresa] = @CodigoEmpresa
      AND [RazonSocial] = N'Golden Investment S.A.'
);

IF @IdEmpresaReferencia IS NULL
    THROW 51000, N'No se encontro la empresa referencia Golden Investment.', 1;

DECLARE @IdEmpresaEmpleadoraCorporativa UNIQUEIDENTIFIER =
(
    SELECT [IdEmpresaCorporativa]
    FROM [organizacion].[EmpresaReferencia]
    WHERE [IdEmpresaReferencia] = @IdEmpresaReferencia
);

DECLARE @IdUnidadOrganizativaOrigenCorporativa UNIQUEIDENTIFIER =
(
    SELECT [IdUnidadOrganizativaCorporativa]
    FROM [organizacion].[ConfiguracionUnidadOrganizativa]
    WHERE [IdConfiguracionUnidadOrganizativa] = 1
);

IF @IdEmpresaEmpleadoraCorporativa IS NULL OR @IdUnidadOrganizativaOrigenCorporativa IS NULL
    THROW 51001, N'No se encontro la configuracion corporativa de Golden Investment.', 1;

DECLARE @IdSede INT =
(
    SELECT [IdSede]
    FROM [organizacion].[Sede]
    WHERE [IdEmpresaReferencia] = @IdEmpresaReferencia
      AND [CodigoSede] = @CodigoSede
      AND [NombreSede] = @NombreSede
);

IF @IdSede IS NULL
    THROW 51002, N'No se encontro la sede Golden Palace de Golden Investment.', 1;

DECLARE @AreasOrigen TABLE
(
    [IdAreaOrigen] INT NOT NULL PRIMARY KEY,
    [CodigoArea] NVARCHAR(30) NOT NULL,
    [NombreArea] NVARCHAR(150) NOT NULL
);

INSERT INTO @AreasOrigen ([IdAreaOrigen], [CodigoArea], [NombreArea])
VALUES
    (1, N'GI-AREA-1', N'ADMINISTRACION'),
    (2, N'GI-AREA-2', N'LOGISTICA'),
    (3, N'GI-AREA-3', N'ANALISIS Y ESTADISTICA'),
    (4, N'GI-AREA-4', N'AUDITORIA'),
    (5, N'GI-AREA-5', N'OPERACIONES'),
    (6, N'GI-AREA-6', N'CAMARAS'),
    (7, N'GI-AREA-7', N'CONTABILIDAD'),
    (8, N'GI-AREA-8', N'FINANZAS'),
    (9, N'GI-AREA-9', N'GERENCIA'),
    (10, N'GI-AREA-10', N'CUMPLIMIENTO'),
    (11, N'GI-AREA-11', N'LEGAL'),
    (12, N'GI-AREA-12', N'MARKETING'),
    (13, N'GI-AREA-13', N'RRHH'),
    (14, N'GI-AREA-14', N'TI');

DECLARE @Posiciones TABLE
(
    [IdPosicion] INT NOT NULL PRIMARY KEY,
    [IdAreaOrigen] INT NOT NULL
);

INSERT INTO @Posiciones ([IdPosicion], [IdAreaOrigen])
VALUES
    (1, 8),
    (2, 8),
    (3, 4),
    (4, 12),
    (5, 10),
    (6, 3),
    (7, 6),
    (8, 1),
    (9, 2),
    (10, 5),
    (11, 7),
    (12, 13),
    (13, 14),
    (14, 9),
    (15, 4),
    (16, 12),
    (17, 12),
    (18, 12),
    (19, 12),
    (20, 12),
    (22, 4),
    (23, 4),
    (24, 12),
    (25, 12),
    (26, 12),
    (27, 12),
    (28, 12),
    (31, 12),
    (32, 12),
    (33, 12),
    (34, 12),
    (35, 12),
    (36, 12),
    (37, 12),
    (38, 12),
    (39, 12),
    (40, 12),
    (41, 12),
    (42, 12),
    (43, 12),
    (44, 12),
    (45, 10),
    (46, 10),
    (47, 10),
    (48, 10),
    (49, 10),
    (50, 10),
    (51, 10),
    (52, 10),
    (53, 10),
    (54, 3),
    (55, 3),
    (56, 6),
    (57, 1),
    (58, 1),
    (59, 1),
    (60, 1),
    (61, 1),
    (62, 2),
    (63, 2),
    (64, 2),
    (65, 5),
    (66, 5),
    (67, 5),
    (68, 5),
    (69, 7),
    (70, 7),
    (71, 7),
    (72, 13),
    (74, 13),
    (75, 13),
    (76, 13),
    (77, 13),
    (78, 13),
    (79, 13),
    (82, 14),
    (83, 14),
    (84, 14),
    (85, 14),
    (86, 14),
    (87, 14),
    (88, 14),
    (89, 14),
    (90, 14),
    (91, 14),
    (92, 14),
    (93, 14),
    (94, 14),
    (95, 14),
    (96, 14),
    (97, 9),
    (98, 9),
    (99, 9),
    (100, 9),
    (101, 10),
    (102, 11),
    (103, 11),
    (104, 11),
    (105, 11),
    (106, 11),
    (107, 11);

DECLARE @Carga TABLE
(
    [CodigoColaboradorSAP] NVARCHAR(30) NOT NULL PRIMARY KEY,
    [IdPosicion] INT NOT NULL
);

INSERT INTO @Carga ([CodigoColaboradorSAP], [IdPosicion])
VALUES
    (N'20003850', 58),
    (N'20003863', 59),
    (N'20003855', 57),
    (N'20003148', 60),
    (N'20003654', 60),
    (N'20001432', 8),
    (N'20003722', 61),
    (N'20003695', 53),
    (N'20000027', 52),
    (N'20000207', 52),
    (N'20002766', 52),
    (N'20003241', 53),
    (N'20003380', 53),
    (N'20000131', 101),
    (N'20000435', 51),
    (N'20001278', 63),
    (N'20000003', 64),
    (N'20000015', 9),
    (N'20000125', 62),
    (N'20001639', 54),
    (N'20003214', 6),
    (N'20002320', 55),
    (N'20000109', 38),
    (N'20003038', 38),
    (N'20003768', 38),
    (N'20003856', 38),
    (N'20000020', 34),
    (N'20000026', 34),
    (N'20000058', 34),
    (N'20000258', 36),
    (N'20000330', 36),
    (N'20003018', 36),
    (N'20003023', 36),
    (N'20001446', 37),
    (N'20003151', 37),
    (N'20003181', 37),
    (N'20003208', 37),
    (N'20003275', 37),
    (N'20003320', 37),
    (N'20003374', 37),
    (N'20003436', 37),
    (N'20003462', 37),
    (N'20003499', 37),
    (N'20003526', 37),
    (N'20003540', 37),
    (N'20003651', 37),
    (N'20003736', 37),
    (N'20003765', 37),
    (N'20003795', 37),
    (N'20003813', 37),
    (N'20003821', 37),
    (N'20003846', 37),
    (N'20000080', 37),
    (N'20000197', 37),
    (N'20000268', 37),
    (N'20000271', 37),
    (N'20001381', 37),
    (N'20000063', 33),
    (N'20002839', 18),
    (N'20000297', 35),
    (N'20002199', 22),
    (N'20003707', 22),
    (N'20000128', 3),
    (N'20000532', 23),
    (N'20001107', 23),
    (N'20002200', 23),
    (N'20002319', 23),
    (N'20003366', 23),
    (N'20003470', 23),
    (N'20001328', 15),
    (N'20002870', 26),
    (N'20003570', 42),
    (N'20003600', 42),
    (N'20003742', 42),
    (N'20003793', 42),
    (N'20003838', 42),
    (N'20000416', 42),
    (N'20002797', 42),
    (N'20003210', 42),
    (N'20003362', 42),
    (N'20003825', 42),
    (N'20003880', 42),
    (N'20000009', 17),
    (N'20000066', 31),
    (N'20000119', 31),
    (N'20000141', 31),
    (N'20000216', 31),
    (N'20000671', 31),
    (N'20001500', 31),
    (N'20001540', 31),
    (N'20001663', 31),
    (N'20001681', 31),
    (N'20002683', 31),
    (N'20003031', 31),
    (N'20003033', 31),
    (N'20003227', 31),
    (N'20000657', 28),
    (N'20000031', 16),
    (N'20000069', 16),
    (N'20000334', 16),
    (N'20001817', 16),
    (N'20001485', 32),
    (N'20001562', 32),
    (N'20001771', 32),
    (N'20001799', 32),
    (N'20002112', 32),
    (N'20002612', 32),
    (N'20002786', 32),
    (N'20002821', 32),
    (N'20002850', 32),
    (N'20003012', 32),
    (N'20003034', 32),
    (N'20003082', 32),
    (N'20003099', 32),
    (N'20003103', 32),
    (N'20003199', 32),
    (N'20003222', 32),
    (N'20003228', 32),
    (N'20003234', 32),
    (N'20003242', 32),
    (N'20003259', 32),
    (N'20003265', 32),
    (N'20003266', 32),
    (N'20003285', 32),
    (N'20003338', 32),
    (N'20003396', 32),
    (N'20003490', 32),
    (N'20003493', 32),
    (N'20003498', 32),
    (N'20003690', 32),
    (N'20003697', 32),
    (N'20003723', 32),
    (N'20003730', 32),
    (N'20003754', 32),
    (N'20003764', 32),
    (N'20003779', 32),
    (N'20003786', 32),
    (N'20003802', 32),
    (N'20003803', 32),
    (N'20003804', 32),
    (N'20003830', 32),
    (N'20003831', 32),
    (N'20003832', 32),
    (N'20003833', 32),
    (N'20003836', 32),
    (N'20003837', 32),
    (N'20003857', 32),
    (N'20003866', 32),
    (N'20003705', 32),
    (N'20003772', 32),
    (N'20003783', 32),
    (N'20003785', 32),
    (N'20003859', 32),
    (N'20000118', 32),
    (N'20001431', 32),
    (N'20003701', 48),
    (N'20002947', 49),
    (N'20003629', 49),
    (N'20000048', 47),
    (N'20002268', 50),
    (N'20000059', 5),
    (N'20003169', 46),
    (N'20002875', 67),
    (N'20001569', 68),
    (N'20003689', 68),
    (N'20000352', 65),
    (N'20000007', 10),
    (N'20001981', 66),
    (N'20003114', 25),
    (N'20003637', 25),
    (N'20003743', 25),
    (N'20003839', 25),
    (N'20000354', 25),
    (N'20001190', 25),
    (N'20000443', 24),
    (N'20000097', 16),
    (N'20003770', 69),
    (N'20003102', 70),
    (N'20003773', 71),
    (N'20000005', 11),
    (N'20003015', 2),
    (N'20003322', 56),
    (N'20000130', 7),
    (N'20002869', 43),
    (N'20002341', 20),
    (N'20000019', 44),
    (N'20000194', 44),
    (N'20000198', 44),
    (N'20000245', 44),
    (N'20000246', 44),
    (N'20000849', 44),
    (N'20001970', 44),
    (N'20002066', 44),
    (N'20002496', 44),
    (N'20003011', 44),
    (N'20003014', 44),
    (N'20003296', 44),
    (N'20003304', 44),
    (N'20003474', 44),
    (N'20003537', 44),
    (N'20003568', 44),
    (N'20003590', 44),
    (N'20003669', 44),
    (N'20003726', 44),
    (N'20003735', 44),
    (N'20003745', 44),
    (N'20003759', 44),
    (N'20003776', 44),
    (N'20003788', 44),
    (N'20003843', 44),
    (N'20003845', 44),
    (N'20003860', 44),
    (N'20000108', 44),
    (N'20000190', 44),
    (N'20000426', 97),
    (N'20003708', 99),
    (N'20000545', 14),
    (N'20001403', 98),
    (N'20003826', 100),
    (N'20002502', 106),
    (N'20003316', 106),
    (N'20003539', 106),
    (N'20003808', 105),
    (N'20001492', 106),
    (N'20003036', 107),
    (N'20003878', 107),
    (N'20000404', 103),
    (N'20003315', 104),
    (N'20002963', 102),
    (N'20000078', 4),
    (N'20000473', 12),
    (N'20001452', 72),
    (N'20000936', 74),
    (N'20003233', 75),
    (N'20000110', 79),
    (N'20001053', 78),
    (N'20000474', 76),
    (N'20003157', 77),
    (N'20000166', 82),
    (N'20000047', 50),
    (N'20000256', 50),
    (N'20001895', 50),
    (N'20003098', 50),
    (N'20000372', 86),
    (N'20002506', 84),
    (N'20003009', 85),
    (N'20003533', 87),
    (N'20003849', 88),
    (N'20002643', 83),
    (N'20003865', 96),
    (N'20003767', 95),
    (N'20003058', 93),
    (N'20003043', 91),
    (N'20003509', 94),
    (N'20003848', 94),
    (N'20003061', 92),
    (N'20003550', 92),
    (N'20003467', 90),
    (N'20003542', 90),
    (N'20003876', 90),
    (N'20003879', 90),
    (N'20000376', 89),
    (N'20000220', 42),
    (N'20001826', 42),
    (N'20001896', 42),
    (N'20002042', 42),
    (N'20003050', 42),
    (N'20003188', 42),
    (N'20003202', 42),
    (N'20003223', 42),
    (N'20003273', 42),
    (N'20003309', 42),
    (N'20003416', 42),
    (N'20003419', 42),
    (N'20003516', 42),
    (N'20003517', 42),
    (N'20003545', 42),
    (N'20003610', 42),
    (N'20003670', 42),
    (N'20003671', 42),
    (N'20003673', 42),
    (N'20003747', 42),
    (N'20003752', 42),
    (N'20003774', 42),
    (N'20003829', 42),
    (N'20003840', 42),
    (N'20003841', 42),
    (N'20003842', 42),
    (N'20003853', 42),
    (N'20003864', 42),
    (N'20003868', 42),
    (N'20003869', 42),
    (N'20003871', 42),
    (N'20003872', 42),
    (N'20003873', 42),
    (N'20003874', 42),
    (N'20000001', 19),
    (N'20000049', 39),
    (N'20000114', 41),
    (N'20000181', 41),
    (N'20000203', 41),
    (N'20000279', 41),
    (N'20000348', 41),
    (N'20000390', 41),
    (N'20000461', 41),
    (N'20003750', 41),
    (N'20000052', 40),
    (N'20001410', 40),
    (N'20000368', 45);

IF EXISTS
(
    SELECT 1
    FROM @Carga AS [carga]
    LEFT JOIN @Posiciones AS [posicion]
        ON [posicion].[IdPosicion] = [carga].[IdPosicion]
    WHERE [posicion].[IdPosicion] IS NULL
)
    THROW 51003, N'No se encontro una posicion de origen para uno de los colaboradores.', 1;

IF EXISTS
(
    SELECT 1
    FROM @Posiciones AS [posicion]
    LEFT JOIN @AreasOrigen AS [areaOrigen]
        ON [areaOrigen].[IdAreaOrigen] = [posicion].[IdAreaOrigen]
    WHERE [areaOrigen].[IdAreaOrigen] IS NULL
)
    THROW 51004, N'No se encontro un area de origen para una de las posiciones.', 1;

IF EXISTS
(
    SELECT 1
    FROM @Carga AS [carga]
    INNER JOIN @Posiciones AS [posicion]
        ON [posicion].[IdPosicion] = [carga].[IdPosicion]
    INNER JOIN @AreasOrigen AS [areaOrigen]
        ON [areaOrigen].[IdAreaOrigen] = [posicion].[IdAreaOrigen]
    LEFT JOIN [organizacion].[Area] AS [areaLocal]
        ON [areaLocal].[IdEmpresaReferencia] = @IdEmpresaReferencia
       AND [areaLocal].[CodigoArea] = [areaOrigen].[CodigoArea]
    WHERE [areaLocal].[IdArea] IS NULL
)
    THROW 51005, N'No se encontro una de las areas de Golden Investment.', 1;

IF EXISTS
(
    SELECT 1
    FROM @Carga AS [carga]
    LEFT JOIN [rrhh].[RelacionLaboral] AS [relacion]
        ON [relacion].[IdEmpresaReferencia] = @IdEmpresaReferencia
       AND [relacion].[CodigoColaboradorSAP] = [carga].[CodigoColaboradorSAP]
    WHERE [relacion].[IdRelacionLaboralCorporativa] IS NULL
)
    THROW 51006, N'No se encontro una relacion laboral de Golden Investment.', 1;

IF EXISTS
(
    SELECT 1
    FROM @Carga AS [carga]
    INNER JOIN @Posiciones AS [posicion]
        ON [posicion].[IdPosicion] = [carga].[IdPosicion]
    INNER JOIN @AreasOrigen AS [areaOrigen]
        ON [areaOrigen].[IdAreaOrigen] = [posicion].[IdAreaOrigen]
    INNER JOIN [organizacion].[Area] AS [areaLocal]
        ON [areaLocal].[IdEmpresaReferencia] = @IdEmpresaReferencia
       AND [areaLocal].[CodigoArea] = [areaOrigen].[CodigoArea]
    INNER JOIN [rrhh].[RelacionLaboral] AS [relacion]
        ON [relacion].[IdEmpresaReferencia] = @IdEmpresaReferencia
       AND [relacion].[CodigoColaboradorSAP] = [carga].[CodigoColaboradorSAP]
    INNER JOIN [rrhh].[AsignacionOrganizacional] AS [asignacion]
        ON [asignacion].[IdRelacionLaboralCorporativa] = [relacion].[IdRelacionLaboralCorporativa]
    WHERE [asignacion].[IdEmpresaReferencia] <> @IdEmpresaReferencia
       OR [asignacion].[IdSede] <> @IdSede
       OR [asignacion].[IdArea] <> [areaLocal].[IdArea]
       OR [asignacion].[EstaActiva] <> 1
)
    THROW 51007, N'Existe una asignacion organizacional incompatible con la semilla.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO [rrhh].[AsignacionOrganizacional]
    (
        [IdRelacionLaboralCorporativa],
        [IdColaboradorCorporativo],
        [IdUnidadOrganizativaOrigenCorporativa],
        [IdEmpresaEmpleadoraCorporativa],
        [IdEmpresaReferencia],
        [IdSede],
        [IdArea],
        [EstaActiva]
    )
    SELECT
        [relacion].[IdRelacionLaboralCorporativa],
        [relacion].[IdColaboradorCorporativo],
        @IdUnidadOrganizativaOrigenCorporativa,
        @IdEmpresaEmpleadoraCorporativa,
        @IdEmpresaReferencia,
        @IdSede,
        [areaLocal].[IdArea],
        1
    FROM @Carga AS [carga]
    INNER JOIN @Posiciones AS [posicion]
        ON [posicion].[IdPosicion] = [carga].[IdPosicion]
    INNER JOIN @AreasOrigen AS [areaOrigen]
        ON [areaOrigen].[IdAreaOrigen] = [posicion].[IdAreaOrigen]
    INNER JOIN [organizacion].[Area] AS [areaLocal]
        ON [areaLocal].[IdEmpresaReferencia] = @IdEmpresaReferencia
       AND [areaLocal].[CodigoArea] = [areaOrigen].[CodigoArea]
    INNER JOIN [rrhh].[RelacionLaboral] AS [relacion]
        ON [relacion].[IdEmpresaReferencia] = @IdEmpresaReferencia
       AND [relacion].[CodigoColaboradorSAP] = [carga].[CodigoColaboradorSAP]
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM [rrhh].[AsignacionOrganizacional] WITH (UPDLOCK, HOLDLOCK)
        WHERE [IdRelacionLaboralCorporativa] = [relacion].[IdRelacionLaboralCorporativa]
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
