#' Read a griddle file
#' @param path YAML path
#'
#' @return list, see [parse_griddle()]
#' @export
read_griddle <- function(path) {
  parse_griddle(yaml::read_yaml(path))
}

#' Convert griddle file contents into a list of parameter sets
#'
#' @param griddle griddle file contents
#' @return list of parameter sets, each of which is a named list
parse_griddle <- function(griddle) {
  validate_griddle(griddle)

  # if there are grid parameters, start there
  if ("grid_parameters" %in% names(griddle)) {
    # expand_grid makes a table; row in the grid is a combination of
    # parameters
    parameter_sets <- do.call(tidyr::expand_grid, griddle$grid_parameters) |>
      # transpose turns the column-wise list into a row-wise list
      purrr::transpose()
  } else {
    # if not, the "grid" is one, empty list
    parameter_sets <- list(list())
  }

  # for each set of nested parameters, try to match them against each
  # parameter set
  if ("nested_parameters" %in% names(griddle)) {
    for (nest in griddle$nested_parameters) {
      parameter_sets <- purrr::map(
        parameter_sets,
        function(ps) add_nested_pars(ps, nest)
      )
    }
  }

  # add in the baseline parameters
  if ("baseline_parameters" %in% names(griddle)) {
    for (i in seq_along(parameter_sets)) {
      parameter_sets[[i]] <- update_list(
        griddle$baseline_parameters,
        parameter_sets[[i]]
      )
    }
  }

  validate_parameter_sets(parameter_sets)

  parameter_sets
}

#' Add nested parameters
#'
#' @details
#' Utility function for parsing griddle file contents.
#' Look at the keys shared between `pars` and `nested_pars`. If the values
#' associated with those keys are the same in both lists, then add the
#' other key-value pairs from `nested_pars` into `pars`.
#'
#' @param parameter_set named list of parameters to be added to
#' @param nest named list of parameters
#' @return list
add_nested_pars <- function(parameter_set, nest) {
  # figure out which parameters to match on
  match_names <- intersect(names(parameter_set), names(nest))
  stopifnot(length(match_names) > 0)
  # other names are the ones to be added
  added_names <- setdiff(names(nest), names(parameter_set))

  # are all the match parameters the same?
  if (isTRUE(all.equal(parameter_set[match_names], nest[match_names]))) {
    # then add in the added values for that
    c(parameter_set, nest[added_names])
  } else {
    # else, do nothing
    parameter_set
  }
}

#' Update a list with values from another list
#'
#' @param x starting list
#' @param y updating list
#'
#' @return list, with all names present in `x` and `y`, with values from `y`
#' if a name is present in both
update_list <- function(x, y) {
  for (nm in names(y)) {
    x[[nm]] <- y[[nm]]
  }

  x
}

#' Validate griddle file contents
#'
#' @param griddle griddle file contents
#' @return `TRUE`, or error
#' @export
validate_griddle <- function(griddle) {
  # griddle must be null, or a list
  if (is.null(griddle)) {
    return(TRUE)
  }
  stopifnot(methods::is(griddle, "list"))

  # all top-level keys must be known
  stopifnot(all(names(griddle) %in% c(
    "baseline_parameters",
    "grid_parameters",
    "nested_parameters"
  )))

  # convenience variables
  has_baseline <- "baseline_parameters" %in% names(griddle)
  has_grid <- "grid_parameters" %in% names(griddle)
  has_nested <- "nested_parameters" %in% names(griddle)

  if (has_baseline) {
    baseline_names <- names(griddle$baseline_parameters)
  }
  if (has_grid) {
    grid_names <- names(griddle$grid_parameters)
  }
  if (has_nested) {
    # a list, each element is vector of names in each "nest"
    nested_names_by_nest <- griddle$nested_parameters |>
      purrr::map(names)

    nested_names <- nested_names_by_nest |>
      unlist() |>
      unique()
  }

  # no baseline parameter can appear in the grid
  if (has_baseline && has_grid) {
    stopifnot(length(intersect(baseline_names, grid_names)) == 0)
  }

  if (has_nested) {
    # if nested, must also have grid
    stopifnot(has_grid)

    # nests must not have names
    stopifnot(is.null(names(griddle$nested_parameters)))

    for (nest in griddle$nested_parameters) {
      # every nest must be a list
      stopifnot(class(nest) == "list")

      # every nest must have at least one name that appears in the grid
      stopifnot(length(intersect(names(nest), grid_names)) >= 1)
    }
  }

  TRUE
}

validate_parameter_sets <- function(parameter_sets) {
  # all parameter sets must be lists
  stopifnot(all(purrr::map_lgl(parameter_sets, function(x) class(x) == "list")))

  # all parameter sets must have the same names
  names_list <- purrr::map(parameter_sets, names)
  stopifnot(all(
    purrr::map_lgl(names_list, function(x) identical(x, names_list[[1]]))
  ))
}

#' Either is an integer, or equal to its integer cast
#'
#' @param x value
#' @return boolean
could_be_integer <- function(x) {
  class(x) == "integer" || (class(x) == "numeric" && x == as.integer(x))
}
