
# system_tools

Different file system tools.

Most of the scripts are short and simple in functionality.
They are just convenient tools for the terminal.

Things they do:

- **adsl_refresh_ip.sh           :**  Refresh ip by refreshing adsl connection 
- **auto_commit_push_git.sh      :**  Auto commit and push all git repos
- **auto_make.sh                 :**  Just a cron job to run all Makefiles 
- **bib_fix_home_paths.sh        :**  Add missing '/' to bib files pahts
- **browser_bookmarks.sh         :**  Open a browser bookmark with dmenu
- **browser_history.sh           :**  Open a url from history with dmenu
- **btrfs_defrag.sh              :**  Defrag all btrfs filesystems
- **btrfs_scrub.sh               :**  Start a btrfs scrub to check data integrity
- **clamscan_daily.sh            :** 
- **clean_metadata.sh            :**  Remove metadata from any file using exiftool
- **commit_push_folders.sh       :**  Auto commit and push all git repos within a folder
- **compress_dirs_best.sh        :**  Compress individual folders after testing for best compression method for each folder
- **compress_files_best.sh       :**  Compress individual files after testing for best compression method for each file
- **daemonize.sh                 :**  Keep a program always running and restart it if needed
- **disks_arrays_report.sh       :**  Gather information for hard disks and arrays
- **disks_check_status.sh        :**  Check status of akk mdraid and btrfs arrays for the host.
- **disks_smart_report.sh        :**  Gather S.M.A.R.T. info on all system drives
- **extensions_to_lower.sh       :**  Convert file extensions to lower case
- **filename_checks_fixes.sh     :**  Make file and folder names consistent and nice
- **link_bib_files_here.sh       :**  Create links here to files included in a bib file
- **list_compressed.sh           :**  List compressed files by looking for mime type
- **list_duplicate_filenames.sh  :**  Find duplicate filenames recursively in a folder structure
- **list_extensions.sh           :**  list unique extensions and count them
- **list_filenames_chars.sh      :**  list and count file names characters
- **list_filenames_lengths.sh    :**  Get the length of filename in characters and in bytes
- **list_files_by_date.sh        :**  List file by date 
- **list_matching_filenames.sh   :**  Create list of filename (ignoring extensions) occurrences recursively
- **list_no_extensions.sh        :**  List files without extensions
- **list_R_libraries.sh          :**  List libraries used in R and Rmd scripts
- **mempeakusg.sh                :**  Run a command and capture peek memory usage
- **mount_enc_home.sh            :**  Mount an encrypted LUKS partition over users home
- **nc_hb_pub.sh                 :**  Post a heartbeat from this host to everybody
- **nc_hb_sub.sh                 :**  Capture heartbeat from my machines
- **new_bash.sh                  :**  Create a new executable bash script
- **new_journal.sh               :**  Just create a new .md file with a given or current date 
- **new_md.sh                    :**  Just create a new md file with the current date
- **new_note.sh                  :**  Just create a new md file with the current date and title
- **pass_formater.sh             :**  Organize 'pass' entries with a uniform manner "./url/login"
- **pub_notifications.py         :**  Send a notifications to other machine
- **quick_note.sh                :**  Create a quick note and get in the Notes dir. 
- **remove_duplicate_files.sh    :**  find duplicate files with fdupes and remove them by matching patter
- **remove_old_snaps.sh          :**  Removes old revisions of snaps
- **run_tmux_session.sh          :**  Create or reuse a named tmux session to run commands 
- **scripts_titles.sh            :**  Get info for scripts containing a specified header
- **shell_keep_history.sh        :**  Keep a record of all history from all hosts  
- **show_config.sh               :**  Display the keybinds of some programs by parsing their config files
- **speedup_clock.sh             :**  Speed up the time of a linux machine by adding a fixed amount of time at every interval
- **sub_messages2.py             :** 
- **sub_notifications.py         :**  Accept and decode notifications from other systems.
- **throttle_by_temp.sh          :**  Throttle a process cpu usage according to cpu temperature
- **touch_random.sh              :**  Randomize files and folders dates
- **unmount_enc_home.sh          :**  Unmount mounted user home and close LUKS
- **vnc_connect.sh               :**  Creates a ssh tunnel and open a new vnc connection to known hosts
- **zfs_scrub.sh                 :**  Start a zfs scrub to check data integrity






*Suggestions and improvements are always welcome.*

*I use those regular, but they have their quirks, may broke and maybe superseded by other tools.*
