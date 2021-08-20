# OSX
# brew install mariadb-connector-c
# brew install mysql-connector-c

setwd("~/Documents/BigCreek7.2ForExample/out/bigcreek/")
warming = 2

library(ncdf4)
library(RMariaDB)
library(RMySQL)
library(DBI)

basin <- nc_open("spatial_data_point_patchvar.nc")

# next steps: load in dates, 
day = ncvar_get(basin, "day")
dfspace = as.data.frame(day)
rm(day)
month = ncvar_get(basin, "month")
dfspace$month = as.matrix(month)
rm(month)
year = ncvar_get(basin, "year")
dfspace$year = as.matrix(year)
rm(year)
plantcleaf = ncvar_get(basin, "cs.leafc")  
dfspace$plantc = as.matrix(plantcleaf)
rm(plantcleaf)
plantcstem = ncvar_get(basin, "cs.live_stemc")
dfspace$plantc = dfspace$plantc + as.matrix(plantcstem)
rm(plantcstem)
plantcdead = ncvar_get(basin, "cs.dead_stemc")
dfspace$plantc = dfspace$plantc + as.matrix(plantcdead)
rm(plantcdead)
snow = ncvar_get(basin, "snowpack")
dfspace$snowpack = as.matrix(snow)
rm(snow)
burn = ncvar_get(basin, "burn")
dfspace$burn = as.matrix(burn)
rm(burn)
patches = ncvar_get(basin, "patchID")
dfspace$patchfamilyIdx = as.matrix(patches) 
rm(patches)

nc_close(basin)

dfspace$warmingIdx = warming

# send to mysql
con = dbConnect(RMariaDB::MariaDB(), user = 'root', password = '',host = 'localhost', port=3306, db="BigCreek_FutMtn")
RMySQL::dbWriteTable(con, "spatial_data_point", dfspace) 
dbSendStatement(con, "ALTER TABLE spatial_data_point
                ADD id int not null auto_increment PRIMARY KEY,
                ADD UNIQUE KEY (warmingIdx),
                ADD UNIQUE KEY (patchfamilyIdx)")
