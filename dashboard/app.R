library(shiny)
library(bslib)
library(plotly)
library(DT)
root <- normalizePath(if(file.exists("R/dashboard_data.R")) "." else "..",mustWork=TRUE)
source(file.path(root,"R/dashboard_data.R"),local=TRUE)
source(file.path(root,"R/refresh_dashboard.R"),local=TRUE)
initial <- load_jobs(root)
choices_for <- function(x) c("All",sort(unique(x)))
chart_card <- function(title,id) card(height="420px", full_screen=TRUE, card_header(title),plotlyOutput(id,height="330px"))
ui <- page_sidebar(
 fillable=FALSE,
 title=div(class="brand","TECHPULSE",span(" / JOB MARKET INTELLIGENCE",class="brand-sub")),
 theme=bs_theme(version=5,bootswatch="darkly",primary="#43c6b5",base_font="system-ui"),
 tags$head(tags$link(rel="stylesheet",href="style.css")),
 sidebar=sidebar(width=285,
  div(class="sidebar-label","EXPLORE THE DATASET"),
  textInput("search","Search title or company",placeholder="e.g. Python, analyst..."),
  selectizeInput("role","Role family",choices_for(initial$role)),
  selectizeInput("company","Company",choices_for(initial$company)),
  selectizeInput("location","Location",choices_for(initial$location)),
  selectizeInput("skill","Skill mention",choices_for(unlist(initial$skills))),
  selectInput("salary_filter","Salary coverage",c("All","Bounds present","Unflagged only")),
  checkboxInput("date_enabled","Filter listing creation dates",FALSE),
  dateRangeInput("dates","Creation date",start=min(initial$date,na.rm=TRUE),end=max(initial$date,na.rm=TRUE)),
  actionButton("reset","Reset filters",class="btn-outline-light"),
  hr(),downloadButton("download","Export filtered listings"),
  p(class="small-note","Targeted Adzuna searches in India. These listings are not a representative market census.")
 ),
 div(class="intro",h2("Technology hiring, made explorable."),p("Explore collected listings, discover skill mentions, and inspect data quality.")),
 uiOutput("metrics"),textOutput("scope"),br(),
 navset_card_tab(
  nav_panel("Overview",layout_columns(chart_card("Top skill mentions","overview_skills"),chart_card("Role families","overview_roles")),
   card(card_header("Dataset context"),p("Counts refer to distinct collected listings, not vacancies or hiring commitments. Role families are title-based heuristics. Skills are dictionary matches in titles and descriptions."),textOutput("freshness"))),
  nav_panel("Skills",layout_columns(chart_card("Most mentioned skills","skills"),chart_card("Role mix for selected skill","skill_roles")),
   p("Select a skill in the sidebar to inspect its role mix. Aliases are normalized; each listing counts at most once per skill. Missing mentions do not prove a skill is not required.")),
  nav_panel("Roles",layout_columns(chart_card("Role families","roles"),chart_card("Common job titles","titles"))),
  nav_panel("Companies",chart_card("Companies represented in this collection","companies")),
  nav_panel("Locations",chart_card("Locations represented in this collection","locations"),p("Locations use the API display labels, not geocoded cities. Different labels may refer to the same metro area.")),
  nav_panel("Salary",div(class="warning-note",strong("Salary fields are not verified compensation estimates."),p("Currency, pay period, and units are not verified per listing. No national salary average is calculated. Review flags are heuristics, not validation.")),
   chart_card("Salary coverage and review status","salary_quality"),
   checkboxInput("show_salary","Show raw numeric midpoint distribution (units / period unverified)",FALSE),
   conditionalPanel("input.show_salary",plotlyOutput("salary_hist"),p("Only finite, non-negative, ordered ranges without low-minimum or wide-range flags are included. An unflagged range can still be inaccurate. Values are not annualized."))),
  nav_panel("Listing dates",chart_card("Creation dates of currently collected listings","dates_plot"),
   p("This is a snapshot of creation dates, not historical hiring activity. Old listings and search selection affect the distribution. No forecast is made.")),
  nav_panel("Listings",DTOutput("listings"),p("Export includes the filtered listing records. External URLs are supplied as plain text by the API.")),
  nav_panel("Data quality",DTOutput("quality"),h4("Refresh controls"),
   p("Reload reads local processed files without using API quota. Live refresh runs the existing 12-search collector, then cleaning and analysis in a staging directory. It may take a minute or more; this local app blocks while refreshing."),
   actionButton("reload","Reload local data"),checkboxInput("consent","I understand live refresh uses Adzuna quota",FALSE),
   actionButton("refresh","Refresh from Adzuna",class="btn-primary"),verbatimTextOutput("refresh_status"),
   p("Credentials are read from your local .Renviron at R startup. Failed pipeline runs do not publish their staged results. Stop other readers/writers during refresh; multi-process concurrent publication is not supported."))
 ),
 footer=div(class="footer-note","TECHPULSE | Sanjeev T K & Hridhayansh Reddi Bommana | Source: Adzuna India")
)
server <- function(input,output,session) {
 data <- reactiveVal(initial); status <- reactiveVal("Ready. Existing dataset loaded; no API requests made.")
 filtered <- reactive({
  d <- data(); keep <- rep(TRUE,nrow(d))
  for(field in c("role","company","location")) if(!is.null(input[[field]]) && input[[field]]!="All") keep <- keep & d[[field]]==input[[field]]
  if(!is.null(input$skill) && input$skill!="All") keep <- keep & vapply(d$skills,function(s) input$skill %in% s,logical(1))
  if(nzchar(trimws(input$search))) keep <- keep & grepl(tolower(trimws(input$search)),tolower(paste(d$title,d$company)),fixed=TRUE)
  if(input$salary_filter=="Bounds present") keep <- keep & is.finite(d$salary_min) & is.finite(d$salary_max)
  if(input$salary_filter=="Unflagged only") keep <- keep & d$salary_status=="Unflagged / units unverified"
  if(isTRUE(input$date_enabled) && length(input$dates)==2) keep <- keep & !is.na(d$date) & d$date>=input$dates[1] & d$date<=input$dates[2]
  d[which(keep),,drop=FALSE]
 })
 observeEvent(input$reset,{
  for(f in c("role","company","location","skill")) updateSelectizeInput(session,f,selected="All")
  updateTextInput(session,"search",value="");updateSelectInput(session,"salary_filter",selected="All");updateCheckboxInput(session,"date_enabled",value=FALSE)
 })
 output$metrics <- renderUI({d<-filtered(); s<-skill_rows(d); top<-counts(s$skill,1)
  layout_columns(value_box("Collected listings",format(nrow(d),big.mark=",")),value_box("Companies",length(unique(d$company[d$company!="Unknown"]))),value_box("Locations",length(unique(d$location[d$location!="Unknown"]))),value_box("Top skill mention",if(nrow(top)) top$label[1] else "No matches"),col_widths=c(3,3,3,3))
 })
 output$scope <- renderText(paste(nrow(filtered()),"of",nrow(data()),"listings match your filters."))
 output$freshness <- renderText({data(); f<-file.path(root,"data/processed/last_refresh.txt"); if(file.exists(f)) paste("Last successful API refresh:",readLines(f,warn=FALSE)[1]) else "API collection timestamp was not recorded in the existing dataset. Listing creation dates are not collection dates."})
 bar <- function(x) {
  validate(need(nrow(x)>0,"No listings match these filters."))
  x <- x[nrow(x):1,,drop=FALSE]
  plot_ly(x,x=~listings,y=~label,type="bar",orientation="h",marker=list(color="#43c6b5"),hovertemplate="%{y}: %{x} listings<extra></extra>") |>
   layout(paper_bgcolor="transparent",plot_bgcolor="transparent",font=list(color="#dce5ee"),margin=list(l=150,r=25,b=45,t=10),xaxis=list(title="Listings",gridcolor="#293749"),yaxis=list(title="",categoryorder="array",categoryarray=x$label))
 }
 for(id in c("overview_skills","skills")) local({key<-id;output[[key]]<-renderPlotly(bar(counts(skill_rows(filtered())$skill)))})
 for(pair in list(c("overview_roles","role"),c("roles","role"),c("skill_roles","role"),c("titles","title"),c("companies","company"),c("locations","location"),c("salary_quality","salary_status"))) local({id<-pair[1];field<-pair[2];output[[id]]<-renderPlotly(bar(counts(filtered()[[field]])))})
 output$salary_hist <- renderPlotly({x<-filtered()$salary_midpoint; x<-x[is.finite(x)];validate(need(length(x)>0,"No unflagged numeric ranges in this selection."));plot_ly(x=x,type="histogram",marker=list(color="#43c6b5")) |> layout(xaxis=list(title="Raw midpoint (period and units unverified)"),yaxis=list(title="Listings"))})
 output$dates_plot <- renderPlotly({d<-filtered(); z<-d$date[!is.na(d$date)];validate(need(length(z)>0,"No valid dates."));x<-as.data.frame(table(format(z,"%Y-%m")));names(x)<-c("month","listings");plot_ly(x,x=~month,y=~listings,type="bar",marker=list(color="#43c6b5")) |> layout(xaxis=list(title="Creation month"),yaxis=list(title="Listings in current snapshot"))})
 export_data <- reactive({d<-filtered();d$skills<-vapply(d$skills,paste,character(1),collapse=", ");d[,setdiff(names(d),"record_key"),drop=FALSE]})
 output$listings<-renderDT({d<-export_data();datatable(d[,intersect(c("title","company","location","role","skills","created","salary_status","redirect_url"),names(d)),drop=FALSE],escape=TRUE,rownames=FALSE,filter="top",options=list(pageLength=10,scrollX=TRUE))})
 output$download<-downloadHandler(filename=function() paste0("techpulse-",Sys.Date(),".csv"),content=function(file){d<-export_data();for(k in names(d)) if(is.character(d[[k]])) d[[k]]<-ifelse(!is.na(d[[k]]) & grepl("^[=+@-]",d[[k]]),paste0("'",d[[k]]),d[[k]]);write.csv(d,file,row.names=FALSE,na="")})
 output$quality<-renderDT({d<-filtered(); z<-data.frame(Check=c("Listings","Missing IDs","Unknown companies","Unknown locations","Missing creation dates","No dictionary skill matches","Missing salary bounds","Review flagged salary","Invalid salary ranges"),Count=c(nrow(d),sum(is.na(d$job_id)|d$job_id==""),sum(d$company=="Unknown"),sum(d$location=="Unknown"),sum(is.na(d$date)),sum(lengths(d$skills)==0),sum(d$salary_status=="Missing bounds"),sum(d$salary_status=="Review flagged"),sum(d$salary_status=="Invalid range")));datatable(z,rownames=FALSE,options=list(dom="t",paging=FALSE))})
 reload <- function() {
  d<-load_jobs(root);data(d)
  for(f in c("role","company","location")) updateSelectizeInput(session,f,choices=choices_for(d[[f]]),selected="All",server=TRUE)
  updateSelectizeInput(session,"skill",choices=choices_for(unlist(d$skills)),selected="All",server=TRUE)
  updateDateRangeInput(session,"dates",start=min(d$date,na.rm=TRUE),end=max(d$date,na.rm=TRUE))
 }
 observeEvent(input$reload,{tryCatch({reload();status("Local data reloaded. No API calls made.")},error=function(e) status(conditionMessage(e)))})
 observeEvent(input$refresh,{
  if(!isTRUE(input$consent)) {status("Please acknowledge API quota use first.");return()}
  withProgress(message="Refreshing dataset; please wait",value=0.1,{
   tryCatch({refresh_dashboard(root);incProgress(0.8);reload();status("Refresh completed successfully. New data loaded.")},error=function(e) status(conditionMessage(e)))
  })
 })
 output$refresh_status<-renderText(status())
}
shinyApp(ui,server)
