#!/bin/bash
## created on 2013-05-07
## https://github.com/thanasisn <lapauththanasis@gmail.com>

#### Auto commit and push all git repos

exec 9>"/dev/shm/$(basename $0).lock"
if ! flock -n 9  ; then
    echo "another instance of $0 is running";
    exit 1
fi

info() { echo "$(date +%F_%T) ${SECONDS}s :: $* ::" >&1; }
LOG_FILE="/dev/shm/$(basename "$0")_$(date +%F).log"
ERR_FILE="/dev/shm/$(basename "$0")_$(date +%F).err"
touch "$LOG_FILE" "$ERR_FILE"
exec  > >(tee -i "${LOG_FILE}")
exec 2> >(tee -i "${ERR_FILE}" >&2)
trap 'echo $( date +%F_%T ) ${SECONDS}s :: $0 interrupted ::  >&2;' INT TERM
info "START :: $0 :: $* ::"

set +e


##  COMMIT PUSH to github repos  ###############################################

## The following do not add files to git automatically

## this works only on tyler
echo "DOTFILES"
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" commit -uno -a -m "Commit $(date +'%F %R')"
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" push -u origin master



echo "---------------"
cd "$HOME/CODE/"
pwd
git commit -uno -a -m "Commit $(date +'%F %R')"
git push -f -u origin main



echo "---------------"
cd "$HOME/CODE/R_myRtools/myRtools"
pwd
git commit -uno -a -m "Commit $(date +'%F %R')"
git push -f -u origin main



echo "---------------"
cd "$HOME/CODE/R_POLAr/POLAr/"
pwd
git commit -uno -a -m "Commit $(date +'%F %R')"
git push -f -u origin master



echo "---------------"
cd "$HOME/CODE/deploy/"
pwd
git commit -uno -a -m "Commit $(date +'%F %R')"
git push -f -u origin main



echo "---------------"
cd "$HOME/PANDOC/Deployment_notes"
cd "./_book"
ln -f ./Deployment_notes.html ./index.html
git add -f .
cd ".."
pwd
git commit -uno -a -m "Commit $(date +'%F %R')"
git push -f -u origin main



echo "---------------"
cd "$HOME/PANDOC/Libradtran_guide"
cd "./_book"
ln -f ./Libratran_guide.html ./index.html
git add -f .
cd ".."
pwd
git commit -uno -a -m "Commit $(date +'%F %R')"
git push -f -u origin main



echo "---------------"
cd "$HOME/PANDOC/CHP1_measurements_guide"
cd "./_book"
ln -f ./CHP1_measurements_guide.html ./index.html
git add -f .
cd ".."
pwd
git commit -uno -a -m "Commit $(date +'%F %R')"
## will include to thesis
git push -f -u origin main



echo "---------------"
cd "$HOME/PANDOC/Tracker_manual"
cd "./_book"
ln -f ./LAP_tracker_manual.html ./index.html
git add -f .
cd ".."
pwd
git commit -uno -a -m "Commit $(date +'%F %R')"
git push -f -u origin main




echo "---------------"
cd "$HOME/PANDOC/thanasisnsite"
git add -f .
cd "./public"
git add -f .
cd ".."
cd "./static"
git add -f .
cd ".."
cd "./themes"
git add -f .
cd ".."
pwd
git commit -uno -a -m "Commit $(date +'%F %R')"
git push -f -u origin main



####  Automatically commit to github  ################################

## use full paths
folders=(
    "$HOME/CHP_1_DIR/"
    "$HOME/CM_21_GLB/"
    "$HOME/CS_id/"
    "$HOME/PANDOC/Thesis"
    "$HOME/RAD_QC"
    "$HOME/SUN"
    "$HOME/TSI"
)

## go through main folder
for i in "${folders[@]}"; do
    echo
    info " $i "
    echo
    [ ! -d "$i" ] && echo "Not a folder: $i" && continue
    ## go through sub folders
    cd "$i" || return
    ## in the git folder here
    pwd
    ## add files we care about
    find . -type f \(    -iname '*.bas'      \
                      -o -iname '*.bib'      \
                      -o -iname '*.c'        \
                      -o -iname '*.conf'     \
                      -o -iname '*.cpp'      \
                      -o -iname '*.cs'       \
                      -o -iname '*.css'      \
                      -o -iname '*.dia'      \
                      -o -iname '*.dot'      \
                      -o -iname '*.ex'       \
                      -o -iname '*.f90'      \
                      -o -iname '*.frm'      \
                      -o -iname '*.gnu'      \
                      -o -iname '*.gp'       \
                      -o -iname '*.h'        \
                      -o -iname '*.jl'       \
                      -o -iname '*.list'     \
                      -o -iname '*.makefile' \
                      -o -iname '*.md'       \
                      -o -iname '*.par'      \
                      -o -iname '*.pbs'      \
                      -o -iname '*.py'       \
                      -o -iname '*.qgs'      \
                      -o -iname '*.qmd'      \
                      -o -iname '*.r'        \
                      -o -iname '*.rmd'      \
                      -o -iname '*.sh'       \
                      -o -iname '*.tex'      \
                      -o -iname '*.txt'      \) -print0 |\
                  xargs -t -0 git add -f
    ## commit and push
    git commit -uno -a -m "Commit $(date +'%F %R')"
    git push -f
done












##  COMMIT PUSH to local repos  ################################################


## use full paths
folders=(
    "$HOME/Aerosols/"
    "$HOME/BASH/"
    "$HOME/Ecotime_machine/Scripts/"
    "$HOME/Improved_Aerosols_O3/"
    "$HOME/MISC/Redmi7_internal/documents"
    "$HOME/PANDOC/Journal/"
    "$HOME/PANDOC/Notes/"
    "$HOME/PANDOC/Notes_Aerosols/"
    "$HOME/PROJECTS/"
    "$HOME/PROJECTS/UVindex_Production/"
    "$HOME/PYTHON2/"
    "$HOME/PYTHON3/"
    "$HOME/TEX/"
)

## go through main folder
for i in "${folders[@]}"; do
    echo
    info " $i "
    echo
    [ ! -d "$i" ] && echo "Not a folder: $i" && continue
    ## go through sub folders
    cd "$i" || return
    ## in the git folder here
    pwd
    ## always break lock
    rm -f "${i}/.git/index.lock"
    ## add files we care about
    find . -type f \(    -iname '*.bas'      \
                      -o -iname '*.bib'      \
                      -o -iname '*.c'        \
                      -o -iname '*.conf'     \
                      -o -iname '*.cpp'      \
                      -o -iname '*.cs'       \
                      -o -iname '*.css'      \
                      -o -iname '*.dia'      \
                      -o -iname '*.dot'      \
                      -o -iname '*.ex'       \
                      -o -iname '*.f90'      \
                      -o -iname '*.frm'      \
                      -o -iname '*.gnu'      \
                      -o -iname '*.gp'       \
                      -o -iname '*.h'        \
                      -o -iname '*.jl'       \
                      -o -iname '*.list'     \
                      -o -iname '*.makefile' \
                      -o -iname '*.md'       \
                      -o -iname '*.par'      \
                      -o -iname '*.pbs'      \
                      -o -iname '*.py'       \
                      -o -iname '*.qgs'      \
                      -o -iname '*.qmd'      \
                      -o -iname '*.r'        \
                      -o -iname '*.rmd'      \
                      -o -iname '*.sh'       \
                      -o -iname '*.tex'      \
                      -o -iname '*.txt'      \) -print0 |\
                  xargs -t -0 git add 
    ## commit to local repo
    git commit -uno -a -m "Commit $(date +'%F %R')"
done





#TODO



#-----------------------------------------------------------------------------#

folder="$HOME/LibRadTranG"

echo ""
echo " vvvv START vvvv ${folder}"
echo ""

cd ${folder}
rm -f "${folder}/.git/index.lock"

find . -type f \(    -iname '*.sh'  \
                  -o -iname '*.md'  \
                  -o -iname '*.gnu' \
                  -o -iname '*.dot' \
                  -o -iname '*.qmd' \
                  -o -iname '*.jl'  \
                  -o -iname '*.frm' \
                  -o -iname '*.pbs' \
                  -o -iname '*.r'   \) -print0  |\
                  xargs -0 git add

git commit -uno -a -m "Commit $(date +'%F %R')"

echo ""
echo " ^^^^ FINISH ^^^^ ${folder}"

#-----------------------------------------------------------------------------#



folder="$HOME/Formal/CV"

echo ""
echo " vvvv START vvvv ${folder}"
echo ""

cd ${folder}
rm -f "${folder}/.git/index.lock"

find . -type f \(    -iname '*.tex'   \
                  -o -iname '*.css'   \
                  -o -iname '*.md'    \) -print0 |\
                  xargs -0 git add

git commit -uno -a -m "Commit $(date +'%F %R')"

echo ""
echo " ^^^^ FINISH ^^^^ ${folder}"


#-----------------------------------------------------------------------------#

folder="$HOME/LifeAsti"

echo ""
echo " vvvv START vvvv ${folder}"
echo ""

cd ${folder}
rm -f "${folder}/.git/index.lock"

find . -type f \(    -iname '*.sh'  \
                  -o -iname '*.Rmd' \
                  -o -iname '*.bas' \
                  -o -iname '*.bib' \
                  -o -iname '*.c'   \
                  -o -iname '*.dot' \
                  -o -iname '*.ex'  \
                  -o -iname '*.f90' \
                  -o -iname '*.qmd' \
                  -o -iname '*.frm' \
                  -o -iname '*.gnu' \
                  -o -iname '*.jl'  \
                  -o -iname '*.gp'  \
                  -o -iname '*.h'   \
                  -o -iname '*.md'  \
                  -o -iname '*.par' \
                  -o -iname '*.py'  \
                  -o -iname '*.tex' \
                  -o -iname '*.r'   \) -print0  |\
                  xargs -0 git add

git commit -uno -a -m "Commit $(date +'%F %R')"

#-----------------------------------------------------------------------------#

folder="$HOME/Documents/Docu/to"

echo ""
echo " vvvv START vvvv ${folder}"
echo ""

cd ${folder}
rm -f "${folder}/.git/index.lock"

find . -type f \(    -iname '*.sh'  \
                  -o -iname '*.md'  \
                  -o -iname '*.txt' \) -print0  |\
                  xargs -0 git add

git commit -uno -a -m "Commit $(date +'%F %R')"

echo ""
echo " ^^^^ FINISH ^^^^ ${folder}"

#-----------------------------------------------------------------------------#

folder="$HOME/Documents/po"

echo ""
echo " vvvv START vvvv ${folder}"
echo ""

cd ${folder}
rm -f "${folder}/.git/index.lock"

find . -type f \(    -iname '*.sh'  \
                  -o -iname '*.md'  \
                  -o -iname '*.txt' \) -print0  |\
                  xargs -0 git add

sleep $((RANDOM%60+1))
git commit -uno -a -m "Commit $(date +'%F %R')"

echo ""
echo " ^^^^ FINISH ^^^^ ${folder}"

echo "LOGFILE: $LOG_FILE"
echo "ERRFILE: $ERR_FILE"



exit 0
