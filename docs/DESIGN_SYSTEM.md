# TechPulse visual redesign

## Direction
Swiss minimal: monochrome, strict grid, typography-led, balanced information density, compact fixed sidebar, and persistent light/dark themes.

## Design tokens

| Token | Light | Dark |
|---|---|---|
| Background | `#f4f4f1` | `#171917` |
| Surface | `#ffffff` | `#202320` |
| Secondary surface | `#f7f7f5` | `#252925` |
| Main text | `#202321` | `#eceee9` |
| Muted text | `#737873` | `#a2a79f` |
| Border | `#e2e4df` | `#343a34` |
| Accent | `#343a36` | `#e1e5de` |

## Layout principles
- Fixed, compact desktop navigation rail; horizontally scrollable compact navigation on small screens.
- Consistent two-column chart grid with single-column mobile fallback.
- Thin borders, square/low-radius corners, minimal shadows, and no decorative gradients or glow.
- KPI cards use aligned labels, numeric values, and concise context notes.
- Tables, controls, dialogs, and chart labels inherit the active theme.

## Functional preservation
The redesign is presentation-focused. Existing Shiny input/output IDs, filtering, tab navigation, Plotly interactions, DT row selection, job detail modal, CSV export, local reload, API refresh, and data-processing scripts are retained. The plot palette and theme-aware chart text/heatmap colours were adjusted to match the monochrome system.

## Files changed
- `dashboard/www/style.css`: complete replacement of the previous glass/emerald visual system.
- `dashboard/www/studio.css`: kept in sync with the main stylesheet.
- `dashboard/app.R`: neutral Bootstrap theme, light as the first-visit default, neutral navigation states, and monochrome chart palette.
