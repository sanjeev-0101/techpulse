
library(jsonlite)

jobs <- fromJSON(
  "data/raw/jobs_raw.json",
  simplifyVector = FALSE
)

has_value <- function(job, field) {
  value <- job[[field]]

  if (is.null(value) || length(value) == 0) {
    return(FALSE)
  }

  if (all(is.na(value))) {
    return(FALSE)
  }

  text_value <- as.character(value)

  any(!is.na(text_value) & nzchar(trimws(text_value)))
}

cat("Total jobs:", length(jobs), "\n")

cat(
  "Usable salary_min:",
  sum(vapply(jobs, has_value, logical(1), field = "salary_min")),
  "\n"
)

cat(
  "Usable salary_max:",
  sum(vapply(jobs, has_value, logical(1), field = "salary_max")),
  "\n"
)

cat(
  "Usable salary_is_predicted:",
  sum(vapply(jobs, has_value, logical(1), field = "salary_is_predicted")),
  "\n"
)
