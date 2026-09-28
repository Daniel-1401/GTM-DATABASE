-- Migración: 004_crear_integracion_sap_kafka
-- Fecha: 2026-09-24
-- Entidad(es) afectada(s): integracion.PersonalSAPStaging, integracion.TVP_RecepcionPersonalSAP, integracion.usp_RegistrarPersonalSAPStaging
-- Referencia: er-diagram-v1 / STACK.md
-- Motivo: persistir de forma idempotente los eventos completos de personal SAP recibidos por Kafka.

-- UP
SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF SCHEMA_ID(N'integracion') IS NULL
    EXEC(N'CREATE SCHEMA [integracion] AUTHORIZATION [dbo]');

CREATE TABLE [integracion].[PersonalSAPStaging]
(
    [IdPersonalSAPStaging] BIGINT IDENTITY(1,1) NOT NULL,
    [IdEventoOrigen] UNIQUEIDENTIFIER NOT NULL,
    [TipoEvento] NVARCHAR(100) NOT NULL,
    [VersionEsquema] INT NOT NULL,
    [FechaEventoOrigenUtc] DATETIME2(3) NOT NULL,
    [SecuenciaOrigen] NVARCHAR(200) NOT NULL,
    [Fuente] NVARCHAR(50) NOT NULL,
    [KafkaTopic] NVARCHAR(255) NOT NULL,
    [KafkaPartition] INT NOT NULL,
    [KafkaOffset] BIGINT NOT NULL,
    [KafkaMessageKey] NVARCHAR(500) NULL,
    [PayloadOriginal] NVARCHAR(MAX) NOT NULL,
    [FechaRecepcionUtc] DATETIME2(3) NOT NULL CONSTRAINT [VP_PersonalSAPStaging_FechaRecepcionUtc] DEFAULT (SYSUTCDATETIME()),
    [Sociedad] NVARCHAR(MAX) NULL, [Codigo] NVARCHAR(MAX) NULL, [TipoDocumentoIdentidad] NVARCHAR(MAX) NULL,
    [NumeroDocumentoIdentidad] NVARCHAR(MAX) NULL, [ApellidoPaterno] NVARCHAR(MAX) NULL, [ApellidoMaterno] NVARCHAR(MAX) NULL,
    [ApellidoSoltero] NVARCHAR(MAX) NULL, [Nombres] NVARCHAR(MAX) NULL, [FechaIngreso] NVARCHAR(MAX) NULL,
    [FechaCese] NVARCHAR(MAX) NULL, [MotivoCese] NVARCHAR(MAX) NULL, [PosicionCargo] NVARCHAR(MAX) NULL,
    [DescripcionPosicion] NVARCHAR(MAX) NULL, [LugarNacimiento] NVARCHAR(MAX) NULL, [FechaNacimiento] NVARCHAR(MAX) NULL,
    [Profesion] NVARCHAR(MAX) NULL, [CodigoArea] NVARCHAR(MAX) NULL, [DescripcionArea] NVARCHAR(MAX) NULL,
    [CodigoJefe] NVARCHAR(MAX) NULL, [CodigoEvaluador] NVARCHAR(MAX) NULL, [FechaFinContrato] NVARCHAR(MAX) NULL,
    [CodigoFotocheck] NVARCHAR(MAX) NULL, [CorreoElectronico] NVARCHAR(MAX) NULL, [Evento] NVARCHAR(MAX) NULL,
    [CodigoVia] NVARCHAR(MAX) NULL, [Calle] NVARCHAR(MAX) NULL, [CalleYNumero] NVARCHAR(MAX) NULL,
    [Numero] NVARCHAR(MAX) NULL, [Interior] NVARCHAR(MAX) NULL, [DepartamentoDireccion] NVARCHAR(MAX) NULL,
    [Manzana] NVARCHAR(MAX) NULL, [Lote] NVARCHAR(MAX) NULL, [Kilometro] NVARCHAR(MAX) NULL,
    [Bloque] NVARCHAR(MAX) NULL, [Etapa] NVARCHAR(MAX) NULL, [CodigoZona] NVARCHAR(MAX) NULL,
    [NombreZona] NVARCHAR(MAX) NULL, [Departamento] NVARCHAR(MAX) NULL, [Provincia] NVARCHAR(MAX) NULL,
    [Distrito] NVARCHAR(MAX) NULL, [TelefonoFijo] NVARCHAR(MAX) NULL, [TelefonoCelular] NVARCHAR(MAX) NULL,
    [TelefonoReferencia] NVARCHAR(MAX) NULL, [GrupoPersonal] NVARCHAR(MAX) NULL, [DescripcionGrupoPersonal] NVARCHAR(MAX) NULL,
    [CodigoAreaPersonal] NVARCHAR(MAX) NULL, [DescripcionAreaPersonal] NVARCHAR(MAX) NULL, [CodigoSubdivision] NVARCHAR(MAX) NULL,
    [DescripcionSubdivision] NVARCHAR(MAX) NULL, [CodigoDivisionPersonal] NVARCHAR(MAX) NULL, [DescripcionDivisionPersonal] NVARCHAR(MAX) NULL,
    [CodigoCentroCosto] NVARCHAR(MAX) NULL, [DescripcionCentroCosto] NVARCHAR(MAX) NULL, [Ubigeo] NVARCHAR(MAX) NULL,
    [Pais] NVARCHAR(MAX) NULL, [Nacionalidad] NVARCHAR(MAX) NULL, [CodigoEstadoCivil] NVARCHAR(MAX) NULL,
    [DescripcionEstadoCivil] NVARCHAR(MAX) NULL, [CampoAdicionalDireccion] NVARCHAR(MAX) NULL, [Tratamiento] NVARCHAR(MAX) NULL,
    [CuentaBancaria] NVARCHAR(MAX) NULL, [DestinoUtilizacion] NVARCHAR(MAX) NULL, [ClaveBanco] NVARCHAR(MAX) NULL,
    CONSTRAINT [CP_PersonalSAPStaging] PRIMARY KEY CLUSTERED ([IdPersonalSAPStaging]),
    CONSTRAINT [CU_PersonalSAPStaging_IdEventoOrigen] UNIQUE ([IdEventoOrigen]),
    CONSTRAINT [CU_PersonalSAPStaging_PosicionKafka] UNIQUE ([KafkaTopic], [KafkaPartition], [KafkaOffset]),
    CONSTRAINT [RV_PersonalSAPStaging_TopicNoVacio] CHECK (LEN(LTRIM(RTRIM([KafkaTopic]))) > 0),
    CONSTRAINT [RV_PersonalSAPStaging_PartitionNoNegativa] CHECK ([KafkaPartition] >= 0),
    CONSTRAINT [RV_PersonalSAPStaging_OffsetNoNegativo] CHECK ([KafkaOffset] >= 0)
);

CREATE TYPE [integracion].[TVP_RecepcionPersonalSAP] AS TABLE
(
    [IdEventoOrigen] UNIQUEIDENTIFIER NULL, [TipoEvento] NVARCHAR(100) NULL, [VersionEsquema] INT NULL,
    [FechaEventoOrigenUtc] DATETIME2(3) NULL, [SecuenciaOrigen] NVARCHAR(200) NULL, [Fuente] NVARCHAR(50) NULL,
    [KafkaTopic] NVARCHAR(255) NULL, [KafkaPartition] INT NULL, [KafkaOffset] BIGINT NULL, [KafkaMessageKey] NVARCHAR(500) NULL,
    [PayloadOriginal] NVARCHAR(MAX) NULL,
    [Sociedad] NVARCHAR(MAX) NULL, [Codigo] NVARCHAR(MAX) NULL, [TipoDocumentoIdentidad] NVARCHAR(MAX) NULL,
    [NumeroDocumentoIdentidad] NVARCHAR(MAX) NULL, [ApellidoPaterno] NVARCHAR(MAX) NULL, [ApellidoMaterno] NVARCHAR(MAX) NULL,
    [ApellidoSoltero] NVARCHAR(MAX) NULL, [Nombres] NVARCHAR(MAX) NULL, [FechaIngreso] NVARCHAR(MAX) NULL,
    [FechaCese] NVARCHAR(MAX) NULL, [MotivoCese] NVARCHAR(MAX) NULL, [PosicionCargo] NVARCHAR(MAX) NULL,
    [DescripcionPosicion] NVARCHAR(MAX) NULL, [LugarNacimiento] NVARCHAR(MAX) NULL, [FechaNacimiento] NVARCHAR(MAX) NULL,
    [Profesion] NVARCHAR(MAX) NULL, [CodigoArea] NVARCHAR(MAX) NULL, [DescripcionArea] NVARCHAR(MAX) NULL,
    [CodigoJefe] NVARCHAR(MAX) NULL, [CodigoEvaluador] NVARCHAR(MAX) NULL, [FechaFinContrato] NVARCHAR(MAX) NULL,
    [CodigoFotocheck] NVARCHAR(MAX) NULL, [CorreoElectronico] NVARCHAR(MAX) NULL, [Evento] NVARCHAR(MAX) NULL,
    [CodigoVia] NVARCHAR(MAX) NULL, [Calle] NVARCHAR(MAX) NULL, [CalleYNumero] NVARCHAR(MAX) NULL,
    [Numero] NVARCHAR(MAX) NULL, [Interior] NVARCHAR(MAX) NULL, [DepartamentoDireccion] NVARCHAR(MAX) NULL,
    [Manzana] NVARCHAR(MAX) NULL, [Lote] NVARCHAR(MAX) NULL, [Kilometro] NVARCHAR(MAX) NULL,
    [Bloque] NVARCHAR(MAX) NULL, [Etapa] NVARCHAR(MAX) NULL, [CodigoZona] NVARCHAR(MAX) NULL,
    [NombreZona] NVARCHAR(MAX) NULL, [Departamento] NVARCHAR(MAX) NULL, [Provincia] NVARCHAR(MAX) NULL,
    [Distrito] NVARCHAR(MAX) NULL, [TelefonoFijo] NVARCHAR(MAX) NULL, [TelefonoCelular] NVARCHAR(MAX) NULL,
    [TelefonoReferencia] NVARCHAR(MAX) NULL, [GrupoPersonal] NVARCHAR(MAX) NULL, [DescripcionGrupoPersonal] NVARCHAR(MAX) NULL,
    [CodigoAreaPersonal] NVARCHAR(MAX) NULL, [DescripcionAreaPersonal] NVARCHAR(MAX) NULL, [CodigoSubdivision] NVARCHAR(MAX) NULL,
    [DescripcionSubdivision] NVARCHAR(MAX) NULL, [CodigoDivisionPersonal] NVARCHAR(MAX) NULL, [DescripcionDivisionPersonal] NVARCHAR(MAX) NULL,
    [CodigoCentroCosto] NVARCHAR(MAX) NULL, [DescripcionCentroCosto] NVARCHAR(MAX) NULL, [Ubigeo] NVARCHAR(MAX) NULL,
    [Pais] NVARCHAR(MAX) NULL, [Nacionalidad] NVARCHAR(MAX) NULL, [CodigoEstadoCivil] NVARCHAR(MAX) NULL,
    [DescripcionEstadoCivil] NVARCHAR(MAX) NULL, [CampoAdicionalDireccion] NVARCHAR(MAX) NULL, [Tratamiento] NVARCHAR(MAX) NULL,
    [CuentaBancaria] NVARCHAR(MAX) NULL, [DestinoUtilizacion] NVARCHAR(MAX) NULL, [ClaveBanco] NVARCHAR(MAX) NULL
);

COMMIT TRANSACTION;
GO

CREATE OR ALTER PROCEDURE [integracion].[usp_RegistrarPersonalSAPStaging]
    @Eventos [integracion].[TVP_RecepcionPersonalSAP] READONLY,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    DECLARE @TotalRecibidos INT = (SELECT COUNT(1) FROM @Eventos);
    DECLARE @Insertados INT = 0;

    IF @TotalRecibidos = 0
       OR EXISTS
       (
           SELECT 1
           FROM @Eventos AS [Evento]
           WHERE [Evento].[IdEventoOrigen] IS NULL
              OR [Evento].[TipoEvento] IS NULL OR [Evento].[TipoEvento] <> N'sap.personal.actualizado'
              OR [Evento].[VersionEsquema] IS NULL OR [Evento].[VersionEsquema] <> 1
              OR [Evento].[FechaEventoOrigenUtc] IS NULL
              OR NULLIF(LTRIM(RTRIM([Evento].[SecuenciaOrigen])), N'') IS NULL
              OR [Evento].[Fuente] IS NULL OR [Evento].[Fuente] <> N'SAP'
              OR NULLIF(LTRIM(RTRIM([Evento].[KafkaTopic])), N'') IS NULL
              OR [Evento].[KafkaPartition] IS NULL OR [Evento].[KafkaPartition] < 0
              OR [Evento].[KafkaOffset] IS NULL OR [Evento].[KafkaOffset] < 0
              OR NULLIF(LTRIM(RTRIM([Evento].[PayloadOriginal])), N'') IS NULL
              OR ISJSON([Evento].[PayloadOriginal]) <> 1
       )
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El lote de eventos SAP no cumple el contrato de recepcion.';
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM @Eventos AS [EventoUno]
        INNER JOIN @Eventos AS [EventoDos]
            ON [EventoDos].[IdEventoOrigen] = [EventoUno].[IdEventoOrigen]
        WHERE EXISTS (SELECT [EventoUno].* EXCEPT SELECT [EventoDos].*)
    )
    OR EXISTS
    (
        SELECT 1
        FROM @Eventos AS [EventoUno]
        INNER JOIN @Eventos AS [EventoDos]
            ON [EventoDos].[KafkaTopic] = [EventoUno].[KafkaTopic]
           AND [EventoDos].[KafkaPartition] = [EventoUno].[KafkaPartition]
           AND [EventoDos].[KafkaOffset] = [EventoUno].[KafkaOffset]
        WHERE EXISTS (SELECT [EventoUno].* EXCEPT SELECT [EventoDos].*)
    )
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El lote contiene colisiones internas de eventos SAP.';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        ;WITH [EventosUnicos] AS
        (
            SELECT DISTINCT *
            FROM @Eventos AS [Evento]
        )
        INSERT INTO [integracion].[PersonalSAPStaging]
        (
            [IdEventoOrigen], [TipoEvento], [VersionEsquema], [FechaEventoOrigenUtc], [SecuenciaOrigen], [Fuente], [KafkaTopic], [KafkaPartition], [KafkaOffset], [KafkaMessageKey], [PayloadOriginal],
            [Sociedad], [Codigo], [TipoDocumentoIdentidad], [NumeroDocumentoIdentidad], [ApellidoPaterno], [ApellidoMaterno], [ApellidoSoltero], [Nombres], [FechaIngreso], [FechaCese], [MotivoCese], [PosicionCargo], [DescripcionPosicion], [LugarNacimiento], [FechaNacimiento], [Profesion], [CodigoArea], [DescripcionArea], [CodigoJefe], [CodigoEvaluador], [FechaFinContrato], [CodigoFotocheck], [CorreoElectronico], [Evento], [CodigoVia], [Calle], [CalleYNumero], [Numero], [Interior], [DepartamentoDireccion], [Manzana], [Lote], [Kilometro], [Bloque], [Etapa], [CodigoZona], [NombreZona], [Departamento], [Provincia], [Distrito], [TelefonoFijo], [TelefonoCelular], [TelefonoReferencia], [GrupoPersonal], [DescripcionGrupoPersonal], [CodigoAreaPersonal], [DescripcionAreaPersonal], [CodigoSubdivision], [DescripcionSubdivision], [CodigoDivisionPersonal], [DescripcionDivisionPersonal], [CodigoCentroCosto], [DescripcionCentroCosto], [Ubigeo], [Pais], [Nacionalidad], [CodigoEstadoCivil], [DescripcionEstadoCivil], [CampoAdicionalDireccion], [Tratamiento], [CuentaBancaria], [DestinoUtilizacion], [ClaveBanco]
        )
        SELECT
            [Evento].[IdEventoOrigen], [Evento].[TipoEvento], [Evento].[VersionEsquema], [Evento].[FechaEventoOrigenUtc], [Evento].[SecuenciaOrigen], [Evento].[Fuente], [Evento].[KafkaTopic], [Evento].[KafkaPartition], [Evento].[KafkaOffset], [Evento].[KafkaMessageKey], [Evento].[PayloadOriginal],
            [Evento].[Sociedad], [Evento].[Codigo], [Evento].[TipoDocumentoIdentidad], [Evento].[NumeroDocumentoIdentidad], [Evento].[ApellidoPaterno], [Evento].[ApellidoMaterno], [Evento].[ApellidoSoltero], [Evento].[Nombres], [Evento].[FechaIngreso], [Evento].[FechaCese], [Evento].[MotivoCese], [Evento].[PosicionCargo], [Evento].[DescripcionPosicion], [Evento].[LugarNacimiento], [Evento].[FechaNacimiento], [Evento].[Profesion], [Evento].[CodigoArea], [Evento].[DescripcionArea], [Evento].[CodigoJefe], [Evento].[CodigoEvaluador], [Evento].[FechaFinContrato], [Evento].[CodigoFotocheck], [Evento].[CorreoElectronico], [Evento].[Evento], [Evento].[CodigoVia], [Evento].[Calle], [Evento].[CalleYNumero], [Evento].[Numero], [Evento].[Interior], [Evento].[DepartamentoDireccion], [Evento].[Manzana], [Evento].[Lote], [Evento].[Kilometro], [Evento].[Bloque], [Evento].[Etapa], [Evento].[CodigoZona], [Evento].[NombreZona], [Evento].[Departamento], [Evento].[Provincia], [Evento].[Distrito], [Evento].[TelefonoFijo], [Evento].[TelefonoCelular], [Evento].[TelefonoReferencia], [Evento].[GrupoPersonal], [Evento].[DescripcionGrupoPersonal], [Evento].[CodigoAreaPersonal], [Evento].[DescripcionAreaPersonal], [Evento].[CodigoSubdivision], [Evento].[DescripcionSubdivision], [Evento].[CodigoDivisionPersonal], [Evento].[DescripcionDivisionPersonal], [Evento].[CodigoCentroCosto], [Evento].[DescripcionCentroCosto], [Evento].[Ubigeo], [Evento].[Pais], [Evento].[Nacionalidad], [Evento].[CodigoEstadoCivil], [Evento].[DescripcionEstadoCivil], [Evento].[CampoAdicionalDireccion], [Evento].[Tratamiento], [Evento].[CuentaBancaria], [Evento].[DestinoUtilizacion], [Evento].[ClaveBanco]
        FROM [EventosUnicos] AS [Evento]
        WHERE NOT EXISTS
          (
              SELECT 1
              FROM [integracion].[PersonalSAPStaging] AS [Existente] WITH (UPDLOCK, HOLDLOCK)
              WHERE [Existente].[IdEventoOrigen] = [Evento].[IdEventoOrigen]
                 OR ([Existente].[KafkaTopic] = [Evento].[KafkaTopic]
                     AND [Existente].[KafkaPartition] = [Evento].[KafkaPartition]
                     AND [Existente].[KafkaOffset] = [Evento].[KafkaOffset])
          );

        SET @Insertados = @@ROWCOUNT;
        COMMIT TRANSACTION;

        IF @Insertados = 0
        BEGIN
            SET @Codigo = N'IDEMPOTENT_REPLAY';
            SET @Mensaje = N'Los eventos SAP ya fueron recibidos.';
        END
        ELSE
        BEGIN
            SET @Codigo = N'CREATED';
            SET @Mensaje = N'Los eventos SAP fueron registrados.';
        END;

        SELECT @TotalRecibidos AS [TotalRecibidos], @Insertados AS [Insertados], @TotalRecibidos - @Insertados AS [DuplicadosIdempotentes];
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

        -- Se preserva el error original antes de invocar la auditoria interna.
        DECLARE @NumeroError INT = ERROR_NUMBER();
        DECLARE @EstadoError INT = ERROR_STATE();
        DECLARE @LineaError INT = ERROR_LINE();
        DECLARE @DetalleInterno NVARCHAR(2048) = ERROR_MESSAGE();

        IF @NumeroError IN (2601, 2627)
           AND NOT EXISTS
           (
               SELECT 1
               FROM @Eventos AS [Evento]
               WHERE NOT EXISTS
               (
                   SELECT 1
                   FROM [integracion].[PersonalSAPStaging] AS [Existente]
                   WHERE [Existente].[IdEventoOrigen] = [Evento].[IdEventoOrigen]
                      OR ([Existente].[KafkaTopic] = [Evento].[KafkaTopic]
                          AND [Existente].[KafkaPartition] = [Evento].[KafkaPartition]
                          AND [Existente].[KafkaOffset] = [Evento].[KafkaOffset])
               )
           )
        BEGIN
            SET @Codigo = N'IDEMPOTENT_REPLAY';
            SET @Mensaje = N'Los eventos SAP ya fueron recibidos.';
            SELECT @TotalRecibidos AS [TotalRecibidos], 0 AS [Insertados], @TotalRecibidos AS [DuplicadosIdempotentes];
            RETURN;
        END;

        BEGIN TRY
            EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
                @NombreProcedimiento = N'integracion.usp_RegistrarPersonalSAPStaging',
                @NumeroError = @NumeroError,
                @EstadoError = @EstadoError,
                @LineaError = @LineaError,
                @DetalleInterno = @DetalleInterno;
        END TRY
        BEGIN CATCH
            -- Un fallo de auditoria no altera el contrato seguro del procedure API.
        END CATCH;

        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operacion.';
    END CATCH;
END;
GO

-- DOWN
-- La reversión controlada está centralizada en db/reversiones/revertir_nucleo_corporativo_completo.sql.
