#' Run a function over each of the parameter sets
#'
#' @param fun function of a parameter set
#' @param parameter_sets list of lists, each of which is a named list of
#' parameters
#' @param ... additional arguments to pass to `fun`
#' @param .furrr_options options to pass to `furrr::future_map()` .options
#' argument
#'
#' @export
run <- function(fun, parameter_sets, ..., .furrr_options = list()) {
  parameter_hashes <- purrr::map_chr(parameter_sets, rlang::hash)
  # named list: hash -> parameter set
  parameter_map <- rlang::set_names(parameter_sets, parameter_hashes)

  fun_args <- list(...)
  furrr_opts <- do.call(furrr::furrr_options, .furrr_options)

  simulations <- furrr::future_map(
    seq_along(parameter_sets),
    function(i) {
      args <- c(list(parameter_sets[[i]]), fun_args)
      list(
        parameter_hash = parameter_hashes[i],
        result = do.call(fun, args)
      )
    },
    .options = furrr_opts
  )

  list(
    parameter_map = parameter_map,
    simulations = simulations
  )
}
