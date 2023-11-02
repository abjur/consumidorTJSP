

piggyback::pb_new_release(tag = "tjsp")
piggyback::pb_new_release(tag = "sindec_atendimentos")
piggyback::pb_new_release(tag = "sindec_fornecedor")
piggyback::pb_new_release(tag = "consumidor_gov")




fs::dir_ls("data-raw/consumidor_gov") |>
  purrr::walk(\(x) {
    piggyback::pb_upload(x, tag = "consumidor_gov")
  }, .progress = TRUE)


fs::dir_ls("data-raw/sindec_atendimentos") |>
  purrr::walk(\(x) {
    piggyback::pb_upload(x, tag = "sindec_atendimentos")
  }, .progress = TRUE)

fs::dir_ls("data-raw/sindec_fornecedor") |>
  purrr::walk(\(x) {
    piggyback::pb_upload(x, tag = "sindec_fornecedor")
  }, .progress = TRUE)


piggyback::pb_upload("data-raw/cpopg.zip", tag = "tjsp")
piggyback::pb_upload("data-raw/cjpg/2019.zip", tag = "tjsp")
piggyback::pb_upload("data-raw/cjpg/2020.zip", tag = "tjsp")
piggyback::pb_upload("data-raw/cjpg/2021.zip", tag = "tjsp")
piggyback::pb_upload("data-raw/cjpg/2022.zip", tag = "tjsp")