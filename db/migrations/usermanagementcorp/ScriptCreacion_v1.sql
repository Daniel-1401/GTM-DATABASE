create type OpcionType as table
(
    Nombre      nvarchar(100),
    NombrePadre nvarchar(100)
)
go

create type PermisoType as table
(
    RolId           int,
    SistemaOpcionId int,
    Crear           bit,
    Consultar       bit,
    Actualizar      bit,
    Eliminar        bit
)
go


create table Empresa
(
    EmpresaId        int identity
        constraint pk_EmpresaEmpresaId
            primary key,
    CodigoEmpresa    varchar(10),
    RazonSocial      varchar(150),
    CodigoTributario varchar(11),
    DireccionEmpresa varchar(150),
    UbigeoId         varchar(6),
    NombreComercial  varchar(150),
    EsActivoEmpresa  bit,
    EmpresaSap       varchar(5),
    CentroSap        varchar(5),
    UsuarioCrea      varchar(100),
    FechaCrea        datetime,
    UsuarioModifica  varchar(100),
    FechaModifica    datetime
)
go

create table Cargo
(
    CargoId                int identity
        constraint pk_CargoCargoId
            primary key,
    NombreCargo            varchar(100),
    EsActivoCargo          bit,
    EmpresaId              int
        constraint fk_EmpresaCargoEmpresaId
            references Empresa,
    DivisionPersonalSAP    varchar(5),
    SubDivisionPersonalSAP varchar(5),
    UsuarioCrea            varchar(100),
    FechaCrea              datetime,
    UsuarioModifica        varchar(100),
    FechaModifica          datetime
)
go

create table Local
(
    LocalId         int identity
        constraint pk_LocalLocalId
            primary key,
    NombreLocal     varchar(150),
    CodigoLocal     varchar(5),
    DireccionLocal  varchar(150),
    LocalSap        varchar(5),
    EsActivoLocal   bit,
    UbigeoId        varchar(6),
    EmpresaId       int
        constraint fk_EmpresaEmpresaId
            references Empresa,
    UsuarioCrea     varchar(100),
    FechaCrea       datetime,
    UsuarioModifica varchar(100),
    FechaModifica   datetime
)
go

create table Menu
(
    MenuId           int identity
        constraint pk_MenuMenuId
            primary key,
    MenuPadre        int,
    NombreMenu       varchar(100),
    NombreFormulario varchar(150),
    EsActivoMenu     bit,
    UsuarioCrea      varchar(100),
    FechaCrea        datetime,
    UsuarioModifica  varchar(100),
    FechaModifica    datetime,
    SistemaId        int,
    Icono            varchar(100)
)
go

create table NivelAcceso
(
    NivelAccesoId   int identity
        constraint pk_NivelAccesoNivelAccesoId
            primary key,
    NombreAcceso    varchar(100),
    DetalleAcceso   varchar(150),
    UsuarioCrea     varchar(100),
    FechaCrea       datetime,
    UsuarioModifica varchar(100),
    FechaModifica   datetime
)
go

create table Rol
(
    RolId           int identity
        constraint pk_RolRolId
            primary key,
    NombreRol       varchar(100),
    EsActivoRol     bit,
    RolPadre        int,
    UsuarioCrea     varchar(100),
    FechaCrea       datetime,
    UsuarioModifica varchar(100),
    FechaModifica   datetime
)
go

create table RolAccesoSistema
(
    RolId           int
        constraint fk_Rol
            references Rol,
    SistemaId       int,
    NivelAccesoId   int
        constraint fk_NivelAcceso
            references NivelAcceso,
    UsuarioCrea     varchar(100),
    FechaCrea       datetime,
    UsuarioModifica varchar(100),
    FechaModifica   datetime
)
go

create table RolMenu
(
    MenuId          int not null,
    RolId           int not null,
    UsuarioCrea     varchar(100),
    FechaCrea       datetime,
    UsuarioModifica varchar(100),
    FechaModifica   datetime,
    constraint pk_RolMenuRolMenuId
        primary key (MenuId, RolId)
)
go

create table TipoDocumento
(
    TipoDocumentoId       int identity
        constraint pk_TipoDocumentoTipoDocumentoId
            primary key,
    NombreTipoDocumento   varchar(50),
    AliasTipoDocumento    varchar(10),
    EsActivoTipoDocumento bit,
    UsuarioCrea           varchar(100),
    FechaCrea             datetime,
    UsuarioModifica       varchar(100),
    FechaModifica         datetime
)
go

create table TipoSistema
(
    TipoSistemaId       int identity
        constraint pk_TipoSistemaTipoSistemaId
            primary key,
    NombreTipoSistema   varchar(100),
    EsActivoTipoSistema bit,
    UsuarioCrea         varchar(100),
    FechaCrea           datetime,
    UsuarioModifica     varchar(100),
    FechaModifica       datetime
)
go

create table Sistema
(
    SistemaId       int identity
        constraint PK_SistemaSistemaId
            primary key,
    NombreCorto     varchar(10),
    NombreSistema   varchar(100),
    DetalleSistema  varchar(150),
    EsActivoSistema bit,
    UrlSistema      varchar(250),
    Imagen          varchar(150),
    TipoSistemaId   int
        constraint fk_TipoSistemaTipoSistemaId
            references TipoSistema,
    UsuarioCrea     varchar(100),
    FechaCrea       datetime,
    UsuarioModifica varchar(100),
    FechaModifica   datetime
)
go

create table Sistema_Opcion
(
    SistemaOpcionId int identity
        primary key,
    SistemaId       int
        constraint fk_SistemaSistemaId
            references Sistema,
    Opcion          varchar(200),
    OpcionPadreId   int
        constraint fk_Sistema_OpcionOpcionPadreId
            references Sistema_Opcion
)
go

create table Sistema_Opcion_Rol_Accion
(
    SistemaOpcionRolAccionId int identity
        primary key,
    RolId                    int
        constraint fk_RolRolId_ROL_ACCION
            references Rol,
    SistemaOpcionId          int
        constraint fk_Sistema_OpcionSistemaOpcionId
            references Sistema_Opcion,
    Crear                    bit,
    Consultar                bit,
    Actualizar               bit,
    Eliminar                 bit,
    UsuarioModifica          varchar(100),
    FechaModifica            datetime
)
go

create table Ubigeo
(
    UbigeoId           varchar(6) not null
        constraint pk_UbigeoUbigeoId
            primary key,
    CodigoDepartamento varchar(2),
    NombreDepartamento varchar(100),
    CodigoProvincia    varchar(2),
    NombreProvincia    varchar(100),
    CodigoDistrito     varchar(2),
    NombreDistrito     varchar(100)
)
go

create table Usuario
(
    UsuarioId          int identity
        constraint pk_UsuarioUsuarioId
            primary key,
    CodigoColaborador  varchar(6),
    PrimerNombre       varchar(150),
    SegundoNombre      varchar(150),
    ApellidoPaterno    varchar(150),
    ApellidoMaterno    varchar(150),
    TipoDocumentoId    int
        constraint fk_TipoDocumentoTipoDocumentoId
            references TipoDocumento,
    NumeroDocumento    varchar(20),
    Correo             varchar(100),
    UsuarioAcceso      varchar(100)
        constraint UQ_Usuario_nombre_UsuarioAcceso
            unique,
    ContrasenaAcceso   varchar(150),
    EsActivoUsuario    bit,
    EsCambioContrasena bit,
    CargoId            int
        constraint fk_CargoCargoId
            references Cargo,
    JefeId             int,
    UsuarioCrea        varchar(100),
    FechaCrea          datetime,
    UsuarioModifica    varchar(100),
    FechaModifica      datetime
)
go

create index IX_USUARIO_SOLICITUD
    on Usuario (UsuarioAcceso) include (PrimerNombre, ApellidoPaterno, ApellidoMaterno)
go

create index [NonClusteredIndex-nrodocumento]
    on Usuario (NumeroDocumento)
go

create table UsuarioEnvioCorreo
(
    EnvioCorreoExoneracionId int identity
        primary key,
    UsurioId                 int not null,
    TipoEnvio                int not null,
    SistemaId                int not null
)
go

create table UsuarioLocal
(
    LocalId         int not null
        constraint fk_LocalLocalId
            references Local,
    UsuarioId       int not null
        constraint fk_UsuarioUsuarioId
            references Usuario,
    UsuarioCrea     varchar(100),
    FechaCrea       datetime,
    UsuarioModifica varchar(100),
    FechaModifica   datetime,
    constraint pk_UsuarioLocal
        primary key (UsuarioId, LocalId)
)
go

create table UsuarioRol
(
    RolId           int not null
        constraint fk_RolRolId
            references Rol,
    UsuarioId       int not null
        constraint fk_UsuarioRolUsuarioId
            references Usuario,
    UsuarioCrea     varchar(100),
    FechaCrea       datetime,
    UsuarioModifica varchar(100),
    FechaModifica   datetime,
    constraint pk_RolUsuarioId
        primary key (RolId, UsuarioId)
)
go


	CREATE FUNCTION dbo.fn_diagramobjects()
	RETURNS int
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		declare @id_upgraddiagrams		int
		declare @id_sysdiagrams			int
		declare @id_helpdiagrams		int
		declare @id_helpdiagramdefinition	int
		declare @id_creatediagram	int
		declare @id_renamediagram	int
		declare @id_alterdiagram 	int
		declare @id_dropdiagram		int
		declare @InstalledObjects	int

		select @InstalledObjects = 0

		select 	@id_upgraddiagrams = object_id(N'dbo.sp_upgraddiagrams'),
			@id_sysdiagrams = object_id(N'dbo.sysdiagrams'),
			@id_helpdiagrams = object_id(N'dbo.sp_helpdiagrams'),
			@id_helpdiagramdefinition = object_id(N'dbo.sp_helpdiagramdefinition'),
			@id_creatediagram = object_id(N'dbo.sp_creatediagram'),
			@id_renamediagram = object_id(N'dbo.sp_renamediagram'),
			@id_alterdiagram = object_id(N'dbo.sp_alterdiagram'),
			@id_dropdiagram = object_id(N'dbo.sp_dropdiagram')

		if @id_upgraddiagrams is not null
			select @InstalledObjects = @InstalledObjects + 1
		if @id_sysdiagrams is not null
			select @InstalledObjects = @InstalledObjects + 2
		if @id_helpdiagrams is not null
			select @InstalledObjects = @InstalledObjects + 4
		if @id_helpdiagramdefinition is not null
			select @InstalledObjects = @InstalledObjects + 8
		if @id_creatediagram is not null
			select @InstalledObjects = @InstalledObjects + 16
		if @id_renamediagram is not null
			select @InstalledObjects = @InstalledObjects + 32
		if @id_alterdiagram  is not null
			select @InstalledObjects = @InstalledObjects + 64
		if @id_dropdiagram is not null
			select @InstalledObjects = @InstalledObjects + 128

		return @InstalledObjects
	END
go

exec sp_addextendedproperty 'microsoft_database_tools_support', 1, 'SCHEMA', 'dbo', 'FUNCTION', 'fn_diagramobjects'
go

deny execute on fn_diagramobjects to guest
go

grant execute on fn_diagramobjects to [public]
go


	CREATE PROCEDURE dbo.sp_alterdiagram
	(
		@diagramname 	sysname,
		@owner_id	int	= null,
		@version 	int,
		@definition 	varbinary(max)
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on

		declare @theId 			int
		declare @retval 		int
		declare @IsDbo 			int

		declare @UIDFound 		int
		declare @DiagId			int
		declare @ShouldChangeUID	int

		if(@diagramname is null)
		begin
			RAISERROR ('Invalid ARG', 16, 1)
			return -1
		end

		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner');
		if(@owner_id is null)
			select @owner_id = @theId;
		revert;

		select @ShouldChangeUID = 0
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname

		if(@DiagId IS NULL or (@IsDbo = 0 and @theId <> @UIDFound))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1);
			return -3
		end

		if(@IsDbo <> 0)
		begin
			if(@UIDFound is null or USER_NAME(@UIDFound) is null) -- invalid principal_id
			begin
				select @ShouldChangeUID = 1 ;
			end
		end

		-- update dds data
		update dbo.sysdiagrams set definition = @definition where diagram_id = @DiagId ;

		-- change owner
		if(@ShouldChangeUID = 1)
			update dbo.sysdiagrams set principal_id = @theId where diagram_id = @DiagId ;

		-- update dds version
		if(@version is not null)
			update dbo.sysdiagrams set version = @version where diagram_id = @DiagId ;

		return 0
	END
go

exec sp_addextendedproperty 'microsoft_database_tools_support', 1, 'SCHEMA', 'dbo', 'PROCEDURE', 'sp_alterdiagram'
go

deny execute on sp_alterdiagram to guest
go

grant execute on sp_alterdiagram to [public]
go


	CREATE PROCEDURE dbo.sp_creatediagram
	(
		@diagramname 	sysname,
		@owner_id		int	= null,
		@version 		int,
		@definition 	varbinary(max)
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on

		declare @theId int
		declare @retval int
		declare @IsDbo	int
		declare @userName sysname
		if(@version is null or @diagramname is null)
		begin
			RAISERROR (N'E_INVALIDARG', 16, 1);
			return -1
		end

		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner');
		revert;

		if @owner_id is null
		begin
			select @owner_id = @theId;
		end
		else
		begin
			if @theId <> @owner_id
			begin
				if @IsDbo = 0
				begin
					RAISERROR (N'E_INVALIDARG', 16, 1);
					return -1
				end
				select @theId = @owner_id
			end
		end
		-- next 2 line only for test, will be removed after define name unique
		if EXISTS(select diagram_id from dbo.sysdiagrams where principal_id = @theId and name = @diagramname)
		begin
			RAISERROR ('The name is already used.', 16, 1);
			return -2
		end

		insert into dbo.sysdiagrams(name, principal_id , version, definition)
				VALUES(@diagramname, @theId, @version, @definition) ;

		select @retval = @@IDENTITY
		return @retval
	END
go

exec sp_addextendedproperty 'microsoft_database_tools_support', 1, 'SCHEMA', 'dbo', 'PROCEDURE', 'sp_creatediagram'
go

deny execute on sp_creatediagram to guest
go

grant execute on sp_creatediagram to [public]
go


	CREATE PROCEDURE dbo.sp_dropdiagram
	(
		@diagramname 	sysname,
		@owner_id	int	= null
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
		declare @theId 			int
		declare @IsDbo 			int

		declare @UIDFound 		int
		declare @DiagId			int

		if(@diagramname is null)
		begin
			RAISERROR ('Invalid value', 16, 1);
			return -1
		end

		EXECUTE AS CALLER;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner');
		if(@owner_id is null)
			select @owner_id = @theId;
		REVERT;

		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1)
			return -3
		end

		delete from dbo.sysdiagrams where diagram_id = @DiagId;

		return 0;
	END
go

exec sp_addextendedproperty 'microsoft_database_tools_support', 1, 'SCHEMA', 'dbo', 'PROCEDURE', 'sp_dropdiagram'
go

deny execute on sp_dropdiagram to guest
go

grant execute on sp_dropdiagram to [public]
go


	CREATE PROCEDURE dbo.sp_helpdiagramdefinition
	(
		@diagramname 	sysname,
		@owner_id	int	= null
	)
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		set nocount on

		declare @theId 		int
		declare @IsDbo 		int
		declare @DiagId		int
		declare @UIDFound	int

		if(@diagramname is null)
		begin
			RAISERROR (N'E_INVALIDARG', 16, 1);
			return -1
		end

		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner');
		if(@owner_id is null)
			select @owner_id = @theId;
		revert;

		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname;
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId ))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1);
			return -3
		end

		select version, definition FROM dbo.sysdiagrams where diagram_id = @DiagId ;
		return 0
	END
go

exec sp_addextendedproperty 'microsoft_database_tools_support', 1, 'SCHEMA', 'dbo', 'PROCEDURE',
     'sp_helpdiagramdefinition'
go

deny execute on sp_helpdiagramdefinition to guest
go

grant execute on sp_helpdiagramdefinition to [public]
go


	CREATE PROCEDURE dbo.sp_helpdiagrams
	(
		@diagramname sysname = NULL,
		@owner_id int = NULL
	)
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		DECLARE @user sysname
		DECLARE @dboLogin bit
		EXECUTE AS CALLER;
			SET @user = USER_NAME();
			SET @dboLogin = CONVERT(bit,IS_MEMBER('db_owner'));
		REVERT;
		SELECT
			[Database] = DB_NAME(),
			[Name] = name,
			[ID] = diagram_id,
			[Owner] = USER_NAME(principal_id),
			[OwnerID] = principal_id
		FROM
			sysdiagrams
		WHERE
			(@dboLogin = 1 OR USER_NAME(principal_id) = @user) AND
			(@diagramname IS NULL OR name = @diagramname) AND
			(@owner_id IS NULL OR principal_id = @owner_id)
		ORDER BY
			4, 5, 1
	END
go

exec sp_addextendedproperty 'microsoft_database_tools_support', 1, 'SCHEMA', 'dbo', 'PROCEDURE', 'sp_helpdiagrams'
go

deny execute on sp_helpdiagrams to guest
go

grant execute on sp_helpdiagrams to [public]
go


	CREATE PROCEDURE dbo.sp_renamediagram
	(
		@diagramname 		sysname,
		@owner_id		int	= null,
		@new_diagramname	sysname

	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
		declare @theId 			int
		declare @IsDbo 			int

		declare @UIDFound 		int
		declare @DiagId			int
		declare @DiagIdTarg		int
		declare @u_name			sysname
		if((@diagramname is null) or (@new_diagramname is null))
		begin
			RAISERROR ('Invalid value', 16, 1);
			return -1
		end

		EXECUTE AS CALLER;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner');
		if(@owner_id is null)
			select @owner_id = @theId;
		REVERT;

		select @u_name = USER_NAME(@owner_id)

		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1)
			return -3
		end

		-- if((@u_name is not null) and (@new_diagramname = @diagramname))	-- nothing will change
		--	return 0;

		if(@u_name is null)
			select @DiagIdTarg = diagram_id from dbo.sysdiagrams where principal_id = @theId and name = @new_diagramname
		else
			select @DiagIdTarg = diagram_id from dbo.sysdiagrams where principal_id = @owner_id and name = @new_diagramname

		if((@DiagIdTarg is not null) and  @DiagId <> @DiagIdTarg)
		begin
			RAISERROR ('The name is already used.', 16, 1);
			return -2
		end

		if(@u_name is null)
			update dbo.sysdiagrams set [name] = @new_diagramname, principal_id = @theId where diagram_id = @DiagId
		else
			update dbo.sysdiagrams set [name] = @new_diagramname where diagram_id = @DiagId
		return 0
	END
go

exec sp_addextendedproperty 'microsoft_database_tools_support', 1, 'SCHEMA', 'dbo', 'PROCEDURE', 'sp_renamediagram'
go

deny execute on sp_renamediagram to guest
go

grant execute on sp_renamediagram to [public]
go


	CREATE PROCEDURE dbo.sp_upgraddiagrams
	AS
	BEGIN
		IF OBJECT_ID(N'dbo.sysdiagrams') IS NOT NULL
			return 0;

		CREATE TABLE dbo.sysdiagrams
		(
			name sysname NOT NULL,
			principal_id int NOT NULL,	-- we may change it to varbinary(85)
			diagram_id int PRIMARY KEY IDENTITY,
			version int,

			definition varbinary(max)
			CONSTRAINT UK_principal_name UNIQUE
			(
				principal_id,
				name
			)
		);


		/* Add this if we need to have some form of extended properties for diagrams */
		/*
		IF OBJECT_ID(N'dbo.sysdiagram_properties') IS NULL
		BEGIN
			CREATE TABLE dbo.sysdiagram_properties
			(
				diagram_id int,
				name sysname,
				value varbinary(max) NOT NULL
			)
		END
		*/

		IF OBJECT_ID(N'dbo.dtproperties') IS NOT NULL
		begin
			insert into dbo.sysdiagrams
			(
				[name],
				[principal_id],
				[version],
				[definition]
			)
			select
				convert(sysname, dgnm.[uvalue]),
				DATABASE_PRINCIPAL_ID(N'dbo'),			-- will change to the sid of sa
				0,							-- zero for old format, dgdef.[version],
				dgdef.[lvalue]
			from dbo.[dtproperties] dgnm
				inner join dbo.[dtproperties] dggd on dggd.[property] = 'DtgSchemaGUID' and dggd.[objectid] = dgnm.[objectid]
				inner join dbo.[dtproperties] dgdef on dgdef.[property] = 'DtgSchemaDATA' and dgdef.[objectid] = dgnm.[objectid]

			where dgnm.[property] = 'DtgSchemaNAME' and dggd.[uvalue] like N'_EA3E6268-D998-11CE-9454-00AA00A3F36E_'
			return 2;
		end
		return 1;
	END
go

exec sp_addextendedproperty 'microsoft_database_tools_support', 1, 'SCHEMA', 'dbo', 'PROCEDURE', 'sp_upgraddiagrams'
go

CREATE   PROCEDURE [dbo].[up_ActualizarSistema]
(
  @SistemaId INT,
  @NombreCorto VARCHAR(10) = NULL,
  @NombreSistema VARCHAR(100) = NULL,
  @DetalleSistema VARCHAR(150) = NULL,
  @EsActivoSistema BIT = NULL,
  @UrlSistema VARCHAR(250) = NULL,
  @Imagen VARCHAR(150) = NULL,
  @TipoSistemaId INT = NULL,
  @UsuarioModifica VARCHAR(100) = NULL,
  @Opciones dbo.OpcionType READONLY
 )
AS
BEGIN
  SET NOCOUNT ON;

  -- Actualizar datos generales del sistema
  UPDATE dbo.Sistema
  SET NombreCorto     = ISNULL(@NombreCorto, NombreCorto),
      NombreSistema   = ISNULL(@NombreSistema, NombreSistema),
      DetalleSistema  = ISNULL(@DetalleSistema, DetalleSistema),
      EsActivoSistema = ISNULL(@EsActivoSistema, EsActivoSistema),
      UrlSistema      = @UrlSistema,
      Imagen          = ISNULL(@Imagen, Imagen),
      TipoSistemaId   = ISNULL(@TipoSistemaId, TipoSistemaId),
      UsuarioModifica = ISNULL(@UsuarioModifica, UsuarioModifica),
      FechaModifica   = GETDATE()
  WHERE SistemaId = @SistemaId;

  ------------------------------------------------------
  -- REEMPLAZAR OPCIONES Y SUBOPCIONES
  ------------------------------------------------------
  DELETE FROM Sistema_Opcion_Rol_Accion
  WHERE SistemaOpcionId IN (
      SELECT SistemaOpcionId FROM Sistema_Opcion WHERE SistemaId = @SistemaId
  );

  DELETE FROM Sistema_Opcion WHERE SistemaId = @SistemaId;

  -- Insertar nuevas opciones principales
  INSERT INTO Sistema_Opcion (SistemaId, Opcion, OpcionPadreId)
  SELECT @SistemaId, Nombre, NULL
  FROM @Opciones
  WHERE NombrePadre IS NULL;

  -- Insertar subopciones con sus padres
  INSERT INTO Sistema_Opcion (SistemaId, Opcion, OpcionPadreId)
  SELECT @SistemaId, o.Nombre, so.SistemaOpcionId
  FROM @Opciones o
  INNER JOIN Sistema_Opcion so ON so.Opcion = o.NombrePadre AND so.SistemaId = @SistemaId
  WHERE o.NombrePadre IS NOT NULL;

  ------------------------------------------------------
  -- RECREAR PERMISOS (misma lógica que creación)
  ------------------------------------------------------
  INSERT INTO Sistema_Opcion_Rol_Accion (RolId, SistemaOpcionId, Crear, Consultar, Actualizar, Eliminar)
  SELECT ras.RolId, so.SistemaOpcionId, 0, 0, 0, 0
  FROM RolAccesoSistema ras
  INNER JOIN Sistema_Opcion so ON so.SistemaId = ras.SistemaId
  WHERE ras.SistemaId = @SistemaId AND so.OpcionPadreId IS NOT NULL;

  -- Permisos completos al SAdmin
  UPDATE soa
  SET soa.Crear = 1, soa.Consultar = 1, soa.Actualizar = 1, soa.Eliminar = 1
  FROM Sistema_Opcion_Rol_Accion soa
  INNER JOIN Sistema_Opcion so ON soa.SistemaOpcionId = so.SistemaOpcionId
  WHERE soa.RolId = 2053 AND so.SistemaId = @SistemaId AND so.OpcionPadreId IS NOT NULL;

  ------------------------------------------------------
  -- Devolver sistema actualizado
  ------------------------------------------------------
  SELECT
      si.SistemaId       AS sistemaId,
      si.NombreCorto     AS nombreCorto,
      si.NombreSistema   AS nombreSistema,
      si.DetalleSistema  AS detalleSistema,
      si.EsActivoSistema AS esActivoSistema,
      si.UrlSistema      AS urlSistema,
      si.Imagen          AS imagen,
      si.TipoSistemaId   AS tipoSistemaId,
      tipoSis.NombreTipoSistema AS desTipoSistema,
      si.UsuarioCrea,
      si.FechaCrea,
      si.UsuarioModifica,
      si.FechaModifica
  FROM dbo.Sistema si
  LEFT JOIN dbo.TipoSistema tipoSis
         ON si.TipoSistemaId = tipoSis.TipoSistemaId
  WHERE si.SistemaId = @SistemaId;
END
go

create PROCEDURE [dbo].[up_AsignarLocalesAUsuario]
    @UsuarioId INT,
    @LocalesCsv VARCHAR(MAX),
    @UsuarioCreaId INT
AS
BEGIN
    SET NOCOUNT ON;
    --Obtenemos el nombre de usuario del UsuarioCreaId
    DECLARE @NombreUsuarioCrea VARCHAR(100) = (SELECT UsuarioAcceso FROM Usuario WHERE UsuarioId=@UsuarioCreaId)

    -- Convertir CSV a tabla temporal
    DECLARE @LocalesTemporal TABLE (LocalId INT);

    INSERT INTO @LocalesTemporal (LocalId)
    SELECT TRY_CAST(value AS INT) FROM STRING_SPLIT(@LocalesCsv, ',') WHERE TRY_CAST(value AS INT) IS NOT NULL;

    -- Insertar nuevos locales que no estén asignados
    INSERT INTO UsuarioLocal (UsuarioId, LocalId, UsuarioCrea, FechaCrea)
    SELECT @UsuarioId, L.LocalId, @NombreUsuarioCrea,  GETDATE() FROM @LocalesTemporal L WHERE NOT EXISTS (
        SELECT 1
        FROM UsuarioLocal UL
        WHERE UL.UsuarioId = @UsuarioId AND UL.LocalId = L.LocalId
    );

    -- Eliminar locales que ya no estén seleccionados
    DELETE FROM UsuarioLocal
    WHERE UsuarioId = @UsuarioId
      AND LocalId NOT IN (SELECT LocalId FROM @LocalesTemporal);

    SELECT 'Asignación actualizada correctamente' AS Mensaje;
END;
go

CREATE   PROCEDURE [dbo].[up_AsignarRolUsuario]
(
    @UsuarioId INT,
    @RolId INT,
    @UsuarioCreaId INT
)
AS
BEGIN
    SET NOCOUNT ON;

    --Obtenemos el nombre de usuario del UsuarioCreaId
    DECLARE @NombreUsuarioCrea VARCHAR(100) = (SELECT UsuarioAcceso FROM Usuario WHERE UsuarioId=@UsuarioCreaId)

    -- Validar duplicado
    IF EXISTS (SELECT 1 FROM dbo.UsuarioRol WHERE UsuarioId = @UsuarioId AND RolId = @RolId)
    BEGIN
        RAISERROR('El usuario ya tiene asignado este rol', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.UsuarioRol (UsuarioId, RolId, UsuarioCrea, FechaCrea, UsuarioModifica, FechaModifica)
    VALUES (@UsuarioId, @RolId, @NombreUsuarioCrea, GETDATE(), NULL, NULL);

    SELECT
		RolId as rolId,
		UsuarioId as usuarioId,
		UsuarioCrea as usuarioCrea,
		FechaCrea as fechaCrea,
		UsuarioModifica as usuarioModifica,
		FechaModifica as fechaModifica
	FROM dbo.UsuarioRol WHERE UsuarioId = @UsuarioId AND RolId = @RolId;
END
go

CREATE   PROCEDURE [dbo].[up_AsociarRolSistema]
(
    @RolId INT,
    @SistemaId INT,
    @NivelAccesoId INT,
    @UsuarioCrea VARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;

	-- Validar si el sistema ya tiene el rol asociado
	IF EXISTS (SELECT 1 FROM dbo.RolAccesoSistema
			WHERE
			RolId = @RolId AND
			SistemaId = @SistemaId
			)
    BEGIN
        RAISERROR('El rol ya está asociado a este sistema', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.RolAccesoSistema
    (
        RolId,
        SistemaId,
        NivelAccesoId,
        UsuarioCrea,
        FechaCrea
    )
    VALUES
    (
        @RolId,
        @SistemaId,
        1,
        @UsuarioCrea,
        GETDATE()
    );

    -- Devolver el registro insertado
    SELECT
		RolId as rolId,
		SistemaId as sistemaId,
		NivelAccesoId as nivelAccesoId,
		UsuarioCrea as usuarioCrea,
		FechaCrea as fechaCrea,
		UsuarioModifica as usuarioModifica,
		FechaModifica as fechaModifica
    FROM dbo.RolAccesoSistema
    WHERE RolId = @RolId AND SistemaId = @SistemaId;
END;
go

CREATE   PROCEDURE [dbo].[up_BuscarUsuariosPorNombre]
(
    @TextoBusqueda VARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 10
        UsuarioId,
        CONCAT(
            ISNULL(ApellidoPaterno, ''), ' ',
            ISNULL(ApellidoMaterno, ''), ' ',
            ISNULL(PrimerNombre, ''), ' ',
            ISNULL(SegundoNombre, '')
        ) AS NombreCompleto
    FROM dbo.Usuario
    WHERE
        PrimerNombre LIKE '%' + @TextoBusqueda + '%'
        OR SegundoNombre LIKE '%' + @TextoBusqueda + '%'
        OR ApellidoPaterno LIKE '%' + @TextoBusqueda + '%'
        OR ApellidoMaterno LIKE '%' + @TextoBusqueda + '%'
    ORDER BY ApellidoPaterno, ApellidoMaterno, PrimerNombre;
END
go

CREATE   PROCEDURE [dbo].[up_BuscarUsuariosPorNombreONroDocumento]
(
    @SistemaId INT,
    @TextoBusqueda VARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DISTINCT
        U.UsuarioId,
        U.PrimerNombre,
        U.SegundoNombre,
        U.ApellidoPaterno,
        U.ApellidoMaterno,
        U.NumeroDocumento,
        S.SistemaId,
        S.NombreSistema
    FROM dbo.Usuario U
    INNER JOIN UsuarioRol UR ON U.UsuarioId = UR.UsuarioId
    INNER JOIN Rol R ON UR.RolId = R.RolId
    INNER JOIN RolAccesoSistema RAS ON R.RolId = RAS.RolId
    INNER JOIN Sistema S ON RAS.SistemaId = S.SistemaId
    WHERE
        S.SistemaId = @SistemaId
        AND R.EsActivoRol = 1
        AND (
        PrimerNombre LIKE '%' + @TextoBusqueda + '%'
        OR SegundoNombre LIKE '%' + @TextoBusqueda + '%'
        OR ApellidoPaterno LIKE '%' + @TextoBusqueda + '%'
        OR ApellidoMaterno LIKE '%' + @TextoBusqueda + '%'
        OR NumeroDocumento LIKE '%' + @TextoBusqueda + '%'
        )
    ORDER BY ApellidoPaterno, ApellidoMaterno, PrimerNombre;
END
go

CREATE   PROCEDURE [dbo].[up_CrearRolSistema]
(
    @SistemaId INT,
    @NombreRol VARCHAR(100),
    @UsuarioCreaId INT
)
AS
BEGIN
    SET NOCOUNT ON;
    --Obtenemos el nombre de usuario del UsuarioCreaId
    DECLARE @NombreUsuarioCrea VARCHAR(100) = (SELECT UsuarioAcceso FROM Usuario WHERE UsuarioId=@UsuarioCreaId)

    IF EXISTS (
        SELECT 1
        FROM dbo.RolAccesoSistema ras
        INNER JOIN dbo.Rol r ON R.RolId = ras.RolId
        WHERE r.NombreRol = @NombreRol AND ras.SistemaId = @SistemaId
    )
    BEGIN
        RAISERROR('El rol con ese nombre ya existe', 16, 1);
        RETURN;
    END

    DECLARE @NuevoRolId INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Insertar en Rol
        INSERT INTO Rol (NombreRol, EsActivoRol, UsuarioCrea, FechaCrea)
        VALUES (@NombreRol, 1, @NombreUsuarioCrea, GETDATE());

        SET @NuevoRolId = SCOPE_IDENTITY();

        -- 2. Asociar el nuevo rol al sistema
        INSERT INTO RolAccesoSistema (SistemaId, RolId)
        VALUES (@SistemaId, @NuevoRolId);

        COMMIT TRANSACTION;

        SELECT
            @NuevoRolId AS RolId,
            @NombreRol AS NombreRol,
            'Rol creado y asociado correctamente' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error en up_CrearRolSistema: %s', 16, 1, @ErrMsg);
    END CATCH
END
go

CREATE   PROCEDURE [dbo].[up_CrearSistema]
(
    @NombreCorto     VARCHAR(10),
    @NombreSistema   VARCHAR(100),
    @DetalleSistema  VARCHAR(150) = NULL,
    @EsActivoSistema BIT,
    @UrlSistema      VARCHAR(250) = NULL,
    @Imagen          VARCHAR(150) = NULL,
    @TipoSistemaId   INT = NULL,
    @UsuarioCrea     VARCHAR(100),
    @Opciones dbo.OpcionType READONLY
)
AS
BEGIN
    SET NOCOUNT ON;

	-- Validar si existe un sistema con el mismo nombre
	IF EXISTS (SELECT 1 FROM dbo.Sistema WHERE NombreSistema = @NombreSistema)
    BEGIN
        RAISERROR('El sistema con ese nombre ya existe', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.Sistema
    (
        NombreCorto,
        NombreSistema,
        DetalleSistema,
        EsActivoSistema,
        UrlSistema,
        Imagen,
        TipoSistemaId,
        UsuarioCrea,
        FechaCrea
    )
    VALUES
    (
        @NombreCorto,
        @NombreSistema,
        @DetalleSistema,
        @EsActivoSistema,
        @UrlSistema,
        @Imagen,
        @TipoSistemaId,
        @UsuarioCrea,
        GETDATE()
    );

    DECLARE @SistemaId INT = SCOPE_IDENTITY();

    -- AGREGAMOS AL SISTEMA RECIÉN CREADO LOS 4 ROLES QUE POR DEFECTO TENDRÁ TODO SISTEMA (SAdmin,Admin,Supervisor,Operador)
    INSERT INTO RolAccesoSistema (RolId, SistemaId, NivelAccesoId, UsuarioCrea, FechaCrea) values (1066,@SistemaId,1,@UsuarioCrea,GETDATE());
    INSERT INTO RolAccesoSistema (RolId, SistemaId, NivelAccesoId, UsuarioCrea, FechaCrea) values (1067,@SistemaId,8,@UsuarioCrea,GETDATE());
    INSERT INTO RolAccesoSistema (RolId, SistemaId, NivelAccesoId, UsuarioCrea, FechaCrea) values (1068,@SistemaId,11,@UsuarioCrea,GETDATE());
    INSERT INTO RolAccesoSistema (RolId, SistemaId, NivelAccesoId, UsuarioCrea, FechaCrea) values (1069,@SistemaId,4,@UsuarioCrea,GETDATE());

    -- HACEMOS LOS INSERTOS DE LAS OPCIONES Y SUBOPCIONES
    INSERT INTO Sistema_Opcion (SistemaId, Opcion, OpcionPadreId)
    SELECT @SistemaId, Nombre, NULL
    FROM @Opciones
    WHERE NombrePadre IS NULL;

    INSERT INTO Sistema_Opcion (SistemaId, Opcion, OpcionPadreId)
    SELECT @SistemaId, o.Nombre, so.SistemaOpcionId
    FROM @Opciones o
    INNER JOIN Sistema_Opcion so ON so.Opcion = o.NombrePadre AND so.SistemaId = @SistemaId
    WHERE o.NombrePadre IS NOT NULL;

    -- INSERTAMOS EN LA TABLA Sistema_Opcion_Rol_Accion PARA QUE LOS ROLES POR DEFECTO TENGAN SUS PERMISOS SOBRE LAS SUBOPCIONES RECIÉN CREADAS
    INSERT INTO Sistema_Opcion_Rol_Accion (RolId, SistemaOpcionId, Crear, Consultar, Actualizar, Eliminar)
    SELECT ras.RolId,so.SistemaOpcionId,0, 0, 0, 0
    FROM RolAccesoSistema ras INNER JOIN Sistema_Opcion so ON so.SistemaId = ras.SistemaId
    WHERE ras.SistemaId = @SistemaId AND so.OpcionPadreId IS NOT NULL;

    -- OTORGAMOS TODOS LOS PERMISOS AL SADMIN (2053)
    UPDATE soa
    SET soa.Crear = 1,
        soa.Consultar = 1,
        soa.Actualizar = 1,
        soa.Eliminar = 1
    FROM Sistema_Opcion_Rol_Accion soa INNER JOIN Sistema_Opcion so ON soa.SistemaOpcionId = so.SistemaOpcionId
    WHERE soa.RolId = 1066 AND so.SistemaId = @SistemaId AND so.OpcionPadreId IS NOT NULL;

    -- Devolver el registro insertado
    SELECT
		si.SistemaId       AS sistemaId,
		si.NombreCorto     AS nombreCorto,
		si.NombreSistema   AS nombreSistema,
		si.DetalleSistema  AS detalleSistema,
		si.EsActivoSistema AS esActivoSistema,
		si.UrlSistema      AS urlSistema,
		si.Imagen          AS imagenSistema,
		si.TipoSistemaId   AS tipoSistemaId,
		si.UsuarioCrea     AS usuarioCrea,
		si.FechaCrea       AS fechaCrea,
		si.UsuarioModifica AS usuarioModifica,
		si.FechaModifica   AS fechaModifica
    FROM dbo.Sistema si
	INNER JOIN dbo.TipoSistema tipoSis
      ON si.TipoSistemaId = tipoSis.TipoSistemaId
    WHERE si.SistemaId = @SistemaId;

END;
go


CREATE PROC [dbo].[up_EmpresaLocalUsuario](
@usuario varchar(100)
)
AS BEGIN
	SELECT l.LocalId [idLocal], l.CodigoLocal [codLocal] ,l.NombreLocal [desLocal] ,e.CodigoEmpresa [codEmpresa]
	FROM Usuario u
	INNER JOIN UsuarioLocal ul ON ul.UsuarioId = u.UsuarioId
	INNER JOIN [Local] l ON l.LocalId = ul.LocalId
	INNER JOIN Empresa e ON l.EmpresaId = e.EmpresaId
	where u.UsuarioAcceso = @usuario and l.EsActivoLocal=1

	select EmpresaId [idEmpresa], CodigoEmpresa [codEmpresa], RazonSocial [desEmpresa]
	from Empresa
	where CodigoEmpresa in (
	SELECT e.CodigoEmpresa
	FROM Usuario u
	INNER JOIN UsuarioLocal ul ON ul.UsuarioId = u.UsuarioId
	INNER JOIN [Local] l ON l.LocalId = ul.LocalId
	INNER JOIN Empresa e ON l.EmpresaId = e.EmpresaId
	where u.UsuarioAcceso = @usuario and l.EsActivoLocal=1
	)
END
go

CREATE   PROCEDURE up_FiltrarColaboradoresPorNombApeNroDoc
(
	@FiltroBusqueda VARCHAR (50)
)
AS
BEGIN
	SELECT u.UsuarioId,u.CodigoColaborador,u.PrimerNombre,u.SegundoNombre,u.ApellidoPaterno,u.ApellidoMaterno,td.NombreTipoDocumento,u.NumeroDocumento
	FROM Usuario u INNER JOIN TipoDocumento td ON u.TipoDocumentoId = td.TipoDocumentoId
	WHERE u.EsActivoUsuario=1 AND (u.PrimerNombre LIKE '%'+@filtroBusqueda+'%'
									OR u.SegundoNombre LIKE '%'+@filtroBusqueda+'%'
									OR u.ApellidoPaterno LIKE '%'+@filtroBusqueda+'%'
									OR u.ApellidoMaterno LIKE '%'+@filtroBusqueda+'%'
									OR u.NumeroDocumento LIKE '%'+@filtroBusqueda+'%')
END;
go

CREATE   PROCEDURE [dbo].[up_GuardarPermisosSistema]
(
    @SistemaId INT,
    @Permisos dbo.PermisoType READONLY,
    @UsuarioModificacionId INT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UsuarioModifica VARCHAR(100) = (SELECT u.UsuarioAcceso FROM Usuario u WHERE u.UsuarioId=@UsuarioModificacionId)

    BEGIN TRY
        BEGIN TRANSACTION;

        /*
         * MERGE: compara por RolId + SistemaOpcionId
         * Si coincide -> UPDATE
         * Si no existe -> INSERT
         */
        MERGE INTO dbo.Sistema_Opcion_Rol_Accion AS target
        USING (
            SELECT
                p.RolId,
                p.SistemaOpcionId,
                p.Crear,
                p.Consultar,
                p.Actualizar,
                p.Eliminar
            FROM @Permisos p
        ) AS src
        ON target.RolId = src.RolId
           AND target.SistemaOpcionId = src.SistemaOpcionId
        WHEN MATCHED THEN
            UPDATE SET
                Crear = src.Crear,
                Consultar = src.Consultar,
                Actualizar = src.Actualizar,
                Eliminar = src.Eliminar,
                UsuarioModifica = @UsuarioModifica,
                FechaModifica = GETDATE()
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (RolId, SistemaOpcionId, Crear, Consultar, Actualizar, Eliminar, UsuarioModifica, FechaModifica)
            VALUES (src.RolId, src.SistemaOpcionId, src.Crear, src.Consultar, src.Actualizar, src.Eliminar, @UsuarioModifica, GETDATE());

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrNum INT = ERROR_NUMBER();
        RAISERROR('Error en up_GuardarPermisosSistema: %s', 16, 1, @ErrMsg);
        RETURN;
    END CATCH
END
go

CREATE   PROCEDURE [dbo].[up_ListarEmpresas]
AS
BEGIN
	SELECT EmpresaId, NombreComercial FROM Empresa
	WHERE EsActivoEmpresa=1
END;
go

CREATE   PROCEDURE up_ListarLocalesPorEmpresa
(
	@EmpresaId INT
)
AS
BEGIN
	SELECT l.LocalId, l.NombreLocal FROM Local l
	INNER JOIN Empresa e ON l.EmpresaId=e.EmpresaId
	WHERE @EmpresaId = e.EmpresaId AND l.EsActivoLocal=1
END;
go

CREATE PROCEDURE [dbo].[up_ListarOpciones](
@usuario varchar(100),
@sistema int
)
AS BEGIN
	SELECT n.NivelAccesoId,  CAST(u.UsuarioId AS VARCHAR) AS UsuarioId,n.NombreAcceso
	FROM DBO.Usuario u
	INNER JOIN DBO.UsuarioRol ur ON ur.UsuarioId = u.UsuarioId
	INNER JOIN DBO.Rol r on r.RolId = ur.RolId
	INNER JOIN DBO.RolAccesoSistema ras on ras.RolId = r.RolId
	INNER JOIN DBO.NIVELACCESO n on n.NivelAccesoId = ras.NivelAccesoId
	INNER JOIN DBO.Sistema s on s.SistemaId = ras.SistemaId
	where u.EsActivoUsuario=1 and s.EsActivoSistema=1 and r.EsActivoRol=1
	and s.SistemaId=@sistema and u.UsuarioAcceso=@usuario
END
go

CREATE   PROCEDURE [dbo].[up_ListarRolesPorSistema]
    @SistemaId INT,
    @UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        R.RolId,
        R.NombreRol,
        CASE WHEN UR.UsuarioId IS NOT NULL THEN 1 ELSE 0 END AS TieneRol
    FROM Rol R
    INNER JOIN RolAccesoSistema RAS ON R.RolId = RAS.RolId
    LEFT JOIN UsuarioRol UR ON UR.RolId = R.RolId AND UR.UsuarioId = @UsuarioId
    WHERE RAS.SistemaId = @SistemaId
      AND R.EsActivoRol = 1
    ORDER BY R.NombreRol;
END;
go

CREATE   PROCEDURE [dbo].[up_ListarRolesPorUsuario]
    @UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        r.RolId      AS rolId,
        r.NombreRol  AS nombreRol,
		r.EsActivoRol AS esActivoRol,
		r.FechaCrea AS fechaCrea
    FROM UsuarioRol ur
    INNER JOIN Rol r ON ur.RolId = r.RolId
    WHERE ur.UsuarioId = @UsuarioId
    ORDER BY r.NombreRol;
END
go

create PROCEDURE [dbo].[up_ListarSistemas]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        SistemaId       AS sistemaId,
        NombreCorto     AS nombreCorto,
        NombreSistema   AS nombreSistema,
        DetalleSistema  AS detalleSistema,
        EsActivoSistema AS esActivoSistema,
        UrlSistema      AS urlSistema,
        Imagen          AS imagen,
        TipoSistemaId   AS tipoSistemaId,
        UsuarioCrea     AS usuarioCrea,
        FechaCrea       AS fechaCrea,
        UsuarioModifica AS usuarioModifica,
        FechaModifica   AS fechaModifica
    FROM dbo.Sistema
    WHERE EsActivoSistema = 1;
END
go

CREATE   PROCEDURE [dbo].[up_ListarTipoSistemas]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        TipoSistemaId     AS tipoSistemaId,
        NombreTipoSistema AS nombreTipoSistema,
        EsActivoTipoSistema AS esActivoTipoSistema,
        UsuarioCrea AS usuarioCrea,
        FechaCrea AS fechaCrea,
        UsuarioModifica AS usuarioModifica,
        FechaModifica AS fechaModifica
    FROM dbo.TipoSistema
    WHERE EsActivoTipoSistema = 1;
END
go

create PROCEDURE [dbo].[up_ListarUsuariosParaLocales]
AS
BEGIN
	SELECT u.UsuarioId,u.CodigoColaborador,u.PrimerNombre,u.SegundoNombre,u.ApellidoPaterno,u.ApellidoMaterno,td.NombreTipoDocumento,u.NumeroDocumento FROM Usuario u
	INNER JOIN TipoDocumento td ON u.TipoDocumentoId = td.TipoDocumentoId
	where u.EsActivoUsuario=1
END
go

CREATE   PROCEDURE [dbo].[up_ListarUsuariosPorSistema]
    @SistemaId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DISTINCT
        U.UsuarioId,
        U.PrimerNombre,
        U.SegundoNombre,
        U.ApellidoPaterno,
        U.ApellidoMaterno,
        U.NumeroDocumento,
        S.SistemaId,
        S.NombreSistema
    FROM Usuario U
    INNER JOIN UsuarioRol UR ON U.UsuarioId = UR.UsuarioId
    INNER JOIN Rol R ON UR.RolId = R.RolId
    INNER JOIN RolAccesoSistema RAS ON R.RolId = RAS.RolId
    INNER JOIN Sistema S ON RAS.SistemaId = S.SistemaId
    WHERE S.SistemaId = @SistemaId
      AND R.EsActivoRol = 1
    ORDER BY U.ApellidoPaterno, U.ApellidoMaterno, U.PrimerNombre;
END;
go

CREATE   PROCEDURE [dbo].[up_ObtenerConfiguracionPermisosSistema]
    @SistemaId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Traer roles asociados al sistema
    SELECT
        R.RolId,
        R.NombreRol
    FROM RolAccesoSistema RS
    INNER JOIN Rol R ON R.RolId = RS.RolId
    WHERE RS.SistemaId = @SistemaId;

    -- Traer opciones y subopciones (jerarquía)
    SELECT
        SO.SistemaOpcionId,
        SO.Opcion AS NombreOpcion,
        SO.OpcionPadreId,
        SOPadre.Opcion AS NombreOpcionPadre
    FROM Sistema_Opcion SO
    LEFT JOIN Sistema_Opcion SOPadre ON SOPadre.SistemaOpcionId = SO.OpcionPadreId
    WHERE SO.SistemaId = @SistemaId;

    -- Traer permisos actuales (CRUD)
    SELECT
        SORA.RolId,
        SORA.SistemaOpcionId,
        SORA.Crear,
        SORA.Consultar,
        SORA.Actualizar,
        SORA.Eliminar
    FROM Sistema_Opcion_Rol_Accion SORA
    INNER JOIN Sistema_Opcion SO ON SO.SistemaOpcionId = SORA.SistemaOpcionId
    WHERE SO.SistemaId = @SistemaId;
END;
go

CREATE   PROCEDURE up_ObtenerLocalesAsignadosAUsuario(
	@UsuarioId INT
)
AS
BEGIN
	SELECT LocalId FROM UsuarioLocal WHERE @UsuarioId=UsuarioId
END;
go

CREATE   PROCEDURE [dbo].[up_ObtenerRoles]
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    RolId,
    NombreRol,
    EsActivoRol,
    RolPadre,
    UsuarioCrea,
    FechaCrea,
    UsuarioModifica,
    FechaModifica
  FROM dbo.Rol
  WHERE EsActivoRol = 1
  ORDER BY FechaCrea DESC;
END
go

CREATE   PROCEDURE [dbo].[up_ObtenerRolesPorSistema]
(
    @SistemaId INT
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        r.RolId     AS rolId,
        r.NombreRol AS nombreRol
    FROM Rol r
    INNER JOIN RolAccesoSistema ras
        ON r.RolId = ras.RolId
    WHERE ras.SistemaId = @SistemaId
      AND r.EsActivoRol = 1;
END
go

CREATE   PROCEDURE [dbo].[up_ObtenerSistemaCompleto]
(
    @IdSistema INT
)
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    si.SistemaId       AS sistemaId,
    si.NombreCorto     AS nombreCorto,
    si.NombreSistema   AS nombreSistema,
    si.DetalleSistema  AS detalleSistema,
    si.EsActivoSistema AS esActivoSistema,
    si.UrlSistema      AS urlSistema,
    si.Imagen          AS imagenSistema,
    si.TipoSistemaId   AS tipoSistemaId,
    tipoSis.NombreTipoSistema AS desTipoSistema,
    si.UsuarioCrea     AS usuarioCrea,
    si.FechaCrea       AS fechaCrea,
    si.UsuarioModifica AS usuarioModifica,
    si.FechaModifica   AS fechaModifica,
    so.SistemaOpcionId  AS sistemaOpcionId,
    so.Opcion           AS nombreOpcion,
    so.OpcionPadreId    AS opcionPadreId

    FROM dbo.Sistema si
    INNER JOIN dbo.TipoSistema tipoSis
        ON si.TipoSistemaId = tipoSis.TipoSistemaId
    LEFT JOIN dbo.Sistema_Opcion so
        ON si.SistemaId = so.SistemaId
    WHERE si.SistemaId = @IdSistema;
END
go

CREATE   PROCEDURE [dbo].[up_ObtenerSistemaSearchTable]
(
    @limit           INT = 20,
    @offset          INT = 1,
    @NombreSistema   NVARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH SystemResult AS (
        SELECT
            si.SistemaId        AS sistemaId,
            si.NombreCorto      AS nombreCorto,
            si.NombreSistema    AS nombreSistema,
            si.DetalleSistema   AS detalleSistema,
            si.EsActivoSistema  AS esActivoSistema,
            si.UrlSistema       AS urlSistema,
            si.Imagen           AS imagen,
            si.TipoSistemaId    AS tipoSistemaId,
            si.UsuarioCrea      AS usuarioCrea,
            si.FechaCrea        AS fechaCrea,
            si.UsuarioModifica  AS usuarioModifica,
            si.FechaModifica    AS fechaModifica,
            tipoSis.NombreTipoSistema AS desTipoSistema,
            ROW_NUMBER() OVER (ORDER BY si.FechaCrea DESC) AS RowNum
        FROM dbo.Sistema si
        INNER JOIN dbo.TipoSistema tipoSis
            ON si.TipoSistemaId = tipoSis.TipoSistemaId
        WHERE (@NombreSistema IS NULL OR si.NombreSistema LIKE '%' + @NombreSistema + '%')
    )
    SELECT *
    FROM SystemResult
    WHERE RowNum BETWEEN ((@offset - 1) * @limit) + 1 AND (@offset * @limit);

    -- Totales y paginación
    DECLARE @TotalRecords INT;
    SELECT @TotalRecords = COUNT(*)
    FROM dbo.Sistema si
    WHERE (@NombreSistema IS NULL OR si.NombreSistema LIKE '%' + @NombreSistema + '%');

    DECLARE @TotalPages INT;
    SET @TotalPages = CEILING(CAST(@TotalRecords AS FLOAT) / @limit);

    SELECT
        @offset       AS PaginaActual,
        @TotalPages   AS TotalPaginas,
        @limit        AS PageSize,
        @TotalRecords AS RegistrosTotales;
END
go

CREATE PROC [dbo].[up_ObtieneMenuSistema](
    @Usuario varchar(50),
    @SistemaId INT = NULL
)
AS BEGIN
	SELECT m.MenuId [id]
	,isnull(m.NombreMenu,'') [menu]
	,isnull(m.NombreFormulario,'') [enlace]
	,isnull(m.MenuPadre,'') [parent]
	,isnull(m.Icono,'') [icono]
	FROM Usuario u
	INNER JOIN UsuarioRol ur ON ur.UsuarioId=u.UsuarioId
	INNER JOIN RolAccesoSistema ras ON ras.RolId = ur.RolId
	INNER JOIN RolMenu rm ON rm.RolId = ur.RolId
	INNER JOIN Menu m ON m.MenuId = rm.MenuId and m.SistemaId=ras.SistemaId
	where u.UsuarioAcceso=@Usuario
	AND ras.SistemaId=@SistemaId
END
go

create procedure [dbo].[up_ObtieneRolUsuario](
    @userId int,
    @system int
) as
begin
    select RAS.SistemaId    AS systemId,
           S.NombreCorto    AS systemAlias,
           S.NombreSistema  AS systemName,
           NA.NivelAccesoId AS accessLevel,
           NA.NombreAcceso  AS accessName,
           UR.RolId         AS roleId,
           R.NombreRol      AS roleName
    from RolAccesoSistema as RAS
             inner join dbo.NivelAcceso NA on RAS.NivelAccesoId = NA.NivelAccesoId
             inner join dbo.Sistema S on RAS.SistemaId = S.SistemaId
             inner join dbo.UsuarioRol UR on RAS.RolId = UR.RolId
             inner join dbo.Rol R ON RAS.RolId = R.RolId
             inner join dbo.Usuario U on UR.UsuarioId = U.UsuarioId
    where U.UsuarioId = @userId
      and RAS.SistemaId = @system;
end
go

CREATE procedure up_ObtieneRolesUsuario(
    @Usuario varchar(50),
    @SistemaId INT = NULL
) as
begin
    select RAS.SistemaId    AS [sistemaId],
           S.NombreCorto    AS [sistemaAlias],
           S.NombreSistema  AS [sistemaNombre],
           NA.NivelAccesoId AS [accesoId],
           NA.NombreAcceso  AS [accesoNombre],
           UR.RolId         AS [rolId],
           R.NombreRol      AS [rolNombre],
           UR.UsuarioId     AS [usuarioId],
           U.UsuarioAcceso  AS [usuarioAlias]
    from RolAccesoSistema as RAS
             inner join dbo.NivelAcceso NA on RAS.NivelAccesoId = NA.NivelAccesoId
             inner join dbo.Sistema S on RAS.SistemaId = S.SistemaId
             inner join dbo.UsuarioRol UR on RAS.RolId = UR.RolId
             inner join dbo.Rol R ON RAS.RolId = R.RolId
             inner join dbo.Usuario U on UR.UsuarioId = U.UsuarioId
    where U.UsuarioAcceso = @Usuario
      and RAS.SistemaId = IIF(@SistemaId is null, RAS.SistemaId, @SistemaId);
end
go

CREATE procedure [dbo].[up_ObtieneUsuario](
	@UsuarioId			INT = NULL,
	@CodigoColaborador	VARCHAR(20) = NULL,
	@UsuarioAcceso		VARCHAR(20) = NULL
) as
begin
	select
		 UsuarioId
		 ,CodigoColaborador
		 ,UsuarioAcceso
		 ,EsActivoUsuario
		 ,Correo
	from
		USERMANAGEMENTCORP.dbo.Usuario
	where
		UsuarioId = ISNULL(@UsuarioId,UsuarioId)
		AND CodigoColaborador = ISNULL(@CodigoColaborador,CodigoColaborador)
		AND UsuarioAcceso like ISNULL(nullif('%'+@UsuarioAcceso+'%',''),UsuarioAcceso)
end
go

CREATE procedure up_ObtieneUsuariosSistema(
    @SistemaId INT
) as
begin
    select RAS.SistemaId    AS [SISTEMA_ID],
           S.NombreSistema  AS [SISTEMA_NOMBRE],
           UR.UsuarioId     AS [USUARIO_ID],
           U.UsuarioAcceso  AS [USUARIO_ALIAS],
           NA.NivelAccesoId AS [ACCESO_ID],
           NA.NombreAcceso  AS [ACCESO_NOMBRE],
           UR.RolId         AS [ROL_ID],
           R.NombreRol      AS [NOMBRE_ROL]

    from RolAccesoSistema as RAS
             inner join dbo.NivelAcceso NA on RAS.NivelAccesoId = NA.NivelAccesoId
             inner join dbo.Sistema S on RAS.SistemaId = S.SistemaId
             inner join dbo.UsuarioRol UR on RAS.RolId = UR.RolId
             inner join dbo.Rol R ON RAS.RolId = R.RolId
             inner join dbo.Usuario U on UR.UsuarioId = U.UsuarioId
    where RAS.SistemaId = @SistemaId;
end
go

CREATE PROCEDURE [dbo].[up_QuitarRolUsuario]
  @UsuarioId INT,
  @RolId INT
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM UsuarioRol WHERE UsuarioId = @UsuarioId AND RolId = @RolId;
END
go

 CREATE PROC [dbo].[up_listar_dominioCorreo]
AS BEGIN
	DECLARE @tblTmp as table(
	dominios varchar(120)
	)
	insert into @tblTmp values ('newport.com.pe'),('goldenpalace.com.pe'),('inverdesgroup.com.pe'),('palacioreal.com.pe'),('mcc.pe'),('lungfung.com.pe'),('betara.com'),('gruposam.com.pe')
    --insert into @tblTmp values ('newport.com.pe'),('goldenpalace.com.pe'),('palacioreal.com.pe'),('lungfung.com.pe'),('betara.com'),('gruposam.com.pe')
	select * from @tblTmp
END
go

-- Migración: 001_crear_usuario_referencia_colaborador
-- Fecha: 2026-09-25
-- Entidad(es) afectada(s): dbo.UsuarioReferenciaColaborador
-- Referencia: docs-proyecto/STACK.md / docs-proyecto/nucleo/er-diagram-v1.md
-- Motivo: vincular de forma aditiva un usuario legacy con sus GUID corporativos del núcleo GTM.

-- UP
SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE [dbo].[UsuarioReferenciaColaborador]
(
    [UsuarioId] INT NOT NULL,
    [IdUsuarioCorporativo] UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT [VP_UsuarioReferenciaColaborador_IdUsuarioCorporativo] DEFAULT (NEWID()),
    [IdColaboradorCorporativo] UNIQUEIDENTIFIER NULL,
    [EstaActiva] BIT NOT NULL
        CONSTRAINT [VP_UsuarioReferenciaColaborador_EstaActiva] DEFAULT (1),
    [FechaCrea] DATETIME2(3) NOT NULL
        CONSTRAINT [VP_UsuarioReferenciaColaborador_FechaCrea] DEFAULT (SYSDATETIME()),
    [FechaModifica] DATETIME2(3) NULL,
    CONSTRAINT [CP_UsuarioReferenciaColaborador] PRIMARY KEY CLUSTERED ([UsuarioId]),
    CONSTRAINT [CU_UsuarioReferenciaColaborador_UsuarioCorporativo] UNIQUE ([IdUsuarioCorporativo]),
    CONSTRAINT [CA_UsuarioReferenciaColaborador_Usuario] FOREIGN KEY ([UsuarioId])
        REFERENCES [dbo].[Usuario] ([UsuarioId])
);

CREATE UNIQUE INDEX [IU_UsuarioReferenciaColaborador_ColaboradorActivo]
    ON [dbo].[UsuarioReferenciaColaborador] ([IdColaboradorCorporativo])
    WHERE [EstaActiva] = 1 AND [IdColaboradorCorporativo] IS NOT NULL;

COMMIT TRANSACTION;
GO

-- Migración: 002_crear_resolucion_contexto_usuario_nucleo
-- Fecha: 2026-09-25
-- Entidad(es) afectada(s): auditoria.ErrorProcedimiento,
-- auditoria.usp_RegistrarErrorProcedimiento,
-- dbo.usp_ResolverContextoUsuarioNucleoPorAcceso
-- Referencia: docs-proyecto/usermanagementcorp/TABLAS_REFERENCIA_COLABORADOR.md
-- Motivo: resolver un usuario legacy activo por acceso exacto o UsuarioId y su vínculo lógico al núcleo.

-- CREATE SCHEMA requiere su propio batch; no reutiliza ni oculta objetos homónimos.
IF SCHEMA_ID(N'auditoria') IS NULL
    EXEC(N'CREATE SCHEMA [auditoria] AUTHORIZATION [dbo];');
GO

-- UP: auditoría local exclusiva para el CATCH del procedure API nuevo.
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;

    CREATE TABLE [auditoria].[ErrorProcedimiento]
    (
        [IdErrorProcedimiento] BIGINT IDENTITY(1, 1) NOT NULL,
        [NombreProcedimiento] SYSNAME NOT NULL,
        [ProcedimientoError] NVARCHAR(128) NULL,
        [NumeroError] INT NOT NULL,
        [SeveridadError] INT NULL,
        [EstadoError] INT NULL,
        [LineaError] INT NULL,
        [DetalleInterno] NVARCHAR(2048) NULL,
        [FechaCreacion] DATETIME2(3) NOT NULL
            CONSTRAINT [VP_ErrorProcedimiento_FechaCreacion] DEFAULT (SYSDATETIME()),
        CONSTRAINT [CP_ErrorProcedimiento] PRIMARY KEY CLUSTERED ([IdErrorProcedimiento])
    );

    CREATE INDEX [IX_ErrorProcedimiento_FechaCreacion]
        ON [auditoria].[ErrorProcedimiento] ([FechaCreacion]);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

-- Procedure interno de mejor esfuerzo: no se expone al backend ni propaga errores.
CREATE PROCEDURE [auditoria].[usp_RegistrarErrorProcedimiento]
    @NombreProcedimiento SYSNAME,
    @ProcedimientoError NVARCHAR(128) = NULL,
    @NumeroError INT,
    @SeveridadError INT = NULL,
    @EstadoError INT = NULL,
    @LineaError INT = NULL,
    @DetalleInterno NVARCHAR(2048) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO [auditoria].[ErrorProcedimiento]
        (
            [NombreProcedimiento],
            [ProcedimientoError],
            [NumeroError],
            [SeveridadError],
            [EstadoError],
            [LineaError],
            [DetalleInterno]
        )
        VALUES
        (
            @NombreProcedimiento,
            @ProcedimientoError,
            @NumeroError,
            @SeveridadError,
            @EstadoError,
            @LineaError,
            @DetalleInterno
        );
    END TRY
    BEGIN CATCH
        RETURN;
    END CATCH;
END;
GO

CREATE PROCEDURE [dbo].[usp_ResolverContextoUsuarioNucleoPorAcceso]
    @UsuarioAcceso VARCHAR(100) = NULL,
    @UsuarioId INT = NULL,
    @Codigo NVARCHAR(50) OUTPUT,
    @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Codigo = N'OK';
    SET @Mensaje = NULL;

    BEGIN TRY
        DECLARE @TieneUsuarioAcceso BIT =
            CASE WHEN NULLIF(LTRIM(RTRIM(@UsuarioAcceso)), '') IS NULL THEN 0 ELSE 1 END;

        IF @TieneUsuarioAcceso = 0 AND @UsuarioId IS NULL
        BEGIN
            SET @Codigo = N'BAD_REQUEST';
            SET @Mensaje = N'UsuarioAcceso o UsuarioId es obligatorio.';
            RETURN;
        END;

        IF @UsuarioId IS NOT NULL AND @UsuarioId <= 0
        BEGIN
            SET @Codigo = N'BAD_REQUEST';
            SET @Mensaje = N'UsuarioId debe ser mayor que cero.';
            RETURN;
        END;

        DECLARE @CantidadUsuario BIGINT;
        DECLARE @EsActivoUsuario BIT;

        SELECT @CantidadUsuario = COUNT_BIG(1)
        FROM [dbo].[Usuario] AS [u]
        WHERE (@UsuarioId IS NULL OR [u].[UsuarioId] = @UsuarioId)
          AND (@TieneUsuarioAcceso = 0 OR [u].[UsuarioAcceso] = @UsuarioAcceso);

        IF @CantidadUsuario = 0
        BEGIN
            SET @Codigo = N'NOT_FOUND';
            SET @Mensaje = N'El usuario no fue encontrado.';
            RETURN;
        END;

        IF @CantidadUsuario > 1
        BEGIN
            SET @Codigo = N'CONFLICT';
            SET @Mensaje = N'La identidad de usuario es ambigua.';
            RETURN;
        END;

        SELECT @EsActivoUsuario = [u].[EsActivoUsuario]
        FROM [dbo].[Usuario] AS [u]
        WHERE (@UsuarioId IS NULL OR [u].[UsuarioId] = @UsuarioId)
          AND (@TieneUsuarioAcceso = 0 OR [u].[UsuarioAcceso] = @UsuarioAcceso);

        IF ISNULL(@EsActivoUsuario, 0) = 0
        BEGIN
            SET @Codigo = N'FORBIDDEN';
            SET @Mensaje = N'El usuario no está activo.';
            RETURN;
        END;

        SELECT
            [u].[UsuarioId],
            [u].[CodigoColaborador],
            [u].[UsuarioAcceso],
            [u].[Correo],
            [u].[EsActivoUsuario],
            [r].[IdUsuarioCorporativo],
            [r].[IdColaboradorCorporativo],
            CAST(CASE WHEN [r].[UsuarioId] IS NULL THEN 0 ELSE 1 END AS BIT) AS [TieneVinculoNucleo],
            [r].[EstaActiva] AS [EstaActivoVinculo]
        FROM [dbo].[Usuario] AS [u]
        LEFT JOIN [dbo].[UsuarioReferenciaColaborador] AS [r]
            ON [r].[UsuarioId] = [u].[UsuarioId]
        WHERE (@UsuarioId IS NULL OR [u].[UsuarioId] = @UsuarioId)
          AND (@TieneUsuarioAcceso = 0 OR [u].[UsuarioAcceso] = @UsuarioAcceso);
    END TRY
    BEGIN CATCH
        DECLARE @NumeroError INT = ERROR_NUMBER();
        DECLARE @SeveridadError INT = ERROR_SEVERITY();
        DECLARE @EstadoError INT = ERROR_STATE();
        DECLARE @LineaError INT = ERROR_LINE();
        DECLARE @ProcedimientoError NVARCHAR(128) = ERROR_PROCEDURE();
        DECLARE @DetalleInterno NVARCHAR(2048) = CONVERT(NVARCHAR(2048), ERROR_MESSAGE());

        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

        BEGIN TRY
            EXEC [auditoria].[usp_RegistrarErrorProcedimiento]
                @NombreProcedimiento = N'dbo.usp_ResolverContextoUsuarioNucleoPorAcceso',
                @ProcedimientoError = @ProcedimientoError,
                @NumeroError = @NumeroError,
                @SeveridadError = @SeveridadError,
                @EstadoError = @EstadoError,
                @LineaError = @LineaError,
                @DetalleInterno = @DetalleInterno;
        END TRY
        BEGIN CATCH
            -- La auditoría no puede modificar la respuesta segura del API.
            DECLARE @NumeroErrorAuditoria INT = ERROR_NUMBER();
        END CATCH;

        SET @Codigo = N'INTERNAL_ERROR';
        SET @Mensaje = N'No fue posible completar la operación.';
    END CATCH;
END;
GO
