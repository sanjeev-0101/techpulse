# Lightweight base-R checks for the shared data logic. Run from repository root:
# Rscript tests/test_pipeline.R

source("R/dashboard_data.R")

stopifnot(length(role_family(c("Data Scientist", "Backend Developer", "DevOps Engineer"))) == 3)
stopifnot(role_family("Data Scientist") == "Data Scientist")
stopifnot(role_family("Backend Developer") == "Backend")
stopifnot(role_family("DevOps Engineer") == "DevOps")

matches <- extract_matches(c(
  "Python and SQL experience required",
  "AWS, Docker and Kubernetes",
  "No recognized skills listed"
))
stopifnot(all(c("Python", "SQL") %in% matches[[1]]))
stopifnot(all(c("AWS", "Docker", "Kubernetes") %in% matches[[2]]))
stopifnot(length(matches[[3]]) == 0)

sample <- data.frame(
  record_key = c("1", "2"),
  job_id = c("1", "2"),
  role = c("Backend", "Data Analyst"),
  stringsAsFactors = FALSE
)
sample$skills <- list(c("Python", "SQL"), c("SQL"))
rows <- skill_rows(sample)
stopifnot(nrow(rows) == 3)
stopifnot(sum(rows$skill == "SQL") == 2)

summary <- counts(c("R", "Python", "Python", "SQL"), 2)
stopifnot(nrow(summary) == 2)
stopifnot(summary$label[1] == "Python")
cat("PASS: role classification, skill extraction, skill rows and counts.\n")
