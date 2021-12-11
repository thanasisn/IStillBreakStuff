#!/bin/bash
## created on 2013-05-07
## https://github.com/thanasisn <lapauththanasis@gmail.com>


#### Auto commit and push all git repos

set +e



##  COMMIT PUSH to github repos  ###############################################

## The following do not add files to git automatically

## this works only on tyler
echo "DOTFILES"
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" commit -uno -a -m "Auto commit"
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" push -u origin master



echo "------"
cd "$HOME/CODE/"
pwd
git commit -uno -a -m "Auto commit"
git push -f -u origin main



echo "------"
cd "$HOME/CODE/R_myRtools/"
pwd
git commit -uno -a -m "Auto commit"
git push -f -u origin main



echo "------"
cd "$HOME/CODE/R_POLAr/POLAr/"
pwd
git commit -uno -a -m "Auto commit"
git push -f -u origin master



echo "------"
cd "$HOME/CODE/deploy/"
pwd
git commit -uno -a -m "Auto commit"
git push -f -u origin main



echo "------"
cd "$HOME/PANDOC/Deployment_notes"
cd "./_book"
git add -f .
cd ".."
pwd
git commit -uno -a -m "Auto commit"
git push -f -u origin main



echo "------"
cd "$HOME/PANDOC/Libradtran_guide"
cd "./_book"
ln -f ./Libratran_guide.html ./index.html
git add -f .
cd ".."
pwd
git commit -uno -a -m "Auto commit"
git push -f -u origin main



##  COMMIT PUSH to local repos  ################################################

## The following add files to git automatically

echo "------"
folder="$HOME/CM_21_GLB/"
cd ${folder}
pwd
rm -f "${folder}/.git/index.lock"
find . -type f \(    -iname '*.sh'  \
                  -o -iname '*.py'  \
                  -o -iname '*.md'  \
                  -o -iname '*.bas' \
                  -o -iname '*.gnu' \
                  -o -iname '*.dot' \
                  -o -iname '*.frm' \
                  -o -iname '*.par' \
                  -o -iname '*.f90' \
                  -o -iname '*.jl'  \
                  -o -iname '*.c'   \
                  -o -iname '*.h'   \
                  -o -iname '*.gp'  \
                  -o -iname '*.ex'  \
                  -o -iname '*.bib' \
                  -o -iname '*.tex' \
                  -o -iname '*.Rmd' \
                  -o -iname '*.md'  \
                  -o -iname '*.r'   \) -print0 |\
                  xargs -0 git add

git commit -uno -a -m "Auto commit"
git push -f -u origin main





##  Autocommit in local repos  ##


folder="$HOME/PROJECTS/"
echo ${folder}
cd ${folder}
rm -f "${folder}/.git/index.lock"

find . -type f \(  -iname '*.sh'  \
                -o -iname '*.py'  \
                -o -iname '*.md'  \
                -o -iname '*.Rmd' \
                -o -iname '*.qgs' \
                -o -iname '*.bas' \
                -o -iname '*.par' \
                -o -iname '*.f90' \
                -o -iname '*.gnu' \
                -o -iname '*.dot' \
                -o -iname '*.jl'  \
                -o -iname '*.frm' \
                -o -iname '*.c'   \
                -o -iname '*.h'   \
                -o -iname '*.gp'  \
                -o -iname '*.ex'  \
                -o -iname '*.bib' \
                -o -iname '*.tex' \
                -o -iname '*.md'  \
                -o -iname '*.r'   \) -print0  |\
                xargs -0 git add

git commit -uno -a -m "auto update $(date +%F_%T)"
echo



folder="$HOME/TEX/"
echo ${folder}
cd ${folder}
rm -f "${folder}/.git/index.lock"

find . -type f \( -iname '*.sh' \
        -o -iname '*.py'  \
        -o -iname '*.gnu' \
        -o -iname '*.dot' \
        -o -iname '*.frm' \
        -o -iname '*.gp'  \
        -o -iname '*.ex'  \
        -o -iname '*.bib' \
        -o -iname '*.tex' \
        -o -iname '*.r'   \) -print0  |\
        xargs -0 git add

git commit -uno -a -m "auto update $(date +%F_%T)"
echo





#TODO

## python 2 folder
folder="$HOME/PYTHON2"
echo ${folder}
cd ${folder}
rm -f "$HOME/PYTHON2/.git/index.lock"

find . -type f \(    -iname '*.sh'   \
                  -o -iname '*.py'   \
                  -o -iname '*.gnu'  \
                  -o -iname '*.dot'  \
                  -o -iname '*.frm'  \
                  -o -iname '*.jl'   \
                  -o -iname '*.c'    \
                  -o -iname '*.cpp'  \) -print0  |\
        xargs -0 git add

git commit -uno -a -m "auto update $(date +%F_%T)"
echo


## python 3 folder
folder="$HOME/PYTHON3"
echo ${folder}
cd ${folder}
rm -f "HOME/PYTHON3/.git/index.lock"


find . -type f \(  -iname '*.sh'  \
                -o -iname '*.py'  \
                -o -iname '*.R'   \
                -o -iname '*.f90' \
                -o -iname '*.gnu' \
                -o -iname '*.dot' \
                -o -iname '*.frm' \
                -o -iname '*.cs'  \
                -o -iname '*.jl'  \
                -o -iname '*.h'   \
                -o -iname '*.c'   \
                -o -iname '*.cpp' \) -print0  |\
        xargs -0 git add

git commit -uno -a -m "auto update $(date +%F_%T)"
echo

folder="$HOME/UVindex_prod"
echo ${folder}
cd  ${folder}
rm -f "$HOME/UVindex_prod/.git/index.lock"

find . -type f \(  -iname '*.sh'   \
                -o -iname '*.r'    \
                -o -iname '*.gnu'  \
                -o -iname '*.dot'  \
                -o -iname '*.jl'  \
                -o -iname '*.frm'  \
                -o -iname '*.py'   \
                -o -iname '*.frm' \) -print0  |\
        xargs -0 git add

git commit -uno -a -m "auto update $(date +%F_%T)"
echo







####    ALL HOSTS    ##########################################################


folder="$HOME/Aerosols/"

echo ""
echo " vvvv START vvvv ${folder}"
echo ""

cd ${folder}
rm -f "${folder}/.git/index.lock"

find . -type f \(    -iname '*.sh'  \
                  -o -iname '*.py'  \
                  -o -iname '*.md'  \
                  -o -iname '*.bas' \
                  -o -iname '*.gnu' \
                  -o -iname '*.dot' \
                  -o -iname '*.frm' \
                  -o -iname '*.par' \
                  -o -iname '*.f90' \
                  -o -iname '*.jl'  \
                  -o -iname '*.c'   \
                  -o -iname '*.h'   \
                  -o -iname '*.gp'  \
                  -o -iname '*.ex'  \
                  -o -iname '*.bib' \
                  -o -iname '*.tex' \
                  -o -iname '*.Rmd' \
                  -o -iname '*.md'  \
                  -o -iname '*.r'   \) -print0 |\
                  xargs -0 git add

sleep $((RANDOM%60+1))
git commit -uno -a -m "auto update $(date +%F_%T)"

echo ""
echo " ^^^^ FINISH ^^^^ ${folder}"

#-----------------------------------------------------------------------------#

folder="$HOME/Ecotime_machine/Scripts/"

echo ""
echo " vvvv START vvvv ${folder}"
echo ""

cd ${folder}
rm -f "${folder}/.git/index.lock"

find . -type f \(    -iname '*.sh'  \
                  -o -iname '*.py'  \
                  -o -iname '*.md'  \
                  -o -iname '*.bas' \
                  -o -iname '*.gnu' \
                  -o -iname '*.dot' \
                  -o -iname '*.frm' \
                  -o -iname '*.jl'  \
                  -o -iname '*.par' \
                  -o -iname '*.f90' \
                  -o -iname '*.c'   \
                  -o -iname '*.h'   \
                  -o -iname '*.gp'  \
                  -o -iname '*.ex'  \
                  -o -iname '*.bib' \
                  -o -iname '*.tex' \
                  -o -iname '*.Rmd' \
                  -o -iname '*.md'  \
                  -o -iname '*.r'   \) -print0 |\
                  xargs -0 git add

git commit -uno -a -m "auto update $(date +%F_%T)"

echo ""
echo " ^^^^ FINISH ^^^^ ${folder}"

#-----------------------------------------------------------------------------#



#-----------------------------------------------------------------------------#

folder="$HOME/Improved_Aerosols_O3"

echo ""
echo " vvvv START vvvv ${folder}"
echo ""

cd ${folder}
rm -f "${folder}/.git/index.lock"

find . -type f \(    -iname '*.sh'  \
                  -o -iname '*.py'  \
                  -o -iname '*.md'  \
                  -o -iname '*.Rmd' \
                  -o -iname '*.bas' \
                  -o -iname '*.par' \
                  -o -iname '*.gnu' \
                  -o -iname '*.dot' \
                  -o -iname '*.jl'  \
                  -o -iname '*.frm' \
                  -o -iname '*.f90' \
                  -o -iname '*.c'   \
                  -o -iname '*.h'   \
                  -o -iname '*.gp'  \
                  -o -iname '*.ex'  \
                  -o -iname '*.bib' \
                  -o -iname '*.tex' \
                  -o -iname '*.Rmd' \
                  -o -iname '*.md'  \
                  -o -iname '*.r'   \) -print0  |\
                  xargs -0 git add

git commit -uno -a -m "auto update $(date +%F_%T)"

echo ""
echo " ^^^^ FINISH ^^^^ ${folder}"

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
                  -o -iname '*.jl'  \
                  -o -iname '*.frm' \
                  -o -iname '*.pbs' \
                  -o -iname '*.r'   \) -print0  |\
                  xargs -0 git add

git commit -uno -a -m "auto update $(date +%F_%T)"

echo ""
echo " ^^^^ FINISH ^^^^ ${folder}"

#-----------------------------------------------------------------------------#

folder="$HOME/BASH"

echo ""
echo " vvvv START vvvv ${folder}"
echo ""

cd ${folder}
rm -f "${folder}/.git/index.lock"

find . -type f \(    -iname '*.sh'   \
                  -o -iname '*.R'    \
                  -o -iname '*.Rmd'  \
                  -o -iname '*.c'    \
                  -o -iname '*.conf' \
                  -o -iname '*.dot'  \
                  -o -iname '*.frm'  \
                  -o -iname '*.gnu'  \
                  -o -iname '*.jl'   \
                  -o -iname '*.gp'   \
                  -o -iname '*.jl'   \
                  -o -iname '*.list' \
                  -o -iname '*.md'   \
                  -o -iname '*.par'  \
                  -o -iname '*.py'   \
                  -o -iname '*.ex'   \) -print0 |\
                  xargs -0 git add

git commit -uno -a -m "auto update $(date +%F_%T)"

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

git commit -uno -a -m "auto update $(date +%F_%T)"

echo ""
echo " ^^^^ FINISH ^^^^ ${folder}"

#-----------------------------------------------------------------------------#

folder="$HOME/FUNCTIONS"

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
                  -o -iname '*.frm' \
                  -o -iname '*.jl'  \
                  -o -iname '*.gnu' \
                  -o -iname '*.gp'  \
                  -o -iname '*.h'   \
                  -o -iname '*.md'  \
                  -o -iname '*.par' \
                  -o -iname '*.py'  \
                  -o -iname '*.tex' \
                  -o -iname '*.r'   \) -print0 |\
                  xargs -0 git add

git commit -uno -a -m "auto update $(date +%F_%T)"

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

git commit -uno -a -m "auto update $(date +%F_%T)"

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

git commit -uno -a -m "auto update $(date +%F_%T)"

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
git commit -uno -a -m "auto update $(date +%F_%T)"

echo ""
echo " ^^^^ FINISH ^^^^ ${folder}"




exit 0
