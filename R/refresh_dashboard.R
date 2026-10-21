# Stage the entire pipeline before publishing. No API calls during filtering.
refresh_dashboard <- function(root) {
 if(!nzchar(Sys.getenv("ADZUNA_APP_ID")) || !nzchar(Sys.getenv("ADZUNA_APP_KEY"))) stop("Credentials missing. Add them to your local .Renviron and restart R.")
 lock <- file.path(root,".refresh-lock")
 if(!dir.create(lock,showWarnings=FALSE)) stop("A refresh is already running. If a previous process crashed, remove .refresh-lock after checking no refresh is active.")
 on.exit(unlink(lock,recursive=TRUE),add=TRUE)
 stage <- tempfile("techpulse-stage-"); dir.create(stage)
 on.exit(unlink(stage,recursive=TRUE),add=TRUE)
 dir.create(file.path(stage,"data/raw"),recursive=TRUE); dir.create(file.path(stage,"data/processed"))
 dir.create(file.path(stage,"R"))
 for(f in c("collect_jobs.R","clean_jobs.R","dashboard_data.R","extract_skills.R","analyze_jobs.R"))
  if(!file.copy(file.path(root,"R",f),file.path(stage,"R",f))) stop("Cannot stage pipeline.")
 old <- getwd(); on.exit(setwd(old),add=TRUE); setwd(stage)
 for(f in c("collect_jobs.R","clean_jobs.R","extract_skills.R","analyze_jobs.R")) {
  tryCatch(sys.source(file.path("R",f),envir=new.env(parent=globalenv())),error=function(e) stop(paste("Refresh failed in",f,". Previous dataset preserved. Check configuration and API availability."),call.=FALSE))
 }
 source("R/dashboard_data.R",local=TRUE); checked <- load_jobs(stage)
 if(!nrow(checked)) stop("Empty refresh; previous dataset preserved.")
 writeLines(format(Sys.time(),tz="UTC",format="%Y-%m-%d %H:%M:%S UTC"),"data/processed/last_refresh.txt")
 setwd(old)
 targets <- list.files(file.path(stage,"data"),recursive=TRUE,full.names=FALSE)
 backup <- file.path(stage,"backup"); dir.create(backup)
 existed <- file.exists(file.path(root,"data",targets))
 for(i in which(existed)) { dest <- file.path(backup,targets[i]); dir.create(dirname(dest),recursive=TRUE,showWarnings=FALSE); if(!file.copy(file.path(root,"data",targets[i]),dest)) stop("Cannot back up existing data.") }
 tryCatch({
  for(f in targets) if(!file.copy(file.path(stage,"data",f),file.path(root,"data",f),overwrite=TRUE)) stop("Cannot publish refreshed files.")
 },error=function(e) {
  for(i in seq_along(targets)) {
   dst <- file.path(root,"data",targets[i])
   if(existed[i]) file.copy(file.path(backup,targets[i]),dst,overwrite=TRUE) else unlink(dst)
  }; stop("Publishing failed; rollback attempted. Check file permissions.")
 })
 invisible(nrow(checked))
}
