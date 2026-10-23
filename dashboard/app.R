# TechPulse Studio: a local R/Shiny application. No external font/CDN assets required.
library(shiny)
library(bslib)
library(plotly)
library(DT)
root <- normalizePath(if(file.exists("R/dashboard_data.R")) "." else "..",mustWork=TRUE)
source(file.path(root,"R/dashboard_data.R"),local=TRUE)
source(file.path(root,"R/refresh_dashboard.R"),local=TRUE)
normalize_city <- function(x) {
 x <- trimws(as.character(x))
 lower <- tolower(x)
 out <- x
 out[is.na(x) | !nzchar(x)] <- "Unknown / unspecified"
 lower <- tolower(out)
 out[lower %in% c("india","india, india","all india")] <- "India (country-wide)"
 out[grepl("bangalore|bengaluru", lower)] <- "Bengaluru"
 out[grepl("chennai|madras", lower)] <- "Chennai"
 out[grepl("hyderabad", lower)] <- "Hyderabad"
 out[grepl("pune", lower)] <- "Pune"
 out[grepl("mumbai|bombay", lower)] <- "Mumbai"
 out[grepl("delhi|new delhi|gurugram|gurgaon|noida", lower)] <- "Delhi NCR"
 out[grepl("kolkata|calcutta", lower)] <- "Kolkata"
 out[grepl("ahmedabad", lower)] <- "Ahmedabad"
 out[grepl("kochi|cochin", lower)] <- "Kochi"
 out[grepl("coimbatore", lower)] <- "Coimbatore"
 out[grepl("jaipur", lower)] <- "Jaipur"
 out[grepl("indore", lower)] <- "Indore"
 out[grepl("chandigarh", lower)] <- "Chandigarh"
 out[grepl("lucknow", lower)] <- "Lucknow"
 out[grepl("thiruvananthapuram|trivandrum", lower)] <- "Thiruvananthapuram"
 out[grepl("visakhapatnam|vizag", lower)] <- "Visakhapatnam"
 out[grepl("bhubaneswar", lower)] <- "Bhubaneswar"
 out[grepl("mysuru|mysore", lower)] <- "Mysuru"
 out[grepl("vadodara|baroda", lower)] <- "Vadodara"
 out[grepl("surat", lower)] <- "Surat"
 out[grepl("nagpur", lower)] <- "Nagpur"
 out[grepl("patna", lower)] <- "Patna"
 out[grepl("ranchi", lower)] <- "Ranchi"
 out[grepl("guwahati", lower)] <- "Guwahati"
 out
}
initial <- load_jobs(root)
initial$city <- normalize_city(initial$location)
opts <- function(x,label="All") { z <- c("All",sort(unique(x))); names(z) <- z; names(z)[1] <- label; z }
panel <- function(title,subtitle=NULL,...,class="") div(class=paste("panel",class),div(class="panel-heading",h3(title),if(!is.null(subtitle)) p(subtitle)),...)
chart <- function(id,height="340px") plotlyOutput(id,height=height)
nav_button <- function(id,number,label) actionButton(id,label=tagList(span(number,class="nav-number"),span(label)),class="rail-link")
ui <- fluidPage(
 theme=bs_theme(version=5, bg="#071312",fg="#e7f4f0",primary="#18a58f",base_font="system-ui"),
 tags$head(
    tags$link(rel="stylesheet",href="style.css?v=5"),
    tags$script(HTML("document.addEventListener('DOMContentLoaded', function(){
      document.body.classList.remove('theme-light');
      document.body.classList.add('theme-dark');
      document.addEventListener('click', function(e){
        if(e.target && e.target.closest && e.target.closest('#theme_toggle')){
          var light = document.body.classList.toggle('theme-light');
          document.body.classList.toggle('theme-dark', !light);
        }
      });
    });"))
   ),
 div(class="studio",
  tags$aside(class="rail",
   div(class="wordmark",span("T",class="logo-mark"),div(strong("techpulse"),tags$small("MARKET INTELLIGENCE"))),
   div(class="rail-caption","WORKSPACE"),
   nav_button("nav_overview","01","Overview"),nav_button("nav_skills","02","Skill studio"),nav_button("nav_jobs","03","Job explorer"),nav_button("nav_quality","04","Data & methods"),
   div(class="rail-bottom",span(class="source-dot"),strong("Adzuna / India"),p("An exploration of collected technology job listings."),span(class="rail-credit","Sanjeev T K\nHridhayansh Reddi Bommana"))
  ),
  tags$main(class="workspace",
   div(class="topline",span("RESEARCH WORKSPACE / TECH JOBS"),div(class="top-actions",actionButton("theme_toggle","Light / dark",class="btn-quiet"),actionButton("reload","Reload local data",class="btn-quiet"),downloadButton("download","Export selection",class="btn-export"))),
   div(class="page-heading",div(span("THE HIRING LANDSCAPE",class="eyebrow"),h1(textOutput("page_title",inline=TRUE)),p(textOutput("page_subtitle",inline=TRUE))),span("IN",class="country-badge")),
   div(class="filterbar",
    div(class="search-control",textInput("search",NULL,placeholder="Search title or company (2+ characters)")),
    selectizeInput("role",NULL,choices=opts(initial$role,"All role families"),options=list(placeholder="All role families")),
    selectizeInput("city",NULL,choices=opts(initial$city,"All cities"),options=list(placeholder="All cities")),
    selectizeInput("skill",NULL,choices=opts(unlist(initial$skills),"All skills"),options=list(placeholder="All skills")),
    actionButton("advanced","More filters",class="btn-quiet"),actionButton("reset","Reset",class="btn-reset")
   ),
   conditionalPanel("input.advanced % 2 == 1",div(class="advanced-filters",
    selectizeInput("company","Company",opts(initial$company),options=list(minChars=2,openOnFocus=FALSE,maxOptions=100,placeholder="Type 2+ characters to find a company")),selectInput("salary_filter","Salary data",c("All","Bounds present","Unflagged only")),
    div(checkboxInput("date_enabled","Limit creation dates",FALSE),dateRangeInput("dates",NULL,start=min(initial$date,na.rm=TRUE),end=max(initial$date,na.rm=TRUE)))
   )),
   div(class="selection-line",textOutput("scope"),uiOutput("filter_tags")),
   tabsetPanel(id="pages",type="hidden",
    tabPanel("Overview",value="overview",
     uiOutput("metrics"),
     div(class="grid-two overview-grid",
      panel("Skills in the spotlight","Distinct listings mentioning each skill",chart("top_skills")),
      panel("The role mix","Title-based classification of collected listings",chart("role_mix"))
     ),
     div(class="grid-two",
      panel("Listings by city","Select a bar to filter the dashboard and open matching jobs. Neighbourhoods are grouped by city.",chart("locations","310px")),
      panel("Companies in the collection","Most represented companies in this selection",chart("companies","310px"))
     ),
     div(class="context-strip",strong("A snapshot, not a census."),span("Targeted searches shape what is collected. Counts describe listings, not total vacancies or national hiring demand."))
    ),
    tabPanel("Skills",value="skills",
     div(class="grid-two skill-top",
      panel("Build your skill comparison","Choose up to five skills; percentages use the current filtered selection.",
       selectizeInput("compare",NULL,choices=sort(names(skill_dictionary)),selected=c("Python","SQL","AWS"),multiple=TRUE,options=list(maxItems=5)),chart("compare_plot","300px")),
      panel("Reading the signals","A quick interpretation of this selection",uiOutput("skill_insights"),class="insight-panel")
     ),
     panel("Skill x role matrix","Percentage of listings within each role mentioning a skill. Hover for counts and sample size.",chart("heatmap","440px")),
     div(class="context-strip",strong("Mentions, not endorsements."),span("Matching uses titles and available descriptions, including normalized aliases. Missing text, ambiguous tokens and truncated descriptions can affect results."))
    ),
    tabPanel("Jobs",value="jobs",
     panel("Explore the records","Select a row to inspect the description, detected skills and source link.",DTOutput("listings")),
     div(class="context-strip",strong("Take the selection with you."),span("Export selection downloads all records matching the global filters. Table-only search and sorting do not change the export."))
    ),
    tabPanel("Quality",value="quality",
     div(class="grid-two",
      panel("Salary data coverage","Presence of salary fields does not establish accuracy or pay period.",chart("salary_quality","300px")),
      panel("Collection health","Checks apply to the currently filtered selection.",DTOutput("quality"))
     ),
     panel("Inspect raw salary values","Optional diagnostic view. No annualization or verified currency assumption.",
      checkboxInput("show_salary","Show unflagged numeric midpoints",FALSE),conditionalPanel("input.show_salary",chart("salary_hist","300px")),
      p(class="muted","Unflagged values may still be incorrect. Non-finite, negative, inverted, low-minimum and very wide ranges are excluded from this diagnostic.")),
     panel("Listing creation dates","Dates of listings in the current snapshot, not observed hiring growth.",chart("date_plot","260px")),
     div(class="grid-two",
      panel("Refresh the dataset","Live collection is optional and uses your Adzuna quota.",
       textOutput("freshness"),
       div(class="refresh-actions",
         checkboxInput("consent","I understand this makes API requests",FALSE),
         actionButton("refresh","Collect & rebuild dataset",class="btn-export")),
       div(class="refresh-status",verbatimTextOutput("status"))),
      panel("How TechPulse works","A transparent, reproducible R workflow.",
       tags$ol(class="method-list",tags$li(strong("Collect")," Targeted role searches through Adzuna India."),tags$li(strong("Clean")," Normalize records and deduplicate known IDs."),tags$li(strong("Extract")," Match a normalized skill dictionary once per listing."),tags$li(strong("Explore")," Filter, compare and inspect the underlying records.")),
       p(class="muted","Role groups are heuristics. No salary prediction, hiring forecast or claim of representative national coverage is made."))
     )
    )
   ),
   tags$footer(span("TECHPULSE / PROGRAMMING FOR DATA SCIENCE"),span("Built with R + Shiny. Powered by collected Adzuna listings."))
  )
 )
)
server <- function(input,output,session) {
 data <- reactiveVal(initial); status <- reactiveVal("Ready. No API requests made.")
 pages <- c(overview="Market overview",skills="Skill studio",jobs="Find the story behind a listing",quality="Know your data")
 subtitles <- c(overview="A clearer view of the technology roles, skills and companies in your collection.",skills="Compare skill mentions and see how they differ across role families.",jobs="Move from aggregate patterns to the actual job records.",quality="Inspect coverage, understand limitations, and refresh with confidence.")
 for(name in names(pages)) local({key<-name;observeEvent(input[[paste0("nav_",if(key=="jobs") "jobs" else key)]],updateTabsetPanel(session,"pages",selected=key))})
 # Navigation uses action buttons; active state is supplied through a tiny R-rendered stylesheet.
 output$page_title <- renderText(pages[[input$pages]])
 output$page_subtitle <- renderText(subtitles[[input$pages]])
 output$nav_style <- renderUI({ req(input$pages); tags$style(HTML(paste0("#nav_",input$pages,"{background:rgba(80,217,186,.13)!important;color:#effff9!important;border-color:rgba(80,217,186,.25)!important} #nav_",input$pages," .nav-number{color:#65e4c5}"))) })
 filtered_data <- function(ignore_city=FALSE) {
  d<-data()
  if(!"city" %in% names(d)) d$city<-normalize_city(d$location)
  keep<-rep(TRUE,nrow(d))
  for(f in c("role","city","skill","company")) {
   if(f=="city" && ignore_city) next
   x<-input[[f]]
   if(!is.null(x)&&length(x)>0&&nzchar(x[1])&&x[1]!="All") {
    target<-if(f=="city") d$city else d[[f]]
    keep<-keep & if(f=="skill") vapply(d$skills,function(s)x[1] %in% s,logical(1)) else target==x[1]
   }
  }
  if(!is.null(input$search)&&nchar(trimws(input$search))>=2) keep<-keep & grepl(tolower(trimws(input$search)),tolower(paste(d$title,d$company)),fixed=TRUE)
  if(identical(input$salary_filter,"Bounds present")) keep<-keep & is.finite(d$salary_min)&is.finite(d$salary_max)
  if(identical(input$salary_filter,"Unflagged only")) keep<-keep & d$salary_status=="Unflagged / units unverified"
  if(isTRUE(input$date_enabled)&&length(input$dates)==2&&!anyNA(input$dates)) keep<-keep & !is.na(d$date)&d$date>=input$dates[1]&d$date<=input$dates[2]
  d[which(keep),,drop=FALSE]
 }
 filtered <- reactive(filtered_data(FALSE))
 observeEvent(input$reset,{
  for(f in c("role","city","skill","company")) updateSelectizeInput(session,f,selected="All")
  updateTextInput(session,"search",value="");updateSelectInput(session,"salary_filter",selected="All");updateCheckboxInput(session,"date_enabled",value=FALSE)
 })
 output$scope<-renderText(paste(format(nrow(filtered()),big.mark=","),"of",format(nrow(data()),big.mark=","),"collected listings"))
 output$filter_tags<-renderUI({
  tags<-lapply(c("role","city","skill","company"),function(f) {x<-input[[f]];if(!is.null(x)&&nzchar(x)&&x!="All") span(class="filter-chip",x)})
  tagList(tags)
 })
 output$metrics<-renderUI({
  d<-filtered();s<-skill_rows(d);coverage<-if(nrow(d)) round(100*mean(is.finite(d$salary_min)&is.finite(d$salary_max))) else 0
  metric<-function(label,value,note,accent=FALSE) div(class=paste("metric",if(accent) "metric-accent" else ""),span(class="metric-label",label),strong(class="metric-value",value),span(class="metric-note",note))
  div(class="metrics",metric("COLLECTED LISTINGS",format(nrow(d),big.mark=","),"Within the current selection",TRUE),metric("COMPANIES",length(unique(d$company[d$company!="Unknown"])),"Distinct known company labels"),metric("SKILLS DETECTED",length(unique(s$skill)),"Normalized dictionary matches"),metric("SALARY BOUNDS PRESENT",paste0(coverage,"%"),"Coverage is not verification"))
 })
 colors<-c("#18a58f","#35a6a1","#edac65","#2f9e8f","#62cbb6","#d98b9c","#7ea384","#bac1ce","#d6bf78","#82b9c3","#8de0cf")
 finish<-function(p,margin=list(l=15,r=20,t=15,b=25)) {
  dark<-is.null(input$theme_toggle) || input$theme_toggle %% 2 == 0
  font_color<-if(dark) "#d0dae4" else "#64748b"
  p<-layout(p,paper_bgcolor="rgba(0,0,0,0)",plot_bgcolor="rgba(0,0,0,0)",
    font=list(family="Inter, ui-sans-serif, system-ui, sans-serif",size=12,color=font_color),margin=margin)
  config(p,displayModeBar=FALSE,responsive=TRUE)
 }
 bars<-function(z,color="#18a58f",source=NULL) {
  shiny::validate(shiny::need(nrow(z)>0,"No records match this selection. Try resetting the filters."))
  z<-z[nrow(z):1,,drop=FALSE]
  p<-plot_ly(z,x=~listings,y=~label,type="bar",orientation="h",source=source,marker=list(color=color),hovertemplate="%{y}<br>%{x:,d} listings<extra></extra>")
  finish(layout(p,
    xaxis=list(title="",gridcolor="rgba(148,163,184,0.18)",zeroline=FALSE,rangemode="tozero",nticks=5,tickformat=",d",automargin=TRUE,tickfont=list(size=10)),
    yaxis=list(title="",categoryorder="array",categoryarray=z$label,automargin=TRUE,tickfont=list(size=11)),
    bargap=.38),list(l=12,r=25,t=10,b=42))
 }
 output$top_skills<-renderPlotly(bars(counts(skill_rows(filtered())$skill,8)))
 output$locations<-renderPlotly({
  d<-filtered_data(ignore_city=TRUE)
  z<-counts(d$city,10)
  bars(z,"#38b9a7",source="city_plot")
 })
 
output$companies <- renderPlotly({
  d <- filtered()

  d <- d[
    !is.na(d$company) &
    nzchar(trimws(d$company)) &
    d$company != "Unknown",
    ,
    drop = FALSE
  ]

  z <- counts(d$company, 10)
  bars(z, "#18a58f")
})

 observeEvent(event_data("plotly_click",source="city_plot"),{
  click<-event_data("plotly_click",source="city_plot")
  if(is.null(click)||is.null(click$y)) return()
  chosen<-as.character(click$y[1])
  if(identical(input$city,chosen)) updateSelectizeInput(session,"city",selected="All")
  else updateSelectizeInput(session,"city",selected=chosen)
  updateTabsetPanel(session,"pages",selected="jobs")
 },ignoreInit=TRUE)
 output$role_mix<-renderPlotly({
  z<-counts(filtered()$role,20);shiny::validate(shiny::need(nrow(z)>0,"No records match this selection."))
  p<-plot_ly(z,labels=~label,values=~listings,type="pie",hole=.68,sort=FALSE,marker=list(colors=colors,line=list(color="white",width=3)),textinfo="none",hovertemplate="%{label}<br>%{value} listings (%{percent})<extra></extra>")
  dark<-is.null(input$theme_toggle) || input$theme_toggle %% 2 == 0
  center_color<-if(dark) "#dffcf3" else "#18312d"
  finish(layout(p,showlegend=TRUE,legend=list(orientation="h",x=0,y=-.05,font=list(size=11)),
    annotations=list(list(text=paste0("<b>",nrow(z),"</b><br>role groups"),x=.5,y=.5,showarrow=FALSE,
      font=list(size=17,color=center_color)))),list(l=8,r=8,t=5,b=20))
 })
 output$compare_plot<-renderPlotly({
  d<-filtered();shiny::validate(shiny::need(nrow(d)>0,"No listings in this selection."),shiny::need(length(input$compare)>0,"Choose one or more skills above."))
  keys<-input$compare
  nums<-vapply(keys,function(k)sum(vapply(d$skills,function(s)k %in% s,logical(1))),integer(1))
  z<-data.frame(skill=keys,n=nums,pct=100*nums/nrow(d));z<-z[order(z$pct),]
  p<-plot_ly(z,x=~pct,y=~skill,type="bar",orientation="h",marker=list(color="#18a58f"),customdata=~n,hovertemplate="%{y}<br>%{x:.1f}% / %{customdata} listings<extra></extra>")
  finish(layout(p,xaxis=list(title="% of selected listings",range=c(0,max(10,max(z$pct)*1.2)),gridcolor="rgba(148,163,184,0.18)"),yaxis=list(title="",categoryorder="array",categoryarray=z$skill),bargap=.5))
 })
 output$skill_insights<-renderUI({
  d<-filtered();s<-skill_rows(d);z<-counts(s$skill,1)
  if(!nrow(d)) return(p("No records match your filters."))
  matched<-sum(lengths(d$skills)>0)
  div(class="insights",span(class="insight-kicker","MOST MENTIONED"),h2(if(nrow(z)) z$label[1] else "No skill matches"),
   p(if(nrow(z)) paste(z$listings[1],"listings mention this skill in the current selection.") else "Try a broader selection."),
   hr(),div(class="insight-stat",strong(paste0(round(100*matched/nrow(d)),"%")),span("of selected listings contain at least one dictionary skill mention.")),
   p(class="muted","Use the comparison chart for specific skills and the matrix below for differences between role groups."))
 })
 output$heatmap<-renderPlotly({
  d<-filtered();s<-skill_rows(d);shiny::validate(shiny::need(nrow(s)>0,"No detected skill mentions in this selection."))
  skills<-counts(s$skill,10)$label;roles<-counts(d$role,12)$label
  m<-matrix(0,nrow=length(skills),ncol=length(roles));hover<-matrix("",nrow(m),ncol(m))
  for(i in seq_along(skills)) for(j in seq_along(roles)) {
   den<-sum(d$role==roles[j]);num<-sum(s$role==roles[j]&s$skill==skills[i]);m[i,j]<-100*num/den
   hover[i,j]<-paste0(skills[i],"<br>",roles[j],"<br>",num," of ",den," listings (",round(m[i,j],1),"%)")
  }
  dark<-is.null(input$theme_toggle) || input$theme_toggle %% 2 == 0
  heat_colors<-if(dark) c("#163a33","#52c6aa","#d5fff0") else c("#f0faf6","#82d7bf","#087d69")
  heat_scale<-list(c(0,heat_colors[1]),c(0.5,heat_colors[2]),c(1,heat_colors[3]))
  p<-plot_ly(x=roles,y=skills,z=m,type="heatmap",text=hover,hovertemplate="%{text}<extra></extra>",
    zmin=0,zmax=100,colorscale=heat_scale,xgap=2,ygap=2,colorbar=list(title="%",thickness=12))
  finish(layout(p,xaxis=list(title="",tickangle=-25,automargin=TRUE),yaxis=list(title="",autorange="reversed",automargin=TRUE)),list(l=15,r=15,t=15,b=80))
 })
 table_data<-reactive({d<-filtered();data.frame(Title=d$title,Company=d$company,City=d$city,`Source location`=d$location,Role=d$role,Skills=vapply(d$skills,paste,character(1),collapse=", "),check.names=FALSE)})
 output$listings<-renderDT(datatable(table_data(),escape=TRUE,rownames=FALSE,selection="single",options=list(pageLength=8,lengthMenu=c(8,15,30),scrollX=TRUE,autoWidth=FALSE,language=list(search="Search this table:",emptyTable="No listings match your filters."))))
 observeEvent(input$listings_rows_selected,{
  i<-input$listings_rows_selected;d<-filtered();if(length(i)!=1||i>nrow(d))return()
  row<-d[i,,drop=FALSE];url<-if("redirect_url" %in% names(row)) row$redirect_url[1] else NA_character_
  safe<-!is.na(url)&&grepl("^https?://[^[:space:]]+$",url,ignore.case=TRUE)
  description<-row$description[1];if(is.na(description)||!nzchar(description))description<-"No description text available."
  showModal(modalDialog(title=row$title[1],size="l",easyClose=TRUE,
   div(class="detail-meta",strong(row$company[1]),span(paste("City:",row$city[1])),span(paste("Source location:",row$location[1])),span(row$role[1])),
    div(class="detail-facts",
     div(strong("Job category"),span(if("category" %in% names(row)&&!is.na(row$category[1])&&nzchar(row$category[1])) row$category[1] else "Not provided")),
     div(strong("Contract"),span(if("contract_time" %in% names(row)&&!is.na(row$contract_time[1])&&nzchar(row$contract_time[1])) row$contract_time[1] else "Not provided")),
     div(strong("Salary minimum"),span(if(is.finite(row$salary_min[1])) format(row$salary_min[1],big.mark=",") else "Not provided")),
     div(strong("Salary maximum"),span(if(is.finite(row$salary_max[1])) format(row$salary_max[1],big.mark=",") else "Not provided")),
     div(strong("Created"),span(ifelse(is.na(row$date[1]),"Unknown",as.character(row$date[1])))),
     div(strong("Salary assessment"),span(row$salary_status[1]))),
   div(class="detail-chips",lapply(row$skills[[1]],function(x)span(class="filter-chip",x))),
   h5("Available description"),p(class="job-description",description),
   p(class="muted",paste("Created:",ifelse(is.na(row$date[1]),"Unknown",as.character(row$date[1])))),
   p(class="muted",paste("Salary status:",row$salary_status[1])),
   if(safe)tags$a("Open original listing",href=url,target="_blank",rel="noopener noreferrer",class="btn btn-primary"),footer=modalButton("Close")))
 })
 output$salary_quality<-renderPlotly(bars(counts(filtered()$salary_status,5),"#d6a46c"))
 output$quality<-renderDT({d<-filtered();z<-data.frame(Check=c("Listings","Missing job IDs","Unknown companies","Unknown locations","No detected skills","Missing dates","Invalid salary ranges"),Count=c(nrow(d),sum(is.na(d$job_id)|d$job_id==""),sum(d$company=="Unknown"),sum(d$location=="Unknown"),sum(lengths(d$skills)==0),sum(is.na(d$date)),sum(d$salary_status=="Invalid range")));datatable(z,rownames=FALSE,escape=TRUE,options=list(dom="t",paging=FALSE,ordering=FALSE))})
 output$salary_hist<-renderPlotly({x<-filtered()$salary_midpoint;x<-x[is.finite(x)];shiny::validate(shiny::need(length(x)>0,"No eligible numeric midpoints."));finish(layout(plot_ly(x=x,type="histogram",marker=list(color="#d6a46c")),xaxis=list(title="Raw numeric midpoint: period / units unverified"),yaxis=list(title="Listings")))})
 output$date_plot<-renderPlotly({
  x<-filtered()$date
  x<-x[!is.na(x)]
  shiny::validate(shiny::need(length(x)>0,"No dated listings."))
  z<-as.data.frame(table(date=as.Date(x)))
  names(z)<-c("date","listings")
  z$date<-as.Date(as.character(z$date))
  z<-z[z$listings>0,,drop=FALSE]
  p<-plot_ly(z,x=~date,y=~listings,type="bar",marker=list(color="#49b9a5"),
    hovertemplate="%{x|%d %b %Y}<br>%{y:,d} listings<extra></extra>")
  date_ticks<-pretty(range(z$date),n=min(8,nrow(z)))
  date_ticks<-as.Date(date_ticks,origin="1970-01-01")
  date_ticks<-date_ticks[date_ticks>=min(z$date)&date_ticks<=max(z$date)]
  finish(layout(p,
    xaxis=list(title="Listing creation date",type="date",tickmode="array",tickvals=date_ticks,ticktext=format(date_ticks,"%d %b"),tickangle=-45,automargin=TRUE,gridcolor="rgba(148,163,184,0.18)",tickfont=list(size=10)),
    yaxis=list(title="Listings",rangemode="tozero",nticks=5,tickformat=",d",gridcolor="rgba(148,163,184,0.18)",tickfont=list(size=10))),
    list(l=55,r=20,t=15,b=78))
 })
 export<-reactive({d<-filtered();d$skills<-vapply(d$skills,paste,character(1),collapse=", ");d[,setdiff(names(d),"record_key"),drop=FALSE]})
 output$download<-downloadHandler(filename=function()paste0("techpulse-",Sys.Date(),".csv"),content=function(file){d<-export();for(k in names(d))if(is.character(d[[k]]))d[[k]]<-ifelse(!is.na(d[[k]])&grepl("^[[:space:]]*[=+@-]",d[[k]]),paste0("'",d[[k]]),d[[k]]);write.csv(d,file,row.names=FALSE,na="")})
 reload<-function(){d<-load_jobs(root);d$city<-normalize_city(d$location);data(d);updateSelectizeInput(session,"role",choices=opts(d$role,"All role families"),selected="All",server=TRUE);updateSelectizeInput(session,"city",choices=opts(d$city,"All cities"),selected="All",server=TRUE);updateSelectizeInput(session,"company",choices=opts(d$company,"All companies"),selected="All",server=TRUE);updateSelectizeInput(session,"skill",choices=opts(unlist(d$skills),"All skills"),selected="All",server=TRUE);updateDateRangeInput(session,"dates",start=min(d$date,na.rm=TRUE),end=max(d$date,na.rm=TRUE))}
 observeEvent(input$reload,tryCatch({reload();status("Local data reloaded; no API requests made.");showNotification("Local data reloaded",type="message")},error=function(e)showNotification(conditionMessage(e),type="error")))
 observeEvent(input$refresh,{
  if(!isTRUE(input$consent)){showNotification("Acknowledge API quota use first.",type="warning");return()}
  withProgress(message="Collecting and rebuilding; this can take a minute",value=.1,{
   tryCatch({refresh_dashboard(root);incProgress(.8);reload();status("Refresh completed successfully.");showNotification("Dataset updated",type="message")},error=function(e){status(conditionMessage(e));showNotification(conditionMessage(e),type="error",duration=15)})
  })
 })
 output$status<-renderText(status())
 output$freshness<-renderText({data();f<-file.path(root,"data/processed/last_refresh.txt");if(file.exists(f))paste("Last successful collection:",readLines(f,warn=FALSE)[1])else "The existing snapshot has no recorded collection timestamp. Listing creation dates are not collection dates."})
}
# Navigation state is styled through an R-rendered output; no custom JavaScript.
ui <- tagList(ui,uiOutput("nav_style"))
shinyApp(ui,server)
