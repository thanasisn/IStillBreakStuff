let
  ## Nix repo for R 4.3.3
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/019f5c29c5afeb215587e17bf1ec31dc1913595b.tar.gz") {};

  ## System packages
  system_packages = builtins.attrValues {
    inherit (pkgs)
      adwaita-qt
      glibcLocales
      nix
      R;
  };

  ## R packages
  rpkgs = builtins.attrValues {
    inherit (pkgs.rPackages)
      ## for rendering
      lintr
      formatR
      knitr
      ## for data analysis
      data_table
      metrica
      dplyr
      ggplot2
      renv
      ;
  };

  ## R packages from github
  git_archive_pkgs = [

   (pkgs.rPackages.buildRPackage {
      name = "colorout";
      src = pkgs.fetchgit {
        url    = "https://github.com/jalvesaq/colorout/";
        rev    = "2a5f21496162ea30684d2783e3a204f4756db4e8";
        sha256 = "sha256-RglnS3QS85598qC87uciW/d64mgeavUDccdXt+GKwFM=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) ;
      };
    })

# 19864453f7d0ed095256d848b46e7b8630989bac

#    (pkgs.rPackages.buildRPackage {
#      name = "duckdb";
#      version = "1.1.2";
#      src = pkgs.fetchgit {
#        url = "https://github.com/duckdb/duckdb-r/";
#        rev = "71c71a6b824bd0f2c0fca43c5dfa53645b17bfb7";
#        sha256 = "sha256-oNrRa0OebsHiUkYl5yDZnpVG+Du5Zhx3fH69vbaRwtk=";
#      };
#      propagatedBuildInputs = builtins.attrValues {
#        inherit (pkgs.rPackages)
#          DBI;
#      };
#    })
   ];

  ## Feed Rstudio with this environment packages
  wrapped_pkgs = pkgs.rstudioWrapper.override {
    packages = [ git_archive_pkgs rpkgs ];
  };

in

pkgs.mkShell {

  LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
  LANG           = "en_US.UTF-8";
  LC_ALL         = "en_US.UTF-8";
  LC_TIME        = "en_US.UTF-8";
  LC_MONETARY    = "en_US.UTF-8";
  LC_PAPER       = "en_US.UTF-8";
  LC_MEASUREMENT = "en_US.UTF-8";

  buildInputs = [ git_archive_pkgs rpkgs  system_packages  wrapped_pkgs ];

  shellHook = ''
    ## for rstudio GUI
    export QT_XCB_GL_INTEGRATION=none
    alias rstudio='setsid rstudio &'
    ## check for dependencies
    Rscript -e "renv::update(check=TRUE)"
  '';

}
