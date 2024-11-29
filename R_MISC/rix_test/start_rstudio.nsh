#!/usr/bin/env nix-shell
#### Drop in this project environment
#!nix-shell /home/athan/CODE/R_MISC/rix_test/default.nix -i bash

## Start rstudio for this project
export QT_XCB_GL_INTEGRATION=none
export GTK_THEME=Adwaita:dark
setsid env GTK_THEME=Adwaita:dark rstudio &
