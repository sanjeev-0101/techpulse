# TechPulse — Tech Job Market Analysis Dashboard

TechPulse is an interactive **R Shiny** dashboard for exploring technology job listings and identifying patterns in job roles, skill mentions, companies, locations, and salary-data availability. It uses job listings collected from the **Adzuna API** and provides a repeatable pipeline for collecting, cleaning, extracting skills, analyzing, and visualizing the data.

> **Important:** TechPulse analyzes a targeted collection of job listings, not the entire technology job market. Skill mentions are dictionary-based, role groups are heuristic, and salary currency/pay period are not independently verified. Treat the results as exploratory insights rather than definitive market-wide estimates.

## Contents

- [Project goals](#project-goals)
- [Features](#features)
- [Technology stack](#technology-stack)
- [How it works](#how-it-works)
- [Repository structure](#repository-structure)
- [Requirements](#requirements)
- [Installation and setup](#installation-and-setup)
- [Run the dashboard](#run-the-dashboard)
- [Refresh data from Adzuna](#refresh-data-from-adzuna)
- [Run tests](#run-tests)
- [Understanding the metrics](#understanding-the-metrics)
- [Data limitations](#data-limitations)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Team](#team)
- [License](#license)

## Project goals

TechPulse aims to make a collected set of technology job listings easier to explore by answering questions such as:

- Which technical skills appear most often in the collected listings?
- How do skill mentions vary across job-role families?
- Which companies and locations are most represented in the current selection?
- What role categories appear in the dataset?
- How much salary information is available, and what quality checks does it pass?
- Which individual listings match the selected filters?

## Features

### 1. Market overview

- Summary metrics for the current filtered selection.
- Breakdown of collected listings by role family and city.
- Most-mentioned technical skills.
- Companies represented in the current selection.

### 2. Skill Studio

- Compare skill mentions across the selected listings.
- Filter by role family, city, skill, and text search.
- View skill percentages and a skill-by-role matrix.
- Skill extraction checks job titles and available descriptions against a normalized keyword dictionary.

### 3. Job Explorer

- Search job titles and company names.
- Filter listings by role family, city, company, skill, salary-data status, and optionally creation-date range.
- Inspect individual listing details.
- Export the current globally filtered selection to CSV.

### 4. Data & Methods

- Review salary-data coverage and collection-health checks.
- Inspect listing creation-date patterns.
- Optionally display a diagnostic histogram of salary midpoints that pass the configured checks.
- Reload the local dataset without making an API request.
- Trigger an explicit Adzuna collection and rebuild pipeline when credentials are configured.
- Review the timestamp of the last successful collection when available.

### 5. Data pipeline

The project separates collection, cleaning, skill extraction, and analysis into R scripts. Live refresh stages outputs before publishing and attempts to preserve the previously published data if collection or processing fails.

## Technology stack

- **R** — data processing and analysis
- **Shiny** — interactive web application
- **bslib** — Bootstrap-based theme support
- **Plotly** — interactive charts
- **DT** — interactive data tables
- **httr2** — HTTP requests to Adzuna
- **jsonlite** — JSON parsing and serialization
- **dplyr**, **tidyr**, **stringr** — data cleaning and transformation
- **HTML/CSS/JavaScript** — dashboard layout, styling, and theme interaction

## How it works

```text
Adzuna API
    |
    v
R/collect_jobs.R
    |  Raw API responses
    v
 data/raw/jobs_raw.json
    |
    v
R/clean_jobs.R
    |  Normalized and deduplicated records
    v
 data/processed/jobs_clean.csv
    |
    +------------------------+
    |                        |
    v                        v
R/extract_skills.R      R/analyze_jobs.R
    |                        |
    v                        v
job_skills.csv          Summary CSV files
    \                        /
     \                      /
      v                    v
       dashboard/app.R
          |
          v
     Interactive Shiny UI
```

The dashboard can use the bundled processed snapshot without API credentials. Live collection requires valid Adzuna credentials and uses API quota.

## Repository structure

```text
techpulse-main/
├── README.md
├── run_dashboard.R              # Starts the Shiny application
├── install_packages.R           # Installs required R packages
├── R/
│   ├── collect_jobs.R            # Collects listings from Adzuna
│   ├── clean_jobs.R              # Cleans and deduplicates raw records
│   ├── dashboard_data.R          # Shared loading, role and skill logic
│   ├── extract_skills.R          # Creates listing-skill matches
│   ├── analyze_jobs.R             # Writes summary datasets
│   ├── refresh_dashboard.R       # Staged refresh and publishing workflow
│   ├── check_salary*.R           # Salary diagnostics
│   ├── inspect_salary_records.R  # Raw salary inspection helpers
│   └── test*.R                   # Validation scripts
├── dashboard/
│   ├── app.R                     # Shiny UI and server logic
│   └── www/                      # CSS assets
├── data/
│   ├── raw/                      # Bundled raw snapshot
│   └── processed/                # Clean data and derived summaries
├── docs/                         # Setup, test, and implementation notes
└── tests/
    └── test_pipeline.R
```

## Requirements

- R (a recent version is recommended)
- Internet access for installing packages and live Adzuna collection
- A modern web browser
- Adzuna application ID and key **only if you want to fetch live data**

## Installation and setup

### 1. Download the repository

Clone the repository or download it as a ZIP and extract it. Open a terminal in the project root — the directory containing `run_dashboard.R` and `install_packages.R`.

```bash
git clone https://github.com/sanjeev-0101/techpulse.git
cd techpulse
```

If you downloaded a ZIP, `cd` into the extracted project directory instead.

### 2. Install R dependencies

On Windows PowerShell, macOS, or Linux, run:

```bash
Rscript install_packages.R
```

The installer checks for and installs the packages used by the dashboard and data pipeline. If `Rscript` is not available on your PATH on Windows, run it using the full path to your R installation, for example:

```powershell
& "C:\Program Files\R\R-4.6.1\bin\x64\Rscript.exe" install_packages.R
```

Use the path corresponding to the R version installed on your computer.

## Run the dashboard

From the project root:

```bash
Rscript run_dashboard.R
```

Then open:

**http://127.0.0.1:3838**

Keep the terminal open while using the dashboard. Stop the server with `Ctrl+C` in the terminal.

### If port 3838 is already in use

This usually means another app or an earlier Shiny session is already using the port. Either stop the previous TechPulse process or run the dashboard on another port:

```bash
Rscript -e "shiny::runApp('dashboard', host='127.0.0.1', port=3839)"
```

Then open `http://127.0.0.1:3839`.

## Refresh data from Adzuna

### Configure credentials locally

Create or edit a `.Renviron` file in your project root (or configure the variables in your R environment) with the following entries:

```text
ADZUNA_APP_ID=your_app_id_here
ADZUNA_APP_KEY=your_app_key_here
```

Optional collection settings are:

```text
ADZUNA_COUNTRY=in
ADZUNA_PAGES_PER_ROLE=1
ADZUNA_RESULTS_PER_PAGE=50
ADZUNA_REQUEST_DELAY_SECONDS=1
```

The default country code is `in` (India). The collector uses 12 configured role/search terms by default. `ADZUNA_RESULTS_PER_PAGE` must be between 1 and 50. After editing `.Renviron`, restart R so the variables are loaded.

**Never commit `.Renviron` or paste your API key into source code, screenshots, issue reports, or public chat.** The repository `.gitignore` excludes `.Renviron`.

### Trigger a live refresh

1. Start the dashboard.
2. Open **Data & Methods**.
3. Choose **Collect & rebuild dataset** and confirm the action if prompted.
4. Wait for the status message and verify the displayed last-successful-refresh timestamp.

A live refresh calls the Adzuna API, so it consumes quota. Do not repeatedly refresh just to test the UI.

### What the refresh pipeline does

1. Collect raw listings from Adzuna.
2. Clean fields and deduplicate records with known IDs.
3. Extract skill mentions.
4. Recalculate analysis summaries.
5. Validate the staged dataset before publishing it.

The refresh code uses a lock to discourage concurrent refreshes and attempts to preserve the previous dataset when a pipeline stage fails. This is a local workflow, not a transactional multi-user database. Avoid running another process that writes to the same data files during refresh.

**Reload local data** reloads the existing local snapshot and does not make an API request.

## Run tests

From the project root, run:

```bash
Rscript R/test_dashboard.R
```

The test script checks data integrity, duplicate record keys, skill matching and aliases, empty selections, salary status handling, and R syntax parsing for key scripts.

There is also a `tests/` directory and additional diagnostic scripts under `R/`. Review `docs/SETUP_AND_TEST.md` for a more detailed manual acceptance checklist, including filtering, exports, and live-refresh safety checks.

A successful script run is not a substitute for checking the interactive dashboard in a browser. Test the main pages, filters, theme toggle, exports, and refresh behavior on the machine used for your demonstration.

## Understanding the metrics

- **Collected listings:** number of listings in the current filtered selection.
- **Companies:** distinct known company labels in that selection; not necessarily distinct parent organizations.
- **Skills detected:** matches to the configured skill dictionary, not every skill that may exist in the source text.
- **Salary bounds present:** share of listings with both minimum and maximum salary values available. Presence does not mean the values are correct.
- **Collection health:** counts of missing IDs, missing/unknown labels, listings with no detected dictionary skills, missing dates, and invalid salary bounds in the current selection.
- **Listing creation dates:** dates reported for listings in the current snapshot; they are not the same as collection/refresh timestamps.
- **Salary midpoint diagnostic:** midpoint of the provided minimum and maximum values for records that pass configured checks. The salary currency and pay period are not independently verified, so do not interpret the values as annual INR salaries unless that is established from source data.

## Data limitations

1. **Targeted sample, not a census.** The collection uses a configured list of job-search terms and API result limits. It does not represent every technology job or employer.
2. **Keyword-based skill extraction.** Only skills in the configured dictionary are detected. Unlisted technologies, missing descriptions, truncated descriptions, or ambiguous tokens can affect counts.
3. **Heuristic role groups.** Role families are inferred from job titles using text rules and can misclassify unusual titles.
4. **Company labels are not entity resolution.** Similar names may be represented separately, while cleaned or missing values may be grouped under an unknown label.
5. **Salary data is incomplete.** Many listings do not include salary bounds. Existing salary values may be estimates or use different periods/units. No independent salary verification is performed.
6. **Creation dates are listing metadata.** They should not be presented as complete market-wide hiring growth or as the time the app fetched a listing.
7. **API results can change.** Counts and charts can vary between refreshes as listings change, expire, or are returned in different result sets.

## Troubleshooting

### `Error in initialize(...): Failed to create server` / `address already in use`

Port 3838 is occupied. Open the existing app at `http://127.0.0.1:3838`, stop the old process, or run on port 3839 using the command above.

### `Rscript` is not recognized

Install R and add it to PATH, or use the full path to `Rscript.exe` as shown in the installation section.

### The dashboard does not start because a package is missing

Run `Rscript install_packages.R` from the project root, then start the dashboard again.

### The company chart or another chart is blank

Reset the filters and check whether the selected dataset has usable values for that chart. Inspect the R terminal for errors. A company chart cannot display meaningful bars if all company names are missing or excluded. Confirm that the dashboard's `output$companies` renderer exists and that the chart ID in the UI matches it.

### Live refresh reports missing credentials

Confirm `.Renviron` is in the expected location, the variable names are exactly `ADZUNA_APP_ID` and `ADZUNA_APP_KEY`, and restart R after changing it. Never put credentials in the repository.

### A refresh fails

Read the status message and terminal output. The existing published dataset should be preserved for collection/processing failures, but inspect the output files before retrying. If `.refresh-lock` remains after a crash, first confirm that no refresh process is active; only then remove the stale lock directory.

### Theme or CSS changes do not appear

Restart the app and hard-refresh the browser (`Ctrl+Shift+R` on most desktop browsers). Confirm you launched the project folder whose files you edited.

## Security

- Keep Adzuna credentials in a local `.Renviron` file or environment variables.
- Do not commit API keys, secrets, or private environment files.
- Review `git status` before committing and stage only the intended files.
- The export feature should be used for the current filtered selection; inspect exported data before sharing it publicly.

## Team

- **Sanjeev T K**
- **Hridhayansh Reddi Bommana**

Repository: [github.com/sanjeev-0101/techpulse](https://github.com/sanjeev-0101/techpulse)

## License

No license is specified in this repository at the time this README was prepared. If you want others to reuse, modify, or distribute the project, add a license file and update this section accordingly.
