USE [RepuestosWebDWH]
GO
--------------------------

CREATE TABLE FactLog
(
	ID_Batch UNIQUEIDENTIFIER DEFAULT(NEWID()),
	FechaEjecucion DATETIME DEFAULT(GETDATE()),
	NuevosRegistros INT,
	CONSTRAINT [PK_FactLog] PRIMARY KEY
	(
		ID_Batch
	)
)
GO



ALTER TABLE Fact.Orden ADD CONSTRAINT [FK_IDBatch] FOREIGN KEY (ID_Batch) 
REFERENCES Factlog(ID_Batch)
GO

--Transfor columna a UNIQUEID
ALTER TABLE Fact.Orden
ALTER COLUMN ID_Batch UNIQUEIDENTIFIER
GO

CREATE SCHEMA [staging]
Go

DROP TABLE IF EXISTS [staging].[Orden]
GO

CREATE TABLE [staging].[Orden](
	[ID_Orden] [int] NOT NULL,
	[ID_Cliente] [int] NULL,
	[ID_Ciudad] [int] NULL,
	[ID_StatusOrden] [int] NULL,
	[ID_DetalleOrden] [int] NULL,
	[ID_Partes] [int] NOT NULL,
	[ID_Descuento] [int] NULL,
	[Total_Orden] decimal(12,2) null,
	[Fecha_Orden] datetime null,
	[NombreStatus] varchar(100) null,
	[Cantidad] int,
	[NombreDescuento] varchar(200) null,
	[PorcentajeDescuento] decimal(2,2),
	[FechaModificacionSource] DATETIME NULL
) ON [PRIMARY]
GO

--Query para llenar datos en Staging
select 
    O.ID_Orden,
    C.ID_Cliente,
    O.ID_Ciudad,
    O.ID_StatusOrden,
    O.Total_Orden,
    O.Fecha_Orden,
    DO.ID_DetalleOrden,
    DO.ID_Partes,
    DO.Cantidad,
    D.ID_Descuento,
    D.NombreDescuento,
    D.PorcentajeDescuento,
    SO.NombreStatus
from RepuestosWeb.dbo.Orden O
INNER JOIN RepuestosWeb.dbo.Detalle_orden DO on (O.ID_Orden=DO.ID_Orden)
INNER JOIN RepuestosWeb.dbo.Descuento D on (DO.ID_Descuento=D.ID_Descuento)
INNER JOIN RepuestosWeb.dbo.StatusOrden SO on (O.ID_StatusOrden=SO.ID_StatusOrden)
INNER JOIN RepuestosWeb.dbo.Clientes C on (O.ID_Cliente = C.ID_Cliente)
GO

--Script de SP para MERGE
CREATE OR ALTER PROCEDURE USP_MergeFact
AS
BEGIN

	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRAN
		DECLARE @NuevoGUIDInsert UNIQUEIDENTIFIER = NEWID(), @MaxFechaEjecucion DATETIME, @RowsAffected INT

		INSERT INTO FactLog ([ID_Batch], [FechaEjecucion], [NuevosRegistros])
		VALUES (@NuevoGUIDInsert,NULL,NULL)
		
		MERGE Fact.Orden AS FO
		USING (
			SELECT [SK_Partes], [SK_Geografia], [SK_Clientes], [DateKey],
			[ID_Orden], [ID_StatusOrden], [ID_DetalleOrden], [ID_Descuento],
			O.Total_Orden, O.NombreStatus, O.Cantidad, O.NombreDescuento, O.PorcentajeDescuento,
			getdate() as FechaCreacion, 'ETL' as UsuarioCreacion, NULL as FechaModificacion, NULL as UsuarioModificacion,
			@NuevoGUIDINsert as ID_Batch, 'ssis' as ID_SourceSystem, O.Fecha_Orden, O.FechaModificacionSource
			FROM STAGING.Orden O
				INNER JOIN Dimension.Partes P ON(P.ID_Partes = O.ID_Partes and
													O.Fecha_Orden BETWEEN P.FechaInicioValidez AND ISNULL(P.FechaFinValidez, '9999-12-31')) 
				INNER JOIN Dimension.Geografia G ON(G.ID_Ciudad = O.ID_Ciudad and
													O.Fecha_Orden BETWEEN G.FechaInicioValidez AND ISNULL(G.FechaFinValidez, '9999-12-31'))
				INNER JOIN Dimension.Clientes C ON(C.ID_Cliente = O.ID_Cliente and
													O.Fecha_Orden BETWEEN C.FechaInicioValidez AND ISNULL(C.FechaFinValidez, '9999-12-31'))
				LEFT JOIN Dimension.Fecha F ON(CAST( (CAST(YEAR(O.Fecha_Orden) AS VARCHAR(4)))+left('0'+CAST(MONTH(O.Fecha_Orden) AS VARCHAR(4)),2)+left('0'+(CAST(DAY(O.Fecha_Orden) AS VARCHAR(4))),2) AS INT)  = F.DateKey)
				) AS S ON (S.ID_Orden = FO.ID_Orden)

		WHEN NOT MATCHED BY TARGET THEN --No existe en Fact
		INSERT (SK_Partes, SK_Geografia, SK_Clientes, DateKey,ID_Orden, ID_StatusOrden, ID_DetalleOrden, ID_Descuento,Total_Orden, NombreStatus, Cantidad, NombreDescuento, PorcentajeDescuento,
		FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion, ID_Batch, ID_SourceSystem, Fecha_Orden, FechaModificacionSource)
		VALUES (S.SK_Partes, S.SK_Geografia, S.SK_Clientes, S.DateKey, S.ID_Orden, S.ID_StatusOrden, S.ID_DetalleOrden, S.ID_Descuento,
		S.Total_Orden, S.NombreStatus, S.Cantidad, S.NombreDescuento, S.PorcentajeDescuento, S.FechaCreacion, S.UsuarioCreacion, S.FechaModificacion, S.UsuarioModificacion, S.ID_Batch,
		S.ID_SourceSystem, S.Fecha_Orden, S.FechaModificacionSource);

		SET @RowsAffected =@@ROWCOUNT

		SELECT @MaxFechaEjecucion=MAX(MaxFechaEjecucion)
		FROM(
			SELECT MAX(Fecha_Orden) as MaxFechaEjecucion
			FROM FACT.Orden
			UNION
			SELECT MAX(FechaModificacionSource)  as MaxFechaEjecucion
			FROM FACT.Orden
		)AS A

		UPDATE FactLog
		SET NuevosRegistros=@RowsAffected, FechaEjecucion = @MaxFechaEjecucion
		WHERE ID_Batch = @NuevoGUIDInsert

		COMMIT
	END TRY
	BEGIN CATCH
		SELECT @@ERROR,'Ocurrio el siguiente error: '+ERROR_MESSAGE()
		IF (@@TRANCOUNT>0)
			ROLLBACK;
	END CATCH

END
GO 