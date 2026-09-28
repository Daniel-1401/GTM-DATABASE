/*
    Consulta de personal SAP con filtros reducidos: solo tablas definidas en
    TablasFisicasSAP.sql.

    Devuelve el layout de FROMSAP.xlsx para cada movimiento PA0000 incluido
    en el filtro. Los datos de los demas infotipos se resuelven a la fecha de
    corte mediante BEGDA/ENDDA y SEQNR.

    Limitaciones de esta version:
      - PA0009 no esta definida, por lo que Cuenta Bancaria, Dest. Utilizacion
        y Clave banco se devuelven como NULL.
      - FROMSAP.xlsx no mapea Codigo Jefe, Codigo Evaluador ni Telefono
        Referencia. Esos campos se devuelven como NULL.
      - La columna Evento se devuelve desde PA0000.MASSN, codigo SAP de medida.
      - La descripcion de centro de costo usa CSKT.LTEXT. El archivo menciona
        CSKT-CSKT, columna que no existe en la definicion fisica.

    Filtros expuestos: mandante, colaborador, rango de movimientos, lista de
    medidas SAP e idioma. @Movimientos acepta valores MASSN separados por coma,
    por ejemplo N'01,02,03'. El filtro no depende de STRING_SPLIT para mantener
    compatibilidad con bases cuya version de compatibilidad sea anterior a 130.
    @Idioma debe coincidir con los valores realmente
    cargados en SPRAS/SPRSL (por ejemplo, N'S' en SAP).

    PA0105 no se segmenta por USRTY porque esos subtipos no fueron entregados.
    Por ello Correo Electronico, Telefono Fijo y Telefono Celular pueden requerir
    un ajuste posterior cuando se confirmen los valores de USRTY.
*/
DECLARE @Mandante NVARCHAR(3) = N'400';
DECLARE @Colaborador NVARCHAR(8) = NULL;
DECLARE @FechaDesde NVARCHAR(8) = NULL; -- YYYYMMDD; filtra PA0000.BEGDA.
DECLARE @FechaHasta NVARCHAR(8) = NULL; -- YYYYMMDD; filtra PA0000.BEGDA.
DECLARE @Movimientos NVARCHAR(100) = NULL; -- PA0000.MASSN; ej.: N'01,02,03'.
DECLARE @Idioma NVARCHAR(1) = N'S';

-- Dato interno: toma el final del rango o la fecha actual, sin filtro adicional.
DECLARE @FechaCorte NVARCHAR(8) =
    COALESCE(@FechaHasta, CONVERT(NVARCHAR(8), GETDATE(), 112));

IF @Mandante IS NULL
   OR @FechaCorte IS NULL
   OR LEN(@FechaCorte) <> 8
   OR (@FechaDesde IS NOT NULL AND LEN(@FechaDesde) <> 8)
   OR (@FechaHasta IS NOT NULL AND LEN(@FechaHasta) <> 8)
   OR (@FechaDesde IS NOT NULL AND @FechaHasta IS NOT NULL AND @FechaDesde > @FechaHasta)
    THROW 50000, N'Los filtros de mandante y fechas no son validos.', 1;

SELECT
    [Organizacion].[BUKRS] AS [Sociedad],
    [Movimiento].[PERNR] AS [Codigo],
    [Documento].[ICTYP] AS [Tipo Documento Identidad],
    [Documento].[ICNUM] AS [Nº Documento Identidad],
    [Persona].[NACHN] AS [Apellido Paterno],
    [Persona].[NACH2] AS [Apellido Materno],
    [Persona].[NAME2] AS [Apellido Solter@],
    [Persona].[VORNA] AS [Nombres],
    [Movimiento].[BEGDA] AS [Fecha de Ingreso],
    [Movimiento].[ENDDA] AS [Fecha de Cese],
    [Movimiento].[MASSG] AS [Motivo Cese],
    [Organizacion].[PLANS] AS [Posicion (cargo)],
    [Posicion].[STEXT] AS [Descripcion Posicion],
    [Persona].[GBORT] AS [Lugar Nacimiento],
    [Persona].[GBDAT] AS [Fecha Nacimiento],
    [Formacion].[AUSBI] AS [Profesion],
    [Organizacion].[ORGEH] AS [Codigo Area],
    [Area].[ORGTX] AS [Descripcion Area],
    CAST(NULL AS NVARCHAR(8)) AS [Codigo Jefe],
    CAST(NULL AS NVARCHAR(8)) AS [Codigo Evaluador],
    [Contrato].[CTEDT] AS [Fecha Fin de Contrato],
    [Fotocheck].[ZAUSW] AS [Codigo Fotocheck],
    [Correo].[USRID_LONG] AS [Correo Electronico],
    [Movimiento].[MASSN] AS [Evento],
    [Direccion].[ZZ_TVIA] AS [Codigo Via],
    CAST(NULL AS NVARCHAR(60)) AS [Calle],
    [Direccion].[STRAS] AS [Calle y Nro],
    [Direccion].[HSNMR] AS [Nro],
    [Direccion].[ZZ_INTE] AS [Interior],
    [Direccion].[ZZ_CDPTO] AS [Dpto],
    [Direccion].[ZZ_MANZ] AS [Manzana],
    [Direccion].[ZZ_LOTE] AS [Lote],
    [Direccion].[ZZ_KILO] AS [Kilometro],
    [Direccion].[ZZ_BLOC] AS [Bloque],
    [Direccion].[ZZ_ETAP] AS [Etapa],
    [Direccion].[ZZ_CZON] AS [Codigo Zona],
    [Direccion].[ZZ_DZON] AS [Nombre Zona],
    [Direccion].[ZZ_DDPTO] AS [Departamento],
    [Direccion].[ZZ_DPROV] AS [Provincia],
    [Direccion].[ZZ_DDIST] AS [Distrito],
    [TelefonoFijo].[USRID] AS [Telefono Fijo],
    [TelefonoCelular].[USRID] AS [Telefono Celular],
    CAST(NULL AS NVARCHAR(30)) AS [Telefono Referencia],
    [Organizacion].[PERSG] AS [Grupo Personal],
    [GrupoPersonal].[PTEXT] AS [Descripcion Grupo Personal],
    [Organizacion].[PERSK] AS [Codigo Area Personal],
    [AreaPersonal].[PTEXT] AS [Descripcion Area Personal],
    [Organizacion].[BTRTL] AS [Codigo SubDivision],
    [Subdivision].[BTEXT] AS [Descripcion SubDivision],
    [Organizacion].[WERKS] AS [Codigo Division Personal],
    [DivisionPersonal].[NAME1] AS [Descripcion Division Personal],
    [Organizacion].[KOSTL] AS [Codigo Centro Costo],
    [CentroCosto].[LTEXT] AS [Descripcion Centro Costo],
    [Direccion].[ZZ_UBIG] AS [Ubigeo],
    [Persona].[NATIO] AS [Pais],
    [Nacionalidad].[NATIO] AS [Nacionalidad],
    [Persona].[FAMST] AS [Codigo Estado civil],
    [EstadoCivil].[FTEXT] AS [Descripcion Estado Civil],
    [Direccion].[LOCAT] AS [Campo Adicional de Direccion],
    [Persona].[ANRED] AS [Tratamiento],
    CAST(NULL AS NVARCHAR(241)) AS [Cuenta Bancaria],
    CAST(NULL AS NVARCHAR(241)) AS [Dest. Utilización],
    CAST(NULL AS NVARCHAR(241)) AS [Clave banco]
FROM [gsp].[PA0000] AS [Movimiento]
CROSS APPLY
(
    SELECT TOP (1) [PA0001].*
    FROM [gsp].[PA0001] AS [PA0001]
    WHERE [PA0001].[MANDT] = [Movimiento].[MANDT]
      AND [PA0001].[PERNR] = [Movimiento].[PERNR]
      AND [PA0001].[BEGDA] <= @FechaCorte
      AND [PA0001].[ENDDA] >= @FechaCorte
    ORDER BY [PA0001].[BEGDA] DESC, [PA0001].[ENDDA] DESC, [PA0001].[SEQNR] DESC
) AS [Organizacion]
OUTER APPLY
(
    SELECT TOP (1) [PA0002].*
    FROM [gsp].[PA0002] AS [PA0002]
    WHERE [PA0002].[MANDT] = [Movimiento].[MANDT]
      AND [PA0002].[PERNR] = [Movimiento].[PERNR]
      AND [PA0002].[BEGDA] <= @FechaCorte
      AND [PA0002].[ENDDA] >= @FechaCorte
    ORDER BY [PA0002].[BEGDA] DESC, [PA0002].[ENDDA] DESC, [PA0002].[SEQNR] DESC
) AS [Persona]
OUTER APPLY
(
    SELECT TOP (1) [PA0185].*
    FROM [gsp].[PA0185] AS [PA0185]
    WHERE [PA0185].[MANDT] = [Movimiento].[MANDT]
      AND [PA0185].[PERNR] = [Movimiento].[PERNR]
      AND [PA0185].[BEGDA] <= @FechaCorte
      AND [PA0185].[ENDDA] >= @FechaCorte
    ORDER BY [PA0185].[BEGDA] DESC, [PA0185].[ENDDA] DESC, [PA0185].[SEQNR] DESC
) AS [Documento]
OUTER APPLY
(
    SELECT TOP (1) [PA0016].*
    FROM [gsp].[PA0016] AS [PA0016]
    WHERE [PA0016].[MANDT] = [Movimiento].[MANDT]
      AND [PA0016].[PERNR] = [Movimiento].[PERNR]
      AND [PA0016].[BEGDA] <= @FechaCorte
      AND [PA0016].[ENDDA] >= @FechaCorte
    ORDER BY [PA0016].[BEGDA] DESC, [PA0016].[ENDDA] DESC, [PA0016].[SEQNR] DESC
) AS [Contrato]
OUTER APPLY
(
    SELECT TOP (1) [PA0022].*
    FROM [gsp].[PA0022] AS [PA0022]
    WHERE [PA0022].[MANDT] = [Movimiento].[MANDT]
      AND [PA0022].[PERNR] = [Movimiento].[PERNR]
      AND [PA0022].[BEGDA] <= @FechaCorte
      AND [PA0022].[ENDDA] >= @FechaCorte
    ORDER BY [PA0022].[BEGDA] DESC, [PA0022].[ENDDA] DESC, [PA0022].[SEQNR] DESC
) AS [Formacion]
OUTER APPLY
(
    SELECT TOP (1) [PA0050].*
    FROM [gsp].[PA0050] AS [PA0050]
    WHERE [PA0050].[MANDT] = [Movimiento].[MANDT]
      AND [PA0050].[PERNR] = [Movimiento].[PERNR]
      AND [PA0050].[BEGDA] <= @FechaCorte
      AND [PA0050].[ENDDA] >= @FechaCorte
    ORDER BY [PA0050].[BEGDA] DESC, [PA0050].[ENDDA] DESC, [PA0050].[SEQNR] DESC
) AS [Fotocheck]
OUTER APPLY
(
    SELECT TOP (1) [PA0006].*
    FROM [gsp].[PA0006] AS [PA0006]
    WHERE [PA0006].[MANDT] = [Movimiento].[MANDT]
      AND [PA0006].[PERNR] = [Movimiento].[PERNR]
      AND [PA0006].[BEGDA] <= @FechaCorte
      AND [PA0006].[ENDDA] >= @FechaCorte
    ORDER BY [PA0006].[BEGDA] DESC, [PA0006].[ENDDA] DESC, [PA0006].[SEQNR] DESC
) AS [Direccion]
OUTER APPLY
(
    SELECT TOP (1) [PA0105].*
    FROM [gsp].[PA0105] AS [PA0105]
    WHERE [PA0105].[MANDT] = [Movimiento].[MANDT]
      AND [PA0105].[PERNR] = [Movimiento].[PERNR]
      AND [PA0105].[BEGDA] <= @FechaCorte
      AND [PA0105].[ENDDA] >= @FechaCorte
    ORDER BY [PA0105].[BEGDA] DESC, [PA0105].[ENDDA] DESC, [PA0105].[SEQNR] DESC
) AS [Correo]
OUTER APPLY
(
    SELECT TOP (1) [PA0105].*
    FROM [gsp].[PA0105] AS [PA0105]
    WHERE [PA0105].[MANDT] = [Movimiento].[MANDT]
      AND [PA0105].[PERNR] = [Movimiento].[PERNR]
      AND [PA0105].[BEGDA] <= @FechaCorte
      AND [PA0105].[ENDDA] >= @FechaCorte
    ORDER BY [PA0105].[BEGDA] DESC, [PA0105].[ENDDA] DESC, [PA0105].[SEQNR] DESC
) AS [TelefonoFijo]
OUTER APPLY
(
    SELECT TOP (1) [PA0105].*
    FROM [gsp].[PA0105] AS [PA0105]
    WHERE [PA0105].[MANDT] = [Movimiento].[MANDT]
      AND [PA0105].[PERNR] = [Movimiento].[PERNR]
      AND [PA0105].[BEGDA] <= @FechaCorte
      AND [PA0105].[ENDDA] >= @FechaCorte
    ORDER BY [PA0105].[BEGDA] DESC, [PA0105].[ENDDA] DESC, [PA0105].[SEQNR] DESC
) AS [TelefonoCelular]
OUTER APPLY
(
    SELECT TOP (1) [HRP1000].*
    FROM [gsp].[HRP1000] AS [HRP1000]
    WHERE [HRP1000].[MANDT] = [Movimiento].[MANDT]
      AND [HRP1000].[PLVAR] = N'01'
      AND [HRP1000].[OTYPE] = N'S'
      AND [HRP1000].[OBJID] = [Organizacion].[PLANS]
      AND [HRP1000].[ISTAT] = N'1'
      AND [HRP1000].[LANGU] = @Idioma
      AND [HRP1000].[BEGDA] <= @FechaCorte
      AND [HRP1000].[ENDDA] >= @FechaCorte
    ORDER BY [HRP1000].[BEGDA] DESC, [HRP1000].[ENDDA] DESC, [HRP1000].[SEQNR] DESC
) AS [Posicion]
OUTER APPLY
(
    SELECT TOP (1) [T527X].*
    FROM [gsp].[T527X] AS [T527X]
    WHERE [T527X].[MANDT] = [Movimiento].[MANDT]
      AND [T527X].[SPRSL] = @Idioma
      AND [T527X].[ORGEH] = [Organizacion].[ORGEH]
      AND [T527X].[BEGDA] <= @FechaCorte
      AND [T527X].[ENDDA] >= @FechaCorte
    ORDER BY [T527X].[BEGDA] DESC, [T527X].[ENDDA] DESC
) AS [Area]
OUTER APPLY
(
    SELECT TOP (1) [CSKT].*
    FROM [gsp].[CSKT] AS [CSKT]
    WHERE [CSKT].[MANDT] = [Movimiento].[MANDT]
      AND [CSKT].[SPRAS] = @Idioma
      AND [CSKT].[KOKRS] = [Organizacion].[KOKRS]
      AND [CSKT].[KOSTL] = [Organizacion].[KOSTL]
      AND [CSKT].[DATBI] >= @FechaCorte
    ORDER BY [CSKT].[DATBI] ASC
) AS [CentroCosto]
LEFT JOIN [gsp].[T501T] AS [GrupoPersonal]
    ON [GrupoPersonal].[MANDT] = [Movimiento].[MANDT]
   AND [GrupoPersonal].[SPRSL] = @Idioma
   AND [GrupoPersonal].[PERSG] = [Organizacion].[PERSG]
LEFT JOIN [gsp].[T503T] AS [AreaPersonal]
    ON [AreaPersonal].[MANDT] = [Movimiento].[MANDT]
   AND [AreaPersonal].[SPRSL] = @Idioma
   AND [AreaPersonal].[PERSK] = [Organizacion].[PERSK]
LEFT JOIN [gsp].[T001P] AS [Subdivision]
    ON [Subdivision].[MANDT] = [Movimiento].[MANDT]
   AND [Subdivision].[WERKS] = [Organizacion].[WERKS]
   AND [Subdivision].[BTRTL] = [Organizacion].[BTRTL]
LEFT JOIN [gsp].[T500P] AS [DivisionPersonal]
    ON [DivisionPersonal].[MANDT] = [Movimiento].[MANDT]
   AND [DivisionPersonal].[PERSA] = [Organizacion].[WERKS]
LEFT JOIN [gsp].[T005T] AS [Nacionalidad]
    ON [Nacionalidad].[MANDT] = [Movimiento].[MANDT]
   AND [Nacionalidad].[SPRAS] = @Idioma
   AND [Nacionalidad].[LAND1] = [Persona].[NATIO]
LEFT JOIN [gsp].[T502T] AS [EstadoCivil]
    ON [EstadoCivil].[MANDT] = [Movimiento].[MANDT]
   AND [EstadoCivil].[SPRSL] = @Idioma
   AND [EstadoCivil].[FAMST] = [Persona].[FAMST]
WHERE [Movimiento].[MANDT] = @Mandante
  AND (@Colaborador IS NULL OR [Movimiento].[PERNR] = @Colaborador)
  AND (@FechaDesde IS NULL OR [Movimiento].[BEGDA] >= @FechaDesde)
  AND (@FechaHasta IS NULL OR [Movimiento].[BEGDA] <= @FechaHasta)
  AND
  (
      @Movimientos IS NULL
      OR CHARINDEX
         (
             N',' + [Movimiento].[MASSN] + N',',
             N',' + REPLACE(@Movimientos, N' ', N'') + N','
         ) > 0
  )
ORDER BY [Movimiento].[PERNR], [Movimiento].[BEGDA], [Movimiento].[SEQNR];
