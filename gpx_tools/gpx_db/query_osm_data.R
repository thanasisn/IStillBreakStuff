#!/usr/bin/env Rscript

#### Get data points from OSM using Overpass API


####_ Set environment _####
rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")
tic = Sys.time()
Script.Name = funr::sys.script()
if(!interactive())pdf(file=sub("\\.R$",".pdf",Script.Name))
sink(file=sub("\\.R$",".out",Script.Name,),split=TRUE)
Script.Base = sub("\\.R$","",Script.Name)



library(osmdata)
library(sf)

## work around for
curl::has_internet()
assign("has_internet_via_proxy", TRUE, environment(curl::has_internet))
curl::has_internet()

regions <- c("Gr")

for (ar in regions) {

    ## Region Definitions
    if ( ar == "Gr") {
        abbox <- c(19.34, 34.79, 28.25, 41.77)
        call  <- opq(abbox,  timeout = 1000)
    } else {
        stop(paste("Unknow region",ar))
    }


    ## Get camp sites from OSM #################################################
    outfile <- paste0("~/GISdata/Layers/Auto/osm/OSM_Camp_sites_",ar,".gpx")
    cat(paste("Query for camp sites",ar,"\n"))


    q1      <- add_osm_feature(call, key = "tourism", value =  "camp_site")
    q1      <- osmdata_sf(q1)
    Sys.sleep(20) ## be polite to server
    q1      <- q1$osm_points
    q1$sym  <- "Campground"
    q1$desc <- "camp"
    saveRDS(q1,"~/GISdata/Layers/Auto/osm/OSM_Camp_sites.Rds")

    q2      <- add_osm_feature(call, key = '^name(:.*)?$', value = 'camping',
                               value_exact = FALSE, key_exact = FALSE, match_case = FALSE)
    q2      <- osmdata_sf(q2)
    Sys.sleep(20) ## be polite to server
    q2      <- q2$osm_points
    q2$sym  <- "Campground"
    q2$desc <- "camp"
    saveRDS(q2,"~/GISdata/Layers/Auto/osm/OSM_Camping.Rds")

    wecare <- intersect(names(q1),names(q2))
    Q      <- rbind( q1[wecare], q2[wecare])
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
    write_sf(EXP, outfile, driver = "GPX", append = F, overwrite = T)





    ## Get drinking water and springs from OSM #################################
    outfile <- paste0("~/GISdata/Layers/Auto/osm/OSM_Drinking_water_springs_",ar,".gpx")
    cat(paste("Query for drinking water and springs",ar,"\n"))

    q1      <- add_osm_feature(call, key = "amenity", value =  "drinking_water")
    q1      <- osmdata_sf(q1)
    Sys.sleep(20) ## be polite to server
    q1      <- q1$osm_points
    q1$sym  <-"Drinking Water"
    q1$desc <- "vrisi"
    saveRDS(q1,"~/GISdata/Layers/Auto/osm/OSM_Drinking_water.Rds")
    q2      <- add_osm_feature(call, key = 'natural', value = 'spring'         )
    q2      <- osmdata_sf(q2)
    Sys.sleep(20) ## be polite to server
    q2      <- q2$osm_points
    q2$sym  <-"Parachute Area"
    q2$desc <- "pigi"
    saveRDS(q2,"~/GISdata/Layers/Auto/osm/OSM_Springs.Rds")

    ## combine available water
    wecare <- intersect(names(q1),names(q2))
    Q      <- rbind( q1[wecare], q2[wecare])

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

    cnames <- unique(c("Вода",           "Drinking water",
                       "Çeşme",          "Чешма",
                       "Spring",         "Burim Uji",
                       "Water tap",      "Kuru Çeşme",
                       "Trinkwasser",    "Water",
                       "Drinking Water", "Eau potable",
                       "Eski Çeşme",     "Soğuksu Pınarı",
                       "Source"))
    for (cn in cnames) {
        Q$name <- sub(paste0("^",cn,"$"), "", Q$name, ignore.case = T)
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
    Q$name[Q$name == ""] <- NA
    Q$cmt[Q$cmt   == ""] <- NA
    Q$cmt[Q$desc  == ""] <- NA

    ## test output
    ss <- table(Q$name)

    ## export data
    EXP <- Q[,c("geometry","name","desc","sym","cmt")]
    write_sf(EXP, outfile, driver = "GPX", append = F, overwrite = T)




    ## Get waterfalls from OSM #################################################
    outfile <- paste0("~/GISdata/Layers/Auto/osm/OSM_Waterfalls_",ar,".gpx")
    cat(paste("Query for waterfalls",ar,"\n"))

    q1      <- add_osm_feature(call, key = "waterway", value =  "waterfall")
    q1      <- osmdata_sf(q1)
    Sys.sleep(20) ## be polite to server
    q1      <- q1$osm_points
    q1$sym  <-"Dam"
    q1$desc <- "falls"
    saveRDS(q1,"~/GISdata/Layers/Auto/osm/OSM_Waterfalls.Rds")

    Q <-    q1

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
    write_sf(EXP, outfile, driver = "GPX", append = F, overwrite = T)





    ## Get caves #####################################
    outfile <- paste0("~/GISdata/Layers/Auto/osm/OSM_Caves_",ar,".gpx")
    cat(paste("Query for caves",ar,"\n"))

    # node["natural"="cave"]({{bbox}});
    # node["natural"~"cave"]({{bbox}});
    # node[~"^name(:.*)?$"~"cave",i]({{bbox}});

    q1      <- add_osm_feature(call, key = "natural",      value =  "cave",
                               value_exact = FALSE )
    q1      <- osmdata_sf(q1)
    Sys.sleep(20) ## be polite to server
    q1      <- q1$osm_points
    q2      <- add_osm_feature(call,   key = "^name(:.*)?$", value =  "cave",
                               value_exact = FALSE, key_exact = FALSE, match_case = FALSE  )
    q2      <- osmdata_sf(q2)
    Sys.sleep(20) ## be polite to server
    q2      <- q2$osm_points

    wecare  <- intersect(names(q1),names(q2))
    Q       <- rbind( q1[wecare], q2[wecare])

    Q$sym  <- "Mine"
    Q$desc <- "cave"

    saveRDS(q2,"~/GISdata/Layers/Auto/osm/OSM_Caves.Rds")


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

    ss<-table(Q$name)

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
    write_sf(EXP, outfile, driver = "GPX", append = F, overwrite = T)

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
