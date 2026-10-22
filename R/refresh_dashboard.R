# Stage the pipeline before publishing. A failed collection or processing step
# must not replace the last known-good dataset.
refresh_dashboard <- function(root) {
  root <- normalizePath(root, mustWork = TRUE)
  if (!nzchar(Sys.getenv("ADZUNA_APP_ID")) || !nzchar(Sys.getenv("ADZUNA_APP_KEY"))) {
    stop("Credentials missing. Add ADZUNA_APP_ID and ADZUNA_APP_KEY to your local .Renviron, then restart R.")
  }

  lock <- file.path(root, ".refresh-lock")
  if (!dir.create(lock, showWarnings = FALSE)) {
    stop("A refresh is already running. If a previous process crashed, check that no refresh is active before removing .refresh-lock.")
  }
  on.exit(unlink(lock, recursive = TRUE), add = TRUE)

  stage <- tempfile("techpulse-stage-")
  dir.create(stage)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  for (d in c("data/raw", "data/processed", "R")) dir.create(file.path(stage, d), recursive = TRUE, showWarnings = FALSE)

  scripts <- c("collect_jobs.R", "clean_jobs.R", "dashboard_data.R", "extract_skills.R", "analyze_jobs.R")
  for (f in scripts) {
    if (!file.copy(file.path(root, "R", f), file.path(stage, "R", f), overwrite = TRUE)) {
      stop(paste("Cannot stage pipeline script:", f))
    }
  }

  old <- getwd()
  on.exit(setwd(old), add = TRUE)
  setwd(stage)

  for (f in c("collect_jobs.R", "clean_jobs.R", "extract_skills.R", "analyze_jobs.R")) {
    tryCatch(
      sys.source(file.path("R", f), envir = new.env(parent = globalenv())),
      error = function(e) stop(sprintf("Refresh failed in %s: %s. Previous published data was preserved.",
                                      f, conditionMessage(e)), call. = FALSE)
    )
  }

  source("R/dashboard_data.R", local = TRUE)
  checked <- load_jobs(stage)
  if (!nrow(checked)) stop("Refresh produced an empty dataset; previous data was preserved.")

  now <- format(Sys.time(), tz = "UTC", format = "%Y-%m-%d %H:%M:%S UTC")
  writeLines(now, "data/processed/last_refresh.txt")

  metadata_path <- "data/processed/collection_metadata.json"
  if (file.exists(metadata_path)) {
    metadata <- jsonlite::fromJSON(metadata_path, simplifyVector = FALSE)
    history_path <- file.path(root, "data/processed/refresh_history.csv")
    history <- if (file.exists(history_path)) {
      tryCatch(read.csv(history_path, stringsAsFactors = FALSE), error = function(e) data.frame())
    } else data.frame()
    row <- data.frame(
      refreshed_at_utc = now,
      status = "success",
      records_returned = if (is.null(metadata$records_returned)) NA_integer_ else as.integer(metadata$records_returned),
      unique_records = if (is.null(metadata$unique_records)) nrow(checked) else as.integer(metadata$unique_records),
      duplicate_ids_removed = if (is.null(metadata$duplicate_ids_removed)) NA_integer_ else as.integer(metadata$duplicate_ids_removed),
      request_count = if (is.null(metadata$request_count)) NA_integer_ else as.integer(metadata$request_count),
      stringsAsFactors = FALSE
    )
    history <- rbind(history, row)
    write.csv(tail(history, 100), "data/processed/refresh_history.csv", row.names = FALSE)
  }

  setwd(old)
  targets <- list.files(file.path(stage, "data"), recursive = TRUE, full.names = FALSE)
  backup <- file.path(stage, "backup")
  dir.create(backup)
  existed <- file.exists(file.path(root, "data", targets))

  for (i in which(existed)) {
    dest <- file.path(backup, targets[i])
    dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
    if (!file.copy(file.path(root, "data", targets[i]), dest, overwrite = TRUE)) {
      stop(paste("Cannot back up existing data:", targets[i]))
    }
  }

  tryCatch({
    for (f in targets) {
      dest <- file.path(root, "data", f)
      dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
      if (!file.copy(file.path(stage, "data", f), dest, overwrite = TRUE)) {
        stop(paste("Cannot publish refreshed file:", f))
      }
    }
  }, error = function(e) {
    for (i in seq_along(targets)) {
      dst <- file.path(root, "data", targets[i])
      if (existed[i]) {
        file.copy(file.path(backup, targets[i]), dst, overwrite = TRUE)
      } else {
        unlink(dst)
      }
    }
    stop(sprintf("Publishing failed; rollback attempted: %s", conditionMessage(e)), call. = FALSE)
  })

  invisible(list(
    listings = nrow(checked),
    refreshed_at_utc = now,
    metadata = if (file.exists(file.path(root, "data/processed/collection_metadata.json"))) file.path(root, "data/processed/collection_metadata.json") else NULL
  ))
}
