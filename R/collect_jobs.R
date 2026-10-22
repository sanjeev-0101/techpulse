suppressPackageStartupMessages({
  library(httr2)
  library(jsonlite)
})

APP_ID <- Sys.getenv("ADZUNA_APP_ID")
APP_KEY <- Sys.getenv("ADZUNA_APP_KEY")
COUNTRY <- Sys.getenv("ADZUNA_COUNTRY", "in")

SEARCH_TERMS <- c(
  "software developer", "software engineer", "data scientist",
  "data analyst", "machine learning engineer", "AI engineer",
  "cloud engineer", "DevOps engineer", "cybersecurity engineer",
  "frontend developer", "backend developer", "full stack developer"
)

PAGES_PER_ROLE <- as.integer(Sys.getenv("ADZUNA_PAGES_PER_ROLE", "1"))
RESULTS_PER_PAGE <- as.integer(Sys.getenv("ADZUNA_RESULTS_PER_PAGE", "50"))
REQUEST_DELAY_SECONDS <- as.numeric(Sys.getenv("ADZUNA_REQUEST_DELAY_SECONDS", "1"))
ADZUNA_BASE_URL <- "https://api.adzuna.com/v1/api"

if (is.na(PAGES_PER_ROLE) || PAGES_PER_ROLE < 1) stop("ADZUNA_PAGES_PER_ROLE must be a positive integer.")
if (is.na(RESULTS_PER_PAGE) || RESULTS_PER_PAGE < 1 || RESULTS_PER_PAGE > 50) stop("ADZUNA_RESULTS_PER_PAGE must be between 1 and 50.")
if (is.na(REQUEST_DELAY_SECONDS) || REQUEST_DELAY_SECONDS < 0) stop("ADZUNA_REQUEST_DELAY_SECONDS must be zero or greater.")

collect_jobs <- function(
  app_id = APP_ID,
  app_key = APP_KEY,
  country = COUNTRY,
  search_terms = SEARCH_TERMS,
  pages_per_role = PAGES_PER_ROLE,
  results_per_page = RESULTS_PER_PAGE,
  request_delay_seconds = REQUEST_DELAY_SECONDS
) {
  if (!nzchar(app_id) || !nzchar(app_key)) {
    stop("Adzuna credentials missing. Set ADZUNA_APP_ID and ADZUNA_APP_KEY in your local .Renviron, then restart R.")
  }
  if (!length(search_terms)) stop("No search terms configured.")
  if (pages_per_role < 1 || results_per_page < 1 || results_per_page > 50) {
    stop("Invalid collection settings: pages must be positive and results_per_page must be between 1 and 50.")
  }

  collected <- list()
  search_log <- list()
  request_count <- 0L

  for (term in search_terms) {
    for (page in seq_len(pages_per_role)) {
      url <- paste0(ADZUNA_BASE_URL, "/jobs/", country, "/search/", page)
      cat(sprintf("\nSearching '%s' (page %d/%d)...\n", term, page, pages_per_role))

      response <- tryCatch(
        request(url) |>
          req_url_query(
            app_id = app_id,
            app_key = app_key,
            results_per_page = results_per_page,
            what = term,
            sort_by = "date",
            `content-type` = "application/json"
          ) |>
          req_timeout(30) |>
          req_retry(max_tries = 3) |>
          req_error(is_error = function(resp) FALSE) |>
          req_perform(),
        error = function(e) stop(sprintf(
          "Adzuna request failed for '%s', page %d: %s",
          term, page, conditionMessage(e)
        ), call. = FALSE)
      )
      request_count <- request_count + 1L

      if (resp_status(response) >= 400) {
        body <- tryCatch(resp_body_string(response), error = function(e) "")
        stop(sprintf("Adzuna returned HTTP %s for '%s'. Check credentials, quota and query parameters. %s",
                     resp_status(response), term, substr(body, 1, 300)), call. = FALSE)
      }

      page_data <- tryCatch(resp_body_json(response, simplifyVector = FALSE),
                            error = function(e) stop(sprintf("Could not parse Adzuna JSON for '%s': %s", term, conditionMessage(e)), call. = FALSE))
      results <- page_data$results
      n <- if (is.null(results)) 0L else length(results)
      search_log[[length(search_log) + 1L]] <- data.frame(
        search_term = term, page = page, returned = n, stringsAsFactors = FALSE
      )
      if (n) collected <- c(collected, results)
      cat(sprintf("  Returned: %d\n", n))

      if (request_delay_seconds > 0) Sys.sleep(request_delay_seconds)
    }
  }

  if (!length(collected)) {
    stop("Adzuna returned no listings. Existing raw and processed data have not been overwritten.")
  }

  ids <- vapply(collected, function(job) {
    if (is.null(job$id) || !length(job$id)) NA_character_ else as.character(job$id[[1]])
  }, character(1))
  valid_id <- !is.na(ids) & nzchar(ids)
  keep <- !valid_id
  keep[valid_id] <- !duplicated(ids[valid_id])
  unique_jobs <- collected[keep]

  # Metadata is written by the staged refresh process together with the data.
  metadata <- list(
    source = "Adzuna Jobs API",
    country = country,
    collected_at_utc = format(Sys.time(), tz = "UTC", format = "%Y-%m-%d %H:%M:%S UTC"),
    search_terms = as.list(search_terms),
    pages_per_role = pages_per_role,
    results_per_page = results_per_page,
    request_count = request_count,
    records_returned = length(collected),
    unique_records = length(unique_jobs),
    duplicate_ids_removed = sum(valid_id) - sum(keep & valid_id),
    records_without_id = sum(!valid_id),
    per_search = lapply(search_log, function(x) as.list(x[1, ]))
  )

  dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
  dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
  write_json(unique_jobs, "data/raw/jobs_raw.json", pretty = TRUE, auto_unbox = TRUE)
  write_json(metadata, "data/processed/collection_metadata.json", pretty = TRUE, auto_unbox = TRUE)

  cat("\n-----------------------------\n")
  cat("Search terms:", length(search_terms), "\n")
  cat("Requests:", request_count, "\n")
  cat("Records returned:", length(collected), "\n")
  cat("Unique records:", length(unique_jobs), "\n")
  cat("Duplicate IDs removed:", metadata$duplicate_ids_removed, "\n")
  cat("Records without ID:", metadata$records_without_id, "\n")
  cat("-----------------------------\n")
  invisible(metadata)
}

collect_jobs()
