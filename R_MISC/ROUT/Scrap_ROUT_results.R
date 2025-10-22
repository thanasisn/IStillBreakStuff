
library(XML)
library(httr)
library(chron)
library(dplyr)
library(readODS)

years <- 2015:2025
year  <- 2024
year  <- 2025

theurl <- paste0("http://www.rout.gr/index.php?name=Rout&file=results&year=", year)
#theurl <- "http://www.rout.gr/index.php?name=Rout&file=results_printer&year=2011&order=final_a&race=rout"

doc <- htmlParse(GET(theurl, user_agent("Mozilla")))
removeNodes(getNodeSet(doc,"//*/comment()"))

test <- readHTMLTable(doc,header=F)

names3   <- as.matrix(test$table_results_h_1)
names4   <- as.matrix(test$table_results_h_2)
names    <- c(names3[1,],names4[1,])
names    <- unname(names)
stathmoi <- regmatches(names[8:32],gregexpr("K-[0-9]*",names[8:32]))
kmark    <- as.numeric(substr(stathmoi,3,5))
kmarks   <- append(kmark,164)

all.data2 <- data.frame(test$table_results_r_1,test$table_results_r_2)

# all.data2[,c(5,8:25)]
# as.matrix((all.data2[,c(8:25)]))
# strsplit(as.matrix((all.data2[,c(8:25)])),split=".",fixed=T)
# sapply(sapply(X=all.data2[,c(8:25)],as.character),strsplit,split=".",fixed=T)

# ddd <- as.data.frame(t(as.matrix(all.data2)[c(1:42),c(5,8:25)]))

# dum <- data.frame(test$table_results_r_2[1:35,1:25])
# dum <- as.matrix(data.frame(test$table_results_r_2[1:35,1:25]))
# dum <- as.numeric(dum)
# dum <- matrix(dum,nrow=35)

## add names to data frame
names(all.data2) <- c(names3, names4)

all.data2[all.data2 == ""] <- NA

all.data2 <- janitor::remove_empty(all.data2, "cols")

hh.mm_to_minutes <- function(x) {
  as.numeric(x) * 60
}

hh.mm.ss_to_minutes <- function(time_string) {
  # Handle vector input
  sapply(time_string, function(x) {
    if(is.na(x) || x == "" || x == "NA") return(NA)

    # Remove any whitespace
    x <- trimws(x)

    time_parts <- strsplit(x, "\\.")[[1]]

    # Check format
    if(length(time_parts) != 3) {
      warning(paste("Invalid time format. Expected hh.mm.ss, got:", x))
      return(NA)
    }

    # Convert to numeric
    hours <- as.numeric(time_parts[1])
    minutes <- as.numeric(time_parts[2])
    seconds <- as.numeric(time_parts[3])

    # Validate numeric conversion
    if(any(is.na(c(hours, minutes, seconds)))) {
      warning(paste("Non-numeric time value:", x))
      return(NA)
    }

    # Validate time ranges
    if(minutes >= 60 | seconds >= 60) {
      warning(paste("Invalid time values (minutes/seconds >= 60):", x))
      return(NA)
    }

    # Calculate total minutes
    total_minutes <- hours * 60 + minutes + seconds / 60
    return(total_minutes)
  }, USE.NAMES = FALSE)
}

## convert intermediate times
all.data2 <- all.data2 |>
  mutate_at(vars(contains("CP-")), hh.mm_to_minutes)

all.data2 <- all.data2 |>
  mutate_at(vars(`K-181Χαϊντού`), hh.mm.ss_to_minutes)

print(all.data2)

## export data
write_ods(all.data2, paste0("~/Documents/Running/ROUT results/ROUT_", year, ".ods"))
