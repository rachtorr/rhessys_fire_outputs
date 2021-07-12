# organizing rhessys outputs, from output filters, to be input to future mountain SQL 
# based on variables given in FB_DB.sql
#setwd("~/fire/")
setwd("~/Documents/BigCreek7.2ForExample/out/test/")
library(tidyverse)

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
aggc_p_summed <- aggc_p %>% 
  mutate(date = as.Date(paste(year, month, day, sep="/"))) %>%
  group_by(date) %>% 
  summarize_at(vars(litterc, burn, soilc, evap, canopyevap, streamflow, Qin, Qout), list(sum))

aggc_p_avgd <- aggc_p %>% 
  mutate(date = as.Date(paste(year, month, day, sep="/"))) %>%
  group_by(date) %>% 
  summarize_at(vars(depthToGW, family_pct_cover, snowpack, VegAccessWater, rootdepth), list(mean))

aggc_p_grouped <- inner_join(aggc_p_summed, aggc_p_avgd)

# need to double check this - overstory is 1, understory is 2
aggc_over <- aggc_c %>% dplyr::filter(stratumID==1) %>%
  mutate(date = as.Date(paste(year, month, day, sep="/"))) %>%
  dplyr::select(-month, -day, -year,
                -basinID, -hillID, -zoneID, -patchID, -stratumID) %>% 
  group_by(date) %>% 
  summarize_all(sum) 

n = ncol(aggc_over)
overnames <- paste(names(aggc_over)[2:n], "Over", sep="")
colnames(aggc_over)[2:n] <- overnames
  
aggc_under <- aggc_c %>% dplyr::filter(stratumID==2) %>%
  mutate(date = as.Date(paste(year, month, day, sep="/"))) %>%
  dplyr::select(-month, -day, -year,
                -basinID, -hillID, -zoneID, -patchID, -stratumID) %>% 
  group_by(date) %>% 
  summarize_all(sum)

n = ncol(aggc_under)
undernames <- paste(names(aggc_under)[2:n], "Under", sep="")
colnames(aggc_under)[2:n] <- undernames

cube_agg <- inner_join(aggc_over, aggc_under, by="date")
cube_agg <- inner_join(cube_agg, aggc_p_grouped, by="date")
# whats missing:
# [id] int PRIMARY KEY,
# [dateIdx] [key],
# [warmingIdx] [key],
# [rain] float8 NOT NULL,
# [snowfall] float8 NOT NULL,

# what is agg cube actually is it sum, avg, etc?? 

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
