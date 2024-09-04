#!/usr/bin/env bash
## created on 2013-05-07
## https://github.com/thanasisn <natsisphysicist@gmail.com>

#### Auto commit and push all git repos

exec 9>"/dev/shm/$(basename $0).lock"
if ! flock -n 9; then
	echo "another instance of $0 is running"
	exit 1
fi

info() { echo "$(date +%F_%T) ${SECONDS}s :: $* ::" >&1; }
LOG_FILE="/dev/shm/$(basename "$0")_$(date +%F).log"
ERR_FILE="/dev/shm/$(basename "$0")_$(date +%F).err"
touch "$LOG_FILE" "$ERR_FILE"
exec > >(tee -i "${LOG_FILE}")
exec 2> >(tee -i "${ERR_FILE}" >&2)
trap 'echo $( date +%F_%T ) ${SECONDS}s :: $0 interrupted ::  >&2;' INT TERM
info "START :: $0 :: $* ::"

set +e

##  COMMIT PUSH to github repos  ###############################################

echo "DOTFILES"
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" commit -uno -a -m "Commit $(date +'%F %R')"
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" push -u origin master
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" maintenance run --auto

# echo "---------------"
# cd "$HOME/PANDOC/Deployment_notes"
# cd "./_book"
# ln -f ./Deployment_notes.html ./index.html
# git add -f .
# cd ".."
# pwd
# git commit -uno -a -m "Commit $(date +'%F %R')"
# git push -f -u origin main
# git maintenance run --auto

echo "---------------"
cd "$HOME/PANDOC/Libradtran_guide"
cd "./_book"
ln -f ./Libratran_guide.html ./index.html
git add -f .
cd ".."
pwd
git commit -uno -a -m "Commit $(date +'%F %R')"
git push -f -u origin main
git maintenance run --auto

echo "---------------"
cd "$HOME/PANDOC/CHP1_measurements_guide"
cd "./_book"
ln -f ./CHP1_measurements_guide.html ./index.html
git add -f .
cd ".."
pwd
git commit -uno -a -m "Commit $(date +'%F %R')"
git push -f -u origin main
git maintenance run --auto

echo "---------------"
cd "$HOME/PANDOC/Tracker_manual"
cd "./_book"
ln -f ./LAP_tracker_manual.html ./index.html
git add -f .
cd ".."
pwd
git commit -uno -a -m "Commit $(date +'%F %R')"
git push -f -u origin main
git maintenance run --auto

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
git maintenance run --auto

####  COMMIT and PUSH to github NO ADD  ################################

## use full paths
folders=(
	"$HOME/CODE/"
	"$HOME/CODE/R_myRtools/myRtools"
	"$HOME/CODE/deploy/"
)

## go through main folder
for i in "${folders[@]}"; do
	echo
	info " $i "
	echo
	[ ! -d "$i" ] && echo "Not a folder: $i" && continue
	## go through sub folders
	cd "$i" || return
  chmod +w .git
	pwd
	## commit and push
	git commit -uno -a -m "Commit $(date +'%F %R')"
	git push -f
	git push --tag
	git maintenance run --auto
done

####  ADD COMMIT and PUSH to github  ################################

## use full paths
folders=(
	"$HOME/.dot_files"
	"$HOME/BBand_LAP"
	"$HOME/CM_21_GLB/"
	"$HOME/CODE/nixos"
	"$HOME/CODE/training_location_analysis"
	"$HOME/CS_id/"
	"$HOME/MANUSCRIPTS/01_2022_sdr_trends"
	"$HOME/MANUSCRIPTS/02_enhancement"
	"$HOME/MANUSCRIPTS/03_thesis"
	"$HOME/MANUSCRIPTS/presentations"
	"$HOME/MANUSCRIPTS/reports"
	"$HOME/PANDOC/My_Publications"
	"$HOME/PANDOC/thanasisn.github.io"
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
	## go in the sub folders
	cd "$i" || return
	## make sure git is writable
  chmod +w .git
	pwd
	(
		## add files we care about
		find . -type f \( -iname '*.bas' \
			-o -iname '*.Rmd'      \
			-o -iname '*.bas'      \
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
			-o -iname '*.lua'      \
			-o -iname '*.makefile' \
			-o -iname '*.md'       \
			-o -iname '*.nix'      \
			-o -iname '*.par'      \
			-o -iname '*.pbs'      \
			-o -iname '*.py'       \
			-o -iname '*.qgs'      \
			-o -iname '*.qmd'      \
			-o -iname '*.r'        \
			-o -iname '*.rmd'      \
			-o -iname '*.sh'       \
			-o -iname '*.tex'      \
			-o -iname '*.txt'      \
			-o -iname '*.vim'      \
			-o -iname '*.yaml'     \
			-o -iname '*.yml'      \
			-o -iname 'flake.lock' \
			-o -iname 'makefile'   \) -print0 |
			xargs -t -0 git add
		## commit and push
		git commit -uno -a -m "Commit $(date +'%F %R')"
		git push -f
		git push --tag
		git maintenance run --auto
	) > >(tee .autogit.log) 2> >(tee .autogit.err >&2)
done

## ADD and COMMIT only for LOCAL repos ########################################

## use full paths
folders=(
	"$HOME/.dot_files_private"
	"$HOME/Aerosols/"
	"$HOME/BASH/"
	"$HOME/DATA_ARC/10_TODO/JOURNAL"
	"$HOME/Ecotime_machine/Scripts/"
	"$HOME/Improved_Aerosols_O3/"
	"$HOME/LibRadTranG"
	"$HOME/LifeAsti"
	"$HOME/MISC/Redmi7_internal/documents"
	"$HOME/NOTES"
	"$HOME/NOTES/01_PROJECTS/Aerosols"
  "$HOME/NOTES/05_CV/"
	"$HOME/NOTES/08_JOURNAL"
	"$HOME/NOTES/09_JOURNAL_WORK"
	"$HOME/NOTES/12_WRITINGS/po"
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
	## go in the sub folders
	cd "$i" || return
	## make sure git is writable
  chmod +w .git
	pwd
	(
		## always break lock
		rm -f "${i}/.git/index.lock"
		## add files we care about
		find . -type f \( -iname '*.bas' \
			-o -iname '*.Rmd'      \
			-o -iname '*.bas'      \
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
			-o -iname '*.lua'      \
			-o -iname '*.makefile' \
			-o -iname '*.md'       \
			-o -iname '*.nix'      \
			-o -iname '*.par'      \
			-o -iname '*.pbs'      \
			-o -iname '*.py'       \
			-o -iname '*.qgs'      \
			-o -iname '*.qmd'      \
			-o -iname '*.r'        \
			-o -iname '*.rmd'      \
			-o -iname '*.sh'       \
			-o -iname '*.tex'      \
			-o -iname '*.txt'      \
			-o -iname '*.yaml'     \
			-o -iname '*.yml'      \
			-o -iname 'flake.lock' \
			-o -iname 'makefile'   \) -print0 |
			xargs -t -0 git add
		## commit to local repo
		git commit -uno -a -m "Commit $(date +'%F %R')"
		git maintenance run --auto
	) > >(tee .autogit.log) 2> >(tee .autogit.err >&2)
done

echo
echo "LOGFILE: $LOG_FILE"
echo "ERRFILE: $ERR_FILE"

exit 0
