/* Planificaciones: menu y transiciones de estado. Contrato backend Alimentacion. */

CREATE OR ALTER PROCEDURE [alimentacion].[usp_Planificaciones_GuardarMenu]
 @IdentityId UNIQUEIDENTIFIER,@ActorId UNIQUEIDENTIFIER,@CollaboratorId UNIQUEIDENTIFIER=NULL,@Application NVARCHAR(100),@RolesJson NVARCHAR(MAX),@AllowedSiteIdsJson NVARCHAR(MAX),
 @IdempotencyKey UNIQUEIDENTIFIER,@PlanId UNIQUEIDENTIFIER,@Date DATE,@ServiceType NVARCHAR(20),@ServiceAvailable BIT,@Name NVARCHAR(200)=NULL,@Description NVARCHAR(1000)=NULL,@ComponentsJson NVARCHAR(MAX),@ImageRef NVARCHAR(500)=NULL,@ConfirmAffectedReservations BIT,@ExpectedVersion INT
AS BEGIN SET NOCOUNT ON; SET XACT_ABORT ON;
 IF ISJSON(@RolesJson)<>1 OR ISJSON(@AllowedSiteIdsJson)<>1 OR ISJSON(@ComponentsJson)<>1 BEGIN SELECT N'VALIDATION_ERROR' Codigo,N'JSON inválido' Mensaje; RETURN; END;
 IF NOT EXISTS(SELECT 1 FROM OPENJSON(@RolesJson) WHERE [value] IN(N'ROOT',N'ALIMENTACION_GESTOR')) BEGIN SELECT N'FORBIDDEN' Codigo,N'Rol insuficiente' Mensaje; RETURN; END;
 DECLARE @P BIGINT,@V BIGINT; SELECT @P=IdPlanificacionMensual,@V=VersionRegistro FROM [alimentacion].[PlanificacionMensual] p JOIN [organizacion].[Sede] s ON s.IdSede=p.IdSede WHERE p.IdentificadorPublico=@PlanId AND EXISTS(SELECT 1 FROM OPENJSON(@AllowedSiteIdsJson) a WHERE TRY_CONVERT(UNIQUEIDENTIFIER,a.[value])=s.IdentificadorPublico);
 IF @P IS NULL BEGIN SELECT N'PLAN_NOT_FOUND' Codigo,N'Planificación no encontrada' Mensaje; RETURN; END;
 IF @V<>@ExpectedVersion BEGIN SELECT N'PLAN_VERSION_CONFLICT' Codigo,N'La versión de la planificación cambió' Mensaje; RETURN; END;
 IF @ServiceType NOT IN(N'DESAYUNO',N'ALMUERZO',N'CENA') OR @Date IS NULL BEGIN SELECT N'VALIDATION_ERROR' Codigo,N'Datos de menú inválidos' Mensaje; RETURN; END;
 BEGIN TRANSACTION;
 IF EXISTS(SELECT 1 FROM [alimentacion].[Menu] WHERE IdPlanificacionMensual=@P AND FechaServicio=@Date AND TipoServicio=@ServiceType)
  UPDATE [alimentacion].[Menu] SET EstaDisponible=@ServiceAvailable,Nombre=@Name,Descripcion=@Description,ReferenciaImagen=@ImageRef,VersionRegistro=VersionRegistro+1,FechaModificacionUtc=SYSUTCDATETIME() WHERE IdPlanificacionMensual=@P AND FechaServicio=@Date AND TipoServicio=@ServiceType;
 ELSE INSERT [alimentacion].[Menu](IdPlanificacionMensual,Anio,Mes,FechaServicio,TipoServicio,EstaDisponible,Nombre,Descripcion,ReferenciaImagen) SELECT @P,Anio,Mes,@Date,@ServiceType,@ServiceAvailable,@Name,@Description,@ImageRef FROM [alimentacion].[PlanificacionMensual] WHERE IdPlanificacionMensual=@P;
 UPDATE [alimentacion].[PlanificacionMensual] SET VersionRegistro=VersionRegistro+1,FechaModificacionUtc=SYSUTCDATETIME() WHERE IdPlanificacionMensual=@P AND VersionRegistro=@ExpectedVersion;
 COMMIT;
 SELECT IdentificadorPublico AS menuId,FechaServicio AS [date],TipoServicio AS serviceType,EstaDisponible AS serviceAvailable,Nombre AS [name],Descripcion AS [description],ReferenciaImagen AS imageRef FROM [alimentacion].[Menu] WHERE IdPlanificacionMensual=@P AND FechaServicio=@Date AND TipoServicio=@ServiceType;
 SELECT N'UPDATED' Codigo,N'Menú guardado' Mensaje;
END;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_Planificaciones_Publicar]
 @IdentityId UNIQUEIDENTIFIER,@ActorId UNIQUEIDENTIFIER,@CollaboratorId UNIQUEIDENTIFIER=NULL,@Application NVARCHAR(100),@RolesJson NVARCHAR(MAX),@AllowedSiteIdsJson NVARCHAR(MAX),@IdempotencyKey UNIQUEIDENTIFIER,@PlanId UNIQUEIDENTIFIER,@ExpectedVersion INT
AS BEGIN SET NOCOUNT ON; SET XACT_ABORT ON; DECLARE @n INT=0;
 IF NOT EXISTS(SELECT 1 FROM OPENJSON(@RolesJson) WHERE [value] IN(N'ROOT',N'ALIMENTACION_GESTOR')) BEGIN SELECT N'FORBIDDEN' Codigo,N'Rol insuficiente' Mensaje; RETURN; END;
 UPDATE p SET Estado=N'PUBLICADA_ABIERTA',VersionRegistro=VersionRegistro+1,FechaModificacionUtc=SYSUTCDATETIME() FROM [alimentacion].[PlanificacionMensual] p JOIN [organizacion].[Sede] s ON s.IdSede=p.IdSede WHERE p.IdentificadorPublico=@PlanId AND p.VersionRegistro=@ExpectedVersion AND p.Estado=N'BORRADOR' AND EXISTS(SELECT 1 FROM OPENJSON(@AllowedSiteIdsJson) a WHERE TRY_CONVERT(UNIQUEIDENTIFIER,a.[value])=s.IdentificadorPublico); SET @n=@@ROWCOUNT;
 IF @n=0 BEGIN SELECT N'INVALID_PLAN_STATE' Codigo,N'Plan inexistente, obsoleto o no publicable' Mensaje; RETURN; END; SELECT N'PUBLICADA_ABIERTA' State,@ExpectedVersion+1 Version,N'UPDATED' Codigo,N'Plan publicado' Mensaje;
END;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_Planificaciones_CerrarReservas]
 @IdentityId UNIQUEIDENTIFIER,@ActorId UNIQUEIDENTIFIER,@CollaboratorId UNIQUEIDENTIFIER=NULL,@Application NVARCHAR(100),@RolesJson NVARCHAR(MAX),@AllowedSiteIdsJson NVARCHAR(MAX),@IdempotencyKey UNIQUEIDENTIFIER,@PlanId UNIQUEIDENTIFIER,@ExpectedVersion INT
AS BEGIN SET NOCOUNT ON; SET XACT_ABORT ON; DECLARE @n INT=0;
 UPDATE p SET Estado=N'PUBLICADA_CERRADA',VersionRegistro=VersionRegistro+1,FechaModificacionUtc=SYSUTCDATETIME() FROM [alimentacion].[PlanificacionMensual] p JOIN [organizacion].[Sede] s ON s.IdSede=p.IdSede WHERE p.IdentificadorPublico=@PlanId AND p.VersionRegistro=@ExpectedVersion AND p.Estado=N'PUBLICADA_ABIERTA' AND EXISTS(SELECT 1 FROM OPENJSON(@AllowedSiteIdsJson) a WHERE TRY_CONVERT(UNIQUEIDENTIFIER,a.[value])=s.IdentificadorPublico); SET @n=@@ROWCOUNT;
 IF @n=0 BEGIN SELECT N'INVALID_PLAN_STATE' Codigo,N'Plan no puede cerrarse' Mensaje; RETURN; END; SELECT N'PUBLICADA_CERRADA' State,@ExpectedVersion+1 Version,N'UPDATED' Codigo,N'Reservas cerradas' Mensaje;
END;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_Planificaciones_ReabrirReservas]
 @IdentityId UNIQUEIDENTIFIER,@ActorId UNIQUEIDENTIFIER,@CollaboratorId UNIQUEIDENTIFIER=NULL,@Application NVARCHAR(100),@RolesJson NVARCHAR(MAX),@AllowedSiteIdsJson NVARCHAR(MAX),@IdempotencyKey UNIQUEIDENTIFIER,@PlanId UNIQUEIDENTIFIER,@ExpectedVersion INT
AS BEGIN SET NOCOUNT ON; SET XACT_ABORT ON; DECLARE @n INT=0;
 UPDATE p SET Estado=N'PUBLICADA_ABIERTA',VersionRegistro=VersionRegistro+1,FechaModificacionUtc=SYSUTCDATETIME() FROM [alimentacion].[PlanificacionMensual] p JOIN [organizacion].[Sede] s ON s.IdSede=p.IdSede WHERE p.IdentificadorPublico=@PlanId AND p.VersionRegistro=@ExpectedVersion AND p.Estado=N'PUBLICADA_CERRADA' AND EXISTS(SELECT 1 FROM OPENJSON(@AllowedSiteIdsJson) a WHERE TRY_CONVERT(UNIQUEIDENTIFIER,a.[value])=s.IdentificadorPublico); SET @n=@@ROWCOUNT;
 IF @n=0 BEGIN SELECT N'INVALID_PLAN_STATE' Codigo,N'Plan no puede reabrirse' Mensaje; RETURN; END; SELECT N'PUBLICADA_ABIERTA' State,@ExpectedVersion+1 Version,N'UPDATED' Codigo,N'Reservas reabiertas' Mensaje;
END;
GO
