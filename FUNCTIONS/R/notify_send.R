
#### An R wrapper of the notify-send command for linux

#' An R wrapper of the `notify-send` command
#'
#' @param summary
#' @param body
#' @param app_name
#' @param action
#' @param urgency
#' @param expire_time
#' @param icon
#' @param category
#' @param hint
#' @param print_id
#' @param replace_id
#' @param wait
#' @param transient
#'
#' @details
#'        notify-send - a program to send desktop notifications
#' SYNOPSIS
#'        notify-send [OPTIONS] {summary} [body]
#' DESCRIPTION
#'        With notify-send you can send desktop notifications to the user via a notification daemon from the
#'        command line. These notifications can be used to inform the user about an event or display some form
#'        of information without getting in the user’s way.
#' OPTIONS
#'        -?, --help
#'            Show help and exit.
#'
#'        -a, --app-name=APP_NAME
#'            Specifies the app name for the notification.
#'
#'        -A, --action=[NAME=]Text...
#'            Specifies the actions to display to the user. Implies --wait to wait for user input. May be set
#'            multiple times. The NAME of the action is output to stdout. If NAME is not specified, the
#'            numerical index of the option is used (starting with 1).
#'
#'        -u, --urgency=LEVEL
#'            Specifies the urgency level (low, normal, critical).
#'
#'        -t, --expire-time=TIME
#'            The duration, in milliseconds, for the notification to appear on screen.
#'
#'            Not all implementations use this parameter. GNOME Shell and Notify OSD always ignore it, while
#'            Plasma ignores it for notifications with the critical urgency level.
#'
#'        -i, --icon=ICON
#'            Specifies an icon filename or stock icon to display.
#'
#'        -c, --category=TYPE[,TYPE...]
#'            Specifies the notification category.
#'
#'        -h, --hint=TYPE:NAME:VALUE
#'            Specifies basic extra data to pass. Valid types are BOOLEAN, INT, DOUBLE, STRING, BYTE and
#'            VARIANT.
#'
#'        -p, --print-id
#'            Print the notification ID.
#'
#'        -r, --replace-id=REPLACE_ID
#'            The ID of the notification to replace.
#'
#'        -w, --wait
#'            Wait for the notification to be closed before exiting. If the expire-time is set, it will be
#'            used as the maximum waiting time.
#'
#'        -e, --transient
#'            Show a transient notification. Transient notifications by-pass the server's persistence
#'            capability, if any. And so it won't be preserved until the user acknowledges it.
#'
#'
#' @return Runs a system command
#' @export
#'
notify_send <- function(summary,
                        body        = NULL,
                        app_name    = NULL,
                        action      = NULL,
                        urgency     = NULL,
                        expire_time = NULL,
                        icon        = NULL,
                        category    = NULL,
                        hint        = NULL,
                        print_id    = FALSE,
                        replace_id  = NULL,
                        wait        = FALSE,
                        transient   = FALSE  ) {
    ## init the command
    command <- "notify-send "
    ## app_name
    if (!is.null(app_name)) command <- c(command, " -a ", app_name)
    ## action
    if (!is.null(action)) warning("\n'notify-send --action' NOT SUPORTED YET")
    ## urgency
    if (sum(urgency %in% c("low", "normal", "critical")) == 1) {
        command <- c(command, " -u ", urgency)
    }
    ## expire_time
    if (is.numeric(expire_time) && expire_time >= 0 ) {
        command <- c(command, " -t ", format(expire_time, scientific = F))
    }
    ## icon
    if (!is.null(icon) && file.exists(icon)) command <- c(command, " -i ", icon)
    ## category
    if (!is.null(category)) warning("\n'notify-send --category' NOT SUPORTED YET")
    ## hint
    if (!is.null(hint)) warning("\n'notify-send --hint' NOT SUPORTED YET")
    ## print_id
    if (print_id) command <- c(command, " -p ")
    ## replace_id
    if (!is.null(replace_id)) warning("\n'notify-send --replace-id' NOT SUPORTED YET")
    ## wait
    if (wait) command <- c(command, " -w ")
    ## transient
    if (transient) command <- c(command, " -e ")
    ## summary is mandatory
    command <- c(command, paste0("\"",summary,"\""))
    ## body
    command <- c(command, paste0("\"",body,"\""))
    ## show command
    cat(command,"\n")
    ## run it
    system(paste(command,collapse = " "))
}

# notify_send(summary = "summary text is here",
#             app_name = "ddd",
#             urgency = "low",
#             print_id = TRUE,
#             transient = T,
#             expire_time = 1000*100)
