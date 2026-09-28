-- Limpieza selectiva de la semilla UMC → núcleo.
-- Nunca elimina una referencia que no coincida exactamente con los valores indicados.

:ON ERROR EXIT

SET XACT_ABORT ON;
SET NOCOUNT ON;

IF N'$(ConfirmarLimpiezaUMC)' <> N'SI'
    THROW 51110, N'Limpieza bloqueada: falta ConfirmarLimpiezaUMC=SI.', 1;

DECLARE @UsuarioId INT = TRY_CONVERT(INT, N'$(UsuarioId)');
DECLARE @IdColaboradorCorporativo UNIQUEIDENTIFIER =
    TRY_CONVERT(UNIQUEIDENTIFIER, N'$(IdColaboradorCorporativo)');

IF @UsuarioId IS NULL OR @UsuarioId <= 0
    THROW 51111, N'Limpieza bloqueada: UsuarioId debe indicar el usuario usado por la semilla.', 1;

IF @IdColaboradorCorporativo IS NULL
   OR @IdColaboradorCorporativo = '00000000-0000-0000-0000-000000000000'
    THROW 51114, N'Limpieza bloqueada: IdColaboradorCorporativo debe indicar un UUID valido.', 1;

IF OBJECT_ID(N'[dbo].[UsuarioReferenciaColaborador]', N'U') IS NULL
    THROW 51112, N'La base no contiene la referencia UMC al núcleo esperada.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[UsuarioReferenciaColaborador] WITH (UPDLOCK, HOLDLOCK)
        WHERE [UsuarioId] = @UsuarioId
          AND NOT
          (
              [IdColaboradorCorporativo] = @IdColaboradorCorporativo
              AND [EstaActiva] = 1
          )
    )
        THROW 51113, N'Limpieza bloqueada: UsuarioId contiene una referencia corporativa ajena.', 1;

    DELETE FROM [dbo].[UsuarioReferenciaColaborador]
    WHERE [UsuarioId] = @UsuarioId
      AND [IdColaboradorCorporativo] = @IdColaboradorCorporativo
      AND [EstaActiva] = 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
