/* Stored procedures de Planificaciones - contrato STORED_PROCEDURES_REQUERIDOS.md
   SQL Server 2017. El backend entrega el contexto despues de validar el bearer.
   Los roles y sedes se validan como JSON; nunca se aceptan desde el body funcional. */

CREATE OR ALTER PROCEDURE [alimentacion].[usp_Planificaciones_Listar]
    @IdentityId UNIQUEIDENTIFIER,
    @ActorId UNIQUEIDENTIFIER,
    @CollaboratorId UNIQUEIDENTIFIER = NULL,
    @Application NVARCHAR(100),
    @RolesJson NVARCHAR(MAX),
    @AllowedSiteIdsJson NVARCHAR(MAX),
    @Year INT = NULL,
    @Month INT = NULL,
    @SiteId UNIQUEIDENTIFIER = NULL,
    @State NVARCHAR(30) = NULL,
    @Page INT,
    @PageSize INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Codigo NVARCHAR(50) = N'OK', @Mensaje NVARCHAR(500) = N'Consulta completada';
    IF @Page < 1 OR @PageSize NOT BETWEEN 1 AND 200
    BEGIN SELECT N'VALIDATION_ERROR' AS Codigo, N'Paginación inválida' AS Mensaje; RETURN; END;
    IF ISJSON(@RolesJson) <> 1 OR ISJSON(@AllowedSiteIdsJson) <> 1
    BEGIN SELECT N'UNAUTHORIZED' AS Codigo, N'Contexto de autorización inválido' AS Mensaje; RETURN; END;
    IF NOT EXISTS (SELECT 1 FROM OPENJSON(@RolesJson) WHERE [value] IN (N'ROOT',N'ALIMENTACION_GESTOR',N'ALIMENTACION_LECTURA'))
    BEGIN SELECT N'FORBIDDEN' AS Codigo, N'Rol sin acceso a planificaciones' AS Mensaje; RETURN; END;
    IF @Year IS NOT NULL AND (@Year NOT BETWEEN 2000 AND 9999) OR @Month IS NOT NULL AND (@Month NOT BETWEEN 1 AND 12)
    BEGIN SELECT N'VALIDATION_ERROR' AS Codigo, N'Periodo inválido' AS Mensaje; RETURN; END;

    SELECT p.IdentificadorPublico AS planId, s.IdentificadorPublico AS siteId,
           p.Anio AS [year], p.Mes AS [month], p.Estado AS [state],
           p.VersionRegistro AS [version]
    FROM [alimentacion].[PlanificacionMensual] p
    INNER JOIN [organizacion].[Sede] s ON s.IdSede = p.IdSede
    WHERE (@Year IS NULL OR p.Anio = @Year)
      AND (@Month IS NULL OR p.Mes = @Month)
      AND (@SiteId IS NULL OR s.IdentificadorPublico = @SiteId)
      AND (@State IS NULL OR p.Estado = @State)
      AND EXISTS (SELECT 1 FROM OPENJSON(@AllowedSiteIdsJson) a WHERE TRY_CONVERT(UNIQUEIDENTIFIER,a.[value]) = s.IdentificadorPublico)
    ORDER BY p.Anio DESC, p.Mes DESC, s.IdentificadorPublico
    OFFSET (@Page - 1) * @PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;

    SELECT COUNT_BIG(*) AS totalItems
    FROM [alimentacion].[PlanificacionMensual] p
    INNER JOIN [organizacion].[Sede] s ON s.IdSede = p.IdSede
    WHERE (@Year IS NULL OR p.Anio = @Year) AND (@Month IS NULL OR p.Mes = @Month)
      AND (@SiteId IS NULL OR s.IdentificadorPublico = @SiteId) AND (@State IS NULL OR p.Estado = @State)
      AND EXISTS (SELECT 1 FROM OPENJSON(@AllowedSiteIdsJson) a WHERE TRY_CONVERT(UNIQUEIDENTIFIER,a.[value]) = s.IdentificadorPublico);
    SELECT @Codigo AS Codigo, @Mensaje AS Mensaje;
END;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_Planificaciones_Obtener]
    @IdentityId UNIQUEIDENTIFIER, @ActorId UNIQUEIDENTIFIER, @CollaboratorId UNIQUEIDENTIFIER = NULL,
    @Application NVARCHAR(100), @RolesJson NVARCHAR(MAX), @AllowedSiteIdsJson NVARCHAR(MAX),
    @PlanId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    IF ISJSON(@RolesJson) <> 1 OR ISJSON(@AllowedSiteIdsJson) <> 1
    BEGIN SELECT N'UNAUTHORIZED' AS Codigo, N'Contexto de autorización inválido' AS Mensaje; RETURN; END;
    SELECT p.IdentificadorPublico AS planId, s.IdentificadorPublico AS siteId,
           p.Anio AS [year], p.Mes AS [month], p.Estado AS [state], p.VersionRegistro AS [version]
    FROM [alimentacion].[PlanificacionMensual] p
    INNER JOIN [organizacion].[Sede] s ON s.IdSede = p.IdSede
    WHERE p.IdentificadorPublico = @PlanId
      AND EXISTS (SELECT 1 FROM OPENJSON(@AllowedSiteIdsJson) a WHERE TRY_CONVERT(UNIQUEIDENTIFIER,a.[value]) = s.IdentificadorPublico);
    IF @@ROWCOUNT = 0 BEGIN SELECT N'PLAN_NOT_FOUND' AS Codigo, N'Planificación no encontrada' AS Mensaje; RETURN; END;
    SELECT m.IdentificadorPublico AS menuId, m.FechaServicio AS [date], m.TipoServicio AS serviceType,
           m.EstaDisponible AS serviceAvailable, m.Nombre AS [name], m.Descripcion AS [description],
           m.ReferenciaImagen AS imageRef, m.VersionRegistro AS [version]
    FROM [alimentacion].[Menu] m
    INNER JOIN [alimentacion].[PlanificacionMensual] p ON p.IdPlanificacionMensual = m.IdPlanificacionMensual
    WHERE p.IdentificadorPublico = @PlanId ORDER BY m.FechaServicio, m.TipoServicio;
    SELECT N'OK' AS Codigo, N'Consulta completada' AS Mensaje;
END;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_Planificaciones_Crear]
    @IdentityId UNIQUEIDENTIFIER, @ActorId UNIQUEIDENTIFIER, @CollaboratorId UNIQUEIDENTIFIER = NULL,
    @Application NVARCHAR(100), @RolesJson NVARCHAR(MAX), @AllowedSiteIdsJson NVARCHAR(MAX),
    @IdempotencyKey UNIQUEIDENTIFIER, @SiteId UNIQUEIDENTIFIER, @Year INT, @Month INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @IdSede INT, @IdActor BIGINT, @IdPlan BIGINT;
    IF ISJSON(@RolesJson) <> 1 OR ISJSON(@AllowedSiteIdsJson) <> 1
    BEGIN SELECT N'UNAUTHORIZED' AS Codigo, N'Contexto de autorización inválido' AS Mensaje; RETURN; END;
    IF NOT EXISTS (SELECT 1 FROM OPENJSON(@RolesJson) WHERE [value] IN (N'ROOT',N'ALIMENTACION_GESTOR'))
    BEGIN SELECT N'FORBIDDEN' AS Codigo, N'Rol insuficiente' AS Mensaje; RETURN; END;
    IF @Year NOT BETWEEN 2000 AND 9999 OR @Month NOT BETWEEN 1 AND 12
    BEGIN SELECT N'VALIDATION_ERROR' AS Codigo, N'Periodo inválido' AS Mensaje; RETURN; END;
    SELECT @IdSede = IdSede FROM [organizacion].[Sede] WHERE IdentificadorPublico = @SiteId
      AND EXISTS (SELECT 1 FROM OPENJSON(@AllowedSiteIdsJson) a WHERE TRY_CONVERT(UNIQUEIDENTIFIER,a.[value]) = @SiteId);
    SELECT @IdActor = IdColaborador FROM [rrhh].[Colaborador] WHERE IdentificadorPublico = @ActorId;
    IF @IdSede IS NULL OR @IdActor IS NULL BEGIN SELECT N'FORBIDDEN' AS Codigo, N'Sede o actor no autorizado' AS Mensaje; RETURN; END;
    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM [alimentacion].[PlanificacionMensual] WHERE IdSede=@IdSede AND Anio=@Year AND Mes=@Month)
    BEGIN ROLLBACK; SELECT N'PLAN_ALREADY_EXISTS' AS Codigo, N'La planificación ya existe' AS Mensaje; RETURN; END;
    INSERT INTO [alimentacion].[PlanificacionMensual](IdSede,Anio,Mes) VALUES(@IdSede,@Year,@Month);
    SET @IdPlan = SCOPE_IDENTITY();
    COMMIT;
    SELECT p.IdentificadorPublico AS planId, s.IdentificadorPublico AS siteId,
           p.Anio AS [year], p.Mes AS [month], p.Estado AS [state], p.VersionRegistro AS [version]
    FROM [alimentacion].[PlanificacionMensual] p INNER JOIN [organizacion].[Sede] s ON s.IdSede=p.IdSede
    WHERE p.IdPlanificacionMensual=@IdPlan;
    SELECT N'CREATED' AS Codigo, N'Planificación creada' AS Mensaje;
END;
GO
