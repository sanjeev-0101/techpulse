library(jsonlite)
library(dplyr)
library(tidyr)
library(stringr)

# -----------------------------
# TechPulse - Data Cleaning
# -----------------------------

# Load raw API data
jobs_raw <- fromJSON(
  "data/raw/jobs_raw.json",
  simplifyVector = FALSE
)

# Convert each job into a clean row
jobs_clean <- lapply(jobs_raw, function(job) {

  data.frame(
    job_id = if (!is.null(job$id)) {
      as.character(job$id)
    } else {
      NA_character_
    },

    title = if (!is.null(job$title)) job$title else NA_character_,

    company = if (!is.null(job$company$display_name)) {
      job$company$display_name
    } else {
      NA_character_
    },

    location = if (!is.null(job$location$display_name)) {
      job$location$display_name
    } else {
      NA_character_
    },

    category = if (!is.null(job$category$label)) {
      job$category$label
    } else {
      NA_character_
    },

    contract_time = if (!is.null(job$contract_time)) {
      job$contract_time
    } else {
      NA_character_
    },

    created = if (!is.null(job$created)) {
      job$created
    } else {
      NA_character_
    },

    salary_is_predicted = if (!is.null(job$salary_is_predicted)) {
      job$salary_is_predicted
    } else {
      NA_character_
    },

    description = if (!is.null(job$description)) {
      job$description
    } else {
      NA_character_
    },

    redirect_url = if (!is.null(job$redirect_url)) {
      job$redirect_url
    } else {
      NA_character_
    },

    salary_min = if (!is.null(job$salary_min)) {
      as.numeric(job$salary_min)
    } else {
      NA_real_
    },

    salary_max = if (!is.null(job$salary_max)) {
      as.numeric(job$salary_max)
    } else {
      NA_real_
    },

    salary_is_predicted = if (!is.null(job$salary_is_predicted)) {
      as.logical(job$salary_is_predicted)
    } else {
      NA
    },

    stringsAsFactors = FALSE
  )

}) |>
  bind_rows()

# -----------------------------
# Basic cleaning
# -----------------------------

jobs_clean <- jobs_clean |>
  mutate(
    title = str_squish(title),
    company = str_squish(company),
    location = str_squish(location),
    category = str_squish(category),
    contract_time = str_squish(contract_time),
    description = str_squish(description),

    created = as.POSIXct(
      created,
      format = "%Y-%m-%dT%H:%M:%SZ",
      tz = "UTC"
    ),

    average_salary = if_else(
      !is.na(salary_min) &
        !is.na(salary_max) &
        salary_min >= 0 &
        salary_max >= salary_min,
      (salary_min + salary_max) / 2,
      NA_real_
    ),
    
    salary_low_minimum = !is.na(salary_min) & salary_min < 10000,

    salary_wide_range = !is.na(salary_min) &
      !is.na(salary_max) &
      salary_max / pmax(salary_min, 1) > 50,

    salary_quality = case_when(
      is.na(salary_min) | is.na(salary_max) ~ "Missing salary",
      salary_low_minimum & salary_wide_range ~ "Review low minimum and wide range",
      salary_low_minimum ~ "Review low minimum",
      salary_wide_range ~ "Review wide range",
      TRUE ~ "Unflagged; period and units unverified"
    )
  ) |>
  distinct(job_id, .keep_all = TRUE)

# -----------------------------
# Save processed dataset
# -----------------------------

write.csv(
  jobs_clean,
  "data/processed/jobs_clean.csv",
  row.names = FALSE
)

cat("Clean jobs:", nrow(jobs_clean), "\n")
cat("Columns:", ncol(jobs_clean), "\n")
cat("Processed dataset saved successfully.\n")