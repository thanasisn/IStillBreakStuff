# /* #!/usr/bin/env Rscript */
# /* Copyright (C) 2025 Athanasios Natsis <natsisphysicist@gmail.com> */
#' ---
#' title:  "`r format(Sys.time(), '%F %T')`"
#' author: ""
#' output:
#'   html_document:
#'     toc: true
#'     fig_width:  6
#'     fig_height: 4
#'     keep_md:    no
#' date: ""
#' ---

#+ echo=F, include=T
rm(list = (ls()[ls() != ""]))
Script.Name <- "utilities_parse.R"
dir.create("./runtime/", showWarnings = FALSE)
Sys.setenv(TZ = "UTC")
tic <- Sys.time()

## __ Document options ---------------------------------------------------------
knitr::opts_chunk$set(out.width  = "100%"   )

## __  Set environment ---------------------------------------------------------
suppressMessages({
  library(data.table, quietly = TRUE, warn.conflicts = FALSE)
  library(janitor,    quietly = TRUE, warn.conflicts = FALSE)
  library(ggplot2,    quietly = TRUE, warn.conflicts = FALSE)
  library(plotly,     quietly = TRUE, warn.conflicts = FALSE)
})

datadir <- "~/Documents/My_xls/data"

#+ include=FALSE, echo=FALSE
## init use of ggplot and html tables in loops
tagList(datatable(cars))
tagList(ggplotly(ggplot()))


##  Water  ------------------------------------------------------------
#'
#' `r cat(paste("# ", Sys.time()), "\n")`
#'
#' ## Water
#'
#+ echo=F, include=T, fig.width=6, fig.height=6, results = "asis"

readO <- paste0(datadir, "/utilities_water.ods")


stop()

AP <- AP[emeromenia_demoprasias > Sys.Date() - 12 * 32 * 2]
AP$duration_weeks <- factor(AP$duration_weeks)

p <- ggplot(data = AP, aes(x = emeromenia_demoprasias)) +
  geom_point(aes(y = apodose, colour = duration_weeks)) +
  geom_line(aes(y = apodose, colour = duration_weeks), linewidth = 0.2) +
  geom_hline(aes(yintercept = upper_limit), color = "blue", linetype = "dashed") +
  geom_vline(aes(xintercept = as.numeric(Sys.Date())), color = "green", linetype = "dotted") +
  xlab("") + ylab("") +
  theme_linedraw() +
  theme(legend.position = "bottom") +
  theme(legend.title = element_blank()) +
  scale_x_date(
    minor_breaks = seq.Date(lubridate::round_date(min(AP$emeromenia_demoprasias), unit = "year"),
                            max(AP$emeromenia_demoprasias), by = "1 months")
  )


if (length(next_4) > 0) {
  p <- p + geom_vline(aes(xintercept = min(as.numeric((next_4))),  colour = "4" ), linetype = "dotted") +
    geom_line(data = data.frame(x = NX4, y = predict(LM2_4, newdata = list(emeromenia_demoprasias = NX4))),
              aes(x = x, y = y, colour = "4")
    ) +
    geom_line(data = data.frame(x = NX4, y = predict(LM1_4, newdata = list(emeromenia_demoprasias = NX4))),
              aes(x = x, y = y, colour = "4"),
              linetype = "dotted"
    )
}

if (length(next_13) > 0) {
  p <- p + geom_vline(aes(xintercept = min(as.numeric((next_13))), colour = "13"), linetype = "dotted") +
    geom_line(data = data.frame(x = NX13, y = predict(LM2_13, newdata = list(emeromenia_demoprasias = NX13))),
              aes(x = x, y = y, colour = "13")
    ) +
    geom_line(data = data.frame(x = NX13, y = predict(LM1_13, newdata = list(emeromenia_demoprasias = NX13))),
              aes(x = x, y = y, colour = "13"),
              linetype = "dotted"
    )
}

if (length(next_26) > 0) {
  p <- p + geom_vline(aes(xintercept = min(as.numeric((next_26))), colour = "26"), linetype = "dotted") +
    geom_line(data = data.frame(x = NX26, y = predict(LM2_26, newdata = list(emeromenia_demoprasias = NX26))),
              aes(x = x, y = y, colour = "26")
    ) +
    geom_line(data = data.frame(x = NX26, y = predict(LM1_26, newdata = list(emeromenia_demoprasias = NX26))),
              aes(x = x, y = y, colour = "26"),
              linetype = "dotted"
    )
}

if (length(next_52) > 0) {
  p <- p + geom_vline(aes(xintercept = min(as.numeric((next_52))), colour = "52"), linetype = "dotted") +
    geom_line(data = data.frame(x = NX52, y = predict(LM2_52, newdata = list(emeromenia_demoprasias = NX52))),
              aes(x = x, y = y, colour = "52")
    ) +
    geom_line(data = data.frame(x = NX52, y = predict(LM1_52, newdata = list(emeromenia_demoprasias = NX52))),
              aes(x = x, y = y, colour = "52"),
              linetype = "dotted"
    )
}


if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}

if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}



##  Επιτόκια  ------------------------------------------------------------------
#'
#' ## Επιτόκια
#'
#+ echo=F, include=T, fig.width=6, fig.height=6, results="asis"

dur <- 12
ttt <- tsig[Set == "Greece" & Months <= dur ]
ttt <- ttt[Interest > quantile(Interest, .60) ]

## remove old results
ttt <- ttt[Sys.Date() - Scraped <= inter_old_limit]

## add online accounts
# tts <- tsig[Set != "Greece" & (Months <= dur | is.na(Months) ) ]
# tts <- tts[Interest > quantile(Interest, .50) ]
# ttt <- rbind(ttt, tts)


# ttt <- ttt[!duplicated(ttt[, .(Bank, Duration, Name, Interest, Update, Min)], fromLast = TRUE), ]

p <- ggplot(ttt, aes(x = Scraped, y = Interest * int_tax,
                colour = Bank, shape = Duration,
              group = interaction(Bank, Duration))) +
  geom_point() +
  geom_line() +
  theme_linedraw()

if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(p))
}

if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(p)
}


## get last scrapped
ttt <- ttt[Scraped == max(Scraped)]

test <- ttt[ , .(I_fc = max(Interest)), by = .(Months, Min)]
test[ , I_ef := I_fc * int_tax]
test$Type <- "Προθεσμιακές"

gathO <- data.frame()
if (length(next_4) > 0) {
  gathO <- rbind(
    gathO,
    data.table(
      Start      = min(next_4),
      End        = min(next_4) + 4 * 7,
      Months     = 1,
      Weeks      = 4,
      Cap        = value,
      Type       = "Εντ Ομολ Γρ",
      I_ef = predict(LM1_4, newdata = list(emeromenia_demoprasias = min(next_4)))
    ),
    data.table(
      Start      = next_4,
      End        = next_4 + 4 * 7,
      Months     = 1,
      Weeks      = 4,
      Cap        = value,
      Type       = "Εντ Ομολ",
      I_ef = predict(LM2_4, newdata = list(emeromenia_demoprasias = next_4))
    )
  )
}

if (length(next_13) > 0) {
  gathO <- rbind(
    gathO,
    data.table(
      Start      = min(next_13),
      End        = min(next_13) + 13 * 7,
      Months     = 3,
      Weeks      = 13,
      Cap        = value,
      Type       = "Εντ Ομολ Γρ",
      I_ef = predict(LM1_13, newdata = list(emeromenia_demoprasias = min(next_13)))
    ),
    data.table(
      Start      = next_13,
      End        = next_13 + 13 * 7,
      Months     = 3,
      Weeks      = 13,
      Cap        = value,
      Type       = "Εντ Ομολ",
      I_ef = predict(LM2_13, newdata = list(emeromenia_demoprasias = next_13))
    )
  )
}

if (length(next_26) > 0) {
  gathO <- rbind(
    gathO,
    data.table(
      Start      = min(next_26),
      End        = min(next_26) + 26 * 7,
      Months     = 6,
      Weeks      = 26,
      Cap        = value,
      Type       = "Εντ Ομολ Γρ",
      I_ef = predict(LM1_26, newdata = list(emeromenia_demoprasias = min(next_26)))
    ),
    data.table(
      Start      = next_26,
      End        = next_26 + 26 * 7,
      Months     = 6,
      Weeks      = 26,
      Cap        = value,
      Type       = "Εντ Ομολ",
      I_ef = predict(LM2_26, newdata = list(emeromenia_demoprasias = next_26))
    )
  )
}


if (length(next_52) > 0) {
  gathO <- rbind(
    gathO,
    data.table(
      Start      = min(next_52),
      End        = min(next_52) + 52 * 7,
      Months     = 12,
      Weeks      = 52,
      Cap        = value,
      Type       = "Εντ Ομολ Γρ",
      I_ef = predict(LM1_52, newdata = list(emeromenia_demoprasias = min(next_52)))
    ),
    data.table(
      Start      = next_52,
      End        = next_52 + 52 * 7,
      Months     = 12,
      Weeks      = 52,
      Cap        = value,
      Type       = "Εντ Ομολ",
      I_ef  = predict(LM2_52, newdata = list(emeromenia_demoprasias = next_52))
    )
  )
}

gathO[, Inc  := round(Cap * (I_ef/52) * Weeks / 100, 1) ]
gathO[, I_ef := round(I_ef, 2)]

gathO[, Start := Start + 2]
gathO[, End   := End   + 2]



capitals <- data.table(
  Cap = c(
    value,
    total_cap,
    total_cap -     value,
    total_cap - 2 * value
  )
)
capitals <- unique(capitals[Cap > 1000])


test <- dplyr::cross_join(test, capitals)
test <- data.table(test)
test <- test[Cap > Min]

test[, Int_p_m := (I_ef / 12) * Months]
test[, Inc     := round(Cap * Int_p_m / 100, 2)]
test[, Start   := Sys.Date()  ]
test[, End     := Sys.Date() %m+% months(Months) ]


test$Int_p_m <- NULL
gathO$Weeks  <- NULL

## use only next values



test <- rbind(
  test,
  gathO |> group_by(Months, Type) |>
    filter(Start == min(Start))   ,
  fill = T
)

test <- test[Start >= Sys.Date()]

test[, P_m := round(Inc/Months, 1) ]

setorder(test, -I_ef, Cap)



print(
  htmltools::tagList(
    datatable(test,
              rownames = FALSE,
              options = list(pageLength = 30),
              style = 'bootstrap',
              class = 'table-bordered table-condensed')
  )
)



##  Τοποθετήσεις  --------------------------------------------------------------
#'
#' ## Τοποθετήσεις
#'
#+ echo=F, include=T, fig.width=6, fig.height=6, results="asis"

## select packets
fut <- ENT[is.na(apodose)]
# fut <- fut[duration_weeks < 50,]
fut <- remove_empty(fut, which = "cols")
fut$parsed <- NULL

fut <- fut[emeromenia_demoprasias > Sys.Date()]


fut[, emeromenia_ekdoses := emeromenia_demoprasias + 2 ]
fut[, lexe := emeromenia_ekdoses + 7 * duration_weeks ]
setorder(fut, -emeromenia_demoprasias)
fut[, duration_weeks := factor(duration_weeks)]
fut[, index := .I]



## create steps
timeline <- rbind(
  fut[, .(date = emeromenia_ekdoses, val = -value, note = "ekdosi", index), ],
  fut[, .(date = lexe,               val = +value, note = "lexe"  , index) ]
)



## test
extra <- data.frame(
  date  = c(Sys.Date() + 1, Sys.Date() %m+% months(4)) + 1,
  val   = c(-total_cap, total_cap*(1+upper_limit/100/12*4)),
  note  = c("ekdosi", "lexe"),
  index = max(timeline$index) + 1
)

timeline <- rbind(timeline, extra)

timeline <- rbind(timeline, done, fill = T)


## add tamieutirio
# extra2 <- data.frame(
#   emeromenia_demoprasias = Sys.Date(),
#   emeromenia_ekdoses = Sys.Date() + 1,
#   duration_weeks     = 4*(52/12),
#   lexe               = Sys.Date() %m+% months(4) + 1,
#   index              = max(fut$index) + 1
# )
# fut <- rbind(fut, extra2)




## compute next steps

## compute available plus placements
starting <- sum(total_cap, done[val < 0, -val]) + boulas


timeline <- rbind(
  timeline,
  data.table(
    date = min(timeline$date) - 1, val = starting, note = "start"
  ), fill = T
)
setorder(timeline, date)

timeline$budget   <- starting

## do nothing
timeline[is.na(index), do_nothing := cumsum(val)]
timeline$do_nothing <- zoo::na.locf(timeline$do_nothing)

## do everything
timeline[, do_all := cumsum(val)]

## do possible
for (n in 2:nrow(timeline)) {
  res <- timeline[n-1, budget] + timeline[n, val]
  # cat(paste(timeline[n]), res, "\n")
  if (res <= 0) {
    timeline[n , val := val - res]
    timeline[index == timeline[n, index] & val>0, val := -timeline[n , val]]
  }
  timeline[n, budget := timeline[n-1, budget] + timeline[n, val]]
}

## scale for plog only
ascale <- max(timeline$budget) / max(fut$index)

basewidh = 0.4
d <- ggplot() +
  geom_segment(
    data = fut,
    mapping =
      aes(x    = emeromenia_ekdoses, y    = index * ascale,
          xend = lexe,               yend = index * ascale,
          colour = duration_weeks), linewidth = 19 * basewidh) +
  geom_step(data = timeline, aes(x = date, y = do_nothing), colour = "black"  , linewidth = 14 * basewidh) +
  geom_step(data = timeline, aes(x = date, y = do_all),     colour = "magenta", linewidth =  9 * basewidh) +
  geom_step(data = timeline, aes(x = date, y = budget),     colour = "cyan"   , linewidth =  3 * basewidh) +
  geom_vline(aes(xintercept = Sys.Date()), linetype = "dotted", col = "red"   , linewidth =  3 * basewidh) +
  xlab("") + ylab("") +
  theme_linedraw() +
  scale_x_date(
    minor_breaks = seq.Date(lubridate::floor_date(min(fut$emeromenia_demoprasias), unit = "month"),
                            max(fut$emeromenia_demoprasias), by = "1 months")
  ) +
  theme(legend.position = "bottom") +
  theme(legend.title = element_blank()) +


## display plot conditionaly
if (!isTRUE(getOption('knitr.in.progress'))) {
  suppressWarnings(print(d))
}

if (interactive() | isTRUE(getOption('knitr.in.progress'))) {
  ggplotly(d)
}


cat(paste0("**Future profit: ",
           done[, sum(val)], ", ",
           done[, round(sum(val) / as.numeric(difftime(range(date)[2], range(date)[1], units = "days") / 30))],
           "e/month**"),"\n\n" )

show(d)

print(
  htmltools::tagList(
    datatable(timeline[is.na(note) & date > Sys.Date() - 10,
                       .(Date      = date,
                         Value     = val,
                         Available = do_nothing)],
              rownames = FALSE,
              options = list(pageLength = 30),
              style = 'bootstrap',
              class = 'table-bordered table-condensed')
  )
)


## calculate potential with exponential moving average

short <-  3
long  <- 15

plot(
  EMA(ENT[duration_weeks == 26 & !is.na(apodose), apodose], n = short),
  col = "red",
  type = "l"
)
lines(
  EMA(ENT[duration_weeks == 26 & !is.na(apodose), apodose], n = long), col = "blue"
)

plot(
  EMA(ENT[duration_weeks == 13 & !is.na(apodose), apodose], n = short),
  col = "red",
  type = "l"
)
lines(
  EMA(ENT[duration_weeks == 13 & !is.na(apodose), apodose], n = long),
  col = "blue"
)


#+ include=T, echo=F
#'
#' - [tsig.gr](https://tsig.gr/prothesmiakes?bank=&telestis=έως&duration=&amount=80000)
#' - [Προγραμμα δανεισμου](https://www.pdma.gr/el/debt-instruments-gr/2012-02-24-17-12-01/προγραμμα-δανεισμου)
#' - [Ιστορικό 4 εβδομάδων](https://www.pdma.gr/el/debt-instruments-gr/2012-02-24-17-12-01/ιστορικοτητα-εντοκων/4-εβδομαδων)
#' - [Ιστορικό 13 εβδομάδων](https://www.pdma.gr/el/debt-instruments-gr/2012-02-24-17-12-01/ιστορικοτητα-εντοκων/13-εβδομαδων)
#' - [Ιστορικό 26 εβδομάδων](https://www.pdma.gr/el/debt-instruments-gr/2012-02-24-17-12-01/ιστορικοτητα-εντοκων/26-εβδομαδων)
#' - [Ιστορικό 52 εβδομάδων](https://www.pdma.gr/el/debt-instruments-gr/2012-02-24-17-12-01/ιστορικοτητα-εντοκων/52-εβδομαδων)
#'

#+ include=T, echo=F, results="asis"
tac <- Sys.time()
cat(sprintf("**END** %s %s@%s %s %f mins\n\n", Sys.time(), Sys.info()["login"],
            Sys.info()["nodename"], basename(Script.Name), difftime(tac,tic,units = "mins")))
