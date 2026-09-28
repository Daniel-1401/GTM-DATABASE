-- Semilla de dbo.UsuarioReferenciaColaborador.
-- Reemplace solamente los valores de UsuarioId e IdColaboradorCorporativo al ejecutar:
-- sqlcmd ... -v UsuarioId="<usuario-id>" IdColaboradorCorporativo="<uuid-colaborador>"
-- IdUsuarioCorporativo se genera automaticamente mediante el valor predeterminado de la tabla.

:ON ERROR EXIT

SET XACT_ABORT ON;
SET NOCOUNT ON;

DECLARE @UsuarioId INT = 3221;
DECLARE @IdColaboradorCorporativo UNIQUEIDENTIFIER = '4D43C4D1-834A-4FC0-811C-7B4A7FF2FF77';

IF @UsuarioId IS NULL OR @UsuarioId <= 0
    THROW 51100, N'UsuarioId debe indicar un usuario legacy existente.', 1;

IF @IdColaboradorCorporativo IS NULL
   OR @IdColaboradorCorporativo = '00000000-0000-0000-0000-000000000000'
    THROW 51101, N'IdColaboradorCorporativo debe indicar un UUID valido.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM [dbo].[Usuario]
    WHERE [UsuarioId] = @UsuarioId
      AND [EsActivoUsuario] = 1
)
    THROW 51102, N'UsuarioId no corresponde a un usuario legacy activo.', 1;

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
        THROW 51103, N'UsuarioId ya tiene una referencia corporativa incompatible.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[UsuarioReferenciaColaborador] WITH (UPDLOCK, HOLDLOCK)
        WHERE [IdColaboradorCorporativo] = @IdColaboradorCorporativo
          AND [UsuarioId] <> @UsuarioId
    )
        THROW 51104, N'El colaborador corporativo ya esta vinculado a otro usuario.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[UsuarioReferenciaColaborador]
        WHERE [UsuarioId] = @UsuarioId
    )
    BEGIN
        COMMIT TRANSACTION;
        RETURN;
    END;

    INSERT INTO [dbo].[UsuarioReferenciaColaborador]
    (
        [UsuarioId],
        [IdColaboradorCorporativo],
        [EstaActiva]
    )
    VALUES
    (
        @UsuarioId,
        @IdColaboradorCorporativo,
        1
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
