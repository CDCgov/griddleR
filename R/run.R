#' Run a function over each of the parameter sets
#'
#' @param fun function of a parameter set
#' @param parameter_sets list of lists, each of which is a named list of
#' parameters
#'
#' @export
run <- function(fun, parameter_sets) {
  parameter_hashes <- purrr::map_chr(parameter_sets, rlang::hash)
  # named list: hash -> parameter set
  parameter_map <- rlang::set_names(parameter_sets, parameter_hashes)

  simulations <- furrr::future_map(
    seq_along(parameter_sets),
    function(i) {
      list(
        parameter_hash = parameter_hashes[i],
        result = fun(parameter_sets[[i]])
      )
    }
  )

  list(
    parameter_map = parameter_map,
    simulations = simulations
  )
}
