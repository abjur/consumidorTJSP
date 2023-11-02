# atendimentos_csv <- fs::dir_ls("data-raw/sindec_atendimentos")

# loc <- readr::locale(
#   encoding = "latin1",
#   decimal_mark = ".",
#   grouping_mark = ","
# )
# atendimentos_csv[1] |>
#   readr::read_delim("\t", locale = loc) |>
#   janitor::clean_names() |>
#   dplyr::glimpse()

# vamos usar essa base!
fornecedor_csv <- fs::dir_ls("data-raw/sindec_fornecedor")

loc <- readr::locale(
  encoding = "latin1",
  decimal_mark = ".",
  grouping_mark = ","
)

# fornecedor_csv[1] |>
#   readr::read_delim("\t", locale = loc) |>
#   janitor::clean_names() |>
#   dplyr::glimpse()


list_sindec_sp <- purrr::map(fornecedor_csv, \(x) {
  x |>
    #readr::read_delim("\t", locale = loc) |>
    data.table::fread() |>
    tibble::as_tibble() |>
    janitor::clean_names() |>
    dplyr::filter(uf == "SP")
}, .progress = TRUE)


aux_sindec_sp <- list_sindec_sp |>
  purrr::map(\(x) {
    x |>
      dplyr::mutate(
        cep_consumidor = as.character(cep_consumidor),
        cnpj = as.character(cnpj),
        radical_cnpj = as.character(radical_cnpj),
        codigo_cnae_principal = as.character(codigo_cnae_principal)
      )
  }, .progress = TRUE) |>
  dplyr::bind_rows(.id = "file")

readr::write_rds(aux_sindec_sp, "data-raw/aux_sindec_sp.rds")

aux_sindec_sp |>
  dplyr::count(ano_atendimento, trimestre_atendimento, sort = TRUE)

readr::write_rds(aux_sindec_sp, "data-raw/aux_sindec_sp.rds")
