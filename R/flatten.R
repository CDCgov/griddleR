#' Flatten results and parameters into a single tibble
#'
#' @param output output from [run()]
#' @param remove_fixed boolean; drop parameters that don't vary
#'
#' @return tibble, with results and parameters
#'
#' @export
flatten_run <- function(output, remove_fixed = TRUE) {
  results_with_hashes <- purrr::map_dfr(
    output$simulations,
    function(simulation) {
      x <- simulation$result
      x$parameter_hash <- simulation$parameter_hash
      x
    }
  )

  parameters_with_hashes <- flatten_map(output$parameter_map)

  if (remove_fixed) {
    parameters_with_hashes <- parameters_with_hashes |>
      dplyr::select(dplyr::where(function(x) length(unique(x)) > 1))
  }

  df <- dplyr::full_join(
    results_with_hashes,
    parameters_with_hashes,
    by = "parameter_hash"
  )
  df$parameter_hash <- NULL
  df
}

#' Convert a named list of lists into a tibble
#'
#' @param x named list, where each element is a list that can be coerced to
#' tibble
#' @param nm_column column in the output tibble to assign the list names to
#' @return tibble
flatten_map <- function(x, nm_column = "parameter_hash") {
  purrr::map2_dfr(
    names(x),
    x,
    function(nm, value) {
      df <- dplyr::as_tibble(value)
      df[[nm_column]] <- nm
      df
    }
  )
}
