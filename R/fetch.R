library(googledrive)

options(
  gargle_oauth_cache = ".secrets",
  gargle_oauth_email = TRUE
)

drive_ls("Concours/Sallivaz") |> 
  purrr::pwalk(~drive_download(..2, path = paste0("data/", ..1), overwrite = T))
  