
# read in worldfile, identify patches, output veg types 
setwd("~/Documents/BigCreek7.2ForExample/out/test/")

smallworld <- read.table("~/Documents/BigCreek7.2ForExample/worldfiles/bcsmall.world.su", quote="\"", comment.char="")

colnames(smallworld) <- c("value", "name")

smallworld_IDs <- smallworld[smallworld$name == "patch_ID" |
             smallworld$name == "num_canopy_strata" |
             smallworld$name == "canopy_strata_ID" |
             smallworld$name == "veg_parm_ID",]

test <- pivot_wider(smallworld_IDs, id_cols=name, values_fn = list)

patch_df <- as.data.frame(mapply(rep, test$patch_ID, test$num_canopy_strata)) 
strata_df <- as.data.frame(mapply(rep, test$canopy_strata_ID, 1)) 
veg_df = as.data.frame(mapply(rep, test$veg_parm_ID, 1))

iddf =cbind(patch_df, strata_df, veg_df)
colnames(iddf) <- c("patchID", "stratumID", "vegID")
iddf$canopy = ifelse(iddf$stratumID==1, "Over","Under")

write.csv(iddf, "vegid.csv")
