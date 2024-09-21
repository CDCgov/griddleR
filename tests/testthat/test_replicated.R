test_that("replicated works without seed", {
  f <- function(pars) tibble::tibble(x_plus_1 = pars$x + 1)
  rep_f <- griddleR::replicated(f)
  out <- rep_f(list(x = 1, seed = 42, n_replicates = 3))
  expect_equal(out, tibble::tibble(x_plus_1 = 2, replicate = 1:3))
})

test_that("replicated with seed", {
  f <- function(pars) tibble::tibble(u = round(runif(1), 3))
  out <- griddleR::replicated(f)(list(seed = 42, n_replicates = 3))
  expect_equal(out, tibble::tibble(u = c(0.915, 0.937, 0.286), replicate = 1:3))
})
