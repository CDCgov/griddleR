#' Read and validate a parameter sets file
#'
#' @param path path to YAML parameter sets file
#' @return parsed YAML
#'
#' @export
read_parameter_sets <- function(path) {
  parameter_sets <- yaml::read_yaml(path)
  validate_parameter_sets(parameter_sets)
  parameter_sets
}

validate_parameter_sets <- function(parameter_sets) {
  # should be an unnamed list
  stopifnot(methods::is(parameter_sets, "list"))
  stopifnot(is.null(names(parameter_sets)))

  for (parameter_set in parameter_sets) {
    stopifnot(methods::is(parameter_set, "list"))
    if (is.null(names(parameter_set))) {
      stop("Parameter set must be named")
    }
  }
}
