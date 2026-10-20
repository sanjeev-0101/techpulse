
library(dplyr)
library(stringr)

jobs <- read.csv(
  "data/processed/jobs_clean.csv",
  stringsAsFactors = FALSE
)

salary_audit <- jobs |>
  filter(!is.na(salary_min), !is.na(salary_max)) |>
  mutate(
    invalid_range = salary_max < salary_min,
    very_low_minimum = salary_min > 0 & salary_min < 10000,
    very_wide_range = salary_max / pmax(salary_min, 1) > 50,
    description_mentions_monthly_pay = str_detect(
      str_to_lower(description),
      "per month|monthly|/month"
    )
  )

cat("Salary records:", nrow(salary_audit), "\n")
cat("Inverted ranges:", sum(salary_audit$invalid_range), "\n")
cat("Minimum below 10,000:", sum(salary_audit$very_low_minimum), "\n")
cat("Maximum/minimum ratio above 50:",
    sum(salary_audit$very_wide_range), "\n")
cat("Descriptions mentioning monthly pay:",
    sum(salary_audit$description_mentions_monthly_pay), "\n")

cat("\nSuspicious salary examples:\n")

print(
  salary_audit |>
    filter(
      invalid_range |
      very_low_minimum |
      very_wide_range
    ) |>
    select(
      title, salary_min, salary_max,
      average_salary, description
    ) |>
    head(10)
)
