# ui.R



library(shiny)
library(shinythemes)
library(DT)
library(plotly)
library(lubridate)

ui <- fluidPage(
  
  theme = shinytheme("flatly"),
  
  # ================= STYLE CSS =================
  tags$style(HTML("
  body { background-color: #f6f8fb; }

  /* Layout général */
  .container-fluid { max-width: 1200px; }

  /* Sidebar */
  .well {
    background: #ffffff;
    border: 1px solid #e5e7eb;
    border-radius: 16px;
    box-shadow: 0 6px 18px rgba(16,24,40,0.06);
  }

  /* Boutons */
  .btn {
    border-radius: 12px;
    font-weight: 600;
  }
  .btn-default { border: 1px solid #d1d5db; }
  .btn-primary {
    background: #2563eb;
    border-color: #2563eb;
  }

  /* Onglets */
  .nav-tabs > li > a {
    border-radius: 12px 12px 0 0;
    font-weight: 600;
  }

  /* Cartes stats */
  .stat-box {
    background: #ffffff !important;
    border: 1px solid #e5e7eb;
    border-radius: 16px;
    padding: 14px 16px;
    text-align: left;
    margin-bottom: 12px;
    box-shadow: 0 6px 18px rgba(16,24,40,0.06);
  }
  .stat-title {
    font-weight: 800;
    font-size: 14px;
    color: #111827;
    margin-bottom: 6px;
    letter-spacing: 0.2px;
    text-transform: uppercase;
  }
  .stat-line {
    font-size: 14px;
    margin: 2px 0;
    color: #374151;
  }

  /* Titres */
  h2 { font-weight: 800; color: #111827; }

  /* Graph + tableau containers */
  .tab-content {
    background: #ffffff;
    border: 1px solid #e5e7eb;
    border-radius: 16px;
    padding: 12px;
    box-shadow: 0 6px 18px rgba(16,24,40,0.06);
  }

  /* DataTable */
  table.dataTable { border-radius: 12px; overflow: hidden; }
")),
  
  
  # ================= NAVIGATION =================
  navbarPage(
    title = "Suivi des campagnes Ulule",
    
    # ================= ACCUEIL =================
    tabPanel(
      "Accueil",
      fluidRow(
        column(
          4,
          div(
            align = "center",
            img(src = "ulule_logo.png", height = "200px")
          )
        ),
        column(
          8,
          h2("Analyse des campagnes Ulule"),
          p("Application interactive de suivi des campagnes de financement participatif."),
          tags$ul(
            tags$li("Analyse temporelle par trimestre"),
            tags$li("Comparaison par catégories"),
            tags$li("Indicateurs financiers et de réussite")
          ),
          br(),
          p(strong("Fait par Constance MOREL et Solène AMIOT"))
        )
      )
    ),
    
    # ================= ANALYSE =================
    tabPanel(
      "Analyse",
      sidebarLayout(
        
        sidebarPanel(
          selectInput(
            "choix_indicateur",
            "Indicateur :",
            choices = c(
              "Nombre de campagnes" = "nb_campagnes",
              "Campagnes réussies" = "nb_reussies",
              "Montant moyen (€)" = "montant_total",
              "Taux de réussite (%)" = "ratio_financees"
            ),
            selected = "nb_campagnes"
          ),
          
          radioButtons(
            "regroupement",
            "Affichage du graphe :",
            choices = c(
              "Catégories séparées" = "sep",
              "Catégories regroupées" = "grp"
            ),
            selected = "sep"
          ),
          
          uiOutput("categorie_ui"),
          
          sliderInput(
            "annee_slider",
            "Période :",
            min = 2020,
            max = year(Sys.Date()),
            value = c(2020, year(Sys.Date())),
            sep = ""
          ),
          
          actionButton("go", "Appliquer"),
          br(), br(),
          
          downloadButton("download_data", "Télécharger")
        ),
        
        mainPanel(
          tabsetPanel(
            tabPanel("Graphique", plotlyOutput("plot_evolution")),
            tabPanel("Tableau", DTOutput("table_evolution"))
          ),
          br(),
          uiOutput("stats_ui")
        )
      )
    ),
    
    
    # ================= AIDE =================
    tabPanel(
      "Aide",
      fluidRow(
        column(
          12,
          h2("Mode d’emploi"),
          tags$div(
            style = "background:#fff; border:1px solid #e5e7eb; border-radius:16px; padding:16px; box-shadow:0 6px 18px rgba(16,24,40,0.06);",
            
            h4("1) Choisir un indicateur"),
            tags$ul(
              tags$li("Nombre de campagnes : volume total de campagnes lancées."),
              tags$li("Campagnes réussies : campagnes ayant atteint leur objectif."),
              tags$li("Montant moyen (€) : moyenne des montants récoltés (en euros)."),
              tags$li("Taux de réussite (%) : part des campagnes réussies.")
            ),
            
            h4("2) Choisir l’affichage"),
            tags$ul(
              tags$li("Catégories séparées : une courbe par catégorie."),
              tags$li("Catégories regroupées : une courbe globale.")
            ),
            
            h4("3) Filtrer et afficher"),
            tags$ul(
              tags$li("Sélectionne une ou plusieurs catégories."),
              tags$li("Choisis la période avec le curseur."),
              tags$li(strong("Clique sur “Appliquer” pour mettre à jour le graphique et le tableau."))
            ),
            
            h4("4) Explorer le tableau"),
            tags$ul(
              tags$li("Clique sur un lien pour ouvrir la campagne Ulule."),
              tags$li("Utilise la barre de recherche du tableau pour filtrer rapidement.")
            ),
            
            h4("5) Télécharger les données"),
            tags$p("Le bouton “Télécharger” exporte les données filtrées au format CSV.")
          )
        )
      )
    )
  )
)