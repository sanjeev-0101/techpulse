# Shared, dependency-free data preparation and validation.
skill_dictionary <- c(Python="Python", Java="Java", JavaScript="JavaScript", TypeScript="TypeScript",
 "C++"="C\\+\\+", "C#"="C#", SQL="SQL", R="R", HTML="HTML", CSS="CSS",
 React="React(?:\\.js)?", Angular="Angular", Vue="Vue(?:\\.js)?", "Node.js"="Node\\.?js",
 Express="Express(?:\\.js)?", Spring="Spring", Django="Django", Flask="Flask",
 AWS="AWS|Amazon Web Services", Azure="Azure", "Google Cloud"="Google Cloud(?: Platform)?|GCP",
 Docker="Docker", Kubernetes="Kubernetes|K8s", Git="Git", GitHub="GitHub", Linux="Linux",
 TensorFlow="TensorFlow", PyTorch="PyTorch", "Scikit-learn"="Scikit-learn|sklearn",
 "Machine Learning"="Machine Learning", "Deep Learning"="Deep Learning", "Data Science"="Data Science",
 "Power BI"="Power\\s*BI", Tableau="Tableau", MongoDB="MongoDB", MySQL="MySQL", PostgreSQL="PostgreSQL|Postgres")
extract_matches <- function(text) {
 text[is.na(text)] <- ""
 lapply(text, function(x) names(skill_dictionary)[vapply(skill_dictionary, function(p)
  grepl(paste0("(?i)(?<![A-Za-z0-9])(?:",p,")(?![A-Za-z0-9])"),x,perl=TRUE),logical(1))])
}
role_family <- function(title) {
 rules <- c("Data Scientist"="data scien", "Data Analyst"="data analyst|business intelligence",
 "AI / ML"="machine learning|\\bAI\\b|\\bML\\b|deep learning", "DevOps"="devops|site reliability|\\bSRE\\b",
 "Cloud"="cloud", "Cybersecurity"="cyber|security", "Full Stack"="full.?stack",
 "Frontend"="front.?end|react|angular", "Backend"="back.?end", "Software Engineering"="software|developer|programmer")
 out <- rep("Other",length(title)); title[is.na(title)] <- ""
 for (i in seq_along(rules)) { hit <- out=="Other" & grepl(rules[i],title,ignore.case=TRUE,perl=TRUE); out[hit] <- names(rules)[i] }; out
}
load_jobs <- function(root=".") {
 d <- read.csv(file.path(root,"data/processed/jobs_clean.csv"),colClasses="character",stringsAsFactors=FALSE)
 required <- c("job_id","title","company","location","created","description","salary_min","salary_max")
 if(!all(required %in% names(d)) || !nrow(d)) stop("Clean data is empty or missing required columns.")
 d <- d[,!grepl("^salary_is_predicted\\.",names(d)),drop=FALSE]
 for (x in c("title","company","location","category","contract_time")) {
  if(!x %in% names(d)) d[[x]] <- "Unknown"
  d[[x]][is.na(d[[x]]) | !nzchar(trimws(d[[x]]))] <- "Unknown"
 }
 valid <- !is.na(d$job_id) & nzchar(d$job_id)
 if(anyDuplicated(d$job_id[valid])) stop("Duplicate job IDs detected; run the cleaning pipeline.")
 d$record_key <- ifelse(valid,d$job_id,paste0("missing-id-",seq_len(nrow(d))))
 d$role <- role_family(d$title)
 d$date <- as.Date(substr(d$created,1,10))
 for(x in c("salary_min","salary_max")) d[[x]] <- suppressWarnings(as.numeric(d[[x]]))
 d$salary_status <- ifelse(!is.finite(d$salary_min)|!is.finite(d$salary_max),"Missing bounds",
  ifelse(d$salary_min<0 | d$salary_max<d$salary_min,"Invalid range",
   ifelse(d$salary_min<10000 | d$salary_max/pmax(d$salary_min,1)>50,"Review flagged","Unflagged / units unverified")))
 d$salary_midpoint <- ifelse(d$salary_status=="Unflagged / units unverified",(d$salary_min+d$salary_max)/2,NA_real_)
 d$skills <- extract_matches(paste(d$title,ifelse(is.na(d$description),"",d$description)))
 d
}
skill_rows <- function(d) {
 lens <- lengths(d$skills)
 data.frame(record_key=rep(d$record_key,lens),job_id=rep(d$job_id,lens),role=rep(d$role,lens),skill=unlist(d$skills,use.names=FALSE),stringsAsFactors=FALSE)
}
counts <- function(x,n=15) {
 z <- sort(table(x),decreasing=TRUE); z <- head(z,n)
 data.frame(label=names(z),listings=as.integer(z),stringsAsFactors=FALSE)
}
