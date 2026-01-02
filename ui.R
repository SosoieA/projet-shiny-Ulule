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

    .stat-box {
      border-radius: 16px;
      padding: 15px;
      text-align: center;
      margin-bottom: 10px;
      color: #1f2933;
    }

    .stat-title {
      font-weight: bold;
      font-size: 18px;
      margin-bottom: 8px;
    }

    .stat-line {
      font-size: 15px;
      margin: 2px 0;
    }
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
    )
  )
)
