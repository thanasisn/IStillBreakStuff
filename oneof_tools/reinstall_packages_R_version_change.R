
#### ReInstall packages on R version update

## get list from old repository
list <- list.files("~/.R/x86_64-pc-linux-gnu-library/4.2.3/")
list <- list.files("~/.R/x86_64-pc-linux-gnu-library/4.0.4/")

## get installed packages for this version
inst <- installed.packages()

## show info
cat("To install:\n")
cat(list[!list %in% rownames(inst)])

## ask to continue
res <- menu(c("Yes", "No"), title = "Continue?")

if (res == 1) {
    install.packages(list[!list %in% rownames(inst)])
}


