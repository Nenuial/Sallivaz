library(fs)
library(here)
library(ymlplyr)
library(googledrive)
library(googlesheets4)

options(
  gargle_oauth_cache = ".secrets",
  gargle_oauth_email = TRUE
)

setup_classes <- function(result_path) {
  class_id <- stringr::str_match(result_path, ".*R.{1,2}sultats_(.{1,3})\\.xls")[,2]
  
  class_data <- classes |> 
    dplyr::filter(`Épreuve` == class_id)
  
  result_ongoing <- TRUE
  #if (stringr::str_detect(class_data$Actuel, "Carré")) result_ongoing <- TRUE
  
  file_copy(path = here("_templates/Results.qmd"), 
            new_path = here(paste0("results/Results_", class_id, ".qmd")), 
            overwrite = T) -> qmd_path
  
  yml_replace(
    file = qmd_path,
    what = list(
      title = class_data$Nom,
      subtitle = paste0('Catégorie - ', class_data$Catégorie),
      Epreuve = class_data$Épreuve,
      order = class_data$Ordre,
      params = list(
        result_file = result_path,
        result_ongoing = result_ongoing
      )
    )
  )
}

carre_off <- function(carre) {
  carre_filename <- stringr::str_replace(carre, " ", "_")
  
  file_copy(path = here("_templates/Carre_pause.qmd"), 
            new_path = here(paste0("actuel/", carre_filename, ".qmd")), 
            overwrite = T) -> qmd_path
  
  yml_replace(
    file = qmd_path,
    what = list(
      title = carre,
      params = list(
        carre = carre
      )
    )
  )
  
  file_copy(path = here("_templates/Carre_pause.qmd"), 
            new_path = here(paste0("actuel/", carre_filename, "_live.qmd")), 
            overwrite = T) -> qmd_path
  
  yml_replace(
    file = qmd_path,
    what = list(
      title = carre,
      css = "../live.css",
      "include-in-header" = "../live.html",
      params = list(
        carre = carre
      )
    )
  )
}

current_classes <- function(...) {
  dots <- list(...)
  
  dir_ls(
    path = here("data"),
    regexp = paste0("_", dots$Épreuve,"[.]xls")
    
  ) -> result_path
  
  if (length(result_path) == 0) return()
  
  carre_filename <- stringr::str_replace(dots$Actuel, " ", "_")
  
  file_copy(path = here("_templates/Carre_result.qmd"),
            new_path = here(paste0("actuel/", carre_filename, ".qmd")), 
            overwrite = T) -> qmd_path
  
  yml_replace(
    file = qmd_path,
    what = list(
      title = dots$Actuel,
      subtitle = paste(dots$Nom, "-", dots$Catégorie),
      params = list(
        result_file = result_path
      )
    )
  )
  
  file_copy(path = here("_templates/Carre_result.qmd"),
            new_path = here(paste0("actuel/", carre_filename, "_live.qmd")), 
            overwrite = T) -> qmd_path
  
  yml_replace(
    file = qmd_path,
    what = list(
      title = dots$Actuel,
      subtitle = paste(dots$Nom, "-", dots$Catégorie),
      css = "../live.css",
      "include-in-header" = "../live.html",
      params = list(
        result_file = result_path
      )
    )
  )
}

drive_get("Concours/Datafiles/Sallivaz") |> 
  read_sheet() |> 
  dplyr::mutate(`Épreuve` = as.character(`Épreuve`)) |> 
  dplyr::mutate(Actuel = as.character(Actuel)) |> 
  dplyr::mutate(Actuel = dplyr::if_else(is.na(Actuel), "", Actuel)) -> classes

dir_ls(here("data"), regexp = ".*R.{1,2}sultats_(.{1,3})\\.xls") -> results

results |> 
  purrr::walk(setup_classes)

c("Carré A") |> 
  purrr::walk(carre_off)

classes |> 
  dplyr::filter(stringr::str_detect(Actuel, "Carré")) |> 
  purrr::pwalk(current_classes)
