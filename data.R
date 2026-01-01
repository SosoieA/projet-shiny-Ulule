library(shiny)
library(shinythemes)
library(dplyr)
library(lubridate)
library(ggplot2)
library(plotly)
library(readr)

data_ulule <- read_csv("data_ulule_2025_new.csv", col_types = cols(.default = "c")) %>%
  # conversion des colonnes numériques et dates
  mutate(
    id = as.integer(id),
    nb_days = as.integer(nb_days),
    amount_raised = as.numeric(amount_raised),
    amount_in_eur = as.numeric(amount_in_eur),
    goal = as.numeric(goal),
    percent = as.numeric(percent),
    date_start = parse_datetime(date_start),
    date_end = parse_datetime(date_end),
    goal_raised = goal_raised == "TRUE",
    is_cancelled = is_cancelled == "TRUE",
    finished = finished == "TRUE",
  ) %>%
  # filtrer les campagnes annulées ou antérieures à 2020
  filter(!is_cancelled & year(date_start) >= 2020)

data_ulule$Début <- format(data$Début, "%Y-%m-%d %H:%M")
data_ulule$Fin   <- format(data$Fin,   "%Y-%m-%d %H:%M")

