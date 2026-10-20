
library(dplyr)

jobs <- read.csv(
  "data/processed/jobs_clean.csv",
  stringsAsFactors = FALSE
)

cat("Total cleaned jobs:", nrow(jobs), "\n")
cat("Total columns:", ncol(jobs), "\n")

cat("\nSalary columns:\n")
print(
  intersect(
    c("salary_min", "salary_max",
      "salary_is_predicted", "average_salary"),
    names(jobs)
  )
)

cat("\nJobs with usable average salary:",
    sum(!is.na(jobs$average_salary)), "\n")

cat("Jobs missing average salary:",
    sum(is.na(jobs$average_salary)), "\n")

cat("\nSample salary records:\n")
print(
  jobs |>
    select(title, salary_min, salary_max, average_salary) |>
    filter(!is.na(average_salary)) |>
    head(5)
)
