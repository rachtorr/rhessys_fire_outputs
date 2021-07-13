# organizing rhessys outputs, from output filters, to be input to future mountain SQL 
# based on variables given in FB_DB.sql
#setwd("~/fire/")
setwd("~/Documents/BigCreek7.2ForExample/out/test/")
library(tidyverse)
library(tm)

# need to update all for climate scenario with cliamte ID in data frames

#################################################################
# first table - spatial data point 

sdp_p <- read.csv("spatial_data_point_patchvar.csv")
sdp_c <- read.csv("spatial_data_point_stratumvar.csv")

sdp_c_patch <- sdp_c %>% 
  group_by(day, month, year, basinID, hillID, zoneID, patchID) %>%
  summarize_at(vars(plantc), list(sum))

all_sdp <- inner_join(sdp_p, sdp_c_patch, 
                      by=c('day', 'month', 'year', 'basinID', 'hillID','zoneID', 'patchID')) %>% 
  mutate(date = as.Date(paste(year, month, day, sep="/"))) %>%
  dplyr::select(-basinID, -hillID, -zoneID, -month, -day, -year) 

#need to add column for ID, warmingID

#################################################################

# next table is aggcube

# need to separate over and unders 
# some of the outputs are missing
aggc_p <- read.csv("cube_agg_p.csv")
aggc_c <- read.csv("cube_agg_c.csv")

# grouping by date only 
aggc_p_grouped <- aggc_p %>% 
  mutate(date = as.Date(paste(year, month, day, sep="/"))) %>% 
  mutate(groundevap = evaporation_surf + 
           exfiltration_unsat_zone +
           exfiltration_sat_zone) %>%
  dplyr::select(-basinID, -day, -month, -year,
                -evaporation_surf, -exfiltration_unsat_zone, -exfiltration_sat_zone) 
  

colnames(aggc_p_grouped) <- c("litterc", 
                              "burn",
                              "soilc",
                              "depthToGW",
                              "snowpack",
                              "canopyevap",
                              "coverfract", 
                              "streamflow", 
                              "rootdepth",
                              "VegAccessWater",
                              "Qin", 
                              "Qout",
                              "date",
                              "groundevap")

# group stratum into over and under 
aggc_avg <- aggc_c %>% 
  mutate(date = as.Date(paste(year, month, day, sep="/"))) %>%
  dplyr::select(-month, -day, -year,
                -basinID, -hillID, -zoneID, -patchID) %>% 
  group_by(date, stratumID) %>% 
  summarize_all(mean) 

overunder <- pivot_wider(aggc_avg, names_from=stratumID, values_from=c(trans, netpsn, height, leafC, stemC, rootC, consumedC, mortC), names_prefix=c("Over","Under"), names_sep = "")
colnames(overunder) <- removeNumbers(names(overunder))

cube_agg <- inner_join(aggc_p_grouped,  overunder, by="date")

# root depth is patch output - not separated into over under here

# whats missing:
# [id] int PRIMARY KEY,
# [dateIdx] [key],
# [warmingIdx] [key],
# [rain] float8 NOT NULL,
# [snowfall] float8 NOT NULL,

############################################################
# cube_data_point table 

cubedp_p <- read.csv("cube_data_point_p.csv")
cubedp_c1 <- read.csv("cube_data_point_c_over.csv")
cubedp_c2 <- read.csv("cube_data_point_c_under.csv")

cube_p_grouped <- cubedp_p %>% 
  mutate(date = as.Date(paste(year, month, day, sep="/"))) %>%
  group_by(date, patchID) %>% 
  summarize_all(sum) %>%
  dplyr::select(-month, -day, -year, -basinID, -hillID, -zoneID)

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

# names left over
# CREATE TABLE [cube_data_point] (
#   [id] int PRIMARY KEY,
#   [dateIdx] [key],
#   [cubeIdx] int,
#   [warmingIdx] [key],
#   [rain] float8 NOT NULL,
#   [snowfall] float8 NOT NULL
# )
# also ask about percent_cover - might not be family output
