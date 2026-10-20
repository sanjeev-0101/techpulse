
library(httr2)
library(jsonlite)

# -----------------------------
# TechPulse - Multi-Role Collector
# -----------------------------

APP_ID <- Sys.getenv("ADZUNA_APP_ID")
APP_KEY <- Sys.getenv("ADZUNA_APP_KEY")

COUNTRY <- "in"

SEARCH_TERMS <- c(
  "software developer",
  "software engineer",
  "data scientist",
  "data analyst",
  "machine learning engineer",
  "AI engineer",
  "cloud engineer",
  "DevOps engineer",
  "cybersecurity engineer",
  "frontend developer",
  "backend developer",
  "full stack developer"
)

PAGES_PER_ROLE <- 1
RESULTS_PER_PAGE <- 50

collect_jobs <- function() {

  # Check credentials before making requests
  if (APP_ID == "" || APP_KEY == "") {
    stop("Adzuna credentials missing. Check your .Renviron file.")
  }

  all_jobs <- list()

  for (term in SEARCH_TERMS) {

    cat("\nSearching for:", term, "\n")

    for (page in seq_len(PAGES_PER_ROLE)) {

      url <- paste0(
        "https://api.adzuna.com/v1/api/jobs/",
        COUNTRY,
        "/search/",
        page
      )

      response <- request(url) |>
        req_url_query(
          app_id = APP_ID,
          app_key = APP_KEY,
          results_per_page = RESULTS_PER_PAGE,
          what = term,
          `content-type` = "application/json"
        ) |>
        req_timeout(30) |>
        req_retry(max_tries = 3) |>
        req_perform()

      page_data <- resp_body_json(response)

      results <- page_data$results

      if (is.null(results) || length(results) == 0) {
        cat("  No results returned.\n")
      } else {
        all_jobs <- c(all_jobs, results)
        cat("  Jobs returned:", length(results), "\n")
      }

      Sys.sleep(2)
    }
  }

  if (length(all_jobs) == 0) {
    stop("No jobs collected. Existing raw data was preserved.")
  }

  # Extract IDs and remove duplicate listings
  job_ids <- vapply(
    all_jobs,
    function(job) {
      if (is.null(job$id)) {
        NA_character_
      } else {
        as.character(job$id)
      }
    },
    character(1)
  )

  # Keep the first occurrence of each valid ID.
  # Preserve records with missing IDs rather than dropping them.
  valid_id <- !is.na(job_ids) & nzchar(job_ids)

  keep <- !valid_id
  keep[valid_id] <- !duplicated(job_ids[valid_id])

  unique_jobs <- all_jobs[keep]

  cat("\n-----------------------------\n")
  cat("Search terms:", length(SEARCH_TERMS), "\n")
  cat("Jobs collected:", length(all_jobs), "\n")
  cat("Unique jobs:", length(unique_jobs), "\n")
  cat("Duplicates removed:", sum(valid_id) - sum(keep & valid_id), "\n")
  cat("-----------------------------\n")

  unique_jobs
}

# -----------------------------
# Collect and save raw data
# -----------------------------

jobs <- collect_jobs()

write_json(
  jobs,
  "data/raw/jobs_raw.json",
  pretty = TRUE,
  auto_unbox = TRUE
)

cat("\nRaw data saved successfully.\n")
