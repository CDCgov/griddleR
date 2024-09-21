test_that("trivial flatten", {
  fun <- function(params) list(y = params$x)

  parameter_sets <- list(
    list(x = 1),
    list(x = 2)
  )

  output <- griddleR::run(fun, parameter_sets)
  expect_equal(
    griddleR::flatten_run(output),
    tibble::tibble(
      y = c(1, 2),
      x = c(1, 2)
    )
  )
})

test_that("trivial flatten without removal", {
  fun <- function(params) list(y = params$x)

  parameter_sets <- list(
    list(x = 1, foo = 0),
    list(x = 2, foo = 0)
  )

  output <- griddleR::run(fun, parameter_sets)
  expect_equal(
    griddleR::flatten_run(output, remove_fixed = FALSE),
    tibble::tibble(
      y = c(1, 2),
      x = c(1, 2),
      foo = c(0, 0)
    )
  )
})
