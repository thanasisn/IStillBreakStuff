let
  ## Nix repo for R 4.3.3
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/019f5c29c5afeb215587e17bf1ec31dc1913595b.tar.gz") {};
  ## Nix repo for R 4.2.3
  # pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2023-04-01.tar.gz") {};

  ## System packages
  system_packages = builtins.attrValues {
    inherit (pkgs)
      adwaita-qt
      glibcLocales
      nix
      python310
      R;
  };

  pypkgs = builtins.attrValues {
    inherit (pkgs.python310Packages)
     numpy
     tendo
      ;
  };

  ## R packages
  rpkgs = builtins.attrValues {
    inherit (pkgs.rPackages)
      Hmisc
      fs
      gdata
      lintr
      optparse
      rlang
      stringr
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

#   (pkgs.rPackages.buildRPackage {
#       name = "duckdb";
#       version = "1.2.0";
#       src = pkgs.fetchgit {
#         url = "https://github.com/duckdb/duckdb-r/";
#         rev = "d7b7108c2e526fa125669439cabc179021585d43";
#         sha256 = "sha256-ksk9QBiiZlleWxdidO41ppu3juREGCeEcE6Q2SlQM50=";
#       };
#       propagatedBuildInputs = builtins.attrValues {
#         inherit (pkgs.rPackages)
#           DBI;
#       };
#     })

   ];



  ## Feed Rstudio with this environment packages
  wrapped_pkgs = pkgs.rstudioWrapper.override {
    packages = [ git_archive_pkgs rpkgs pypkgs system_packages ];
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

  buildInputs = [ git_archive_pkgs rpkgs  system_packages  wrapped_pkgs pypkgs ];
 
  ## something like this for rstudio?
  # https://github.com/NixOS/nixpkgs/issues/61144
  #shellHook = ''
  #   export PYTHONPATH="${tarPyPacks}/lib/python3.7:${tarPyPacks}/lib/python3.7/site-packages"
  # '';
  shellHook = ''
    ## for rstudio GUI
    export QT_XCB_GL_INTEGRATION=none
    alias rstudio='setsid rstudio &'
    ## check for dependencies
    Rscript -e "old.packages(repos='https://cran.rstudio.com', checkBuilt=FALSE)"
    echo "Show recomendation"
  '';

}
