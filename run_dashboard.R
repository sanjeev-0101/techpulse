if(!file.exists("dashboard/app.R")) stop("Run this command from the techpulse project root.")
if(!requireNamespace("shiny",quietly=TRUE)) stop("Run Rscript install_packages.R first.")
shiny::runApp("dashboard",host="127.0.0.1",port=3838,launch.browser=interactive())
