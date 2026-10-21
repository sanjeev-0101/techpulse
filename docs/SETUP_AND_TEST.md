# TechPulse setup and acceptance checks

## Installation (Windows / PowerShell)
1. Back up your existing project folder. Stop any running dashboard.
2. Extract the completion ZIP into the project root (the directory containing R and data). Merge matching folders and replace the included files. Do not create an extra nested techpulse folder.
3. Keep your local .Renviron unchanged. This ZIP contains no credentials and does not need them to display the included real dataset.
4. From that root run:

```powershell
Rscript install_packages.R
Rscript R/extract_skills.R
Rscript R/analyze_jobs.R
Rscript R/test_dashboard.R
Rscript run_dashboard.R
```

If Rscript is not recognized, use your actual R installation path, for example:

```powershell
& "C:\Program Files\R\R-4.6.1\bin\x64\Rscript.exe" install_packages.R
& "C:\Program Files\R\R-4.6.1\bin\x64\Rscript.exe" run_dashboard.R
```

Open http://127.0.0.1:3838 in your browser. Leave the terminal running. Stop with Ctrl+C. For a busy port, run `Rscript -e "shiny::runApp('dashboard', host='127.0.0.1', port=3839)"` instead.

## Acceptance checklist
- On first launch, see 598 listings before filtering. This is the bundled snapshot, not a promise about future collection.
- Overview, Skills, Roles, Companies, Locations, Salary, Listing dates, Listings, and Data quality tabs load.
- Select Python: listing count falls and every displayed listing has a Python mention.
- Combine incompatible company/location filters: an empty table and a no-matches message appear, not an app crash.
- Reset filters restores all listings.
- Search title/company with punctuation: no regex error.
- Enable the date filter and narrow its range; reset restores all dates.
- Salary status counts total 598: missing 295, review 29, unflagged 274. No annual or national salary estimate is shown.
- Raw salary histogram is hidden until explicitly enabled.
- Export downloads only filtered listings. Text beginning with spreadsheet formula prefixes is escaped.
- Reload local data makes no API calls.
- Live refresh without acknowledgement makes no API calls.
- Without credentials, acknowledged refresh reports missing credentials and preserves the current dataset.
- With valid local credentials, refresh makes the existing 12 API searches and updates all stages. This consumes quota: do it once, not repeatedly for testing.
- For an API-failure preservation check, use invalid credentials in a separate local R session and verify the file hashes do not change. Never commit or share credentials.
- Test on your demo laptop/browser and resize the window before recording.

## Live refresh
The root .Renviron must define ADZUNA_APP_ID and ADZUNA_APP_KEY. Restart R after changing it. The collector and cleaner remain separate scripts. The dashboard stages collection, cleaning, extraction and analysis before copying outputs into the project. It locks concurrent refresh attempts, backs up destination files and attempts rollback on copy failures. This is a local single-process workflow, not a transactional multi-user database. Do not run other writers during refresh. Missing/failed API results leave the old data in place. An interrupted process can leave .refresh-lock; remove that folder only after confirming no refresh is active.

## What was tested by the assistant
The public repository was cloned and inspected. Base-R validation passed for 598 listings, unique record keys, normalized skill aliases, C++/C# matching, R/Java boundary cases, empty selections, salary coverage, and syntax parsing of all R scripts. Skills were regenerated: 634 distinct listing-skill pairs and 37 skills. These use titles AND descriptions, so they can differ from the original description-only extractor.

The sandbox does not have shiny, bslib, plotly, DT, httr2, jsonlite or stringr. Dependencies were NOT installed there. Browser rendering, Shiny reactive behavior, full collector/cleaner execution, live API refresh and rollback were NOT runtime-tested. Run the acceptance checklist locally; send the exact terminal error if a check fails. No API keys or fabricated listings were used.

## Data limitations
Targeted searches are not a census. Skill extraction is keyword-based; short tokens can still be ambiguous and API descriptions may be truncated. Role families are heuristic. Listing creation dates are not refresh history. Compensation period/currency are not verified, even for unflagged records. Data with unknown names is reported as Unknown. No salary summary asserting verified compensation is produced.

## Git safety
Review replacements, particularly R/clean_jobs.R and R/extract_skills.R. Original diagnostic scripts can remain. The duplicate salary_is_predicted field was removed from the cleaner; missing-ID rows are preserved. The dashboard loader also tolerates the older duplicate CSV column. Stage explicit files, never .Renviron.

```powershell
git status
git check-ignore .Renviron
git diff
```

## Suggested three-minute demo (after acceptance tests)
0:00-0:25: goal, Adzuna source, and overview metrics.
0:25-1:05: Python skill filter; compare roles, companies and locations.
1:05-1:35: listings table, search, and filtered CSV export.
1:35-2:05: salary coverage and honest limitations.
2:05-2:35: data quality and refresh workflow (use local reload rather than a live API wait).
2:35-3:00: R pipeline, Git collaboration, limitations and conclusion.
