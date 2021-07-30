CREATE TABLE [spatial_data_point] (
  [id] int PRIMARY KEY IDENTITY(1, 1),
  [warmingIdx] [key],
  [patchfamilyIdx] [key],
  [dateIdx] [key],
  [snowpack] float8 NOT NULL,
  [plantC] float8 NOT NULL
)
GO


CREATE TABLE [aggcube_data_point] (
  [id] int PRIMARY KEY,
  [dateIdx] [key],
  [warmingIdx] [key],
  [date] nvarchar(255) NOT NULL,
  [rain] float8 NOT NULL,
  [streamflow] float 8 NOT NULL,
  [snowfall] float8 NOT NULL,
  [snowpack] float8 NOT NULL,
  [groundevap] float8 NOT NULL,
  [canopyevap] float8 NOT NULL,
  [netpsn] float8 NOT NULL,
  [depthToGW] float8 NOT NULL,
  [vegAccessWater] float8 NOT NULL,
  [litterC] float8 NOT NULL,
  [soilC] float8 NOT NULL,
  [height] float8 NOT NULL,
  [trans] float8 NOT NULL,
  [leafC] float8 NOT NULL,
  [rootC] float8 NOT NULL,
  [stemC] float8 NOT NULL,
  [rootdepth] float8 NOT NULL,
  [coverfract] float8 NOT NULL,
  [consumedC] float8 NOT NULL,
  [mortC] float8 NOT NULL
)
GO

CREATE TABLE [cube_data_point] (
  [id] int PRIMARY KEY,
  [dateIdx] [key],
  [cubeIdx] int,
  [warmingIdx] [key],
  [patchIdx] [key],
  [patchfamilyIdx] [key],
  [vegtypeOver] int NOT NULL,
  [vegtypeUnder] int NOT NULL,
  [date] nvarchar(255) NOT NULL,
  [rain] float8 NOT NULL,
  [Qin] float8 NOT NULL,
  [Qout] float8 NOT NULL,
  [snowfall] float8 NOT NULL,
  [snowpack] float8 NOT NULL,
  [groundevap] float8 NOT NULL,
  [canopyevap] float8 NOT NULL,
  [netpsnOver] float8 NOT NULL,
  [netpsnUnder] float8 NOT NULL,
  [depthToGW] float8 NOT NULL,
  [vegAccessWater] float8 NOT NULL,
  [litterC] float8 NOT NULL,
  [soilC] float8 NOT NULL,
  [heightOver] float8 NOT NULL,
  [transOver] float8 NOT NULL,
  [heightUnder] float8 NOT NULL,
  [transUnder] float8 NOT NULL,
  [leafCOver] float8 NOT NULL,
  [stemCOver] float8 NOT NULL,
  [rootCOver] float8 NOT NULL,
  [leafCUnder] float8 NOT NULL,
  [stemCUnder] float8 NOT NULL,
  [rootCUnder] float8 NOT NULL
  [rootdepthUnder] float8 NOT NULL
  [rootdepthOver] float8 NOT NULL
  [coverfract] float8 NOT NULL
  [consumedCOver] float8 NOT NULL
  [consumedCUnder] float8 NOT NULL
  [mortCUnder] float8 NOT NULL
  [mortCOver] float8 NOT NULL
)
GO

CREATE TABLE [dates] (
  [dateIdx] [pk],
  [year] int,
  [month] int,
  [day] int
)
GO

CREATE TABLE [patch_locations] (
  [patchIdx] int PRIMARY KEY,
  [x] int NOT NULL,
  [y] int NOT NULL
)
GO

ALTER TABLE [spatial_data_point] ADD FOREIGN KEY ([patchIdx]) REFERENCES [patch_locations] ([patchIdx])
GO

ALTER TABLE [cube_data_point] ADD FOREIGN KEY ([patchIdx]) REFERENCES [patch_locations] ([patchIdx])
GO

ALTER TABLE [cube_data_point] ADD FOREIGN KEY ([warmingIdx]) REFERENCES [spatial_data_point] ([warmingIdx])
GO

ALTER TABLE [cube_data_point] ADD FOREIGN KEY ([dateIdx]) REFERENCES [dates] ([dateIdx])
GO

ALTER TABLE [spatial_data_point] ADD FOREIGN KEY ([dateIdx]) REFERENCES [dates] ([dateIdx])
GO
