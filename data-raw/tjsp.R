
download_day <- function(date) {
  path <- stringr::str_glue("data-raw/tjsp/cjpg/{date}")
  if (!fs::dir_exists(path)) {
    usethis::ui_info("Downloading {date}...")
    fs::dir_create(path)
    tjsp::baixar_cjpg(
      diretorio = path,
      classe = c("8714", "8501"),
      assunto = c(
        "5245", "8103", "6220", "15052", "7779", "15074", "6226", "7781",
        "11553", "7780", "7767", "7768", "7769", "7770", "7771", "7752",
        "6904", "6905", "15053", "10945", "11495", "11496", "50884",
        "11497", "11498", "11546", "11547", "7772", "7773", "7774", "7775",
        "7776", "11502", "11503", "7760", "7761", "7617", "10598", "7626",
        "7627", "7618", "7619", "7620", "7621", "6233", "1429", "1430",
        "1431", "1432", "4862", "4829", "4830", "4831", "4832", "7748",
        "11438", "11439", "11440", "3717", "11550", "11551", "11552",
        "11554", "11499", "11500", "11501"
      ),
      inicio = format(date, "%d/%m/%Y"),
      fim = format(date, "%d/%m/%Y")
    )
  }
}

safe_download_day <- purrr::possibly(download_day)
purrr::walk(
  seq(as.Date("2019-01-01"), as.Date("2022-12-31"), "day"),
  safe_download_day,
  .progress = TRUE
)

ja_foi <- fs::dir_ls("data-raw/tjsp/cjpg", recurse = TRUE, type = "file") |>
  dirname()

tamanho_zero <- fs::dir_ls("data-raw/tjsp/cjpg", recurse = TRUE, type = "file") |>
  fs::file_info() |>
  dplyr::filter(size == 0) |>
  with(path) |>
  dirname()

fs::dir_ls("data-raw/tjsp/cjpg") |>
  setdiff(ja_foi) |>
  append(tamanho_zero) |>
  purrr::walk(
    \(x) if (fs::dir_exists(x)) fs::dir_delete(x),
    .progress = TRUE
  )


all_files <- fs::dir_ls(
  "data-raw/tjsp/cjpg", recurse = TRUE, type = "file"
)

ler_e_salvar <- function(x) {
  rds_file <- stringr::str_glue(
    "data-raw/tjsp/cjpg_rds/{tools::file_path_sans_ext(basename(x))}.rds"
  )
  if (!file.exists(rds_file)) {
    da <- tjsp::tjsp_ler_cjpg(x)
    readr::write_rds(da, rds_file)
  }
  rds_file
}
safe <- purrr::possibly(ler_e_salvar)

future::plan(future::multicore, workers = 8)
furrr::future_walk(all_files, safe, .progress = TRUE)


set.seed(1)

rds_files <- fs::dir_ls("data-raw/tjsp/cjpg_rds")

da_cjpg <- purrr::map(rds_files, \(x) dplyr::select(readr::read_rds(x), -julgado), .progress = TRUE) |>
  purrr::list_rbind(names_to = "file")

readr::write_rds(da_cjpg, "data-raw/tjsp/da_cjpg.rds")
arrow::write_parquet(da_cjpg, "data-raw/tjsp/da_cjpg.parquet")

da_cjpg |>
  dplyr::mutate(anomes = lubridate::floor_date(disponibilizacao, "week")) |>
  dplyr::count(anomes) |>
  dplyr::filter(anomes >= "2019-01-01") |>
  ggplot2::ggplot(ggplot2::aes(anomes, n)) +
  ggplot2::geom_line(linewidth = 2) +
  ggplot2::scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  ggplot2::labs(
    x = NULL, y = NULL,
    title = "Quantidade de julgamentos por semana"
  ) +
  ggplot2::theme_minimal()


da_cjpg |>
  dplyr::count(disponibilizacao) |>
  dplyr::filter(disponibilizacao >= "2019-01-01") |>
  ggplot2::ggplot(ggplot2::aes(disponibilizacao, n)) +
  ggplot2::geom_point(alpha = .2) +
  ggplot2::geom_smooth(method = "loess", span = .1) +
  ggplot2::scale_x_date(date_breaks = "3 month", date_labels = "%Y\n%m") +
  ggplot2::theme_light()

da_cjpg |>
  dplyr::mutate(anomes = lubridate::floor_date(disponibilizacao, "week")) |>
  dplyr::count(anomes) |>
  dplyr::filter(anomes >= "2019-01-01") |>
  dplyr::mutate(anomes = tsibble::yearweek(anomes)) |>
  tsibble::as_tsibble(index = anomes) |>
  tsibble::fill_gaps() |>
  tidyr::replace_na(list(n = 0)) |>
  feasts::gg_season(
    y = n, pal = viridis::viridis(5, begin = .1, end = .8),
    linewidth = 2, polar = FALSE
  ) +
  ggplot2::theme_minimal()

da_cjpg |>
  dplyr::mutate(anomes = lubridate::floor_date(disponibilizacao, "week")) |>
  dplyr::count(anomes) |>
  dplyr::filter(anomes >= "2019-01-01") |>
  dplyr::mutate(anomes = tsibble::yearweek(anomes)) |>
  tsibble::as_tsibble(index = anomes) |>
  tsibble::fill_gaps() |>
  tidyr::replace_na(list(n = 0)) |>
  feasts::gg_season(
    y = n, pal = viridis::viridis(5, begin = .1, end = .8),
    linewidth = 2, polar = TRUE
  ) +
  ggplot2::theme_minimal()


da_cjpg |>
  dplyr::mutate(anomes = lubridate::floor_date(disponibilizacao, "month")) |>
  dplyr::count(anomes) |>
  dplyr::filter(anomes >= "2019-01-01") |>
  dplyr::mutate(anomes = tsibble::yearmonth(anomes)) |>
  tsibble::as_tsibble(index = anomes) |>
  tsibble::fill_gaps() |>
  tidyr::replace_na(list(n = 0)) |>
  feasts::gg_season(
    y = n, pal = viridis::viridis(5, begin = .1, end = .8),
    linewidth = 2, polar = FALSE, facet_period = "year"
  ) +
  ggplot2::facet_wrap(~facet_id) +
  ggthemes::theme_hc()

x$data

da_cjpg <- readr::read_rds("data-raw/tjsp/da_cjpg.rds")

dplyr::glimpse(da_cjpg)

id_processos <- unique(da_cjpg$cd_doc)
set.seed(1)
amostra <- sample(id_processos, 10000)

tjsp::autenticar()
purrr::walk(
  amostra,
  \(x) tjsp::tjsp_baixar_cpopg_cd_processo(x, diretorio = "data-raw/tjsp/cpopg"),
  .progress = TRUE
)

da_cpopg <- fs::dir_ls("data-raw/tjsp/cpopg") |>
  purrr::map(tjsp::tjsp_ler_dados_cpopg, .progress = TRUE) |>
  purrr::list_rbind(names_to = "file") |>
  dplyr::mutate(
    partes = purrr::map(file, tjsp::tjsp_ler_partes, .progress = TRUE),
    movs = purrr::map(file, tjsp::tjsp_ler_movimentacao, .progress = TRUE)
  )

readr::write_rds(da_cpopg, "data-raw/tjsp/da_cpopg.rds")

loc <- readr::locale(grouping_mark = ".", decimal_mark = ",")
da_cpopg <- readr::read_rds("data-raw/tjsp/da_cpopg.rds") |>
  dplyr::filter(!is.na(area)) |>
  dplyr::mutate(valor = readr::parse_number(valor_da_acao, locale = loc)) |>
  dplyr::filter(!is.na(valor)) |>
  dplyr::mutate(
    dt_dist = purrr::map_chr(movs, \(x) as.character(min(x$data))),
    dt_dist = as.Date(dt_dist)
  ) |>
  dplyr::inner_join(
    da_cjpg |>
      dplyr::arrange(disponibilizacao) |>
      dplyr::select(processo, disponibilizacao) |>
      dplyr::distinct(processo, .keep_all = TRUE),
    "processo"
  ) |>
  dplyr::mutate(
    tempo = as.numeric(disponibilizacao - dt_dist) / 30.4375
  ) |>
  dplyr::filter(classe %in% c(
    "Procedimento Comum Cível", "Procedimento do Juizado Especial Cível"
  ))

da_cpopg <- readr::read_rds("data-raw/tjsp/da_cpopg.rds")

dplyr::glimpse(da_cpopg)


da_cpopg |>
  ggplot2::ggplot(ggplot2::aes(x = tempo)) +
  ggplot2::geom_histogram(bins = 30) +
  ggplot2::theme_minimal()

da_cpopg |>
  dplyr::count(classe)

da_cpopg |>
  ggplot2::ggplot(ggplot2::aes(x = tempo)) +
  ggplot2::geom_histogram(bins = 30) +
  ggplot2::facet_wrap(ggplot2::vars(classe), scales = "free_y") +
  ggplot2::theme_minimal()

da_cpopg |>
  ggplot2::ggplot() +
  ggplot2::aes(x = tempo, y = stringr::str_wrap(classe, 20)) +
  ggridges::geom_density_ridges(
    quantile_lines = TRUE, quantiles = 2,
    alpha = .5
  ) +
  ggplot2::theme_minimal() +
  ggplot2::scale_x_continuous(breaks = seq(0, 60, 6), limits = c(0, NA)) +
  ggplot2::coord_cartesian(xlim = c(0, 60)) +
  ggplot2::labs(x = "Tempo (meses)", y = "Classe")





da_cpopg$movs[[1]]
da_cpopg |>
  dplyr::glimpse()

da_cpopg |>
  dplyr::count(situacao, sort = TRUE)

da_cpopg |>
  dplyr::filter(!stringr::str_detect(distribuicao, "Livre")) |>
  dplyr::count(assunto, sort = TRUE)

dplyr::glimpse()

da_cpopg |>
  dplyr::count(area)
