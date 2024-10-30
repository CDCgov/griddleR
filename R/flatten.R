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

  parameters_with_hashes <- flatten_named_parameter_sets(output$parameter_map)

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
#' @param x named list, where each list element is a named list of parameters,
#'   which will be flattened into a tibble
#' @param nm_column column in the output tibble to assign the list names to
#' @return tibble
flatten_named_parameter_sets <- function(x, nm_column = "parameter_hash") {
  purrr::map2_dfr(
    names(x),
    x,
    function(nm, parameter_set) {
      df <- flatten_parameter_set(parameter_set)
      df[[nm_column]] <- nm
      df
    }
  )
}

#' Convert a parameter set into a tibble
#'
#' @param x named list
#' @return tibble
flatten_parameter_set <- function(x) {
  dplyr::as_tibble(purrr::map(x, flatten_value))
}

#' Convert a value, potentially a vector, into a single value
#'
#' Use `str()` to convert objects with length greater than 1
#' into a single string.
#'
#' @param x input value
#'
#' @return length-1 value, whose type depends on `x`
flatten_value <- function(x) {
  if (length(x) == 1) {
    # no need to do anything if this is a length-1 object
    x
  } else {
    # otherwise, use `str()` representation
    trimws(capture.output(str(x)))
  }
}
