USE master
GO

DECLARE @EliminarDB BIT = 1;
--Eliminar BDD si ya existe y si @EliminarDB = 1
if (((select COUNT(1) from sys.databases where name = 'RepuestosWebDWH')>0) AND (@EliminarDB = 1))
begin
	EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'RepuestosWebDWH'
	
	
	use [master];
	ALTER DATABASE [RepuestosWebDWH] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE;
		
	DROP DATABASE [RepuestosWebDWH]
	print 'RepuestosWebDWH ha sido eliminada'
end


CREATE DATABASE RepuestosWebDWH
GO

USE RepuestosWebDWH
GO

--Enteros
 --User Defined Type _ Surrogate Key
	--Tipo para SK entero: Surrogate Key
	CREATE TYPE [UDT_SK] FROM INT
	GO

	--Tipo para PK entero
	CREATE TYPE [UDT_PK] FROM INT
	GO

--Cadenas

	--Tipo para cadenas largas
	CREATE TYPE [UDT_VarcharLargo] FROM VARCHAR(500)
	GO

	--Tipo para cadenas medianas
	CREATE TYPE [UDT_VarcharMediano] FROM VARCHAR(300)
	GO

	--Tipo para cadenas cortas
	CREATE TYPE [UDT_VarcharCorto] FROM VARCHAR(100)
	GO

	--Tipo para cadenas cortas
	CREATE TYPE [UDT_UnCaracter] FROM CHAR(1)
	GO

--Decimal

	--Tipo Decimal 6,2
	CREATE TYPE [UDT_Decimal6.2] FROM DECIMAL(6,2)
	GO

	--Tipo Decimal 5,2
	CREATE TYPE [UDT_Decimal5.2] FROM DECIMAL(5,2)
	GO

--Fechas
	CREATE TYPE [UDT_DateTime] FROM DATETIME
	GO

--Schemas para separar objetos
	CREATE SCHEMA Fact
	GO

	CREATE SCHEMA Dimension
	GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Dimension].[Partes](
	[SK_Partes] [dbo].[UDT_SK] IDENTITY(1,1) NOT NULL,
	[ID_Partes] [dbo].[UDT_PK] NULL,
	[ID_Categoria] [dbo].[UDT_PK] NULL,
	[ID_Linea] [dbo].[UDT_PK] NULL,
	[NombrePartes] VARCHAR(100) NOT NULL,
	[DescripcionPartes] [dbo].[UDT_VarcharLargo] NULL,
	[Precio] decimal(12,2) NOT NULL,
	[NombreCategoria] [dbo].[UDT_VarcharCorto] NULL,
	[DescripcionCategoria] [dbo].[UDT_VarcharLargo] NULL,
	[NombreLinea] [dbo].[UDT_VarcharCorto] NULL,
	[DescripcionLinea] [dbo].[UDT_VarcharLargo] NULL,
	--Columnas SCD Tipo 2
	[FechaInicioValidez] DATETIME NOT NULL DEFAULT(GETDATE()),
	[FechaFinValidez] DATETIME NULL,
	--Columnas Auditoria
	FechaCreacion DATETIME NULL DEFAULT(GETDATE()),
	UsuarioCreacion NVARCHAR(100) NULL DEFAULT(SUSER_NAME()),
	FechaModificacion DATETIME NULL,
	UsuarioModificacion NVARCHAR(100) NULL,
	--Columnas Linaje
	--ID_Batch UNIQUEIDENTIFIER NULL,
	--ID_SourceSystem VARCHAR(20)	
PRIMARY KEY CLUSTERED 
(
	[SK_Partes] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Dimension].[Geografia](
	[SK_Geografia] [dbo].[UDT_SK] IDENTITY(1,1) NOT NULL,
	[ID_Ciudad] [dbo].[UDT_PK] NULL,
	[ID_Region] [dbo].[UDT_PK] NULL,
	[ID_Pais] [dbo].[UDT_PK] NULL,
	[NombreCiudad] [dbo].[UDT_VarcharCorto] NOT NULL,
	[CodigoPostal] INT NULL,
	[NombreRegion] [dbo].[UDT_VarcharCorto] NOT NULL,
	[NombrePais] [dbo].[UDT_VarcharCorto] NOT NULL,
	--Columnas SCD Tipo 2
	[FechaInicioValidez] DATETIME NOT NULL DEFAULT(GETDATE()),
	[FechaFinValidez] DATETIME NULL,
	--Columnas Auditoria
	FechaCreacion DATETIME NOT NULL DEFAULT(GETDATE()),
	UsuarioCreacion NVARCHAR(100) NOT NULL DEFAULT(SUSER_NAME()),
	FechaModificacion DATETIME NULL,
	UsuarioModificacion NVARCHAR(100) NULL,
	--Columnas Linaje
	--ID_Batch UNIQUEIDENTIFIER NULL,
	--ID_SourceSystem VARCHAR(50)
	
PRIMARY KEY CLUSTERED 
(
	[SK_Geografia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Dimension].[Clientes](
	[SK_Clientes] [dbo].[UDT_SK] IDENTITY(1,1) NOT NULL,
	[ID_Cliente] [dbo].[UDT_PK] NULL,
	[PrimerNombre] [dbo].[UDT_VarcharMediano] NULL,
	[SegundoNombre] [dbo].[UDT_VarcharMediano] NULL,
	[PrimerApellido] [dbo].[UDT_VarcharMediano] NULL,
	[SegundoApellido] [dbo].[UDT_VarcharMediano] NULL,
	[Genero] [dbo].[UDT_UnCaracter] NULL,
	[Correo_Electronico] [dbo].[UDT_VarcharMediano] NULL,
	[FechaNacimiento] DATETIME,
	--Columnas SCD Tipo 2
	[FechaInicioValidez] DATETIME NOT NULL DEFAULT(GETDATE()),
	[FechaFinValidez] DATETIME NULL,
	--Columnas Auditoria
	FechaCreacion DATETIME NOT NULL DEFAULT(GETDATE()),
	UsuarioCreacion NVARCHAR(100) NOT NULL DEFAULT(SUSER_NAME()),
	FechaModificacion DATETIME NULL,
	UsuarioModificacion NVARCHAR(100) NULL,
	--Columnas Linaje
	--ID_Batch UNIQUEIDENTIFIER NULL,
	--ID_SourceSystem VARCHAR(50)
	
PRIMARY KEY CLUSTERED 
(
	[SK_Clientes] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Dimension].[Fecha](
	[DateKey] [int] NOT NULL,
	[Date] [date] NOT NULL,
	[Day] [tinyint] NOT NULL,
	[DaySuffix] [char](2) NOT NULL,
	[Weekday] [tinyint] NOT NULL,
	[WeekDayName] [varchar](10) NOT NULL,
	[WeekDayName_Short] [char](3) NOT NULL,
	[WeekDayName_FirstLetter] [char](1) NOT NULL,
	[DOWInMonth] [tinyint] NOT NULL,
	[DayOfYear] [smallint] NOT NULL,
	[WeekOfMonth] [tinyint] NOT NULL,
	[WeekOfYear] [tinyint] NOT NULL,
	[Month] [tinyint] NOT NULL,
	[MonthName] [varchar](10) NOT NULL,
	[MonthName_Short] [char](3) NOT NULL,
	[MonthName_FirstLetter] [char](1) NOT NULL,
	[Quarter] [tinyint] NOT NULL,
	[QuarterName] [varchar](6) NOT NULL,
	[Year] [int] NOT NULL,
	[MMYYYY] [char](6) NOT NULL,
	[MonthYear] [char](7) NOT NULL,
	[IsWeekend] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[DateKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

DROP TABLE IF EXISTS FACT.Orden 
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Fact].[Orden](
	[SK_Orden] [dbo].[UDT_SK] IDENTITY(1,1) NOT NULL,
	[SK_Partes] [dbo].[UDT_SK] NULL,
	[SK_Geografia] [dbo].[UDT_SK] NULL,
	[SK_Clientes] [dbo].[UDT_SK] NULL,
	[DateKey] [int] NULL,
	[ID_Orden] [dbo].[UDT_PK] NULL,
	[ID_StatusOrden] [dbo].[UDT_PK] NULL,
	[ID_DetalleOrden] [dbo].[UDT_PK] NULL,
	[ID_Descuento] [dbo].[UDT_PK] NULL,
	[Total_Orden] [dbo].[UDT_Decimal6.2] NULL,
	[NombreStatus] [dbo].[UDT_VarcharLargo] NULL,
	[Cantidad] INT NULL,
	[NombreDescuento] [dbo].[UDT_VarcharMediano] NULL,
	[PorcentajeDescuento] [dbo].[UDT_Decimal6.2] NULL,
	[FechaPrueba] DATETIME NOT NULL,
	[FechaModificacionSource] DATETIME NULL,
	[Fecha_Orden] DATETIME NULL,
	--Columnas Auditoria
	FechaCreacion DATETIME NOT NULL DEFAULT(GETDATE()),
	UsuarioCreacion VARCHAR(100) NOT NULL DEFAULT(SUSER_NAME()),
	FechaModificacion DATETIME NULL,
	UsuarioModificacion VARCHAR(100) NULL,
	--Columnas Linaje
	ID_Batch UNIQUEIDENTIFIER NULL,
	ID_SourceSystem VARCHAR(50)
PRIMARY KEY CLUSTERED 
(
	[SK_Orden] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [Fact].[Orden]  WITH CHECK ADD FOREIGN KEY([DateKey])
REFERENCES [Dimension].[Fecha] ([DateKey])
GO
ALTER TABLE [Fact].[Orden]  WITH CHECK ADD FOREIGN KEY([SK_Partes])
REFERENCES [Dimension].[Partes] ([SK_Partes])
GO
ALTER TABLE [Fact].[Orden]  WITH CHECK ADD FOREIGN KEY([SK_Geografia])
REFERENCES [Dimension].[Geografia] ([SK_Geografia])
GO
ALTER TABLE [Fact].[Orden]  WITH CHECK ADD FOREIGN KEY([SK_Clientes])
REFERENCES [Dimension].[Clientes] ([SK_Clientes])
GO


	EXEC sys.sp_addextendedproperty 
     @name = N'Desnormalizacion', 
     @value = N'La dimension Partes provee una vista desnormalizada de las tablas origen Partes, Categoria y Linea, dejando todo en una única dimensión para un modelo estrella', 
     @level0type = N'SCHEMA', 
     @level0name = N'Dimension', 
     @level1type = N'TABLE', 
     @level1name = N'Partes';
	GO

	EXEC sys.sp_addextendedproperty 
     @name = N'Desnormalizacion', 
     @value = N'La dimension Geografia provee una vista desnormalizada de las tablas origen Ciudad, Region y Ciudad en una sola dimensión para un modelo estrella', 
     @level0type = N'SCHEMA', 
     @level0name = N'Dimension', 
     @level1type = N'TABLE', 
     @level1name = N'Geografia';
	GO

	EXEC sys.sp_addextendedproperty 
     @name = N'Desnormalizacion', 
     @value = N'La dimension Clientes provee una vista desnormalizada de las tablas origen Clientes en una sola dimensión para un modelo estrella', 
     @level0type = N'SCHEMA', 
     @level0name = N'Dimension', 
     @level1type = N'TABLE', 
     @level1name = N'Clientes';
	GO

	EXEC sys.sp_addextendedproperty 
     @name = N'Desnormalizacion', 
     @value = N'La dimension fecha es generada de forma automatica y no tiene datos origen, se puede regenerar enviando un rango de fechas al stored procedure USP_FillDimDate', 
     @level0type = N'SCHEMA', 
     @level0name = N'Dimension', 
     @level1type = N'TABLE', 
     @level1name = N'Fecha';
	GO

	EXEC sys.sp_addextendedproperty 
     @name = N'Desnormalizacion', 
     @value = N'La tabla de hechos es una union proveniente de las tablas de Orden, Detalle_Orden, Descuento y StatusOrden', 
     @level0type = N'SCHEMA', 
     @level0name = N'Fact', 
     @level1type = N'TABLE', 
     @level1name = N'Orden';
	GO