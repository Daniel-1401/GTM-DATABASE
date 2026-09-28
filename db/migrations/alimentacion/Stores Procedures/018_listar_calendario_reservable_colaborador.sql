-- Procedimiento: alimentacion.usp_ListarCalendarioReservableColaborador
-- Referencias: migraciones 010, 011 y 017 del modulo Alimentacion.
-- Motivo: alimentar el calendario mensual de almuerzos/servicios del colaborador.
-- Este procedimiento es de lectura y no abre transacciones de negocio.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_ListarCalendarioReservableColaborador]
    @IdColaboradorCorporativo UNIQUEIDENTIFIER,
    @IdSede INT,
    @Anio SMALLINT,
    @Mes TINYINT,
    @TipoServicio NVARCHAR(20),
    @Dia TINYINT = NULL,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    SET @TipoServicio = UPPER(NULLIF(LTRIM(RTRIM(@TipoServicio)), N''));

    IF @IdColaboradorCorporativo IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'La identidad corporativa del colaborador es obligatoria.';
        RETURN;
    END;

    IF @IdSede IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'La sede es obligatoria.';
        RETURN;
    END;

    IF @Anio IS NULL OR @Anio < 1 OR @Anio > 9999
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El año indicado no es válido para el calendario solicitado.';
        RETURN;
    END;

    IF @Mes IS NULL OR @Mes < 1 OR @Mes > 12
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El mes indicado debe estar entre 1 y 12.';
        RETURN;
    END;

    IF @Dia IS NOT NULL AND (@Dia < 1 OR @Dia > 31)
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El día indicado debe estar entre 1 y 31.';
        RETURN;
    END;

    IF @TipoServicio IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El tipo de servicio es obligatorio.';
        RETURN;
    END;

    DECLARE @NombreTipoServicio NVARCHAR(100);
    SELECT
        @NombreTipoServicio = [TipoServicio].[NombreTipoServicio]
    FROM [alimentacion].[TipoServicio] AS [TipoServicio]
    WHERE [TipoServicio].[CodigoTipoServicio] = @TipoServicio
      AND [TipoServicio].[EstaActivo] = 1;

    IF @NombreTipoServicio IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El tipo de servicio indicado no existe o está inactivo.';
        RETURN;
    END;

    DECLARE @NombreSede NVARCHAR(150);
    SELECT
        @NombreSede = [Sede].[NombreSede]
    FROM [PERSONAL_MANAGEMENT_UNIDAD_ORGANIZATIVA].[organizacion].[Sede] AS [Sede]
    WHERE [Sede].[IdSede] = @IdSede;

    IF @NombreSede IS NULL
    BEGIN
        SET @Codigo = N'NOT_FOUND';
        SET @Mensaje = N'La sede indicada no existe.';
        RETURN;
    END;

    BEGIN TRY
        DECLARE @FechaInicioMes DATE = DATEFROMPARTS(@Anio, @Mes, 1);
        DECLARE @FechaFinMes DATE = EOMONTH(@FechaInicioMes);

        IF @Dia IS NOT NULL AND @Dia > DAY(@FechaFinMes)
        BEGIN
            SET @Codigo = N'VALIDATION_ERROR';
            SET @Mensaje = N'El día indicado no existe en el mes solicitado.';
            RETURN;
        END;

        -- No existe en el repositorio una conversion aprobada de la zona IANA
        -- America/Lima para SQL Server. SYSDATETIME() es la convencion vigente.
        DECLARE @FechaOficial DATE = CONVERT(DATE, SYSDATETIME());

        ;WITH [FechasCalendario] AS
        (
            SELECT
                @FechaInicioMes AS [FechaServicio],
                CONVERT
                (
                    DATE,
                    DATEADD
                    (
                        DAY,
                        -((DATEDIFF(DAY, DATEFROMPARTS(1900, 1, 1), @FechaInicioMes) % 7 + 7) % 7),
                        @FechaInicioMes
                    )
                ) AS [FechaInicioSemana]

            UNION ALL

            SELECT
                DATEADD(DAY, 1, [FechasCalendario].[FechaServicio]),
                CONVERT
                (
                    DATE,
                    DATEADD
                    (
                        DAY,
                        -((DATEDIFF(DAY, DATEFROMPARTS(1900, 1, 1), DATEADD(DAY, 1, [FechasCalendario].[FechaServicio])) % 7 + 7) % 7),
                        DATEADD(DAY, 1, [FechasCalendario].[FechaServicio])
                    )
                )
            FROM [FechasCalendario]
            WHERE [FechasCalendario].[FechaServicio] < @FechaFinMes
        ),
        [ReservaActiva] AS
        (
            SELECT
                [Reserva].[IdReserva] AS [IdReservaInterno],
                [Reserva].[IdentificadorPublico] AS [IdReserva],
                [Reserva].[IdPlanificacion] AS [IdPlanificacionInterno],
                [Reserva].[IdMenu] AS [IdMenuInterno],
                [Reserva].[IdSede],
                [Sede].[NombreSede] AS [NombreSedeReservaActiva],
                [Reserva].[FechaServicio],
                [Reserva].[TipoServicio],
                [Reserva].[Estado] AS [EstadoReserva],
                [Planificacion].[Estado] AS [EstadoPlanificacionReserva]
            FROM [alimentacion].[Reserva] AS [Reserva]
            INNER JOIN [alimentacion].[Planificacion] AS [Planificacion]
                ON [Planificacion].[IdPlanificacion] = [Reserva].[IdPlanificacion]
            INNER JOIN [PERSONAL_MANAGEMENT_UNIDAD_ORGANIZATIVA].[organizacion].[Sede] AS [Sede]
                ON [Sede].[IdSede] = [Reserva].[IdSede]
            WHERE [Reserva].[IdColaboradorCorporativo] = @IdColaboradorCorporativo
              AND [Reserva].[FechaServicio] >= @FechaInicioMes
              AND [Reserva].[FechaServicio] <= @FechaFinMes
              AND [Reserva].[Estado] = N'RESERVADA'
        ),
        [CalendarioBase] AS
        (
            SELECT
                [FechasCalendario].[FechaServicio],
                [FechasCalendario].[FechaInicioSemana],
                [ReservaActiva].[IdReservaInterno],
                [ReservaActiva].[IdReserva],
                [ReservaActiva].[IdPlanificacionInterno] AS [IdPlanificacionReservaInterno],
                [ReservaActiva].[IdSede] AS [IdSedeReservaActiva],
                [ReservaActiva].[NombreSedeReservaActiva],
                [ReservaActiva].[EstadoReserva],
                [ReservaActiva].[EstadoPlanificacionReserva],
                [ContenidoVisible].[IdPlanificacionPublico],
                [ContenidoVisible].[EstadoPlanificacion],
                [ContenidoVisible].[IdMenuInterno],
                [ContenidoVisible].[IdMenuPublico],
                [ContenidoVisible].[EstaDisponible],
                [ContenidoVisible].[NombreMenu],
                [ContenidoVisible].[DescripcionMenu],
                [ContenidoVisible].[ReferenciaImagen]
            FROM [FechasCalendario]
            LEFT JOIN [ReservaActiva]
                ON [ReservaActiva].[FechaServicio] = [FechasCalendario].[FechaServicio]
            OUTER APPLY
            (
                SELECT TOP (1)
                    [Planificacion].[IdPlanificacion] AS [IdPlanificacionInterno],
                    [Planificacion].[IdentificadorPublico] AS [IdPlanificacionPublico],
                    [Planificacion].[Estado] AS [EstadoPlanificacion],
                    [Menu].[IdMenu] AS [IdMenuInterno],
                    [Menu].[IdentificadorPublico] AS [IdMenuPublico],
                    [Menu].[EstaDisponible],
                    [Menu].[Nombre] AS [NombreMenu],
                    [Menu].[Descripcion] AS [DescripcionMenu],
                    [Menu].[ReferenciaImagen]
                FROM [alimentacion].[Planificacion] AS [Planificacion]
                INNER JOIN [alimentacion].[Menu] AS [Menu]
                    ON [Menu].[IdPlanificacion] = [Planificacion].[IdPlanificacion]
                   AND [Menu].[FechaServicio] = [FechasCalendario].[FechaServicio]
                   AND [Menu].[TipoServicio] = @TipoServicio
                   AND [Menu].[EstaActivo] = 1
                WHERE [Planificacion].[IdSede] = @IdSede
                  AND [Planificacion].[FechaInicio] <= [FechasCalendario].[FechaServicio]
                  AND [Planificacion].[FechaFin] >= [FechasCalendario].[FechaServicio]
                  AND [Planificacion].[EstaActivo] = 1
                  AND [Planificacion].[Estado] IN
                      (N'PUBLICADA_ABIERTA', N'PUBLICADA_CERRADA', N'CONSOLIDADA')
                ORDER BY
                    CASE
                        WHEN [ReservaActiva].[IdSede] = @IdSede
                         AND [Planificacion].[IdPlanificacion] = [ReservaActiva].[IdPlanificacionInterno]
                         AND [Menu].[IdMenu] = [ReservaActiva].[IdMenuInterno]
                        THEN 0
                        ELSE 1
                    END,
                    [Planificacion].[IdPlanificacion] DESC
            ) AS [ContenidoVisible]
        ),
        [PrimeraFechaRelevante] AS
        (
            SELECT MIN([CalendarioBase].[FechaServicio]) AS [FechaServicio]
            FROM [CalendarioBase]
            WHERE [CalendarioBase].[IdMenuInterno] IS NOT NULL
               OR [CalendarioBase].[IdReservaInterno] IS NOT NULL
        )
        SELECT
            [CalendarioBase].[FechaServicio],
            [CalendarioBase].[FechaInicioSemana],
            CONVERT(BIT, CASE WHEN [CalendarioBase].[FechaServicio] = @FechaOficial THEN 1 ELSE 0 END) AS [EsFechaActual],
            CONVERT
            (
                BIT,
                CASE
                    WHEN [CalendarioBase].[FechaServicio] = [PrimeraFechaRelevante].[FechaServicio]
                    THEN 1
                    ELSE 0
                END
            ) AS [EsPrimeraFechaRelevanteDelMes],
            [IdSede] = @IdSede,
            [NombreSede] = @NombreSede,
            [TipoServicio] = @TipoServicio,
            [NombreTipoServicio] = @NombreTipoServicio,
            [CalendarioBase].[IdPlanificacionPublico] AS [IdPlanificacion],
            [CalendarioBase].[EstadoPlanificacion],
            [CalendarioBase].[IdMenuPublico] AS [IdMenu],
            CONVERT(BIT, CASE WHEN [CalendarioBase].[IdMenuInterno] IS NULL THEN 0 ELSE 1 END) AS [TieneMenu],
            [CalendarioBase].[EstaDisponible],
            [CalendarioBase].[NombreMenu],
            [CalendarioBase].[DescripcionMenu],
            [CalendarioBase].[ReferenciaImagen],
            [CalendarioBase].[IdReserva],
            [CalendarioBase].[EstadoReserva],
            [CalendarioBase].[IdSedeReservaActiva],
            [CalendarioBase].[NombreSedeReservaActiva],
            [EstadoCard] =
                CASE
                    WHEN [CalendarioBase].[IdReservaInterno] IS NOT NULL
                     AND [CalendarioBase].[IdSedeReservaActiva] <> @IdSede
                    THEN N'RESERVA_EN_OTRA_SEDE'
                    WHEN [CalendarioBase].[IdReservaInterno] IS NOT NULL
                     AND [CalendarioBase].[IdSedeReservaActiva] = @IdSede
                    THEN N'RESERVA_PROPIA'
                    WHEN [CalendarioBase].[IdMenuInterno] IS NULL
                    THEN N'NO_CONFIGURADO'
                    WHEN [CalendarioBase].[EstaDisponible] = 0
                    THEN N'SIN_ATENCION'
                    WHEN [CalendarioBase].[EstadoPlanificacion] = N'PUBLICADA_ABIERTA'
                    THEN N'RESERVABLE'
                    WHEN [CalendarioBase].[EstadoPlanificacion] = N'PUBLICADA_CERRADA'
                    THEN N'RESERVAS_CERRADAS'
                    WHEN [CalendarioBase].[EstadoPlanificacion] = N'CONSOLIDADA'
                    THEN N'CONSOLIDADA'
                    ELSE N'NO_CONFIGURADO'
                END,
            [PuedeReservar] =
                CONVERT
                (
                    BIT,
                    CASE
                        WHEN [CalendarioBase].[IdReservaInterno] IS NULL
                         AND [CalendarioBase].[IdMenuInterno] IS NOT NULL
                         AND [CalendarioBase].[EstaDisponible] = 1
                         AND [CalendarioBase].[EstadoPlanificacion] = N'PUBLICADA_ABIERTA'
                        THEN 1
                        ELSE 0
                    END
                ),
            [PuedeCancelar] =
                CONVERT
                (
                    BIT,
                    CASE
                        WHEN [CalendarioBase].[IdReservaInterno] IS NOT NULL
                         AND [CalendarioBase].[IdSedeReservaActiva] = @IdSede
                         AND [CalendarioBase].[EstadoPlanificacionReserva] = N'PUBLICADA_ABIERTA'
                        THEN 1
                        ELSE 0
                    END
                ),
            [PuedeGenerarQR] =
                CONVERT
                (
                    BIT,
                    CASE
                        WHEN [CalendarioBase].[IdReservaInterno] IS NOT NULL
                         AND [CalendarioBase].[IdSedeReservaActiva] = @IdSede
                         AND [CalendarioBase].[EstadoPlanificacionReserva] = N'CONSOLIDADA'
                         AND [CalendarioBase].[FechaServicio] = @FechaOficial
                        THEN 1
                        ELSE 0
                    END
                )
        FROM [CalendarioBase]
        CROSS JOIN [PrimeraFechaRelevante]
        WHERE @Dia IS NULL
           OR DAY([CalendarioBase].[FechaServicio]) = @Dia
        ORDER BY [CalendarioBase].[FechaServicio]
        OPTION (MAXRECURSION 0, RECOMPILE);
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @NumeroErrorCapturado INT = ERROR_NUMBER();
        DECLARE @EstadoErrorCapturado INT = ERROR_STATE();
        DECLARE @LineaErrorCapturado INT = ERROR_LINE();
        DECLARE @DetalleErrorCapturado NVARCHAR(2048) = ERROR_MESSAGE();
        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_ListarCalendarioReservableColaborador',
            @NumeroError = @NumeroErrorCapturado,
            @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado,
            @DetalleInterno = @DetalleErrorCapturado;
        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operación.';
    END CATCH;
END;
GO
