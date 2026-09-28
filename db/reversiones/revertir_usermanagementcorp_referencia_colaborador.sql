-- Reversión destructiva de la extensión UMC hacia núcleo.
-- No modifica objetos legacy de USERMANAGEMENTCORP.

:ON ERROR EXIT

SET XACT_ABORT ON;
SET NOCOUNT ON;

IF N'$(ConfirmarReversionUMCReferencia)' <> N'SI'
    THROW 51120, N'Reversión bloqueada: falta ConfirmarReversionUMCReferencia=SI.', 1;

IF NULLIF(N'$(BaseDatosEsperada)', N'') IS NULL OR DB_NAME() <> N'$(BaseDatosEsperada)'
    THROW 51121, N'Reversión bloqueada: la base actual no coincide con BaseDatosEsperada.', 1;

IF DB_ID() <= 4 OR DB_NAME() IN (N'master', N'model', N'msdb', N'tempdb')
    THROW 51122, N'Reversión bloqueada: no se permite operar sobre una base de sistema.', 1;

IF OBJECT_ID(N'[dbo].[UsuarioReferenciaColaborador]', N'U') IS NULL
    THROW 51123, N'Reversión bloqueada: la huella de la referencia UMC no coincide.', 1;

IF OBJECT_ID(N'[dbo].[usp_ResolverContextoUsuarioNucleoPorAcceso]', N'P') IS NULL
    THROW 51124, N'Reversión bloqueada: falta el procedure UMC esperado.', 1;

IF OBJECT_ID(N'[auditoria].[ErrorProcedimiento]', N'U') IS NULL
   OR OBJECT_ID(N'[auditoria].[usp_RegistrarErrorProcedimiento]', N'P') IS NULL
    THROW 51125, N'Reversión bloqueada: falta la auditoría UMC esperada.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
    DROP PROCEDURE [dbo].[usp_ResolverContextoUsuarioNucleoPorAcceso];
    DROP PROCEDURE [auditoria].[usp_RegistrarErrorProcedimiento];
    DROP TABLE [auditoria].[ErrorProcedimiento];
    DROP TABLE [dbo].[UsuarioReferenciaColaborador];
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
