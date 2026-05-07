#!/usr/bin/env Rscript

#### Get data points from OSM using Overpass API

####_ Set environment _####
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic <- Sys.time()
Script.Name <- "~/CODE/gpx_tools/gpx_db/query_osm_data.R"

if (!interactive())  sink(file=sub("\\.R$",".out",Script.Name,), split = TRUE)
Script.Base <- sub("\\.R$","",Script.Name)


library(osmdata)
library(sf)

## work around for
curl::has_internet()
assign("has_internet_via_proxy", TRUE, environment(curl::has_internet))
curl::has_internet()

regions <- c("Gr")

make_tiles <- function(bbox, nx = 3, ny = 3) {
  xs <- seq(bbox[1], bbox[3], length.out = nx + 1)
  ys <- seq(bbox[2], bbox[4], length.out = ny + 1)

  tiles <- list()
  k <- 1
  for (i in 1:nx) {
    for (j in 1:ny) {
      tiles[[k]] <- c(xs[i], ys[j], xs[i+1], ys[j+1])
      k <- k + 1
    }
  }
  tiles
}


safe_osmdata_sf <- function(q, max_tries = 5) {
  for (i in seq_len(max_tries)) {
    res <- try(osmdata::osmdata_sf(q), silent = TRUE)

    if (!inherits(res, "try-error")) return(res)

    wait <- runif(1, 5, 15) * i
    message(sprintf("Retry %d/%d after %.1fs...", i, max_tries, wait))
    Sys.sleep(wait)
  }
  return(NULL)
}


bbox_gr <- c(19.34, 34.79, 28.25, 41.77)
tiles <- make_tiles(bbox_gr, nx = 5, ny = 5)  # 9 tiles

set_overpass_url("https://lz4.overpass-api.de/api/interpreter")
get_overpass_url()

# for (tile in tiles) {
#   print(tile)
#
#   call <- opq(tile, timeout = 1000)
#
#   q1 <- add_osm_feature(call, key = "boundary", value =  "marker")
#   q1 <- safe_osmdata_sf(q1)
#
#
#
#
#   stop("DDD")
# }


delay   <- 20
oldness <- 3600 * 13

is_file_old <- function(file, oldsec = oldness) {
  if (!file.exists(file)) {
    return(FALSE)
  }
  return(difftime(Sys.time(), file.mtime(outfile), units = "sec") > oldness)
}


for (ar in regions) {

  ## Region Definitions
  if ( ar == "Gr") {
    abbox <- c(19.34, 34.79, 28.25, 41.77)
  } else {
    stop(paste("Unknow region",ar))
  }

  call  <- opq(abbox,  timeout = 1000)
  ## Get camp sites from OSM #################################################
  outfile <- paste0("~/GISdata/Layers/Auto/osm/OSM_pyramids_",ar,".gpx")

  if (is_file_old(outfile)) {
    cat(paste("Query for pyramids", ar, "\n"))

    q1      <- add_osm_feature(call, key = "boundary", value =  "marker")
    q1      <- osmdata_sf(q1)
    # q1$geometry <- sf::st_centroid(q1$geometry)

    q1      <- q1$osm_points
    q1$sym  <- "Green Block"
    q1$desc <- "Πυραμίδα"
    if (nrow(q1) > 0) {
      saveRDS(q1,"~/GISdata/Layers/Auto/osm/OSM_boundary_marker.Rds")
    } else {
      cat("No data to save")
    }

    Sys.sleep(delay)

    q2      <- add_osm_feature(call, key = "man_made", value =  "survey_point")
    q2      <- osmdata_sf(q2)
    q2      <- q2$osm_points
    q2$sym  <- "Short Tower"
    q2$desc <- "Τριγωνομετρικό"

    if (nrow(q2) > 0) {
      saveRDS(q2,"~/GISdata/Layers/Auto/osm/OSM_survay_point.Rds")
    } else {
      cat("No data to save")
    }

    Sys.sleep(delay)

    Q          <- unique(q1)
    Q$geometry <- sf::st_centroid(Q$geometry)

    ## drop fields
    Q$osm_id               <- NULL
    Q$wikipedia            <- NULL
    Q$wikidata             <- NULL
    Q$wheelchair           <- NULL
    Q$addr.city            <- NULL
    Q$created_by           <- NULL
    Q$source               <- NULL
    Q$operator             <- NULL
    # Q$historic             <- NULL
    Q$tourism              <- NULL
    Q$access               <- NULL
    Q$bottle               <- NULL
    Q$drinking_water.legal <- NULL
    Q$capacity             <- NULL

    Q <- unique(Q)
    Q <- janitor::remove_empty(Q, "cols")

    ## replace na with spaces
    for (an in names(Q)) {
      Q[as.vector(is.na(Q[, an])), an] <- ""
    }

    ## create name field from many
    wenames <- c("alt_name", "int_name", "name.el", "name.en", "old_name")
    wenames <- names(Q)[names(Q) %in% wenames]
    for (an in wenames) {
      Q$name <- paste(Q$name, Q[[an]])
    }

    ## clean names
    Q$name <- gsub("[ ]+", " ", Q$name)
    Q$name <- gsub("^[ ]",  "", Q$name)
    Q$name <- gsub("[ ]$",  "", Q$name)

    ### Ignore sort names?
    # cnames <- unique(c("..."))
    # for (cn in cnames) {
    #   Q$name <- sub(paste0("^",cn,"$"), "", Q$name, ignore.case = T)
    # }

    ## test output
    ss <- data.frame( table(Q$name) )

    ## use desc for empty names
    Q$name[ Q$name == "" ] <- Q$desc[ Q$name == "" ]

    # ## create comments field
    Q$cmt <- ""
    # Q$cmt <- paste(Q$cmt, paste0(Q$amenity,"=",Q$drinking_water))
    # Q$cmt <- paste(Q$cmt, paste0("natural","=",Q$natural))
    # Q$cmt <- paste(Q$cmt, paste0("seasonal","=",Q$seasonal))
    # Q$cmt <- paste(Q$cmt, paste0("thermal","=",Q$thermal))
    # Q$cmt <- paste(Q$cmt, Q$description)
    # Q$cmt <- paste(Q$cmt, Q$description.en)
    # Q$cmt <- paste(Q$cmt, Q$note)
    #
    # Q$cmt <- gsub(" = ",             "", Q$cmt)
    # Q$cmt <- gsub("drinking_water= ","", Q$cmt)
    # Q$cmt <- gsub("natural= ",       "", Q$cmt)
    # Q$cmt <- gsub("seasonal= ",      "", Q$cmt)
    # Q$cmt <- gsub("thermal= ",       "", Q$cmt)
    #
    # Q$cmt <- gsub("[ ]+", " ", Q$cmt)
    # Q$cmt <- gsub("^[ ]",  "", Q$cmt)
    # Q$cmt <- gsub("[ ]$",  "", Q$cmt)


    ## may be better without
    Q$name[Q$name == ""] <- NA
    Q$cmt[Q$cmt   == ""] <- NA
    Q$cmt[Q$desc  == ""] <- NA


    sel <- Q$name != "Πυραμίδα"
    Q$name[sel] <- paste0("Π # ", Q$name[sel])

    ## test output
    ss <- table(Q$name)

    ## export data
    EXP <- Q[, c("geometry","name","desc","sym","cmt")]
    if (nrow(EXP) > 0) {
      write_sf(EXP, outfile, driver = "GPX", append = F, overwrite = T)
    } else {
      cat("No data to save")
    }
  }


  ##  Get camp sites from OSM  #################################################
  outfile <- paste0("~/GISdata/Layers/Auto/osm/OSM_Camp_sites_",ar,".gpx")

  if (is_file_old(outfile)) {
    cat(paste("Query for camp sites",ar,"\n"))

    q1      <- add_osm_feature(call, key = "tourism", value =  "camp_site")
    q1      <- osmdata_sf(q1)
    # q1$geometry <- sf::st_centroid(q1$geometry)

    Sys.sleep(delay) ## be polite to server

    q1      <- q1$osm_points
    q1$sym  <- "Campground"
    q1$desc <- "camp"

    if (nrow(q2) > 0) {
      saveRDS(q1,"~/GISdata/Layers/Auto/osm/OSM_Camp_sites.Rds")
    } else {
      cat("No data to save")
    }

    q2      <- add_osm_feature(call, key = '^name(:.*)?$', value = 'camping',
                               value_exact = FALSE, key_exact = FALSE, match_case = FALSE)
    q2      <- osmdata_sf(q2)
    # q2$geometry <- sf::st_centroid(q2$geometry)

    Sys.sleep(delay) ## be polite to server
    q2      <- q2$osm_points
    q2$sym  <- "Campground"
    q2$desc <- "camp"
    if (nrow(q2) > 0) {
      saveRDS(q2,"~/GISdata/Layers/Auto/osm/OSM_Camping.Rds")
    } else {
      cat("No data to save")
    }

    wecare     <- intersect(names(q1),names(q2))
    Q          <- rbind( q1[wecare], q2[wecare])
    Q          <- unique(Q)
    Q$geometry <- sf::st_centroid(Q$geometry)

    ## drop fields
    Q$osm_id               <- NULL
    Q$wikipedia            <- NULL
    Q$wikidata             <- NULL
    Q$wheelchair           <- NULL
    Q$addr.city            <- NULL
    Q$created_by           <- NULL
    Q$source               <- NULL
    Q$operator             <- NULL
    Q$historic             <- NULL
    Q$tourism              <- NULL
    Q$access               <- NULL
    Q$bottle               <- NULL
    Q$drinking_water.legal <- NULL
    Q$capacity             <- NULL

    Q <- unique(Q)

    ## replace na with spaces
    for (an in names(Q)) {
      Q[as.vector(is.na(Q[,an])),an] <- ""
    }

    ## create name field from many
    wenames <- c("alt_name", "int_name", "name.el", "name.en", "old_name")
    wenames <- names(Q)[names(Q) %in% wenames]
    for (an in wenames) {
      Q$name <- paste(Q$name, Q[[an]])
    }

    ## clean names
    Q$name <- gsub("[ ]+", " ", Q$name)
    Q$name <- gsub("^[ ]",  "", Q$name)
    Q$name <- gsub("[ ]$",  "", Q$name)

    cnames <- unique(c("..."))
    for (cn in cnames) {
      Q$name <- sub(paste0("^",cn,"$"), "", Q$name, ignore.case = T)
    }

    ## test output
    ss <- data.frame( table(Q$name) )

    ## use desc for empty names
    Q$name[ Q$name == "" ] <- Q$desc[ Q$name == "" ]

    # ## create comments field
    Q$cmt <- ""
    # Q$cmt <- paste(Q$cmt, paste0(Q$amenity,"=",Q$drinking_water))
    # Q$cmt <- paste(Q$cmt, paste0("natural","=",Q$natural))
    # Q$cmt <- paste(Q$cmt, paste0("seasonal","=",Q$seasonal))
    # Q$cmt <- paste(Q$cmt, paste0("thermal","=",Q$thermal))
    # Q$cmt <- paste(Q$cmt, Q$description)
    # Q$cmt <- paste(Q$cmt, Q$description.en)
    # Q$cmt <- paste(Q$cmt, Q$note)
    #
    # Q$cmt <- gsub(" = ",             "", Q$cmt)
    # Q$cmt <- gsub("drinking_water= ","", Q$cmt)
    # Q$cmt <- gsub("natural= ",       "", Q$cmt)
    # Q$cmt <- gsub("seasonal= ",      "", Q$cmt)
    # Q$cmt <- gsub("thermal= ",       "", Q$cmt)
    #
    # Q$cmt <- gsub("[ ]+", " ", Q$cmt)
    # Q$cmt <- gsub("^[ ]",  "", Q$cmt)
    # Q$cmt <- gsub("[ ]$",  "", Q$cmt)


    ## may be better without
    Q$name[Q$name == ""] <- NA
    Q$cmt[Q$cmt   == ""] <- NA
    Q$cmt[Q$desc  == ""] <- NA

    ## test output
    ss <- table(Q$name)

    ## export data
    EXP <- Q[,c("geometry","name","desc","sym","cmt")]
    if (nrow(EXP) > 0) {
      write_sf(EXP, outfile, driver = "GPX", append = F, overwrite = T)
    } else {
      cat("No data to save")
    }
  }

  ## Get drinking water and springs from OSM #################################
  outfile <- paste0("~/GISdata/Layers/Auto/osm/OSM_Drinking_water_springs_",ar,".gpx")

  if (is_file_old(outfile)) {
    cat(paste("Query for drinking water and springs",ar,"\n"))

    q1      <- add_osm_feature(call, key = "amenity", value =  "drinking_water")
    q1      <- osmdata_sf(q1)
    Sys.sleep(delay) ## be polite to server

    q1      <- q1$osm_points
    q1$sym  <- "Drinking Water"
    q1$desc <- "vrisi"
    if (nrow(q1) > 0) {
      saveRDS(q1,"~/GISdata/Layers/Auto/osm/OSM_Drinking_water.Rds")
    } else {
      cat("No data to save")
    }

    q2      <- add_osm_feature(call, key = 'natural', value = 'spring'         )
    q2      <- osmdata_sf(q2)
    Sys.sleep(delay) ## be polite to server

    q2      <- q2$osm_points
    q2$sym  <- "Parachute Area"
    q2$desc <- "pigi"
    if (nrow(q2) > 0) {
      saveRDS(q2, "~/GISdata/Layers/Auto/osm/OSM_Springs.Rds")
    } else {
      cat("No data to save")
    }

    ## combine available water
    wecare <- intersect(names(q1), names(q2))
    Q      <- rbind( q1[wecare], q2[wecare])
    Q      <- unique(Q)
    # Q$geometry <- sf::st_centroid(Q$geometry)

    ## drop fields
    Q$osm_id               <- NULL
    Q$wikipedia            <- NULL
    Q$wikidata             <- NULL
    Q$wheelchair           <- NULL
    Q$addr.city            <- NULL
    Q$created_by           <- NULL
    Q$source               <- NULL
    Q$operator             <- NULL
    Q$historic             <- NULL
    Q$tourism              <- NULL
    Q$access               <- NULL
    Q$bottle               <- NULL
    Q$drinking_water.legal <- NULL

    Q <- unique(Q)

    ## replace na with spaces
    for (an in names(Q)) {
      Q[as.vector(is.na(Q[,an])),an] <- ""
    }

    ## create name field from many
    wenames <- c("alt_name", "int_name", "name.el", "name.en", "old_name")
    wenames <- names(Q)[names(Q) %in% wenames]
    for (an in wenames) {
      Q$name <- paste(Q$name, Q[[an]])
    }

    ## clean names
    Q$name <- gsub("[ ]+", " ", Q$name)
    Q$name <- gsub("^[ ]",  "", Q$name)
    Q$name <- gsub("[ ]$",  "", Q$name)

    table(Q$name)

    cnames <- unique(c("Вода",           "Drinking water",
                       "Çeşme",          "Чешма",
                       "Spring",         "Burim Uji",
                       "Water tap",      "Kuru Çeşme",
                       "Trinkwasser",    "Water",
                       "Drinking Water", "Eau potable",
                       "Eski Çeşme",     "Soğuksu Pınarı",
                       "Source"))
    for (cn in cnames) {
      Q$name <- sub(paste0("^", cn, "$"), "", Q$name, ignore.case = T)
    }

    ## test output
    ss <- data.frame( table(Q$name) )

    ## use desc for empty names
    Q$name[ Q$name == "" ] <- Q$desc[ Q$name == "" ]


    ## create comments field
    Q$cmt <- ""
    Q$cmt <- paste(Q$cmt, paste0(Q$amenity,"=",Q$drinking_water))
    Q$cmt <- paste(Q$cmt, paste0("natural","=",Q$natural))
    Q$cmt <- paste(Q$cmt, paste0("seasonal","=",Q$seasonal))
    Q$cmt <- paste(Q$cmt, paste0("thermal","=",Q$thermal))
    Q$cmt <- paste(Q$cmt, Q$description)
    Q$cmt <- paste(Q$cmt, Q$description.en)
    Q$cmt <- paste(Q$cmt, Q$note)

    Q$cmt <- gsub(" = ",             "", Q$cmt)
    Q$cmt <- gsub("drinking_water= ","", Q$cmt)
    Q$cmt <- gsub("natural= ",       "", Q$cmt)
    Q$cmt <- gsub("seasonal= ",      "", Q$cmt)
    Q$cmt <- gsub("thermal= ",       "", Q$cmt)

    Q$cmt <- gsub("[ ]+", " ", Q$cmt)
    Q$cmt <- gsub("^[ ]",  "", Q$cmt)
    Q$cmt <- gsub("[ ]$",  "", Q$cmt)


    ## may be better without
    Q$name[Q$name  == ""] <- NA
    Q$cmt[ Q$cmt   == ""] <- NA
    Q$cmt[ Q$desc  == ""] <- NA

    ## test output
    ss <- table(Q$name)

    ## export data
    EXP <- Q[, c("geometry","name","desc","sym","cmt")]
    if (nrow(EXP) > 0) {
      write_sf(EXP, outfile, driver = "GPX", append = F, overwrite = T)
    } else {
      cat("No data to save")
    }
  }


  ## Get waterfalls from OSM #################################################
  outfile <- paste0("~/GISdata/Layers/Auto/osm/OSM_Waterfalls_",ar,".gpx")

  if (is_file_old(outfile)) {
    cat(paste("Query for waterfalls",ar,"\n"))

    q1      <- add_osm_feature(call, key = "waterway", value =  "waterfall")
    q1      <- osmdata_sf(q1)
    Sys.sleep(delay) ## be polite to server

    q1      <- q1$osm_points
    q1$sym  <- "Dam"
    q1$desc <- "falls"
    if (nrow(q1) > 0) {
      saveRDS(q1,"~/GISdata/Layers/Auto/osm/OSM_Waterfalls.Rds")
    } else {
      cat("No data to save")
    }

    Q       <- q1
    Q       <- unique(Q)
    # Q$geometry <- sf::st_centroid(Q$geometry)

    Q$osm_id               <- NULL
    Q$wikipedia            <- NULL
    Q$wikidata             <- NULL
    Q$wheelchair           <- NULL
    Q$addr.city            <- NULL
    Q$created_by           <- NULL
    Q$source               <- NULL
    Q$operator             <- NULL
    Q$historic             <- NULL
    Q$tourism              <- NULL
    Q$access               <- NULL
    Q$bottle               <- NULL
    Q$drinking_water.legal <- NULL

    Q <- unique(Q)

    ## replace na with spaces
    for (an in names(Q)) {
      Q[as.vector(is.na(Q[,an])),an] <- ""
    }

    ## create name field
    wenames <- c("alt_name", "int_name", "name.el", "name.en", "old_name")
    wenames <- names(Q)[names(Q) %in% wenames]

    for (an in wenames) {
      Q$name <- paste(Q$name, Q[[an]])
    }

    Q$name <- gsub("[ ]+", " ", Q$name)
    Q$name <- gsub("^[ ]",  "", Q$name)
    Q$name <- gsub("[ ]$",  "", Q$name)

    ## use desc for empty names
    Q$name[ Q$name == "" ] <- Q$desc[ Q$name == "" ]

    Q$cmt <- ""
    # Q$cmt <- paste(Q$cmt, paste0(Q$amenity,"=",Q$drinking_water))
    # Q$cmt <- paste(Q$cmt, paste0("natural","=",Q$natural))
    # Q$cmt <- paste(Q$cmt, paste0("seasonal","=",Q$seasonal))
    # Q$cmt <- paste(Q$cmt, paste0("thermal","=",Q$thermal))
    Q$cmt <- paste(Q$cmt, Q$description    )
    Q$cmt <- paste(Q$cmt, Q$description.en )
    Q$cmt <- paste(Q$cmt, Q$note           )

    Q$cmt <- gsub("[ ]+", " ", Q$cmt)
    Q$cmt <- gsub("^[ ]",  "", Q$cmt)
    Q$cmt <- gsub("[ ]$",  "", Q$cmt)

    ## may be better without
    Q$name[Q$name == ""] <- NA
    Q$cmt[Q$cmt   == ""] <- NA
    Q$cmt[Q$desc  == ""] <- NA

    ss <- table(Q$name)

    ## export data
    EXP <- Q[,c("geometry","name","desc","sym","cmt")]
    if (nrow(EXP) > 0) {
      write_sf(EXP, outfile, driver = "GPX", append = F, overwrite = T)
    } else {
      cat("No data to save")
    }
  }



  ## Get caves #####################################
  outfile <- paste0("~/GISdata/Layers/Auto/osm/OSM_Caves_",ar,".gpx")

  if (is_file_old(outfile)) {
    cat(paste("Query for caves",ar,"\n"))

    # node["natural"="cave"]({{bbox}});
    # node["natural"~"cave"]({{bbox}});
    # node[~"^name(:.*)?$"~"cave",i]({{bbox}});

    q1      <- add_osm_feature(call, key = "natural",      value =  "cave",
                               value_exact = FALSE )
    q1      <- osmdata_sf(q1)
    Sys.sleep(delay) ## be polite to server

    q1      <- q1$osm_points
    q2      <- add_osm_feature(call,   key = "^name(:.*)?$", value =  "cave",
                               value_exact = FALSE, key_exact = FALSE, match_case = FALSE  )
    q2      <- osmdata_sf(q2)
    Sys.sleep(delay) ## be polite to server

    q2      <- q2$osm_points

    wecare  <- intersect(names(q1),names(q2))
    Q       <- rbind( q1[wecare], q2[wecare])
    Q       <- unique(Q)
    # Q$geometry <- sf::st_centroid(Q$geometry)

    Q$sym  <- "Mine"
    Q$desc <- "cave"
    if (nrow(q2) > 0) {
      saveRDS(q2,"~/GISdata/Layers/Auto/osm/OSM_Caves.Rds")
    } else {
      cat("No data to save")
    }

    Q$osm_id               <- NULL
    Q$wikipedia            <- NULL
    Q$wikidata             <- NULL

    Q <- unique(Q)

    ## replace na with spaces
    for (an in names(Q)) {
      Q[as.vector(is.na(Q[,an])),an] <- ""
    }

    grep("name",names(Q), value = T)

    ## create name field from many
    wenames <- c("alt_name", "int_name", "name.el", "name.en", "old_name")
    wenames <- names(Q)[names(Q) %in% wenames]
    for (an in wenames) {
      Q$name <- paste(Q$name, Q[[an]])
    }

    ## clean names
    Q$name <- gsub("[ ]+", " ", Q$name)
    Q$name <- gsub("^[ ]",  "", Q$name)
    Q$name <- gsub("[ ]$",  "", Q$name)

    cnames <- unique(c("Cave",   "Shpellë",
                       "Σπηλιά", "Σπήλαιο"))
    for (cn in cnames) {
      Q$name <- sub(paste0("^",cn,"$"), "", Q$name, ignore.case = T)
    }

    ## use desc for empty names
    Q$name[ Q$name == "" ] <- Q$desc[ Q$name == "" ]

    ss <- table(Q$name)

    Q$cmt <- ""
    Q$cmt <- paste(Q$cmt, Q$description)
    Q$cmt <- paste(Q$cmt, Q$description.en)
    Q$cmt <- paste(Q$cmt, Q$note)

    Q$cmt <- gsub("[ ]+", " ", Q$cmt)
    Q$cmt <- gsub("^[ ]",  "", Q$cmt)
    Q$cmt <- gsub("[ ]$",  "", Q$cmt)

    ## may be better without
    Q$name[Q$name == ""] <- NA
    Q$cmt[Q$cmt   == ""] <- NA
    Q$cmt[Q$desc  == ""] <- NA

    ## export data
    EXP <- Q[,c("geometry","name","desc","sym","cmt")]
    if (nrow(EXP) > 0) {
      write_sf(EXP, outfile, driver = "GPX", append = F, overwrite = T)
    } else {
      cat("No data to save")
    }
  }

}


## another approach
# jsonfl <- "~/GISdata/Layers/Auto/osm/Drinking_water_springs.json"
# sss    <- 'https://overpass-api.de/api/interpreter?data=%5Bout%3Ajson%5D%3B%28node%5B%22amenity%22%3D%22drinking%5Fwater%22%5D%2834%2E976001513176%2C18%2E74267578125%2C41%2E557921577804%2C28%2E2568359375%29%3Bnode%5B%22natural%22%3D%22spring%22%5D%2834%2E976001513176%2C18%2E74267578125%2C41%2E557921577804%2C28%2E2568359375%29%3B%29%3Bout%3B%3E%3Bout%20skel%20qt%3B%0A'
# utils::download.file(url = sss, destfile = jsonfl)
# data <- fromJSON(file = jsonfl)


####_ END _####
tac = Sys.time(); difftime(tac,tic,units="mins")
cat(paste("\n  --  ",  Script.Name, " DONE  --  \n\n"))
cat(sprintf("%s H:%s U:%s S:%s T:%f\n\n",Sys.time(),Sys.info()["nodename"],Sys.info()["login"],Script.Name,difftime(tac,tic,units="mins")))
