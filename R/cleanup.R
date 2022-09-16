library(fs)
library(purrr)

cleanup <- function(dir_path) {
  if (!dir_exists(dir_path)) dir_create(dir_path)
  
  dir_ls(dir_path) |> 
    purrr::walk(file_delete)
}

c("data", "actuel", "results") |> 
  purrr::walk(cleanup)

if (dir_exists("_site")) dir_delete("_site")
if (dir_exists(".quarto")) dir_delete(".quarto")
