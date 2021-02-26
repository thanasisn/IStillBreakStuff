#!/usr/bin/env Rscript

#### Create a timeline of covid-19 development

rm(list = (ls()[ls() != ""]))
Sys.setenv(TZ = "UTC")

library(rvest)
library(data.table)

coro <- fread("https://raw.githubusercontent.com/RamiKrispin/coronavirus/master/csv/coronavirus.csv",  stringsAsFactors = FALSE)

coro      <- data.table(coro)
coro$date <- as.POSIXct(coro$date)

coro <- coro[ country == "Greece" ]
conf <- coro[ type == "confirmed" ]
deat <- coro[ type == "death" ]
reco <- coro[ type == "recovered" ]


dd <- conf
dd$Confirmed.New    <- dd$cases
dd$Confirmed.Total  <- cumsum( dd$Confirmed.New )
dd$Deaths.Total     <- cumsum( deat$cases )
dd$Recoveries.Total <- cumsum( reco$cases )

dd$Active.Total     <- dd$Confirmed.Total - ( dd$Deaths.Total + dd$Recoveries.Total )

dd$removed <- shift( dd$Confirmed.New, n = 14 )


dd$newactive <- dd$Confirmed.New - dd$removed

dd$newactive[ is.na(dd$newactive)] <- 0
# dd$Confirmed.Total[ is.na(dd$Confirmed.Total)] <- 0

dd$aaa <- cumsum( dd$newactive )

## plot only last days
dd <- dd[ dd$date > Sys.time() - 45 * 24 * 3600, ]

if (!any( as.Date(dd$date) == as.Date(Sys.time()) )) {
    ## add today empty
    dd <- rbind(dd, data.table(date = as.POSIXct(as.Date(Sys.time())) ), fill = T)
}




png("/dev/shm/CONKY/corana.png", width = 400, height = 180, units = "px", bg = "transparent")
{
    par(mar = c(2.8,2.0,0,2.0))
    # ylim = range(c(dd$Confirmed.Total,1), na.rm = T)
    # plot(dd$date, dd$Confirmed.Total, "l",
    #      log = "y", xlab = "", ylab = "",
    #      ylim = ylim,
    #      yaxt = 'n', xaxt = "n", bty = "n" , lwd = 8, col = scales::alpha("blue", .7)  )

    # lines(dd$date, dd$Active.Total, lwd = 7, col = scales::alpha("green", .7)  )

    ylim = range(c(dd$aaa,1), na.rm = T)

    plot(dd$date, dd$aaa, "l",
         log = "y", xlab = "", ylab = "",
         ylim = ylim,
         yaxt = 'n', xaxt = "n", bty = "n" , lwd = 8, col = scales::alpha("magenta", .7)  )

    # lines(dd$date, dd$aaa, lwd = 7, col = scales::alpha("magenta", .7)  )

    segments( x0 = as.numeric(dd$date), y0 = 1, y1 = dd$Confirmed.New, lwd = 10, col = scales::alpha("red", .5) )
    axis(2, col = "grey", lwd = 3, col.axis = "grey", font = 2, cex.axis = 1.0)
    axis(4, col = "grey", lwd = 3, col.axis = "grey", font = 2, cex.axis = 1.0)

    axis(4, col = "grey", lwd = 0, col.axis = "white", font = 2, cex.axis = 1.0, at = tail(dd[ !is.na(Confirmed.New), Confirmed.New],1), las = 2, line = -2)
    axis(4, col = "grey", lwd = 0, col.axis = "white", font = 2, cex.axis = 1.0, at = tail(dd[ !is.na(aaa), aaa],1),           las = 2, line = -2)
    axis(4, col = "grey", lwd = 0, col.axis = "white", font = 2, cex.axis = 1.0, at = tail(dd[ !is.na(Confirmed.Total), Confirmed.Total],1), las = 2, line = -2)


    axis.POSIXct(1, at = dd$date, cex.axis = 1.0, col = "grey", lwd = 4,
                 col.axis = "grey", labels = "" )
    axis.POSIXct(1, at = dd$date, cex.axis = 1.0, col = "grey", lwd = 0, line = 0.8,
                 col.axis = "grey", format = "%d\n%m" )
}
dev.off()

