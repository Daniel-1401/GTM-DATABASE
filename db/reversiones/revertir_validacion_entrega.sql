-- Reversion aislada de 017. No ejecutar automaticamente.
IF DB_NAME() IN (N'master', N'model', N'msdb', N'tempdb') THROW 51000, 'Base de sistema rechazada', 1;
IF OBJECT_ID(N'alimentacion.ValidacionEntrega', N'U') IS NOT NULL
    DROP TABLE [alimentacion].[ValidacionEntrega];
GO
