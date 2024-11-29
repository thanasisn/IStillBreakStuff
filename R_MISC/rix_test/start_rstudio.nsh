#!/usr/bin/env nix-shell
#!nix-shell /home/athan/CODE/R_MISC/rix_test/default.nix -i bash
export QT_XCB_GL_INTEGRATION=none
export GTK_THEME=Adwaita:dark
env GTK_THEME=Adwaita:dark rstudio &
