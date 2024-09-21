test_that("trivial run", {
  fun <- function(params) params$x * 10

  parameter_sets <- list(
    list(x = 1),
    list(x = 2),
    list(x = 3)
  )

  simulations <- griddleR::run(fun, parameter_sets)$simulations
  expect_equal(
    simulations[[1]],
    list(parameter_hash = rlang::hash(list(x = 1)), result = 10)
  )
  expect_equal(simulations[[2]]$result, 20)
  expect_equal(simulations[[3]]$result, 30)
})

test_that("run with multicore", {
  # revert to the old plan if anything goes wrong
  old_plan <- future::plan()
  withr::defer(future::plan(old_plan))
  new_plan <- future::plan(future::multicore)

  # if multicore is not supported, skip this test
  if (identical(old_plan, new_plan)) {
    skip()
  }

  fun <- function(params) params$x * 10

  parameter_sets <- list(
    list(x = 1),
    list(x = 2),
    list(x = 3)
  )

  simulations <- griddleR::run(fun, parameter_sets)$simulations
  expect_equal(
    simulations[[1]],
    list(parameter_hash = rlang::hash(list(x = 1)), result = 10)
  )
  expect_equal(simulations[[2]]$result, 20)
  expect_equal(simulations[[3]]$result, 30)
})

test_that("run with replicated", {
  f <- griddleR::replicated(
    function(ps) tibble::tibble(y = round(ps$x + runif(1), 3))
  )
  parameter_sets <- list(
    list(x = 0, seed = 42, n_replicates = 3),
    list(x = 1, seed = 42, n_replicates = 3)
  )
  out <- griddleR::run(f, parameter_sets)

  hashes <- purrr::map_chr(parameter_sets, rlang::hash)

  expect_equal(out, list(
    parameter_map = rlang::set_names(
      list(
        list(x = 0, seed = 42, n_replicates = 3),
        list(x = 1, seed = 42, n_replicates = 3)
      ),
      hashes
    ),
    simulations = list(
      list(
        parameter_hash = hashes[1],
        result = tibble::tibble(y = c(0.915, 0.937, 0.286), replicate = 1:3)
      ),
      list(
        parameter_hash = hashes[2],
        result = tibble::tibble(y = c(1.915, 1.937, 1.286), replicate = 1:3)
      )
    )
  ))
})
