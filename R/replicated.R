#' Functional to run a function many times, with a seed
#'
#' @param fun function of a parameter set, that returns a tibble
#'
#' @details
#' The input `fun` must take a parameter set as its first argument. (It may
#' also take optional arguments.) It must return a tibble (or anything else
#' that [purrr::map_dfr()] can coerce). That tibble must not contain the name
#' `replicate`.
#'
#' A "replicated" function is returned. The
#' replicated function has the same function signature. It assumes that the
#' parameter set has elements `seed` and `n_replicates`. It removes those
#' elements from the list, sets the seed, calls `fun` on the remaining
#' parameter set `n_replicates` times. Each output is augmented with a column
#' `replicate`, and the outputs are row-bound and returned.
#'
#' @return "replicated" function
#'
#' @export
#'
#' @examples
#' f <- function(pars) tibble::tibble(x_plus_1 = pars$x + 1)
#' rep_f <- replicated(f)
#' rep_f(list(x = 1, seed = 42, n_replicates = 3))
replicated <- function(fun) {
  function(parameter_set, ...) {
    # destructively remove `seed` and `n_replicates` from the params list
    stopifnot(all(c("seed", "n_replicates") %in% names(parameter_set)))
    seed <- parameter_set$seed
    n_replicates <- parameter_set$n_replicates
    parameter_set$seed <- NULL
    parameter_set$n_replicates <- NULL

    withr::with_seed(seed, {
      purrr::map_dfr(1:n_replicates, function(replicate) {
        result <- fun(parameter_set, ...)
        result$replicate <- replicate
        result
      })
    })
  }
}
