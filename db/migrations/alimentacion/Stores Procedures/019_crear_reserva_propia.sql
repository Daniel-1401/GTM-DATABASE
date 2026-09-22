-- Procedimiento: alimentacion.usp_CrearReservaPropia
-- Referencias: migraciones 010, 011 y 016 del modulo Alimentacion.
-- Motivo: crear una reserva propia a partir del contexto persistido del menu.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_CrearReservaPropia]
    @IdColaborador BIGINT,
    @IdMenu UNIQUEIDENTIFIER,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    IF @IdColaborador IS NULL OR @IdMenu IS NULL
    BEGIN
        SET @Codigo = N'VALIDATION_ERROR';
        SET @Mensaje = N'El colaborador y el menu son obligatorios.';
        RETURN;
    END;

    DECLARE @IdMenuInterno BIGINT;
    DECLARE @IdPlanificacionInterno BIGINT;
    DECLARE @IdSede INT;
    DECLARE @FechaServicio DATE;
    DECLARE @TipoServicio NVARCHAR(20);
    DECLARE @EstaDisponible BIT;
    DECLARE @EstaActivoMenu BIT;
    DECLARE @EstadoPlanificacion NVARCHAR(25);
    DECLARE @IdReservaInterno BIGINT;
    DECLARE @IdReservaCreadaInterno BIGINT;
    DECLARE @IdMenuReservaActivaInterno BIGINT;
    DECLARE @NumeroErrorCapturado INT;
    DECLARE @EstadoErrorCapturado INT;
    DECLARE @LineaErrorCapturado INT;
    DECLARE @DetalleErrorCapturado NVARCHAR(2048);

    BEGIN TRY
        BEGIN TRANSACTION;

        select @IdColaborador = IdColaborador
        from [rrhh].[Colaborador]
        where UsuarioId = @IdColaborador;

        IF NOT EXISTS
        (
            SELECT 1
            FROM [rrhh].[Colaborador] AS [Colaborador] WITH (UPDLOCK, HOLDLOCK)
            WHERE [Colaborador].[IdColaborador] = @IdColaborador
        )
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'NOT_FOUND';
            SET @Mensaje = N'El colaborador indicado no existe.';
            RETURN;
        END;

        SELECT
            @IdMenuInterno = [Menu].[IdMenu],
            @IdPlanificacionInterno = [Menu].[IdPlanificacion],
            @FechaServicio = [Menu].[FechaServicio],
            @TipoServicio = [Menu].[TipoServicio],
            @EstaDisponible = [Menu].[EstaDisponible],
            @EstaActivoMenu = [Menu].[EstaActivo]
        FROM [alimentacion].[Menu] AS [Menu] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Menu].[IdentificadorPublico] = @IdMenu;

        IF @IdMenuInterno IS NULL
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'MENU_NOT_FOUND';
            SET @Mensaje = N'El menu indicado no existe.';
            RETURN;
        END;

        IF @EstaActivoMenu = 0 OR @EstaDisponible = 0
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'SERVICE_NOT_AVAILABLE';
            SET @Mensaje = N'El servicio no esta disponible para reserva.';
            RETURN;
        END;

        SELECT
            @IdSede = [Planificacion].[IdSede],
            @EstadoPlanificacion = [Planificacion].[Estado]
        FROM [alimentacion].[Planificacion] AS [Planificacion] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Planificacion].[IdPlanificacion] = @IdPlanificacionInterno;

        IF @EstadoPlanificacion = N'PUBLICADA_CERRADA'
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'RESERVATIONS_CLOSED';
            SET @Mensaje = N'Las reservas estan cerradas para esta planificacion.';
            RETURN;
        END;

        IF @EstadoPlanificacion = N'CONSOLIDADA'
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'PLAN_CONSOLIDATED';
            SET @Mensaje = N'La planificacion ya fue consolidada.';
            RETURN;
        END;

        IF @EstadoPlanificacion <> N'PUBLICADA_ABIERTA'
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'INVALID_PLAN_STATE';
            SET @Mensaje = N'La planificacion no permite crear reservas.';
            RETURN;
        END;

        SELECT TOP (1)
            @IdReservaInterno = [Reserva].[IdReserva],
            @IdMenuReservaActivaInterno = [Reserva].[IdMenu]
        FROM [alimentacion].[Reserva] AS [Reserva] WITH (UPDLOCK, HOLDLOCK, INDEX([IN_Reserva_ActivaColaboradorFecha]))
        WHERE [Reserva].[IdColaborador] = @IdColaborador
          AND [Reserva].[FechaServicio] = @FechaServicio
          AND [Reserva].[Estado] = N'RESERVADA';

        IF @IdReservaInterno IS NOT NULL
        BEGIN
            IF @IdMenuReservaActivaInterno = @IdMenuInterno
            BEGIN
                COMMIT TRANSACTION;
                SET @Codigo = N'IDEMPOTENT_REPLAY';
                SET @Mensaje = NULL;

                SELECT
                    [Reserva].[IdentificadorPublico] AS [IdReserva],
                    [Menu].[IdentificadorPublico] AS [IdMenu],
                    [Planificacion].[IdentificadorPublico] AS [IdPlanificacion],
                    [Reserva].[IdSede],
                    [Reserva].[FechaServicio],
                    [Reserva].[TipoServicio],
                    [Reserva].[Estado],
                    [Reserva].[FechaCreacion],
                    [Reserva].[FechaModificacion]
                FROM [alimentacion].[Reserva] AS [Reserva]
                INNER JOIN [alimentacion].[Menu] AS [Menu]
                    ON [Menu].[IdMenu] = [Reserva].[IdMenu]
                INNER JOIN [alimentacion].[Planificacion] AS [Planificacion]
                    ON [Planificacion].[IdPlanificacion] = [Reserva].[IdPlanificacion]
                WHERE [Reserva].[IdReserva] = @IdReservaInterno;
                RETURN;
            END;

            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            SET @Codigo = N'ACTIVE_RESERVATION_EXISTS';
            SET @Mensaje = N'Ya existe una reserva activa del colaborador para la fecha indicada.';
            RETURN;
        END;

        INSERT INTO [alimentacion].[Reserva]
        (
            [IdColaborador],
            [IdPlanificacion],
            [IdMenu],
            [IdSede],
            [FechaServicio],
            [TipoServicio],
            [Estado]
        )
        VALUES
        (
            @IdColaborador,
            @IdPlanificacionInterno,
            @IdMenuInterno,
            @IdSede,
            @FechaServicio,
            @TipoServicio,
            N'RESERVADA'
        );

        SET @IdReservaCreadaInterno = CONVERT(BIGINT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;
        SET @Codigo = N'CREATED';
        SET @Mensaje = NULL;

        SELECT
            [Reserva].[IdentificadorPublico] AS [IdReserva],
            [Menu].[IdentificadorPublico] AS [IdMenu],
            [Planificacion].[IdentificadorPublico] AS [IdPlanificacion],
            [Reserva].[IdSede],
            [Reserva].[FechaServicio],
            [Reserva].[TipoServicio],
            [Reserva].[Estado],
            [Reserva].[FechaCreacion],
            [Reserva].[FechaModificacion]
        FROM [alimentacion].[Reserva] AS [Reserva]
        INNER JOIN [alimentacion].[Menu] AS [Menu]
            ON [Menu].[IdMenu] = [Reserva].[IdMenu]
        INNER JOIN [alimentacion].[Planificacion] AS [Planificacion]
            ON [Planificacion].[IdPlanificacion] = [Reserva].[IdPlanificacion]
        WHERE [Reserva].[IdReserva] = @IdReservaCreadaInterno;
    END TRY
    BEGIN CATCH
        SET @NumeroErrorCapturado = ERROR_NUMBER();
        SET @EstadoErrorCapturado = ERROR_STATE();
        SET @LineaErrorCapturado = ERROR_LINE();
        SET @DetalleErrorCapturado = ERROR_MESSAGE();

        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

        IF @NumeroErrorCapturado IN (2601, 2627)
        BEGIN
            SET @IdReservaInterno = NULL;
            SET @IdMenuReservaActivaInterno = NULL;

            SELECT TOP (1)
                @IdReservaInterno = [Reserva].[IdReserva],
                @IdMenuReservaActivaInterno = [Reserva].[IdMenu]
            FROM [alimentacion].[Reserva] AS [Reserva]
            WHERE [Reserva].[IdColaborador] = @IdColaborador
              AND [Reserva].[FechaServicio] = @FechaServicio
              AND [Reserva].[Estado] = N'RESERVADA';

            IF @IdReservaInterno IS NOT NULL
            BEGIN
                IF @IdMenuReservaActivaInterno = @IdMenuInterno
                BEGIN
                    SET @Codigo = N'IDEMPOTENT_REPLAY';
                    SET @Mensaje = NULL;

                    SELECT
                        [Reserva].[IdentificadorPublico] AS [IdReserva],
                        [Menu].[IdentificadorPublico] AS [IdMenu],
                        [Planificacion].[IdentificadorPublico] AS [IdPlanificacion],
                        [Reserva].[IdSede],
                        [Reserva].[FechaServicio],
                        [Reserva].[TipoServicio],
                        [Reserva].[Estado],
                        [Reserva].[FechaCreacion],
                        [Reserva].[FechaModificacion]
                    FROM [alimentacion].[Reserva] AS [Reserva]
                    INNER JOIN [alimentacion].[Menu] AS [Menu]
                        ON [Menu].[IdMenu] = [Reserva].[IdMenu]
                    INNER JOIN [alimentacion].[Planificacion] AS [Planificacion]
                        ON [Planificacion].[IdPlanificacion] = [Reserva].[IdPlanificacion]
                    WHERE [Reserva].[IdReserva] = @IdReservaInterno;
                    RETURN;
                END;

                SET @Codigo = N'ACTIVE_RESERVATION_EXISTS';
                SET @Mensaje = N'Ya existe una reserva activa del colaborador para la fecha indicada.';
                RETURN;
            END;
        END;

        EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
            @NombreProcedimiento = N'alimentacion.usp_CrearReservaPropia',
            @NumeroError = @NumeroErrorCapturado,
            @EstadoError = @EstadoErrorCapturado,
            @LineaError = @LineaErrorCapturado,
            @DetalleInterno = @DetalleErrorCapturado;

        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operacion.';
    END CATCH;
END;
GO

-- DECLARE @Codigo NVARCHAR(50), @Mensaje NVARCHAR(500);
-- EXEC [alimentacion].[usp_CrearReservaPropia]
--     @IdColaborador = 1,
--     @IdMenu = '00000000-0000-0000-0000-000000000000',
--     @Codigo = @Codigo OUTPUT, @Mensaje = @Mensaje OUTPUT;
