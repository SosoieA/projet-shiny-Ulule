#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

# Chargement des librairies nécessaires
library(shiny)     
library(shinythemes) 
library(DT)         
library(plotly)      

# Définition de l'interface utilisateur
fluidPage(
  
  theme = shinytheme("flatly"),  # Choix du thème
  
  # ================= STYLE CSS =================
  # Personnalisation de l'apparence
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
          img(src = "ulule_logo.png", height = "200px") # Logo Ulule
        ),
        column(
          8,
          h2("Analyse des campagnes Ulule"),           # Titre
          p("Application interactive de suivi des campagnes de financement participatif."), # Description
          tags$ul(
            tags$li("Analyse temporelle par trimestre"),
            tags$li("Comparaison par catégories"),
            tags$li("Indicateurs financiers et de réussite")
          ),
          br(),
          p(strong("Fait par Constance MOREL et Solène AMIOT")) # Auteurs
        )
      )
    ),
    
    # ================= ANALYSE =================
    tabPanel(
      "Analyse",
      sidebarLayout(
        
        # -------- SIDEBAR --------
        sidebarPanel(
          # Choix de l'indicateur à afficher
          selectInput(
            "choix_indicateur",
            "Indicateur :",
            choices = c(
              "Nombre de campagnes" = "nb_campagnes",
              "Campagnes réussies" = "nb_reussies",
              "Montant total (€)" = "montant_total",
              "Taux de réussite (%)" = "ratio_financees"
            )
          ),
          
          # Type d'affichage du graphe (séparé ou regroupé)
          radioButtons(
            "regroupement",
            "Affichage du graphe :",
            choices = c(
              "Catégories séparées" = "sep",
              "Catégories regroupées" = "grp"
            )
          ),
          
          # Menu dynamique des catégories (généré côté serveur)
          uiOutput("categorie_ui"),
          
          # Choix de la période
          sliderInput(
            "annee_slider",
            "Période :",
            min = 2020,
            max = year(Sys.Date()),
            value = c(2020, year(Sys.Date())),
            sep = ""
          ),
          
          # Bouton pour appliquer les filtres
          actionButton("go", "Appliquer"),
          br(), br(),
          
          # Bouton de téléchargement des données
          downloadButton("download_data", "Télécharger")
        ),
        
        # -------- MAIN PANEL --------
        mainPanel(
          tabsetPanel(
            
            # Onglet Graphique
            tabPanel(
              "Graphique",
              plotlyOutput("plot_evolution") # Graphique interactif
            ),
            
            # Onglet Tableau
            tabPanel(
              "Tableau",
              DTOutput("table_evolution")    # Tableau interactif
            )
          ),
          br(),
          # Affichage des statistiques
          uiOutput("stats_ui")
        )
      )
    )
  )
)
