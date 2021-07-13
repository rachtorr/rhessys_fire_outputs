setwd("~/Documents/BigCreek7.2ForExample/auxdata/")
library(tidyverse)
library(raster)

# look at DEM and patch map and select patches where:
# 2 north facing slopes
# 2 south facing slopes
# 1 riparian zone 
# 1 high elevation

# from Janet's original cubes: 
# 1342293 - lower left, shrub
# 1307432 - lower right, pine overstory & shrub understory
# 1239496 - top right, pine overstory & shrub understory
# 1243926 - top left, pine overstory & shrub understory
# 1288284 - middle, shrub

dem <- read.table("~/Documents/BigCreek7.2ForExample/auxdata/DemGrid.txt", quote="\"", comment.char="")
y = nrow(dem)
x = ncol(dem)
dem$y = as.numeric(rownames(dem))
dem_long <- pivot_longer(dem, cols = -y)
xnames = strsplit(dem_long$name, split="V")
dem_long$x = as.numeric(lapply(xnames, "[[", 2))
dem_long$value[dem_long$value==-9999] <- NA
dem_long <- dplyr::select(dem_long, -name)
dem_long$y2 = dem_long$y[order(dem_long$y,decreasing = T)]


blank <- raster(ncols=x, nrows=y)
rast <- rasterize(x=c(dem_long$x, dem_long$y), blank, field=dem_long$value)

ggplot(dem_long) + geom_raster(aes(x=x, y=y2, fill=value))

rast <- as.raster(as.matrix(dem_long))
rast[rast==-9999,] <- NA



