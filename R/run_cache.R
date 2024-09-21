#' Run simulation function over many parameter sets
#'
#' @param fun simulation function, takes in a parameter set
#' @param parameter_sets list of parameter sets
#' @param path path to cache location
#'
#' @details
#' Runs, optionally in parallel, using [furrr::future_walk()].
#'
#' @seealso [query_cache()]
#'
#' @export
run_cache <- function(
    fun,
    parameter_sets,
    path) {
  furrr::future_walk(
    parameter_sets,
    function(parameter_set) {
      run_cache1(fun, parameter_set, path)
    }
  )
}

run_cache1 <- function(
    fun,
    parameter_set,
    path) {
  # create the cache, if it does not exist
  ps_dir <- file.path(path, "parameter_sets")
  results_dir <- file.path(path, "results")

  if (!dir.exists(path)) {
    # if cache doesn't exist, set it up
    dir.create(path, recursive = TRUE)
    dir.create(ps_dir)
    dir.create(results_dir)
  }

  # if it does exist, make sure it has the right parts
  stopifnot(dir.exists(ps_dir))
  stopifnot(dir.exists(results_dir))

  # write the parameter set
  hash <- rlang::hash(parameter_set)
  ps_path <- file.path(ps_dir, paste0(hash, ".rds"))
  readr::write_rds(parameter_set, ps_path)

  # run with only one parameter set
  result <- fun(parameter_set)
  stopifnot(methods::is(result, "tbl"))
  if ("parameter_hash" %in% names(result)) {
    stop("Result cannot have name `parameter_hash`")
  }
  result$parameter_hash <- hash

  arrow::write_dataset(
    dataset = result,
    path = results_dir,
    format = "parquet",
    partitioning = "parameter_hash",
    hive_style = TRUE,
    existing_data_behavior = "delete_matching"
  )
}

#' Read from cache
#' @param path path to cache
#' @seealso [run_cache()]
#' @export
query_cache <- function(path) {
  ps_dir <- file.path(path, "parameter_sets")
  results_dir <- file.path(path, "results")

  parameters_map <- read_parameter_map(ps_dir)
  parameters_with_hashes <- flatten_map(parameters_map)

  arrow::open_dataset(results_dir) |>
    dplyr::inner_join(parameters_with_hashes, by = "parameter_hash")
}

read_parameter_map <- function(dir) {
  paths <- list.files(dir, pattern = "*.rds", full.names = TRUE)
  parameter_sets <- purrr::map(paths, readr::read_rds)
  hashes <- paths |>
    basename() |>
    (\(x) sub("\\.rds", "", x))()

  rlang::set_names(parameter_sets, hashes)
}
