packages <- c("shiny","bslib","plotly","DT","httr2","jsonlite","dplyr","tidyr","stringr")
missing <- packages[!vapply(packages,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)) install.packages(missing,repos="https://cloud.r-project.org")
cat("Dependencies ready. Run: Rscript run_dashboard.R\n")
