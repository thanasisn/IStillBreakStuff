
##
##  Trigonometric Functions with degrees
##


sinde   <- function(x)       sinpi( x / 180 )
cosde   <- function(x)       cospi( x / 180 )
tande   <- function(x)       sinpi( x / 180) / cospi( x / 180)
cotde   <- function(x)       1 / tand( x )

asinde  <- function(x)       asin( x ) * 180 / pi
acosde  <- function(x)       acos( x ) * 180 / pi
atande  <- function(x)       atan( x ) * 180 / pi
acotde  <- function(x)       atand( 1 / x )

atan2de <- function(x1, x2)  atan2( x1, x2 ) * 180 / pi

secde   <- function(x)   1 / cosd( x )
cscde   <- function(x)   1 / sind( x )
asecde  <- function(x)       asec( x ) * 180 / pi
acscde  <- function(x)       acsc( x ) * 180 / pi


