# organizing rhessys outputs, from output filters, to be input to future mountain SQL 
# based on variables given in FB_DB.sql

setwd("~/Documents/BigCreek7.2ForExample/out/bigcreek/")
# setwd("~/Documents/BigCreek7.2ForExample/out/bigcreek_salience_archive/randseed1/")
library(tidyverse)
library(tm)
library(RMariaDB)

# first in terminal: sudo mysql.server start
con = dbConnect(RMariaDB::MariaDB(), user = 'root', password = '',host = 'localhost', port=3306, db="BigCreek_FutMtn")

# using historic climate as baseline, warming ID = 0 
# the climate change scenarios will be ID as degrees of warming (1, 2, 4, 6)
warming = 1

################################################################
# first table is aggcube #######################################
aggc_p <- read.csv("cube_agg_p.csv")

# grouping by date only 
aggc_p_grouped <- aggc_p %>% 
  mutate(date = as.Date(paste(year, month, day, sep="/"))) %>% 
  mutate(groundevap = evaporation_surf + 
           exfiltration_unsat_zone +
           exfiltration_sat_zone,
         trans = transpiration_sat_zone + transpiration_unsat_zone,
         leafC = cs.leafc + cs.leafc_store,
         stemC = cs.live_stemc + cs.dead_stemc,
         rootC = cs.frootc + cs.live_crootc + cs.dead_crootc,
         mortC = fe.canopy_target_prop_c_remain_adjusted + fe.canopy_target_prop_c_remain_adjusted_leafc) %>%
  dplyr::select(-basinID, -day, -month, -year,
                -evaporation_surf, -exfiltration_unsat_zone, -exfiltration_sat_zone, -transpiration_sat_zone, -transpiration_unsat_zone, -cs.leafc, -cs.leafc_store, -cs.live_stemc, -cs.dead_stemc, -cs.frootc, -cs.live_crootc, -cs.dead_crootc, -fe.canopy_target_prop_c_remain_adjusted, -fe.canopy_target_prop_c_remain_adjusted_leafc) 
  
colnames(aggc_p_grouped) <- c("litterc", 
                              "burn",
                              "soilc",
                              "depthToGW",
                              "snowpack",
                              "canopyevap",
                              "coverfract", 
                              "streamflow", 
                              "vegAccessWater",
                              "snowfall",
                              "rain",
                              "netpsn",
                              "height",
                              "consumedC",
                              "rootdepth",
                              "date",
                              "groundevap",
                              "trans",
                              "leafC",
                              "stemC",
                              "rootC",
                              "mortC")

cube_agg <- aggc_p_grouped %>%
  mutate(warmingIdx = warming,
         vegtype = 50)

# whats missing (to be added when passed to mysql:
# [id] int PRIMARY KEY,
# [dateIdx] [key], (Date is included, not as ID)

# check output with plots ##################################
ggplot(cube_agg) + geom_line(aes(x=date, y=burn))
ggplot(cube_agg) + geom_line(aes(x=date, y=stemC))
ggplot(cube_agg) + geom_line(aes(x=date, y=consumedC))
ggplot(cube_agg) + geom_line(aes(x=date, y=mortC))

firesize <- read.delim("../../scriptsFire/FireSizes0.txt")
colnames(firesize) <- cnames <- c("fire_size",
                                  "year",
                                  "month",
                                  "wind_dir",
                                  "wind_spd",
                                  "num_ign")
ggplot(firesize) + geom_line(aes(x=year, y=fire_size))
############################################################

# create new table and write to it (only need to do this once)
#dbWriteTable(con, "aggcube_data_point", cube_agg)
#dbListTables(con)
dbListFields(con, "aggcube_data_point")
# dbSendStatement(con, "ALTER TABLE aggcube_data_point
#                 ADD id int PRIMARY KEY,
#                 ADD dateIdx int UNIQUE KEY,
#                 ADD UNIQUE KEY (warmingIdx)")

# after setting up table the first time, add rows to it 
db_insert_into(con, "aggcube_data_point", cube_agg)


# cube_data_point table ####################################

cubedp_p <- read.csv("cube_data_point_p.csv")
cubedp_c1 <- read.csv("cube_data_point_c_over.csv")
cubedp_c2 <- read.csv("cube_data_point_c_under.csv")

cube_p_grouped <- cubedp_p %>% 
  mutate(date = as.Date(paste(year, month, day, sep="/"))) %>%
  # group_by(date, patchID) %>% 
  # summarize_all(sum) %>%
  dplyr::select(-month, -day, -year, -basinID, -hillID, -zoneID) %>%
  mutate(warmingIdx = warming)

# stratums have already been separated out in the output filter file 
cube_c_over <- cubedp_c1 %>% 
  mutate(date = as.Date(paste(year, month, day, sep="/"))) %>%
  dplyr::select(-month, -day, -year,
                -basinID, -hillID, -zoneID, -stratumID) %>% 
  group_by(date, patchID) %>% 
  summarize_all(sum)


cube_c_under <- cubedp_c2 %>% 
  mutate(date = as.Date(paste(year, month, day, sep="/"))) %>%
  dplyr::select(-month, -day, -year,
                -basinID, -hillID, -zoneID, - stratumID) %>% 
  group_by(date, patchID) %>% 
  summarize_all(sum)


overunder <- inner_join(cube_c_under, cube_c_over, by=c("date","patchID"))
allcube_dp <- right_join(overunder, cube_p_grouped) %>% 
  mutate(patchfamilyIdx = patchID) %>% 
  dplyr::select(-patchID)

ggplot(allcube_dp) + geom_line(aes(x=date, y=stemCOver, col=as.factor(patchfamilyIdx), linetype='over')) + geom_line(aes(x=date, y=stemCUnder, col=as.factor(patchfamilyIdx), linetype='under'))

vegids <- read.csv("~/Documents/BigCreek7.2ForExample/rhessys_fire_outputs/vegIDs_cube_data.txt")

allcube_veg = left_join(allcube_dp, vegids, by='patchfamilyIdx') 

# names left over
# CREATE TABLE [cube_data_point] (
#   [id] int PRIMARY KEY,
#   [dateIdx] [key],
#   [cubeIdx] int, ## is this same as patch??
#   [patchfamilyIdx] [key],
# )

# convert individual cubes to sql #########################

# to write the first table
# dbWriteTable(con, "cube_data_point", allcube_veg) 
# dbSendStatement(con, "ALTER TABLE cube_data_point
#                 ADD id int PRIMARY KEY,
#                 ADD dateIdx int UNIQUE KEY,
#                 ADD cubeIdx int UNIQUE KEy, 
#                 ADD UNIQUE KEY (patchfamilyIdx),
#                 ADD UNIQUE KEY (warmingIdx)")
dbListFields(con, "cube_data_point")
# then to add warming scenarios to this table 
db_insert_into(con, "cube_data_point", allcube_veg)

dbDisconnect(con)
