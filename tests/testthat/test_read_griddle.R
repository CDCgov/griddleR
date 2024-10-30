test_that("validation works", {
  expect_error(griddleR::validate_griddle(list(foo = 5)))
})

test_griddle <- function(nm, parameter_sets) {
  test_that(
    glue::glue("test griddle: {nm}"),
    {
      expect_equal(
        griddleR::read_griddle(test_path("data", glue::glue("{nm}.yaml"))),
        parameter_sets
      )
    }
  )
}

test_griddle(
  "baseline",
  list(
    list(R0 = 1.5, gamma = 1.0, pop_size = 100, scenario = "baseline"),
    list(R0 = 1.5, gamma = 2.0, pop_size = 100, scenario = "short_infection"),
    list(R0 = 0.0, gamma = 1.0, pop_size = 100, scenario = "no_transmission")
  )
)

test_griddle(
  "example1",
  list(
    list(R0 = 3.0, infectious_period = 1.0, p_infected_initial = 0.001)
  )
)

test_griddle(
  "example2",
  list(
    list(p_infected_initial = 0.001, R0 = 2.0, infectious_period = 0.5),
    list(p_infected_initial = 0.001, R0 = 2.0, infectious_period = 2.0),
    list(p_infected_initial = 0.001, R0 = 3.0, infectious_period = 0.5),
    list(p_infected_initial = 0.001, R0 = 3.0, infectious_period = 2.0)
  )
)

test_griddle(
  "example2b",
  list(
    list(R0 = 2.0, infectious_period = 0.5, p_infected_initial = 0.001),
    list(R0 = 2.0, infectious_period = 2.0, p_infected_initial = 0.001),
    list(R0 = 3.0, infectious_period = 0.5, p_infected_initial = 0.001),
    list(R0 = 3.0, infectious_period = 2.0, p_infected_initial = 0.001)
  )
)

test_griddle(
  "example4",
  list(
    list(R0 = 2.0, infectious_period = 0.5, p_infected_initial = 0.01),
    list(R0 = 2.0, infectious_period = 2.0, p_infected_initial = 0.01),
    list(R0 = 4.0, infectious_period = 0.5, p_infected_initial = 0.0001),
    list(R0 = 4.0, infectious_period = 2.0, p_infected_initial = 0.0001)
  )
)

test_griddle(
  "example5",
  list(
    list(
      p_infected_initial = 0.001, scenario = "pessimistic",
      R0 = 4.0, infectious_period = 2.0
    ),
    list(
      p_infected_initial = 0.001, scenario = "optimistic",
      R0 = 2.0, infectious_period = 0.5
    )
  )
)

test_griddle(
  "fixed_list",
  list(
    list(
      n_populations = 5, population_sizes = c(100, 200, 300, 400, 500), R0 = 1.5
    ),
    list(
      n_populations = 5, population_sizes = c(100, 200, 300, 400, 500), R0 = 2.0
    )
  )
)

test_griddle("nest_only", list(
  list(
    vaccine_scenario = "baseline", intervention_scenario = "baseline",
    vaccine_amount = 100, intervention_efficacy = 0.3
  ),
  list(
    vaccine_scenario = "baseline", intervention_scenario = "optimistic",
    vaccine_amount = 100, intervention_efficacy = 0.8
  ),
  list(
    vaccine_scenario = "optimistic", intervention_scenario = "baseline",
    vaccine_amount = 200, intervention_efficacy = 0.3
  ),
  list(
    vaccine_scenario = "optimistic", intervention_scenario = "optimistic",
    vaccine_amount = 200, intervention_efficacy = 0.8
  )
))

test_that("missing nests fail", {
  expect_error({
    read_griddle(test_path("data", "nest_missing.yaml"))
  })
})
