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
	CREATE TYPE [UDT_VarcharLargo] FROM VARCHAR(600)
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

--------------------------------------------------------------------------------------------
-------------------------------MODELADO CONCEPTUAL------------------------------------------
--------------------------------------------------------------------------------------------
--Tablas Dimensiones

	CREATE TABLE Dimension.Partes
	(
		SK_Partes [UDT_SK] PRIMARY KEY IDENTITY
	)
	GO

	CREATE TABLE Dimension.Geografia
	(
		Sk_Geografia [UDT_SK] PRIMARY KEY IDENTITY
	)
	GO

	CREATE TABLE Dimension.Clientes
	(
		SK_Clientes [UDT_SK] PRIMARY KEY IDENTITY
	)
	GO

	CREATE TABLE Dimension.Fecha
	(
		DateKey INT PRIMARY KEY
	)
	GO
--Tablas Fact

	CREATE TABLE Fact.Orden
	(
		SK_Orden       [UDT_SK] PRIMARY KEY IDENTITY,
		SK_Partes      [UDT_SK] REFERENCES Dimension.Partes(SK_Partes),
		Sk_Geografia   [UDT_SK] REFERENCES Dimension.Geografia(Sk_Geografia),
		SK_Clientes    [UDT_SK]  REFERENCES Dimension.Clientes(SK_Clientes),
		DateKey INT REFERENCES Dimension.Fecha(DateKey)
	)

--Metadata

	EXEC sys.sp_addextendedproperty 
     @name = N'Desnormalizacion', 
     @value = N'La dimension Partes provee una vista desnormalizada de las tablas origen Partes, Linea y Categoria, dejando todo en una única dimensión para un modelo estrella', 
     @level0type = N'SCHEMA', 
     @level0name = N'Dimension', 
     @level1type = N'TABLE', 
     @level1name = N'Partes';
	GO

	EXEC sys.sp_addextendedproperty 
     @name = N'Desnormalizacion', 
     @value = N'La dimension carrera provee una vista desnormalizada de las tablas País, Region y Ciudad en una sola dimensión para un modelo estrella', 
     @level0type = N'SCHEMA', 
     @level0name = N'Dimension', 
     @level1type = N'TABLE', 
     @level1name = N'Geografia';
	GO

	EXEC sys.sp_addextendedproperty 
     @name = N'Desnormalizacion', 
     @value = N'La dimension materia provee una vista desnormalizada de las tablas origen Clientes en un modelo estrella', 
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
     @value = N'La tabla de hechos es una union proveniente de las tablas de Orden,StatusOden, detalle orden Y descuento', 
     @level0type = N'SCHEMA', 
     @level0name = N'Fact', 
     @level1type = N'TABLE', 
     @level1name = N'Orden';
	GO
--------------------------------------------------------------------------------------------
---------------------------------MODELADO LOGICO--------------------------------------------
--------------------------------------------------------------------------------------------
--Transformación en modelo lógico (mas detalles)

	--Fact
	ALTER TABLE Fact.Orden ADD ID_Orden          [UDT_PK]
	ALTER TABLE Fact.Orden ADD ID_StatusOrden    [UDT_PK]
	ALTER TABLE Fact.Orden ADD NombreStatus      [UDT_VarcharLargo]
	ALTER TABLE Fact.Orden ADD ID_DetalleOrden   [UDT_PK]
	ALTER TABLE Fact.Orden ADD ID_Descuento      [UDT_PK]
	ALTER TABLE Fact.Orden ADD Total_Orden       [UDT_Decimal5.2]
	ALTER TABLE Fact.Orden ADD Cantidad			 INT
	ALTER TABLE Fact.Orden ADD NombreDescuento   [UDT_VarcharLargo]
	ALTER TABLE Fact.Orden ADD PorcentajeDescuento  [UDT_Decimal6.2]

	--DimFecha	
	ALTER TABLE Dimension.Fecha ADD [Date] DATE NOT NULL
    ALTER TABLE Dimension.Fecha ADD [Day] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [DaySuffix] CHAR(2) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [Weekday] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [WeekDayName] VARCHAR(10) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [WeekDayName_Short] CHAR(3) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [WeekDayName_FirstLetter] CHAR(1) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [DOWInMonth] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [DayOfYear] SMALLINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [WeekOfMonth] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [WeekOfYear] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [Month] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [MonthName] VARCHAR(10) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [MonthName_Short] CHAR(3) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [MonthName_FirstLetter] CHAR(1) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [Quarter] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [QuarterName] VARCHAR(6) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [Year] INT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [MMYYYY] CHAR(6) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [MonthYear] CHAR(7) NOT NULL
    ALTER TABLE Dimension.Fecha ADD IsWeekend BIT NOT NULL
  
	--DimPartes
	ALTER TABLE Dimension.Partes ADD ID_Partes [UDT_PK]
	ALTER TABLE Dimension.Partes ADD ID_Categoria [UDT_PK]
	ALTER TABLE Dimension.Partes ADD ID_Linea [UDT_PK]
	ALTER TABLE Dimension.Partes ADD NombrePartes [UDT_VarcharMediano]
	ALTER TABLE Dimension.Partes ADD NombreCategoria [UDT_VarcharMediano]
	ALTER TABLE Dimension.Partes ADD NombreLinea [UDT_VarcharMediano]
	ALTER TABLE Dimension.Partes ADD Precio [UDT_Decimal6.2]
	ALTER TABLE Dimension.Partes ADD DescripcionPartes [UDT_VarcharLargo]
	ALTER TABLE Dimension.Partes ADD DescripcionCategoria [UDT_VarcharLargo]
	ALTER TABLE Dimension.Partes ADD DescripcionLinea [UDT_VarcharLargo]

	--DimGeografia
	ALTER TABLE Dimension.Geografia ADD ID_Ciudad [UDT_PK]
	ALTER TABLE Dimension.Geografia ADD ID_Region [UDT_PK]
	ALTER TABLE Dimension.Geografia ADD ID_Pais   [UDT_PK]
	ALTER TABLE Dimension.Geografia ADD CodigoPostal [UDT_VarcharMediano]
	ALTER TABLE Dimension.Geografia ADD NombreCiudad [UDT_VarcharMediano]
	ALTER TABLE Dimension.Geografia ADD NombreRegion [UDT_VarcharMediano]
	ALTER TABLE Dimension.Geografia ADD NombrePais [UDT_VarcharMediano]

	--DimCliente
	ALTER TABLE  Dimension.Clientes ADD ID_Cliente[UDT_PK]
	ALTER TABLE Dimension.Clientes ADD PrimerNombre[UDT_VarcharMediano]
	ALTER TABLE Dimension.Clientes ADD SegundoNombre[UDT_VarcharMediano]
	ALTER TABLE Dimension.Clientes ADD PrimerApellido[UDT_VarcharMediano]
	ALTER TABLE Dimension.Clientes ADD SegundoApellido[UDT_VarcharMediano]
	ALTER TABLE Dimension.Clientes ADD Genero[UDT_UnCaracter]
	ALTER TABLE Dimension.Clientes ADD Correo_Electronico[UDT_VarcharMediano]
	ALTER TABLE Dimension.Clientes ADD FechaNacimiento DATETIME


--Indices Columnares
	CREATE NONCLUSTERED COLUMNSTORE INDEX [NCCS-Orden] ON [Fact].[Orden]
	(
	   [ID_Orden],
	   [Total_Orden]
	)WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0)
	GO

--Queries para llenar datos
	
--Dimensiones
	--DimPartes
	INSERT INTO Dimension.Partes
	(
	[ID_Partes],
	[ID_Categoria],
	[ID_Linea],
	[NombrePartes],
	[NombreCategoria], 
	[NombreLinea],
	[Precio],
	[DescripcionPartes],
	[DescripcionCategoria],
	[DescripcionLinea]
	)
	SELECT P.ID_Partes,
	P.ID_Categoria, C.ID_Linea, P.Nombre as NombrePartes, 
	C.Nombre as NombreCategoria, L.Nombre as NombreLinea,
	P.Precio, P.Descripcion as DescripcionPartes, C.Descripcion as DescripcionCategoria,
	L.Descripcion as DescripcionLinea
	From RepuestosWeb.DBO.Partes P 
	INNER JOIN RepuestosWeb.DBO.Categoria C ON(P.ID_Categoria = C.ID_Categoria) 
	INNER JOIN RepuestosWeb.DBO.Linea L ON(C.ID_Linea = L.ID_Linea)
	
	SELECT * FROM Dimension.Partes

	--DimGeografia
	INSERT INTO Dimension.Geografia
	(
	[ID_Ciudad],
	[ID_Region],
	[ID_Pais],
	[CodigoPostal],
	[NombreCiudad],
	[NombreRegion],
	[NombrePais]
	)
	SELECT C.ID_Ciudad, R.ID_Region, P.ID_Pais,
	C.CodigoPostal, C.Nombre as NombreCiudad, R.Nombre as NombreRegion,
	P.Nombre as NombrePais
	FROM RepuestosWeb.dbo.Ciudad C 
		INNER JOIN RepuestosWeb.DBO.Region R ON(C.ID_Region = R.ID_Region)
		INNER JOIN RepuestosWeb.DBO.Pais P ON(R.ID_Pais = P.ID_Pais)
	
	SELECT * FROM Dimension.Geografia

	--DimCliente
	INSERT INTO Dimension.Clientes
	(
	[ID_Cliente],
	[PrimerNombre],
	[SegundoNombre],
	[PrimerApellido],
	[SegundoApellido],
	[Genero],
	[Correo_Electronico],
	[FechaNacimiento]
	)
	SELECT *
	FROM RepuestosWeb.DBO.Clientes

		SELECT * FROM Dimension.Clientes

--------------------------------------------------------------------------------------------
-----------------------CORRER CREATE de USP_FillDimDate PRIMERO!!!--------------------------
--------------------------------------------------------------------------------------------

	DECLARE @FechaMaxima DATETIME=DATEADD(YEAR,2,GETDATE())
	--Fecha
	IF ISNULL((SELECT MAX(Date) FROM Dimension.Fecha),'1900-01-01')<@FechaMaxima
	begin
		EXEC USP_FillDimDate @CurrentDate = '2016-01-01', 
							 @EndDate     = @FechaMaxima
	end
	SELECT * FROM Dimension.Fecha
	
	--Fact
	INSERT INTO [Fact].[Orden]
	(
	[SK_Partes],
	[Sk_Geografia],
	[SK_Clientes],
	[DateKey],
	[ID_Orden],         
	[ID_StatusOrden],   
	[ID_DetalleOrden],  
	[ID_Descuento],
	[Total_Orden],      
	[NombreStatus],
	[Cantidad],
	[NombreDescuento],
	[PorcentajeDescuento]
	)
	SELECT  --Columnas de mis dimensiones en DWH
            SK_Partes,
            Sk_Geografia,
            SK_Clientes,
            F.DateKey,
            O.ID_Orden,
            O.ID_StatusOrden,
            DO.ID_DetalleOrden,
            DO.ID_Descuento,
            O.Total_Orden,
            SO.NombreStatus,
            DO.Cantidad,
            D.NombreDescuento,
            D.PorcentajeDescuento
    FROM RepuestosWeb.DBO.Orden O
        INNER JOIN RepuestosWeb.DBO.Detalle_orden DO ON(O.ID_Orden = DO.ID_Orden)
        INNER JOIN RepuestosWeb.DBO.Descuento D ON(D.ID_Descuento = DO.ID_Descuento)
        INNER JOIN RepuestosWeb.DBO.StatusOrden SO ON(SO.ID_StatusOrden = O.ID_StatusOrden)
        --Referencias a DWH
        INNER JOIN Dimension.Partes P ON(P.ID_Partes = DO.ID_Partes)
        INNER JOIN Dimension.Geografia G ON(G.ID_Ciudad = O.ID_Ciudad)
        INNER JOIN Dimension.Clientes C ON(C.ID_Cliente = O.ID_Cliente)
        INNER JOIN Dimension.Fecha F ON(CAST((CAST(YEAR(O.Fecha_Orden) AS VARCHAR(4)))+left('0'+CAST(MONTH(O.Fecha_Orden) AS VARCHAR(4)),2)+left('0'+(CAST(DAY(O.Fecha_Orden) AS VARCHAR(4))),2) AS INT)  = F.DateKey);

--------------------------------------------------------------------------------------------
------------------------------------Resultado Final-----------------------------------------
--------------------------------------------------------------------------------------------	

	SELECT *
	FROM	Fact.Orden AS O 
			INNER JOIN Dimension.Partes AS P ON(O.SK_Partes = P.SK_Partes)
			INNER JOIN Dimension.Geografia AS G ON(O.Sk_Geografia = G.Sk_Geografia)
			INNER JOIN Dimension.Clientes AS C ON(O.SK_Clientes = C.SK_Clientes)
			INNER JOIN Dimension.Fecha AS F ON (O.DateKey = F.DateKey)