library(shiny)
library(shinythemes)
library(dplyr)
library(lubridate)
library(ggplot2)
library(plotly)
library(readr)

data_ulule <- read_csv("data_ulule_2025_new.csv", col_types = cols(.default = "c")) %>%
  mutate(
    id = as.integer(id),
    nb_days = as.integer(nb_days),
    amount_raised = as.numeric(amount_raised),
    amount_in_eur = as.numeric(amount_in_eur),
    goal = as.numeric(goal),
    percent = as.numeric(percent),
    
    # conversion dates (lubridate)
    date_start = parse_datetime(date_start),
    date_end   = parse_datetime(date_end),
    
    goal_raised   = goal_raised == "TRUE",
    is_cancelled  = is_cancelled == "TRUE",
    finished      = finished == "TRUE"   
  ) %>%
  filter(!is_cancelled & year(date_start) >= 2020)

# Créer des colonnes formatées (sans accents pour éviter DÃ©but)
data_ulule$Debut <- format(data_ulule$date_start, "%Y-%m-%d %H:%M")
data_ulule$Fin   <- format(data_ulule$date_end,   "%Y-%m-%d %H:%M")

