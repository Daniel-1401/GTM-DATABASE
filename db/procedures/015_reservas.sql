/* Stored procedures de Reservas. */
CREATE OR ALTER PROCEDURE [alimentacion].[usp_Reservas_ObtenerCalendario]
 @IdentityId UNIQUEIDENTIFIER,@ActorId UNIQUEIDENTIFIER,@CollaboratorId UNIQUEIDENTIFIER,@Application NVARCHAR(100),@RolesJson NVARCHAR(MAX),@AllowedSiteIdsJson NVARCHAR(MAX),@SiteId UNIQUEIDENTIFIER,@Year INT,@Month INT
AS BEGIN SET NOCOUNT ON;
 IF @CollaboratorId IS NULL OR ISJSON(@AllowedSiteIdsJson)<>1 BEGIN SELECT N'UNAUTHORIZED' Codigo,N'Colaborador o contexto inválido' Mensaje; RETURN; END;
 SELECT m.FechaServicio AS [date],m.TipoServicio AS serviceType,m.EstaDisponible AS serviceAvailable,m.IdentificadorPublico AS menuId,r.IdentificadorPublico AS reservationId,r.Estado AS reservationState
 FROM [alimentacion].[Menu] m JOIN [alimentacion].[PlanificacionMensual] p ON p.IdPlanificacionMensual=m.IdPlanificacionMensual JOIN [organizacion].[Sede] s ON s.IdSede=p.IdSede
 LEFT JOIN [alimentacion].[Reserva] r ON r.IdMenu=m.IdMenu AND r.IdColaborador=(SELECT IdColaborador FROM [rrhh].[Colaborador] WHERE IdentificadorPublico=@CollaboratorId) AND r.Estado=N'RESERVADA'
 WHERE s.IdentificadorPublico=@SiteId AND p.Anio=@Year AND p.Mes=@Month AND EXISTS(SELECT 1 FROM OPENJSON(@AllowedSiteIdsJson) a WHERE TRY_CONVERT(UNIQUEIDENTIFIER,a.[value])=@SiteId) ORDER BY m.FechaServicio,m.TipoServicio;
 SELECT N'OK' Codigo,N'Calendario obtenido' Mensaje;
END;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_Reservas_Crear]
 @IdentityId UNIQUEIDENTIFIER,@ActorId UNIQUEIDENTIFIER,@CollaboratorId UNIQUEIDENTIFIER,@Application NVARCHAR(100),@RolesJson NVARCHAR(MAX),@AllowedSiteIdsJson NVARCHAR(MAX),@IdempotencyKey UNIQUEIDENTIFIER,@Date DATE,@SiteId UNIQUEIDENTIFIER
AS BEGIN SET NOCOUNT ON; SET XACT_ABORT ON; DECLARE @C BIGINT,@S INT,@P BIGINT,@M BIGINT,@R BIGINT;
 SELECT @C=IdColaborador FROM [rrhh].[Colaborador] WHERE IdentificadorPublico=@CollaboratorId; SELECT @S=IdSede FROM [organizacion].[Sede] WHERE IdentificadorPublico=@SiteId AND EXISTS(SELECT 1 FROM OPENJSON(@AllowedSiteIdsJson) a WHERE TRY_CONVERT(UNIQUEIDENTIFIER,a.[value])=@SiteId);
 SELECT TOP(1) @P=p.IdPlanificacionMensual,@M=m.IdMenu FROM [alimentacion].[PlanificacionMensual] p JOIN [organizacion].[Sede] s ON s.IdSede=p.IdSede JOIN [alimentacion].[Menu] m ON m.IdPlanificacionMensual=p.IdPlanificacionMensual WHERE p.IdSede=@S AND m.FechaServicio=@Date AND m.EstaDisponible=1 AND p.Estado=N'PUBLICADA_ABIERTA' ORDER BY m.TipoServicio;
 IF @C IS NULL OR @S IS NULL OR @P IS NULL BEGIN SELECT N'RESERVATIONS_CLOSED' Codigo,N'No existe una opción reservable' Mensaje; RETURN; END;
 IF EXISTS(SELECT 1 FROM [alimentacion].[Reserva] WHERE IdColaborador=@C AND FechaServicio=@Date AND Estado=N'RESERVADA') BEGIN SELECT N'ACTIVE_RESERVATION_EXISTS' Codigo,N'Ya existe una reserva activa' Mensaje; RETURN; END;
 INSERT [alimentacion].[Reserva](IdColaborador,IdPlanificacionMensual,IdMenu,IdSede,FechaServicio,TipoServicio) SELECT @C,@P,@M,@S,@Date,TipoServicio FROM [alimentacion].[Menu] WHERE IdMenu=@M; SET @R=SCOPE_IDENTITY();
 SELECT IdentificadorPublico AS reservationId,Estado AS state,FechaServicio AS [date],N'CREATED' Codigo,N'Reserva creada' Mensaje FROM [alimentacion].[Reserva] WHERE IdReserva=@R;
END;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_Reservas_ListarPropias]
 @IdentityId UNIQUEIDENTIFIER,@ActorId UNIQUEIDENTIFIER,@CollaboratorId UNIQUEIDENTIFIER,@Application NVARCHAR(100),@RolesJson NVARCHAR(MAX),@AllowedSiteIdsJson NVARCHAR(MAX),@SiteId UNIQUEIDENTIFIER=NULL,@State NVARCHAR(30)=NULL,@Page INT,@PageSize INT
AS BEGIN SET NOCOUNT ON; DECLARE @C BIGINT=(SELECT IdColaborador FROM [rrhh].[Colaborador] WHERE IdentificadorPublico=@CollaboratorId);
 SELECT r.IdentificadorPublico AS reservationId,r.FechaServicio AS [date],r.TipoServicio AS serviceType,r.Estado AS state,s.IdentificadorPublico AS siteId,m.IdentificadorPublico AS menuId FROM [alimentacion].[Reserva] r JOIN [organizacion].[Sede] s ON s.IdSede=r.IdSede JOIN [alimentacion].[Menu] m ON m.IdMenu=r.IdMenu WHERE r.IdColaborador=@C AND (@SiteId IS NULL OR s.IdentificadorPublico=@SiteId) AND (@State IS NULL OR r.Estado=@State) ORDER BY r.FechaServicio DESC OFFSET (@Page-1)*@PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
 SELECT N'OK' Codigo,N'Reservas obtenidas' Mensaje;
END;
GO

CREATE OR ALTER PROCEDURE [alimentacion].[usp_Reservas_Cancelar]
 @IdentityId UNIQUEIDENTIFIER,@ActorId UNIQUEIDENTIFIER,@CollaboratorId UNIQUEIDENTIFIER,@Application NVARCHAR(100),@RolesJson NVARCHAR(MAX),@AllowedSiteIdsJson NVARCHAR(MAX),@IdempotencyKey UNIQUEIDENTIFIER,@ReservationId UNIQUEIDENTIFIER
AS BEGIN SET NOCOUNT ON; DECLARE @C BIGINT=(SELECT IdColaborador FROM [rrhh].[Colaborador] WHERE IdentificadorPublico=@CollaboratorId); UPDATE [alimentacion].[Reserva] SET Estado=N'CANCELADA',FechaModificacionUtc=SYSUTCDATETIME() WHERE IdentificadorPublico=@ReservationId AND IdColaborador=@C AND Estado=N'RESERVADA'; IF @@ROWCOUNT=0 BEGIN SELECT N'NOT_OWNER' Codigo,N'Reserva no encontrada o no cancelable' Mensaje; RETURN; END; SELECT N'CANCELLED' Codigo,N'Reserva cancelada' Mensaje;
END;
GO
