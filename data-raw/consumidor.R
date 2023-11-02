## code to prepare `consumidor` dataset goes here

zips <- fs::dir_ls("data-raw/consumidor_gov_zip")

purrr::walk(
  zips,
  \(zip) zip::unzip(zip, exdir = "data-raw/consumidor_gov"),
  .progress = TRUE
)

arqs_csv <- fs::dir_ls("data-raw/consumidor_gov")

ler_cgov <- function(csv) {
  ano <- as.numeric(stringr::str_extract(basename(csv), "\\d{4}"))
  mes <- as.numeric(stringr::str_extract(basename(csv), "(?<=-)\\d{2}"))
  enc <- ifelse(ano > 2020 || ano == 2020 & mes > 7, "UTF-8", "ISO-8859-1")
  if (ano == 2019 && mes %in% c(5:8, 10)) {
    enc <- "UTF-8"
  }
  loc <- readr::locale(
    encoding = enc,
    decimal_mark = ".",
    grouping_mark = ","
  )
  readr::read_delim(csv, delim = ";", locale = loc, show_col_types = FALSE) |>
    janitor::clean_names()
}

list_cgov <- fs::dir_ls("data-raw/consumidor_gov") |>
  purrr::map(ler_cgov, .progress = TRUE)

aux_cgov <- list_cgov |>
  purrr::map(\(x) {
    if (!is.null(x[["data_finalizacao"]]) && is.character(x[["data_finalizacao"]])) {
      x$data_finalizacao <- lubridate::dmy(x$data_finalizacao)
    }
    x
  }) |>
  purrr::list_rbind(names_to = "file")

aux_cgov |>
  dplyr::count(uf, sort = TRUE)

readr::write_rds(aux_cgov, "data-raw/aux_cgov.rds")

aux_cgov_sp <- readr::read_rds("aux_cgov.rds") |>
  dplyr::filter(uf == "SP")

readr::write_rds(aux_cgov_sp, "aux_cgov_sp.rds")

dplyr::glimpse(aux_cgov)

aux_cgov |>
  dplyr::count()