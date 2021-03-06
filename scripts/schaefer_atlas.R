#!/usr/bin Rscript

## Packages
library("here")
library("readr")
library("data.table")
library("purrr")
library("stringr")

rds_file <- here("data/processed/rds/schaefer_atlases.rds")

if (!file.exists(rds_file)) {
  # Create base data.tables
  indir    <- "data/raw/atlas/schaefer_coords"
  files    <- paste0("Schaefer2018_", rep(c(100, 200, 400), each=2),
                     "Parcels_", rep(c(7, 17), times=3),
                  "Networks_order_FSLMNI152_2mm.Centroid_RAS.csv")
  titles   <- paste0("schaefer", rep(c(100,200,400), each=2),
                   "x", rep(c(7,17), times=3))
  schaefer <- set_names(map(here(indir, files), fread), titles)

  # Add columns for hemi & networks from full names
  for (i in seq_along(schaefer)) {
    full_nms <- schaefer[[i]][[2]]
    sep_nms  <- str_split_fixed(full_nms, "_", 4)
    hemi     <- str_sub(sep_nms[,2], 1, 1)
    network  <- sep_nms[,3]
    schaefer[[i]][, ':='(hemi=hemi, network=as.factor(network))]
    schaefer[[i]][grepl("Vis", network),  lobe := "Occipital"]
    schaefer[[i]][grepl("Limb", network), lobe := "Limbic"]
    schaefer[[i]][grepl("Temp", network), lobe := "Temporal"]
    schaefer[[i]][grepl("Sal", network),  lobe := "Central"]
    schaefer[[i]][grepl("Som", network),  lobe := "Parietal"]
    schaefer[[i]][grepl("Dors", network), lobe := "Parietal"]
    schaefer[[i]][grepl("Cont", network), lobe := "Frontal"]
    schaefer[[i]][grepl("Def", network),  lobe := "Frontal"]
    setnames(schaefer[[i]],
             c("ROI Label", "ROI Name", "R", "A", "S"),
             c("index", "name", "x.mni", "y.mni", "z.mni"))
  }

  # Save RDS object with created list
  write_rds(schaefer, rds_file)
}

# Read RDS of Schaefer atlases list
schaefer_list <- read_rds(rds_file)

# Convert to bGraph atlases
suppressWarnings(map(schaefer_list, brainGraph::as_atlas))
for (i in seq_along(schaefer_list)) {
  assign(names(schaefer_list[i]), schaefer_list[[i]])
}
rm(schaefer_list)
