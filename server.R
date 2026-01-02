# server.R

# Chargement des librairies nécessaires
library(shiny)
library(dplyr)
library(lubridate)
library(ggplot2)
library(plotly)
library(DT)

# Charge les données préparées (doit créer l'objet data_ulule)
source("data.R")

function(input, output, session) {
  
  # ================= CATÉGORIES =================
  output$categorie_ui <- renderUI({
    cats <- sort(unique(data_ulule$category))
    
    selectizeInput(
      "choix_categorie",
      "Catégories :",
      choices = cats,
      selected = cats,      # tout sélectionné par défaut
      multiple = TRUE,
      options = list(
        plugins = list("remove_button"),
        placeholder = "Choisis une ou plusieurs catégories"
      )
    )
  })
  
  
  # ================= FILTRAGE =================
  perimetre <- eventReactive(input$go, {
    
    # si rien sélectionné -> on prend tout
    cats <- input$choix_categorie
    if (is.null(cats) || length(cats) == 0) {
      cats <- unique(data_ulule$category)
    }
    
    df <- data_ulule %>%
      filter(
        year(date_start) >= input$annee_slider[1],
        year(date_start) <= input$annee_slider[2],
        category %in% cats
      )
    
    req(nrow(df) > 0)  # évite les erreurs si filtre vide
    df
  })
  
  # ================= DONNÉES TRIMESTRIELLES =================
  data_trimestrielle <- reactive({
    df <- perimetre() %>%
      mutate(
        annee = year(date_start),
        trim  = quarter(date_start),
        trimestre = paste0(annee, "-T", trim)
      )
    
    # tri chronologique des trimestres (important pour le graphe)
    ordre <- df %>%
      distinct(annee, trim, trimestre) %>%
      arrange(annee, trim) %>%
      pull(trimestre)
    
    df %>% mutate(trimestre = factor(trimestre, levels = ordre))
  })
  
  # ================= DONNÉES POUR GRAPHE =================
  indicateur_trimestriel <- reactive({
    
    df <- data_trimestrielle()
    
    if (input$regroupement == "sep") {
      df %>%
        group_by(trimestre, category) %>%
        summarise(
          nb_campagnes = n(),
          nb_reussies = sum(goal_raised, na.rm = TRUE),
          montant_total = mean(amount_in_eur, na.rm = TRUE),
          ratio_financees = 100 * nb_reussies / nb_campagnes,
          .groups = "drop"
        )
    } else {
      df %>%
        group_by(trimestre) %>%
        summarise(
          nb_campagnes = n(),
          nb_reussies = sum(goal_raised, na.rm = TRUE),
          montant_total = mean(amount_in_eur, na.rm = TRUE),
          ratio_financees = 100 * nb_reussies / nb_campagnes,
          .groups = "drop"
        )
    }
  })
  
  # ================= STATS =================
  stats <- reactive({
    
    df <- indicateur_trimestriel()
    indic <- input$choix_indicateur
    req(indic %in% names(df))  # sécurité
    
    if (input$regroupement == "grp") {
      
      min_row <- df %>% filter(.data[[indic]] == min(.data[[indic]], na.rm = TRUE)) %>% slice(1)
      max_row <- df %>% filter(.data[[indic]] == max(.data[[indic]], na.rm = TRUE)) %>% slice(1)
      
      tibble::tibble(
        Min = paste0(round(min_row[[indic]], 2), " (", as.character(min_row$trimestre), ")"),
        Max = paste0(round(max_row[[indic]], 2), " (", as.character(max_row$trimestre), ")"),
        Moyenne = round(mean(df[[indic]], na.rm = TRUE), 2),
        Médiane = round(median(df[[indic]], na.rm = TRUE), 2)
      )
      
    } else {
      
      df %>%
        group_by(category) %>%
        summarise(
          Min = paste0(
            round(min(.data[[indic]], na.rm = TRUE), 2),
            " (", as.character(trimestre[which.min(.data[[indic]])]), ")"
          ),
          Max = paste0(
            round(max(.data[[indic]], na.rm = TRUE), 2),
            " (", as.character(trimestre[which.max(.data[[indic]])]), ")"
          ),
          Moyenne = round(mean(.data[[indic]], na.rm = TRUE), 2),
          Médiane = round(median(.data[[indic]], na.rm = TRUE), 2),
          .groups = "drop"
        )
    }
  })
  
  # ================= BOXES STATS =================
  output$stats_ui <- renderUI({
    
    df <- stats()
    
    couleurs <- c(
      Min = "#e3f2fd",
      Max = "#e8f5e9",
      Moyenne = "#ede7f6",
      Médiane = "#fff3e0"
    )
    
    titres <- c("Min", "Max", "Moyenne", "Médiane")
    
    fluidRow(
      lapply(titres, function(titre) {
        column(
          3,
          div(
            class = "stat-box",
            style = paste0("background-color:", couleurs[titre]),
            div(class = "stat-title", titre),
            
            if (input$regroupement == "grp") {
              div(class = "stat-line", df[[titre]])
            } else {
              lapply(1:nrow(df), function(i) {
                div(class = "stat-line", paste0(df$category[i], " : ", df[[titre]][i]))
              })
            }
          )
        )
      })
    )
  })
  
  # ================= GRAPHIQUE =================
  output$plot_evolution <- renderPlotly({
    
    df <- indicateur_trimestriel()
    indic <- input$choix_indicateur
    req(indic %in% names(df))
    
    if (input$regroupement == "grp") {
      
      gg <- ggplot(
        df,
        aes(
          x = trimestre,
          y = .data[[indic]],
          group = 1,
          text = paste0(
            "Trimestre : ", trimestre, "<br>",
            "Valeur : ", round(.data[[indic]], 2)
          )
        )
      ) +
        geom_line(linewidth = 1.3) +
        geom_point(size = 3) +
        labs(
          title = "Évolution trimestrielle — Toutes catégories confondues",
          x = "Trimestre",
          y = ""
        )
      
    } else {
      
      gg <- ggplot(
        df,
        aes(
          x = trimestre,
          y = .data[[indic]],
          color = category,
          group = category,
          text = paste0(
            "Catégorie : ", category, "<br>",
            "Trimestre : ", trimestre, "<br>",
            "Valeur : ", round(.data[[indic]], 2)
          )
        )
      ) +
        geom_line(linewidth = 1.3) +
        geom_point(size = 3) +
        labs(
          title = "Évolution trimestrielle par catégorie",
          x = "Trimestre",
          y = "",
          color = "Catégorie"
        )
    }
    
    gg <- gg +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(gg, tooltip = "text")
  })
  
  # ================= TABLEAU =================
  output$table_evolution <- renderDT({
    
    df <- data_trimestrielle()
    req(nrow(df) > 0)
    
    df %>%
      mutate(
        `Lien campagne` = paste0(
          '<a href="', absolute_url, '" target="_blank">',
          absolute_url,
          '</a>'
        ),
        `Date début` = as.Date(date_start),
        `Date fin` = as.Date(date_end),
        Pays = country,
        Catégorie = category,
        `Campagne réussie` = ifelse(goal_raised, "Oui", "Non"),
        `Montant (€)` = round(amount_in_eur, 2)
      ) %>%
      select(
        `Lien campagne`,
        `Date début`,
        `Date fin`,
        Pays,
        Catégorie,
        `Campagne réussie`,
        `Montant (€)`
      ) %>%
      datatable(
        rownames = FALSE,
        escape = FALSE,
        options = list(pageLength = 10, autoWidth = TRUE)
      )
  })
  
  # ================= DOWNLOAD =================
  output$download_data <- downloadHandler(
    filename = function() {
      paste0("ulule_", Sys.Date(), ".csv")
    },
    content = function(file) {
      write.csv(data_trimestrielle(), file, row.names = FALSE)
    }
  )
}
