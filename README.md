# TechPulse — Tech Job Market Intelligence Dashboard

TechPulse is an R Shiny dashboard for exploring collected technology job listings, skill mentions, role families, companies, locations, and salary-data quality.

## Run locally

From the repository root:

```bash
Rscript install_packages.R
Rscript run_dashboard.R
```

Then open `http://127.0.0.1:3838`.

## Project structure

```text
techpulse-main/
├── dashboard/
│   ├── app.R
│   └── www/
│       ├── style.css
│       └── studio.css
├── R/                 # collection, cleaning, analysis, and dashboard data helpers
├── data/
│   ├── raw/
│   └── processed/
├── docs/              # setup, testing, and design documentation
├── tests/
├── install_packages.R
└── run_dashboard.R
```

## Dashboard sections

1. **Overview** — listing KPIs, skill mentions, role mix, locations, and companies.
2. **Skill studio** — skill comparison, skill-by-role heatmap, and contextual insights.
3. **Job explorer** — searchable/filterable records, job details, and CSV export.
4. **Data & methods** — salary coverage, collection health, date distribution, and refresh tools.

## Design system

The current interface uses a Swiss-minimal visual direction: monochrome palette, strict grid, compact fixed navigation, restrained borders, typography-led hierarchy, balanced density, and light/dark themes. See [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md).

## Data collection

The existing R collection and refresh pipeline is retained. Live collection requires valid Adzuna credentials configured in the local environment. Do not commit API credentials or `.Renviron` files.

## Notes

- Salary values are exploratory source fields; their presence does not establish accuracy, currency, or pay period.
- Role groups and skill mentions are heuristic classifications.
- The collected listings are a targeted sample, not a census of the Indian technology job market.
\n## Public project homepage\n\nThe repository root includes a standalone, responsive landing page (`index.html`) designed to introduce TechPulse and direct visitors to the Shiny dashboard. It can be published independently with GitHub Pages.\n\nAfter the Shiny app is deployed, open `site-config.js` and set `window.TECHPULSE_DASHBOARD_URL` to its public HTTPS URL. Until this is configured, dashboard links show a setup notice rather than sending visitors to a broken address.\n\nThe landing page uses `landing.css` and `landing.js`; it does not change the Shiny application or its data pipeline.\n