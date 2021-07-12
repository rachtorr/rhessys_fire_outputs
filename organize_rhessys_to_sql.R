# organizing rhessys outputs, from output filters, to be input to future mountain SQL 
# based on variables given in FB_DB.sql
setwd("~/fire/")
library(tidyverse)

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
# then add climate ID as well 
# need to get elevation as well - that should be from DEM file but then will add based on patch ID

# next table is aggcube
# need to separate over and unders 
# some of the outputs are missing
aggc_p <- read.csv("cube_agg_p.csv")
aggc_c <- read.csv("cube_agg_c.csv")

# grouping by date only 
aggc_p_grouped <- aggc_p %>% 
  mutate(date = as.Date(paste(year, month, day, sep="/"))) %>%
  group_by(date) %>% 
  summarize_at(vars(litterc, burn, soilc), list(sum)) # needs more outputs

# need to double check this - overstory is 1, understory is 2
aggc_over <- aggc_c %>% dplyr::filter(stratumID==1) %>%
  mutate(date = as.Date(paste(year, month, day, sep="/"))) %>%
  dplyr::select(-CburnUnder, -CmortUnder, -month, -day, -year,
                -basinID, -hillID, -zoneID, -patchID, -stratumID) %>% 
  group_by(date) %>% 
  summarize_all(sum) 


# need to figure out how to automate this, or make 2:5 values flexible or not date, etc. 
overnames <- paste(names(aggc_over)[2:7], "Over", sep="")
colnames(aggc_over)[2:7] <- overnames
  
aggc_under <- aggc_c %>% dplyr::filter(stratumID==2) %>%
  mutate(date = as.Date(paste(year, month, day, sep="/"))) %>%
  dplyr::select(-burnCOver, -mortCOver, -month, -day, -year,
                -basinID, -hillID, -zoneID, -patchID, -stratumID) %>% 
  group_by(date) %>% 
  summarize_all(sum)

# need to figure out how to automate this, or make 2:5 values flexible or not date, etc. 
undernames <- paste(names(aggc_under)[2:7], "Under", sep="")
colnames(aggc_under)[2:7] <- undernames

cube_agg <- inner_join(aggc_over, aggc_under, by="date")
cube_agg <- inner_join(cube_agg, aggc_p_grouped, by="date")
# whats missing:
# [id] int PRIMARY KEY,
# [dateIdx] [key],
# [warmingIdx] [key],
# [rain] float8 NOT NULL,
# [streamflow] float 8 NOT NULL,
# [snowfall] float8 NOT NULL,
# [snowpack] float8 NOT NULL,
# [groundevap] float8 NOT NULL,
# [canopyevap] float8 NOT NULL,
# [depthToGW] float8 NOT NULL,
# [vegAccessWater] float8 NOT NULL,

# join all for cube_data_point table 

cubedp_p <- read.csv("cube_data_point_p.csv")
cubedp_c <- read.csv("cube_data_point_c.csv")
cubedp_fire <- read.csv("cube_data_point_c_fire.csv") # don't need this though

cube_p_grouped <- cubedp_p %>% 
  mutate(date = as.Date(paste(year, month, day, sep="/"))) %>%
  group_by(date, patchID) %>% 
  summarize_all(sum) %>%
  dplyr::select(-month, -day, -year, -basinID, -hillID, -zoneID)

# need to change names again and group by patch 
cube_c_under <- cubedp_c %>% 
  dplyr::filter(stratumID==2) %>%
  mutate(date = as.Date(paste(year, month, day, sep="/"))) %>%
  dplyr::select(-month, -day, -year,
                -basinID, -hillID, -zoneID, -stratumID) %>% # in real version, add these -burnCOver, -mortCOver
  group_by(date, patchID) %>% 
  summarize_all(sum)

n_names <- length(names(cube_c_under))
colnames(cube_c_under)[3:n_names] <- paste(names(cube_c_under)[3:n_names], "Under", sep="")


cube_c_over <- cubedp_c %>% 
  dplyr::filter(stratumID==1) %>%
  mutate(date = as.Date(paste(year, month, day, sep="/"))) %>%
  dplyr::select(-month, -day, -year,
                -basinID, -hillID, -zoneID, -stratumID) %>% # in real version, add these -burnCOver, -mortCOver
  group_by(date) %>% 
  summarize_all(sum)

n_names <- length(names(cube_c_over))
colnames(cube_c_over)[3:n_names] <- paste(names(cube_c_over)[3:n_names], "Over", sep="")
  
overunder <- inner_join(cube_c_under, cube_c_over, by=c("date","patchID"))
allcube_dp <- right_join(overunder, cube_p_grouped) 

# names left over
# CREATE TABLE [cube_data_point] (
#   [id] int PRIMARY KEY,
#   [dateIdx] [key],
#   [cubeIdx] int,
#   [warmingIdx] [key],
#   [patchIdx] [key],
#   [date] nvarchar(255) NOT NULL,
#   [rain] float8 NOT NULL,
#   [Qin] float8 NOT NULL,
#   [Qout] float8 NOT NULL,
#   [snowfall] float8 NOT NULL,
#   [snowpack] float8 NOT NULL,
#   [groundevap] float8 NOT NULL,
#   [canopyevap] float8 NOT NULL,
#   [netpsnOver] float8 NOT NULL,
#   [netpsnUnder] float8 NOT NULL,
#   [depthToGW] float8 NOT NULL,
#   [vegAccessWater] float8 NOT NULL,
#   [heightOver] float8 NOT NULL,
#   [heightUnder] float8 NOT NULL,
#   [leafCOver] float8 NOT NULL,
#   [stemCOver] float8 NOT NULL,
#   [rootCOver] float8 NOT NULL,
#   [leafCUnder] float8 NOT NULL,
#   [stemCUnder] float8 NOT NULL,
#   [rootCUnder] float8 NOT NULL
#   [rootdepthCUnder] float8 NOT NULL
#   [rootdepthCOver] float8 NOT NULL
#   [coverfract] float8 NOT NULL
#   [burnCOver] float8 NOT NULL
#   [burnCUnder] float8 NOT NULL
#   [mortCUnder] float8 NOT NULL
#   [mortCOver] float8 NOT NULL
# )
