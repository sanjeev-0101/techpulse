suppressPackageStartupMessages({
  library(jsonlite)
  library(dplyr)
  library(stringr)
})

raw_path <- "data/raw/jobs_raw.json"
output_path <- "data/processed/jobs_clean.csv"

if (!file.exists(raw_path)) stop("Raw jobs file not found. Run R/collect_jobs.R first.")
jobs_raw <- fromJSON(raw_path, simplifyVector = FALSE)
if (!length(jobs_raw)) stop("Raw jobs file contains no listings; processed data was not overwritten.")

value_or_na <- function(x) {
  if (is.null(x) || !length(x) || identical(x, "")) NA_character_ else as.character(x[[1]])
}
nested_value <- function(x, ...) {
  keys <- list(...)
  for (key in keys) {
    if (is.null(x) || is.null(x[[key]])) return(NA_character_)
    x <- x[[key]]
  }
  value_or_na(x)
}
num_or_na <- function(x) {
  if (is.null(x) || !length(x)) return(NA_real_)
  y <- suppressWarnings(as.numeric(x[[1]]))
  if (!length(y) || !is.finite(y)) NA_real_ else y
}
bool_or_na <- function(x) {
  if (is.null(x) || !length(x)) return(NA)
  suppressWarnings(as.logical(x[[1]]))
}

jobs_clean <- bind_rows(lapply(jobs_raw, function(job) {
  data.frame(
    job_id = value_or_na(job$id),
    title = value_or_na(job$title),
    company = nested_value(job, "company", "display_name"),
    location = nested_value(job, "location", "display_name"),
    category = nested_value(job, "category", "label"),
    contract_time = value_or_na(job$contract_time),
    created = value_or_na(job$created),
    description = value_or_na(job$description),
    redirect_url = value_or_na(job$redirect_url),
    salary_min = num_or_na(job$salary_min),
    salary_max = num_or_na(job$salary_max),
    salary_is_predicted = bool_or_na(job$salary_is_predicted),
    stringsAsFactors = FALSE
  )
}))

jobs_clean <- jobs_clean |>
  mutate(
    across(c(title, company, location, category, contract_time, description),
           ~ str_squish(.x)),
    created = as.POSIXct(created, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    average_salary = if_else(
      is.finite(salary_min) & is.finite(salary_max) &
        salary_min >= 0 & salary_max >= salary_min,
      (salary_min + salary_max) / 2, NA_real_
    ),
    salary_quality = case_when(
      !is.finite(salary_min) | !is.finite(salary_max) ~ "Missing salary",
      salary_min < 0 | salary_max < salary_min ~ "Invalid range",
      salary_min < 10000 & salary_max / pmax(salary_min, 1) > 50 ~ "Review low minimum and wide range",
      salary_min < 10000 ~ "Review low minimum",
      salary_max / pmax(salary_min, 1) > 50 ~ "Review wide range",
      TRUE ~ "Unflagged; period and units unverified"
    )
  )

# Deduplicate known IDs, while retaining records whose API ID is missing.
has_id <- !is.na(jobs_clean$job_id) & nzchar(jobs_clean$job_id)
jobs_clean <- jobs_clean[!has_id | !duplicated(jobs_clean$job_id), , drop = FALSE]

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
tmp <- tempfile("jobs-clean-", tmpdir = dirname(output_path), fileext = ".csv")
write.csv(jobs_clean, tmp, row.names = FALSE, na = "")
if (!file.rename(tmp, output_path)) {
  unlink(tmp)
  stop("Could not publish cleaned data. Check file permissions.")
}
cat("Clean jobs:", nrow(jobs_clean), "\n")
cat("Columns:", ncol(jobs_clean), "\n")
cat("Processed dataset saved successfully.\n")
