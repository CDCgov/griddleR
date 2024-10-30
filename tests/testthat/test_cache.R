test_that("cache works", {
  local({
    tmpdir <- withr::local_tempdir()
    path <- file.path(tmpdir, "results")

    fun <- function(params) {
      tibble::tibble(y = params$x + 1)
    }

    parameter_sets <- list(
      list(x = 1),
      list(x = 2)
    )

    griddleR::run_cache(fun, parameter_sets, path)

    output <- griddleR::query_cache(path) |>
      dplyr::collect()

    expect_equal(output$y, output$x + 1)
    expect_setequal(output$x, c(1, 2))
  })
})
