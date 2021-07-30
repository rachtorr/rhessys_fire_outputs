# organizing rhessys outputs, from output filters, to be input to future mountain SQL 
# based on variables given in FB_DB.sql
#setwd("~/fire/")
setwd("~/Documents/BigCreek7.2ForExample/out/bigcreek/")
library(tidyverse)
library(tm)

# need to update all for climate scenario with climate ID in data frames

# using historic climate as baseline, warming ID = 0 
# the climate change scenarios will be ID as degrees of warming (1, 2, 4, 6)
warming = 0

# identify which patch IDs you are using for cubes 
# patchID_cubes = c(1, 2)

#################################################################
# first table - spatial data point 
setwd("../test/")
sdp_p <- read.csv("spatial_data_point_patchvar.csv")


all_sdp <- sdp_p %>%
  mutate(plantc = cs.leafc + cs.live_stemc + cs.dead_stemc,
    date = as.Date(paste(year, month, day, sep="/"))) %>%
  dplyr::select(patchfamilyIdx = patchID, 
                plantc, snowpack, date) %>%
  mutate(warmingIdx = warming)

#need to add column for id, not sure what this is 

#################################################################

# next table is aggcube

# need to separate over and unders 
# some of the outputs are missing
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

# what does burn mean? is it 1/0 burn took place in patch? 


############################################################
# cube_data_point table 

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
allcube_dp <- right_join(overunder, cube_p_grouped) 

vegids <- read.csv("vegid.csv")
vegpatch <- pivot_wider(vegids, id_cols=patchID, values_from = vegID, names_from = canopy, names_prefix = "vegtype")
vegpatch$vegtypeOver[is.na(vegpatch$vegtypeOver)] <- 0
vegpatch$vegtypeUnder[is.na(vegpatch$vegtypeUnder)] <- 0

allcube_veg = left_join(allcube_dp, vegpatch, by='patchID') %>% 
  mutate(patchfamilyIdx = patchID) %>%
  dplyr::select(-patchID)


# names left over
# CREATE TABLE [cube_data_point] (
#   [id] int PRIMARY KEY,
#   [dateIdx] [key],
#   [cubeIdx] int, ## is this same as patch??
#   [patchfamilyIdx] [key],
# )

###############################################################
# convert to sql

