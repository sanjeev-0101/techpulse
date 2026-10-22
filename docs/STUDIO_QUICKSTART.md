# TechPulse Studio redesign

## What this update changes
Only dashboard/app.R, a new dashboard/www/studio.css, and this documentation. Your collector, cleaner, data, .Renviron, launch script, and dependency installer are not replaced. Old style.css can remain: the new app does not load it. No additional R packages are needed beyond your existing installation. No external fonts, API key, internet connection or fabricated data is needed to explore the bundled snapshot.

The UI is built in R/Shiny with bslib, Plotly, DT and local CSS. No React, Python service, Node build, custom JavaScript, or external UI framework is required.

## Install from PowerShell in the project root
Stop the running app using Ctrl+C. With TechPulse_Studio_Update.zip in the project folder:

```powershell
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
Copy-Item .\dashboard\app.R ".\dashboard\app.R.backup-$stamp"
Expand-Archive -LiteralPath .\TechPulse_Studio_Update.zip -DestinationPath . -Force
& $Rscript run_dashboard.R
```

Keep your existing $Rscript variable. If this is a new terminal:

```powershell
$Rscript = "C:\Program Files\R\R-4.6.1\bin\x64\Rscript.exe"
& $Rscript run_dashboard.R
```

Open http://127.0.0.1:3838 and use Ctrl+F5 to clear cached styling. Use 100% browser zoom. If dependencies are missing, run `& $Rscript install_packages.R` first. Preserve .Renviron and never upload it.

## Screens
- Overview: compact metrics, top skills, role mix, locations and companies.
- Skill studio: up to five skills compared as percentages, an evidence summary and skill-by-role heatmap with denominators on hover.
- Job explorer: searchable/selectable table, description modal, detected skills and validated http/https source links.
- Data & methods: salary coverage, quality table, optional raw numeric midpoint histogram, creation dates, live refresh and methodology.

The rail stays fixed on desktop; the main document scrolls naturally. Chart heights are explicit, not compressed into the viewport. On smaller screens, navigation moves to the top and charts stack.

## Acceptance checks (before recording)
1. Overview shows 598 listings, 445 known company labels, 37 skills and 51% salary-bound coverage for the current committed snapshot.
2. Choose Python in the global skill filter: 61 listings; all charts and other pages follow that selection.
3. Reset; use More filters -> Unflagged only: 274 listings.
4. Reset; Skill studio -> compare Python, SQL, AWS: approximately 10.2%, 5.7%, 8.2%. Hover reports counts.
5. Hover heatmap cells: role-specific denominator and numerator are shown. A tiny role group should not be mistaken for strong evidence.
6. Job explorer: select a row, inspect its description/skills, close the modal, and check source link behavior. Links may be stale upstream.
7. Export with global Python filter: 61 CSV records. Global filters control export; table-only search/sort does NOT change export.
8. Combine incompatible filters: an empty table and clear chart messages appear; Reset restores 598 listings.
9. Verify date/salary/company filters in More filters. Advanced filters remain active when collapsed; Reset clears them.
10. Reload local data works without API calls. Keep live refresh separate from the demo: it blocks the local R session while running and consumes API quota.
11. Review browser display at 100% zoom and resize; check that no charts are vertically squeezed and content scrolls.
12. Check the R terminal for errors after every action.

## Verified here / still to test
The repository was freshly cloned before this redesign. Existing data regression tests passed: 598 listings, 634 listing-skill pairs, 37 normalized skills, alias/boundary matching, empty selections and salary status checks. The redesigned app passes R syntax parsing.

Shiny, bslib, Plotly and DT are not installed in the sandbox, so the redesigned UI, reactive interactions, downloads, modal behavior and refresh have NOT been browser/runtime-tested here. These require your local acceptance checks. This is a redesign build, not a claim that browser testing has already passed. Send the first terminal error and a browser screenshot if any check fails.

## Three-minute demonstration
0:00-0:20 Overview: explain the user problem, API source and collected snapshot. Do not call it a representative national dataset.
0:20-0:45 Overview charts: describe role mix and where listings are concentrated.
0:45-1:20 Skill studio: compare Python/SQL/AWS, then hover a role-skill cell to show its numerator and denominator.
1:20-1:55 Job explorer: select Python globally, open a real listing, explain its skills and available description, export the selection.
1:55-2:25 Data & methods: reset and show salary coverage, missingness and honest limitations.
2:25-2:45 Explain staged refresh, local credentials and last successful collection timestamp; use local reload instead of waiting for API collection.
2:45-3:00 Conclude with the R workflow: collect -> clean -> extract -> analyze -> explore.

Avoid showing API credentials, private environment files or real API error URLs in a recording. Use a clean browser window, 100% zoom and hide bookmarks/notifications. Practice once before recording.

## Commit after testing
```powershell
git add -- dashboard/app.R dashboard/www/studio.css docs/STUDIO_QUICKSTART.md
git diff --cached --stat
git commit -m "Redesign dashboard with skill studio and listing detail exploration"
```
Do not stage ZIP files or timestamped backups.
