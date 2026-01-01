#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

# Chargement des librairies nécessaires
library(dplyr)     
library(lubridate) 
library(ggplot2)    
library(plotly)     

# Fonction serveur de l'application Shiny
function(input, output, session) {
  
  # ================= CATÉGORIES =================
  # Création dynamique du menu de sélection des catégories
  output$categorie_ui <- renderUI({
    selectInput(
      "choix_categorie",
      "Catégories :",
      choices = sort(unique(data_ulule$category)), # catégories disponibles
      multiple = TRUE                               # sélection multiple autorisée
    )
  })
  
  # ================= FILTRAGE =================
  # Filtrage des données selon l'année et les catégories choisies
  perimetre <- eventReactive(input$go, {
    data_ulule %>%
      filter(
        year(date_start) >= input$annee_slider[1],
        year(date_start) <= input$annee_slider[2],
        category %in% input$choix_categorie
      )
  })
  
  # ================= DONNÉES TRIMESTRIELLES =================
  # Ajout d'une variable trimestre (année + trimestre)
  data_trimestrielle <- reactive({
    perimetre() %>%
      mutate(trimestre = paste0(year(date_start), "-T", quarter(date_start)))
  })
  
  # ================= DONNÉES POUR GRAPHE =================
  # Calcul des indicateurs trimestriels
  indicateur_trimestriel <- reactive({
    
    df <- data_trimestrielle()
    
    # Cas où les catégories sont séparées
    if (input$regroupement == "sep") {
      df %>%
        group_by(trimestre, category) %>%
        summarise(
          nb_campagnes = n(),                         # nombre de campagnes
          nb_reussies = sum(goal_raised),             # campagnes réussies
          montant_total = mean(amount_in_eur, na.rm = TRUE),
          ratio_financees = 100 * nb_reussies / nb_campagnes,
          .groups = "drop"
        )
    } 
    # Cas où toutes les catégories sont regroupées
    else {
      df %>%
        group_by(trimestre) %>%
        summarise(
          nb_campagnes = n(),
          nb_reussies = sum(goal_raised),
          montant_total = mean(amount_in_eur, na.rm = TRUE),
          ratio_financees = 100 * nb_reussies / nb_campagnes,
          .groups = "drop"
        )
    }
  })
  
  # ================= STATS =================
  # Calcul des statistiques descriptives
  stats <- reactive({
    
    df <- indicateur_trimestriel()
    indic <- input$choix_indicateur  # indicateur choisi par l'utilisateur
    
    # Cas regroupé (toutes catégories confondues)
    if (input$regroupement == "grp") {
      
      # Lignes correspondant au minimum et au maximum
      min_row <- df %>% filter(.data[[indic]] == min(.data[[indic]], na.rm = TRUE)) %>% slice(1)
      max_row <- df %>% filter(.data[[indic]] == max(.data[[indic]], na.rm = TRUE)) %>% slice(1)
      
      tibble(
        Min = paste0(round(min_row[[indic]], 2), " (", min_row$trimestre, ")"),
        Max = paste0(round(max_row[[indic]], 2), " (", max_row$trimestre, ")"),
        Moyenne = round(mean(df[[indic]], na.rm = TRUE), 2),
        Médiane = round(median(df[[indic]], na.rm = TRUE), 2)
      )
      
    } 
    # Cas séparé par catégorie
    else {
      df %>%
        group_by(category) %>%
        summarise(
          Min = paste0(
            round(min(.data[[indic]], na.rm = TRUE), 2),
            " (", trimestre[which.min(.data[[indic]])], ")"
          ),
          Max = paste0(
            round(max(.data[[indic]], na.rm = TRUE), 2),
            " (", trimestre[which.max(.data[[indic]])], ")"
          ),
          Moyenne = round(mean(.data[[indic]], na.rm = TRUE), 2),
          Médiane = round(median(.data[[indic]], na.rm = TRUE), 2),
          .groups = "drop"
        )
    }
  })
  
  # ================= BOXES STATS =================
  # Affichage des statistiques sous forme de boîtes
  output$stats_ui <- renderUI({
    
    df <- stats()
    
    # Couleurs associées aux indicateurs
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
            
            # Affichage différent selon le type de regroupement
            if (input$regroupement == "grp") {
              div(class = "stat-line", df[[titre]])
            } else {
              lapply(1:nrow(df), function(i) {
                div(
                  class = "stat-line",
                  paste0(df$category[i], " : ", df[[titre]][i])
                )
              })
            }
          )
        )
      })
    )
  })
  
  # ================= GRAPHIQUE =================
  # Graphique d'évolution trimestrielle
  output$plot_evolution <- renderPlotly({
    
    df <- indicateur_trimestriel()
    
    # Cas regroupé
    if (input$regroupement == "grp") {
      
      gg <- ggplot(
        df,
        aes(
          x = trimestre,
          y = .data[[input$choix_indicateur]],
          group = 1,
          text = paste0(
            "Trimestre : ", trimestre, "<br>",
            "Valeur : ", round(.data[[input$choix_indicateur]], 2)
          )
        )
      ) +
        geom_line(color = "#42a5f5", linewidth = 1.3) +
        geom_point(color = "#42a5f5", size = 3) +
        labs(
          title = "Évolution trimestrielle — Toutes catégories confondues",
          x = "Trimestre",
          y = ""
        )
      
    } 
    # Cas par catégorie
    else {
      
      gg <- ggplot(
        df,
        aes(
          x = trimestre,
          y = .data[[input$choix_indicateur]],
          color = category,
          group = category,
          text = paste0(
            "Catégorie : ", category, "<br>",
            "Trimestre : ", trimestre, "<br>",
            "Valeur : ", round(.data[[input$choix_indicateur]], 2)
          )
        )
      ) +
        geom_line(linewidth = 1.3) +
        geom_point(size = 3) +
        scale_color_brewer(palette = "Set2") +
        labs(
          title = "Évolution trimestrielle par catégorie",
          x = "Trimestre",
          y = "",
          color = "Catégorie"
        )
    }
    
    # Mise en forme du graphique
    gg <- gg +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    # Conversion en graphique interactif
    ggplotly(gg, tooltip = "text")
  })
  
  # ================= TABLEAU =================
  # Tableau interactif des campagnes
  output$table_evolution <- renderDT({
    
    data_trimestrielle() %>%
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
        escape = FALSE,   # nécessaire pour afficher les liens HTML
        options = list(
          pageLength = 10,
          autoWidth = TRUE
        )
      )
  })
  
  # ================= DOWNLOAD =================
  # Téléchargement des données filtrées
  output$download_data <- downloadHandler(
    filename = function() {
      paste0("ulule_", Sys.Date(), ".csv")
    },
    content = function(file) {
      write.csv(data_trimestrielle(), file, row.names = FALSE)
    }
  )
}

