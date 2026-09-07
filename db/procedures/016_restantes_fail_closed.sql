/* Procedimientos restantes del contrato. Fail-closed hasta completar las reglas
   de QR, auditoria, idempotencia y concurrencia con pruebas SQL Server. */

CREATE OR ALTER PROCEDURE [alimentacion].[usp_Planificaciones_CopiarMenu]
 @IdentityId UNIQUEIDENTIFIER,@ActorId UNIQUEIDENTIFIER,@CollaboratorId UNIQUEIDENTIFIER=NULL,@Application NVARCHAR(100),@RolesJson NVARCHAR(MAX),@AllowedSiteIdsJson NVARCHAR(MAX),@IdempotencyKey UNIQUEIDENTIFIER,@PlanId UNIQUEIDENTIFIER,@SourceDate DATE,@SourceServiceType NVARCHAR(20),@DestinationsJson NVARCHAR(MAX),@ConfirmAffectedReservations BIT,@ExpectedVersion INT
AS BEGIN SET NOCOUNT ON; SELECT N'DEPENDENCY_UNAVAILABLE' Codigo,N'Procedimiento pendiente de implementación completa' Mensaje; END;
GO
CREATE OR ALTER PROCEDURE [alimentacion].[usp_Planificaciones_Consolidar]
 @IdentityId UNIQUEIDENTIFIER,@ActorId UNIQUEIDENTIFIER,@CollaboratorId UNIQUEIDENTIFIER=NULL,@Application NVARCHAR(100),@RolesJson NVARCHAR(MAX),@AllowedSiteIdsJson NVARCHAR(MAX),@IdempotencyKey UNIQUEIDENTIFIER,@PlanId UNIQUEIDENTIFIER,@ExpectedVersion INT
AS BEGIN SET NOCOUNT ON; SELECT N'DEPENDENCY_UNAVAILABLE' Codigo,N'Procedimiento pendiente de implementación completa' Mensaje; END;
GO
CREATE OR ALTER PROCEDURE [alimentacion].[usp_Qr_Emitir]
 @IdentityId UNIQUEIDENTIFIER,@ActorId UNIQUEIDENTIFIER,@CollaboratorId UNIQUEIDENTIFIER,@Application NVARCHAR(100),@RolesJson NVARCHAR(MAX),@AllowedSiteIdsJson NVARCHAR(MAX),@IdempotencyKey UNIQUEIDENTIFIER,@ReservationId UNIQUEIDENTIFIER,@BleEvidenceJson NVARCHAR(MAX)
AS BEGIN SET NOCOUNT ON; SELECT N'DEPENDENCY_UNAVAILABLE' Codigo,N'Procedimiento pendiente de implementación completa' Mensaje; END;
GO
CREATE OR ALTER PROCEDURE [alimentacion].[usp_Qr_Revocar]
 @IdentityId UNIQUEIDENTIFIER,@ActorId UNIQUEIDENTIFIER,@CollaboratorId UNIQUEIDENTIFIER,@Application NVARCHAR(100),@RolesJson NVARCHAR(MAX),@AllowedSiteIdsJson NVARCHAR(MAX),@IdempotencyKey UNIQUEIDENTIFIER,@QrId UNIQUEIDENTIFIER,@Reason NVARCHAR(30)
AS BEGIN SET NOCOUNT ON; SELECT N'DEPENDENCY_UNAVAILABLE' Codigo,N'Procedimiento pendiente de implementación completa' Mensaje; END;
GO
CREATE OR ALTER PROCEDURE [alimentacion].[usp_Entregas_ValidarQr]
 @IdentityId UNIQUEIDENTIFIER,@ActorId UNIQUEIDENTIFIER,@CollaboratorId UNIQUEIDENTIFIER=NULL,@Application NVARCHAR(100),@RolesJson NVARCHAR(MAX),@AllowedSiteIdsJson NVARCHAR(MAX),@IdempotencyKey UNIQUEIDENTIFIER,@QrValue NVARCHAR(MAX),@InputMethod NVARCHAR(20)
AS BEGIN SET NOCOUNT ON; SELECT N'DEPENDENCY_UNAVAILABLE' Codigo,N'Procedimiento pendiente de implementación completa' Mensaje; END;
GO
CREATE OR ALTER PROCEDURE [alimentacion].[usp_Entregas_Confirmar]
 @IdentityId UNIQUEIDENTIFIER,@ActorId UNIQUEIDENTIFIER,@CollaboratorId UNIQUEIDENTIFIER=NULL,@Application NVARCHAR(100),@RolesJson NVARCHAR(MAX),@AllowedSiteIdsJson NVARCHAR(MAX),@IdempotencyKey UNIQUEIDENTIFIER,@ValidationId UNIQUEIDENTIFIER
AS BEGIN SET NOCOUNT ON; SELECT N'DEPENDENCY_UNAVAILABLE' Codigo,N'Procedimiento pendiente de implementación completa' Mensaje; END;
GO
CREATE OR ALTER PROCEDURE [alimentacion].[usp_Reportes_ObtenerReservas]
 @IdentityId UNIQUEIDENTIFIER,@ActorId UNIQUEIDENTIFIER,@CollaboratorId UNIQUEIDENTIFIER=NULL,@Application NVARCHAR(100),@RolesJson NVARCHAR(MAX),@AllowedSiteIdsJson NVARCHAR(MAX),@IdempotencyKey UNIQUEIDENTIFIER=NULL,@DateFrom DATE,@DateTo DATE,@SiteId UNIQUEIDENTIFIER=NULL,@ServiceType NVARCHAR(20)=NULL,@MenuId UNIQUEIDENTIFIER=NULL,@State NVARCHAR(30)=NULL
AS BEGIN SET NOCOUNT ON; SELECT N'DEPENDENCY_UNAVAILABLE' Codigo,N'Procedimiento pendiente de implementación completa' Mensaje; END;
GO
CREATE OR ALTER PROCEDURE [alimentacion].[usp_Reportes_ExportarReservas]
 @IdentityId UNIQUEIDENTIFIER,@ActorId UNIQUEIDENTIFIER,@CollaboratorId UNIQUEIDENTIFIER=NULL,@Application NVARCHAR(100),@RolesJson NVARCHAR(MAX),@AllowedSiteIdsJson NVARCHAR(MAX),@IdempotencyKey UNIQUEIDENTIFIER,@DateFrom DATE,@DateTo DATE,@SiteId UNIQUEIDENTIFIER=NULL,@ServiceType NVARCHAR(20)=NULL,@MenuId UNIQUEIDENTIFIER=NULL,@State NVARCHAR(30)=NULL
AS BEGIN SET NOCOUNT ON; SELECT N'DEPENDENCY_UNAVAILABLE' Codigo,N'Procedimiento pendiente de implementación completa' Mensaje; END;
GO
CREATE OR ALTER PROCEDURE [alimentacion].[usp_Auditoria_ListarEventos]
 @IdentityId UNIQUEIDENTIFIER,@ActorId UNIQUEIDENTIFIER,@CollaboratorId UNIQUEIDENTIFIER=NULL,@Application NVARCHAR(100),@RolesJson NVARCHAR(MAX),@AllowedSiteIdsJson NVARCHAR(MAX),@OccurredFrom DATETIME2=NULL,@OccurredTo DATETIME2=NULL,@EventType NVARCHAR(MAX)=NULL,@ActorIdFilter UNIQUEIDENTIFIER=NULL,@ObjectType NVARCHAR(MAX)=NULL,@ObjectId UNIQUEIDENTIFIER=NULL,@SiteId UNIQUEIDENTIFIER=NULL,@ServiceType NVARCHAR(20)=NULL,@Result NVARCHAR(20)=NULL,@CorrelationId UNIQUEIDENTIFIER=NULL,@Page INT,@PageSize INT
AS BEGIN SET NOCOUNT ON; SELECT N'DEPENDENCY_UNAVAILABLE' Codigo,N'Procedimiento pendiente de implementación completa' Mensaje; END;
GO
CREATE OR ALTER PROCEDURE [alimentacion].[usp_Seguridad_ResolverActor]
 @Subject NVARCHAR(300),@ObjectId UNIQUEIDENTIFIER=NULL,@Issuer NVARCHAR(500)
AS BEGIN SET NOCOUNT ON; SELECT N'DEPENDENCY_UNAVAILABLE' Codigo,N'Resolución delegada a Seguridad externa' Mensaje; END;
GO
CREATE OR ALTER PROCEDURE [alimentacion].[usp_Reservas_MarcarNoRecogidas]
 @IdentityId UNIQUEIDENTIFIER,@ActorId UNIQUEIDENTIFIER,@Application NVARCHAR(100),@RolesJson NVARCHAR(MAX),@AllowedSiteIdsJson NVARCHAR(MAX),@CutoffAt DATETIME2,@CorrelationId UNIQUEIDENTIFIER
AS BEGIN SET NOCOUNT ON; SELECT N'DEPENDENCY_UNAVAILABLE' Codigo,N'Job pendiente de implementación completa' Mensaje; END;
GO
