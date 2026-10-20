
jobs <- read.csv("data/processed/jobs_clean.csv")

cat(
  "Low minimum:",
  sum(jobs$salary_low_minimum, na.rm = TRUE),
  "\n"
)

cat(
  "Wide range:",
  sum(jobs$salary_wide_range, na.rm = TRUE),
  "\n"
)
