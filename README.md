# griddleR

Keep those parameters safe & tidy!

## Package overview

This package helps wrap your simulations' input and output.

The basic assumption is that you have some function, let's call it
`myPack::simulate()`, that takes a named list of parameters and returns
a flat data frame. For example, an ODE SIR model would take in $R_0$, infectious
period $1/\gamma$, and some other parameters, and return a tibble of times and
compartment sizes.

## Concepts

- _Parameter_: A combination of a string name and an arbitrary value.
- _Parameter set_: An unordered set of parameters.
- _Simulation function_: A function that takes in a parameter set and returns a _result_.

## Overview of functionality

### Current functionality

- [Parameter input](#parameter-input)

### Future functionality

- Running simulations, given parameter input
  - Handles parallelization with `futures` and `furrr`
- Caching results
  - Creates a persistent database linking arbitrary simulation IDs (e.g., UUIDs)
    with parameter values
  - Concatenates and stores results in an Arrow database, partitioned by
    simulation ID and replicate chunk
  - Does some sensible chunking (e.g., don't put more than a 10,000 simulations
    into one partition?)
- Pulls from cached results
  - Eg, maybe you can say `get_cache(myPack::simulate, my_params)` and then it
    pops right out
  - Unclear how you pull replicates out of that?

## Parameter input

This package provides a standard file format, called the **_griddle_**, to articulate parameter inputs,
including options for specifying:

- Baseline parameters
- A grid of parameter values, to produce varied simulations
- Named scenarios, with specified, non-gridded parameter values

### Specification

- The input parameter specification is read from a YAML with
  `yaml::read_yaml()`.
- The specification is a named list:
  - It must have at least one of `baseline_parameters` or `grid_parameters`.
  - If it has `grid_parameters`, it may also have `nested_parameters`.
  - It must not have any other keys
- `baseline_parameters` is a named list.
  - The names are parameter names; the values are parameter values.
  - The parameter values need not be scalars. E.g., it might be a list of
    strings.
- `grid_parameters` is a named list.
  - The names are parameter names. Each value is a vector or a list. The
    elements in that list are the parameter values gridded over.
  - No name can be repeated between `baseline_parameters` and `grid_parameters`.
- `nested_parameters` is an _unnamed_ list.
  - Each element is a named list, called a "nest."
  - Every nest have at least one name that appears in the grid.
  - Names in each nest must be either:
    1.  Present in `grid_parameters` or `baseline_parameters` (but not both), _or_
    1.  Present in each nest.

This parameter specification parser will produce a list:

- Each element of which is a named list of parameters, called a "parameter set".
- The length of which is equal to the product of the lengths of the parameter
  value lists in `grid_parameters`.

### Examples

In the simplest case, the griddle file will produce one parameter set:

```yaml
baseline_parameters:
  R0: 3.0
  infectious_period: 1.0
  p_infected_initial: 0.001
```

But maybe you want to run simulations over a grid of parameters. So instead use
`grid_parameters`:

```yaml
baseline_parameters:
  p_infected_initial: 0.001

grid_parameters:
  R0: [2.0, 3.0]
  infectious_period: [0.5, 2.0]
```

This will run 4 parameter sets, over the Cartesian product of the parameter values
for $R_0$ and $1/\gamma$.

If you want to run many replicates of each of those parameter sets, wrap your single function in another function that takes the random seed and number of replicates:

```yaml
baseline_parameters:
  p_infected_initial: 0.001
  seed: 42
  n_replicates: 100

grid_parameters:
  R0: [2.0, 3.0]
  infectious_period: [0.5, 2.0]
```

This will still produce 4 parameter sets, and it will be up to your wrapped simulation function to know how to run all the replicates.

If you want to include nested values, use `nested_parameters`. The names in each nest that match `grid_parameters` will be used to determine which part of the grid we are in, and the rest of the parameters in the nest will be added in to that part of the grid. For example:

```yaml
grid_parameters:
  R0: [2.0, 4.0]
  infectious_period: [0.5, 2.0]

nested_parameters:
  - R0: 2.0
    p_infected_initial: 0.01
  - R0: 4.0
    p_infected_initial: 0.0001
```

The nested values of $R_0$ match against the grid, and will add the $p_{I0}$ values in to those parts of the grid. Thus, this will produce 4 parameter sets:

1. $R_0=2$, $1/\gamma=0.5$, $p_{I0}=10^{-2}$
1. $R_0=2$, $1/\gamma=2$, $p_{I0}=10^{-2}$
1. $R_0=4$, $1/\gamma=0.5$, $p_{I0}=10^{-4}$
1. $R_0=4$, $1/\gamma=2$, $p_{I0}=10^{-4}$

Nested parameters can be used to make named scenarios:

```yaml
baseline_parameters:
  p_infected_initial: 0.001

grid_parameters:
  scenario: [pessimistic, optimistic]

nested_parameters:
  - scenario: pessimistic
    R0: 4.0
    infectious_period: 2.0
  - scenario: optimistic
    R0: 2.0
    infectious_period: 0.5
```

This will produce 2 parameter sets.

You cannot repeat a parameter name that is in `baseline_parameters` in `grid_parameters`, because it would be overwritten every time. But you can use `nested_parameters` to sometimes overwrite a baseline parameter value:

```yaml
baseline_parameters:
  R0: 2.0
  infectious_period: 1.0
  p_infected_initial: 0.001

grid_parameters:
  scenario: [short_infection, long_infection, no_infection]
  population_size: [!!float 1e3, !!float 1e4]

nested_parameters:
  - scenario: short_infection
    infectious_period: 0.5
  - scenario: long_infection
    infectious_period: 2.0
  - scenario: no_infection
    R0: 0.0
```

This will produce 6 parameter sets:

1. $R_0 = 2$, $\gamma = 1/0.5$, $N = 10^3$, $p_{I0} = 10^{-3}$
1. $R_0 = 2$, $\gamma = 1/0.5$, $N = 10^4$, $p_{I0} = 10^{-3}$
1. $R_0 = 2$, $\gamma = 1/2.0$, $N = 10^3$, $p_{I0} = 10^{-3}$
1. $R_0 = 2$, $\gamma = 1/2.0$, $N = 10^4$, $p_{I0} = 10^{-3}$
1. $R_0 = 0$, $\gamma = 1.0$, $N = 10^3$, $p_{I0} = 10^{-3}$
1. $R_0 = 0$, $\gamma = 1.0$, $N = 10^4$, $p_{I0} = 10^{-3}$

All of them have the same fixed parameter value $p_{I0}$. Half of them have each of the two grid parameter values $N$. For each of the three scenarios, there is a mix of $R_0$ and $\gamma$ values drawn from `baseline_parameters` and `nested_parameters`.

## Project Admin

Scott Olesen <ulp7@cdc.gov> (e.g., CDC/IOD/ORR/CFA)

---

## General Disclaimer

This repository was created for use by CDC programs to collaborate on public
health related projects in support of the
[CDC mission](https://www.cdc.gov/about/organization/mission.htm). GitHub is not
hosted by the CDC, but is a third party website used by CDC and its partners to
share information and collaborate on software. CDC use of GitHub does not imply
an endorsement of any one particular service, product, or enterprise.

## Public Domain Standard Notice

This repository constitutes a work of the United States Government and is not
subject to domestic copyright protection under 17 USC § 105. This repository is
in the public domain within the United States, and copyright and related rights
in the work worldwide are waived through the
[CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
All contributions to this repository will be released under the CC0 dedication.
By submitting a pull request you are agreeing to comply with this waiver of
copyright interest.

## License Standard Notice

This repository is licensed under ASL v2 or later.

This source code in this repository is free: you can redistribute it and/or
modify it under the terms of the Apache Software License version 2, or (at your
option) any later version.

This source code in this repository is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the Apache Software
License for more details.

You should have received a copy of the Apache Software License along with this
program. If not, see http://www.apache.org/licenses/LICENSE-2.0.html

The source code forked from other open source projects will inherit its license.

## Privacy Standard Notice

This repository contains only non-sensitive, publicly available data and
information. All material and community participation is covered by the
[Disclaimer](https://github.com/CDCgov/template/blob/master/DISCLAIMER.md) and
[Code of Conduct](https://github.com/CDCgov/template/blob/master/code-of-conduct.md).
For more information about CDC's privacy policy, please visit
[http://www.cdc.gov/other/privacy.html](https://www.cdc.gov/other/privacy.html).

## Contributing Standard Notice

Anyone is encouraged to contribute to the repository by
[forking](https://help.github.com/articles/fork-a-repo) and submitting a pull
request. (If you are new to GitHub, you might start with a
[basic tutorial](https://help.github.com/articles/set-up-git).) By contributing
to this project, you grant a world-wide, royalty-free, perpetual, irrevocable,
non-exclusive, transferable license to all users under the terms of the
[Apache Software License v2](http://www.apache.org/licenses/LICENSE-2.0.html) or
later.

All comments, messages, pull requests, and other submissions received through
CDC including this GitHub page may be subject to applicable federal law,
including but not limited to the Federal Records Act, and may be archived. Learn
more at
[http://www.cdc.gov/other/privacy.html](http://www.cdc.gov/other/privacy.html).

## Records Management Standard Notice

This repository is not a source of government records but is a copy to increase
collaboration and collaborative potential. All government records will be
published through the [CDC web site](http://www.cdc.gov).
