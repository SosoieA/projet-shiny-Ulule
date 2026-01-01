####Fichierpour modifier les data ulule

# Charger les bibliothèques nécessaires
library(dplyr)

# Charger le fichier CSV (remplacer par ton propre chemin de fichier)
file_path <- "data_ulule_2025.csv"  # Remplace par le chemin vers ton fichier
data <- read.csv(file_path)

unique(data$currency)

# Table des taux de change vers l'euro
exchange_rates <- data.frame(
  currency = c("EUR", "USD", "CAD", "GBP", "CHF", "BRL", "AUD", "NOK", "DKK", "SEK"),
  rate_to_eur = c(
    1,      # EUR
    0.93,   # USD
    0.68,   # CAD
    1.14,   # GBP
    1.05,   # CHF
    0.19,   # BRL
    0.62,   # AUD
    0.086,  # NOK
    0.13,   # DKK
    0.088   # SEK
  )
)

# Fusionner les taux de change avec les données de transactions en fonction de la colonne 'currency'
data_with_rates <- data %>%
  left_join(exchange_rates, by = "currency")

# Créer une nouvelle colonne 'amount_in_eur' en convertissant les montants
# Conversion en euros
data_with_rates <- data_with_rates %>%
  mutate(amount_in_eur = amount_raised * rate_to_eur)

# Afficher les premières lignes du résultat
head(data_with_rates)

# Enregistrer le résultat dans un nouveau fichier CSV
write.csv(data_with_rates, "fichier_converti_en_eur.csv", row.names = FALSE)

