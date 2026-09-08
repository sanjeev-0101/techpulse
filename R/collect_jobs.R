library(httr2)
library(jsonlite)

# -----------------------------
# TechPulse - Adzuna Collector
# -----------------------------

APP_ID <- Sys.getenv("ADZUNA_APP_ID")
APP_KEY <- Sys.getenv("ADZUNA_APP_KEY")

COUNTRY <- "in"
SEARCH_TERM <- "technology"
PAGES <- 3
RESULTS_PER_PAGE <- 50

collect_jobs <- function() {

  all_jobs <- list()

  for (page in 1:PAGES) {

    cat("Fetching page", page, "of", PAGES, "...\n")

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
        what = SEARCH_TERM,
        `content-type` = "application/json"
      ) |>
      req_perform()

    page_data <- resp_body_json(response)

    if (length(page_data$results) > 0) {
      all_jobs <- c(all_jobs, page_data$results)
    }

    Sys.sleep(1)
  }

  cat("Total jobs collected:", length(all_jobs), "\n")

  all_jobs
}


# Run collection
jobs <- collect_jobs()

# Save raw API response
write_json(
  jobs,
  "data/raw/jobs_raw.json",
  pretty = TRUE,
  auto_unbox = TRUE
)

cat("Raw data saved successfully.\n")