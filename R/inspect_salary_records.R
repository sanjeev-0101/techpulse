
library(jsonlite)

jobs <- fromJSON(
  "data/raw/jobs_raw.json",
  simplifyVector = FALSE
)

shown <- 0

for (job in jobs) {
  if (!is.null(job$salary_min) &&
      !is.null(job$salary_max)) {

    cat("\n-------------------------\n")
    cat("Title:", job$title, "\n")
    cat("Minimum:", job$salary_min, "\n")
    cat("Maximum:", job$salary_max, "\n")
    cat("Predicted:", job$salary_is_predicted, "\n")
    cat("Description:", substr(job$description, 1, 250), "\n")

    shown <- shown + 1

    if (shown >= 5) break
  }
}
