library(dplyr)
library(stringr)
library(tidyr)

# -----------------------------
# TechPulse - Skill Extraction
# -----------------------------

# Technical skills to search for
skill_patterns <- c(
  "Python",
  "Java",
  "JavaScript",
  "TypeScript",
  "C++",
  "C#",
  "SQL",
  "R",
  "HTML",
  "CSS",
  "React",
  "Angular",
  "Vue",
  "Node.js",
  "Express",
  "Spring",
  "Django",
  "Flask",
  "AWS",
  "Azure",
  "Google Cloud",
  "Docker",
  "Kubernetes",
  "Git",
  "GitHub",
  "Linux",
  "TensorFlow",
  "PyTorch",
  "Scikit-learn",
  "Machine Learning",
  "Deep Learning",
  "Data Science",
  "Power BI",
  "Tableau",
  "MongoDB",
  "MySQL",
  "PostgreSQL"
)

# Extract skills from one job description
extract_skills <- function(text) {

  if (is.na(text) || text == "") {
    return(character(0))
  }

  found <- character(0)

  for (skill in skill_patterns) {

    pattern <- paste0(
      "(?i)(?<![A-Za-z0-9])",
      str_replace_all(skill, "\\.", "\\\\."),
      "(?![A-Za-z0-9])"
    )

    if (str_detect(text, pattern)) {
      found <- c(found, skill)
    }
  }

  unique(found)
}


# Apply skill extraction to every job
jobs_with_skills <- jobs_clean |>
  mutate(
    skills = lapply(description, extract_skills)
  )

# Convert list-column into one skill per row
job_skills <- jobs_with_skills |>
  select(job_id, title, company, location, skills) |>
  unnest_longer(skills) |>
  rename(skill = skills)

# Save skill-level dataset
write.csv(
  job_skills,
  "data/processed/job_skills.csv",
  row.names = FALSE
)

cat("Jobs analyzed:", nrow(jobs_with_skills), "\n")
cat("Skill records:", nrow(job_skills), "\n")
cat("Unique skills found:", n_distinct(job_skills$skill), "\n")

cat("\nTop skills:\n")

job_skills |>
  count(skill, sort = TRUE) |>
  head(10) |>
  print()