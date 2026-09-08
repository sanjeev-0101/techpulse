library(httr2)
library(jsonlite)

app_id <- Sys.getenv("ADZUNA_APP_ID")
app_key <- Sys.getenv("ADZUNA_APP_KEY")

url <- "https://api.adzuna.com/v1/api/jobs/in/search/1"

response <- request(url) |>
  req_url_query(
    app_id = app_id,
    app_key = app_key,
    results_per_page = 10,
    what = "software developer",
    `content-type` = "application/json"
  ) |>
  req_perform()

data <- resp_body_json(response)

print(data)