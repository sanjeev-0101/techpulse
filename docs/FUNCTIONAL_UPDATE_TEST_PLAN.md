# TechPulse functional update: installation and verification

## What this update changes

- **Adzuna collector:** validates configuration, allows optional environment-based collection settings, orders results by date, reports per-search counts, handles HTTP/API failures with actionable messages, deduplicates known IDs, preserves listings without IDs, and writes collection metadata.
- **Cleaning:** handles missing nested API fields more defensively, validates numeric salary values, keeps unknown-ID rows while removing duplicate known IDs, and writes cleaned data via a temporary file.
- **Refresh:** stages collection and processing before publishing, keeps a refresh lock, preserves the last known-good dataset on pipeline failure, and records successful refresh history (up to 100 rows).
- **Tests:** adds base-R checks for role classification, skill matching, skill rows and frequency counts.

The update intentionally does not redesign `dashboard/app.R` or CSS. UI work is a separate second stage.

## Install

1. Make a backup or commit your current project before replacing files.
2. Extract this ZIP into the TechPulse project root, preserving the folder structure.
3. Replace `R/collect_jobs.R`, `R/clean_jobs.R`, and `R/refresh_dashboard.R`.
4. Add `tests/test_pipeline.R` and this guide.
5. Keep your `.Renviron` local and out of Git. It should contain:
   ```
   ADZUNA_APP_ID=your_app_id
   ADZUNA_APP_KEY=your_app_key
   ```
6. Restart R/RStudio after changing `.Renviron`.

Optional local settings:
- `ADZUNA_COUNTRY=in`
- `ADZUNA_PAGES_PER_ROLE=1`
- `ADZUNA_RESULTS_PER_PAGE=50` (Adzuna endpoint allows up to 50 per page)
- `ADZUNA_REQUEST_DELAY_SECONDS=1`

## Test in this order

### A. Static/local checks
Run from the repository root:
```
Rscript tests/test_pipeline.R
```
Expected result: `PASS: role classification, skill extraction, skill rows and counts.`

Then run the existing dashboard with the existing local dataset:
```
Rscript run_dashboard.R
```
Check that Overview, Skill studio, Job explorer and Data & methods load.

### B. Test missing credentials safely
Temporarily unset credentials in a fresh R session and invoke the collector. It should stop with a clear credentials message before making network requests. Restore credentials afterward.

### C. Test live refresh
With valid credentials, run the dashboard and use **Collect & rebuild dataset** after checking the API-consent box. Confirm:
- The UI reports success.
- `data/raw/jobs_raw.json` and `data/processed/jobs_clean.csv` are updated.
- `data/processed/collection_metadata.json` contains search, count and timestamp details.
- `data/processed/last_refresh.txt` updates.
- `data/processed/refresh_history.csv` gains a success row.
- The dashboard reflects the refreshed records.

### D. Failure safety test
Do this only after backing up your local `data` folder. Temporarily use invalid credentials or block network access and run refresh. Confirm it reports failure and the previously published `jobs_clean.csv` remains unchanged. Restore credentials.

### E. Data quality spot checks
Inspect `data/processed/jobs_clean.csv`:
- Duplicate non-empty `job_id` values should not remain.
- Missing IDs are counted rather than silently discarded.
- Salary values are not annualized or treated as verified currency.
- Missing company/location values are retained and can be categorized by the dashboard.

## Important limitations

- This environment did not have an R runtime or live Adzuna credentials, so this ZIP has **not** been runtime-tested here. Run the test plan before using it for submission.
- Adzuna quota, credentials, network availability and current API behavior can affect live collection.
- The search terms remain a targeted sample of 12 role phrases. With one page and 50 results per phrase, the theoretical maximum is 600 raw results before deduplication—not all jobs in India.
- The existing dashboard uses local CSV/JSON files; the refresh history is local and is not a multi-user database.
- Salary quality flags are heuristics, not validation of currency or pay period.
