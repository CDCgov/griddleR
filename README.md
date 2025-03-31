# griddleR

:warning: Development of [pygriddler](https://github.com/CDCgov/pygriddler) has diverged from development of griddleR. As of pygriddler [v0.3](https://github.com/CDCgov/pygriddler/releases/tag/v0.3.0), the griddler syntax has been reformulated, and functionality beyond parsing griddles has been removed. griddleR uses should not expect feature parity or regular updates.

---

griddleR is an opinionated tool for managing inputs to simulations or other
analytical functions. This package includes functionality for:

- Parameter sets: an extension of `list` that does some extra validation and can
  produce stable hashes.
- Griddles: a YAML-based format for specifying grid-like lists of parameter
  sets.
- Running a function over multiple parameter sets, and "squashing" the results
  into a single [tibble](https://tibble.tidyverse.org/).
- Running a simulation function over multiple replicates with specified seeds.

This package is intended to be an R port of the Python
[pygriddler](https://github.com/CDCgov/pygriddler) package. Not all
functionality will be identical between the two packages.

See the [pygriddler documentation](https://cdcgov.github.io/pygriddler/) for
more details.

## Package overview

This package helps wrap your simulations' input and output.

The basic assumption is that you have some function, say `simulate()`, that
takes a named list of parameters and returns a tibble. For example, an ODE SIR
model would take in $R_0$, infectious period $1/\gamma$, and some other
parameters, and return a tibble of times and compartment sizes.

## Parameter input

This package provides a standard file format, called the **_griddle_**, to
articulate parameter inputs, including options for specifying:

- Baseline parameters
- A grid of parameter values, to produce varied simulations
- Named scenarios, with specified, non-gridded parameter values

### Specification

- The input parameter specification is read from a YAML with
  `yaml::read_yaml()`.
- The specification is a named list:
  - It must have at least one of `baseline_parameters` or `grid_parameters`.
  - If it has `grid_parameters`, it may also have `nested_parameters`.
- `baseline_parameters` is a named list.
  - The names are parameter names; the values are parameter values.
  - The parameter values need not be scalars. E.g., it might be a list of
    strings.
- `grid_parameters` is a named list.
  - The names are parameter names. Each value is a vector or a list. The
    elements in that list are the parameter values gridded over.
- `nested_parameters` is an _unnamed_ list.
  - Each element is a named list, called a "nest."
  - Every nest have at least one name that appears in the grid.
  - Names in each nest must be either:
    1.  present in `grid_parameters` or `baseline_parameters` (but not both),
        _or_
    1.  present in each nest.

This parameter specification parser will produce a list:

- Each element of which is a named list of parameters, called a "parameter set".
- The length of which is equal to the product of the lengths of the parameter
  value lists in `grid_parameters`.

### Example: grids

This griddle will produce 4 parameter sets, over the Cartesian product of the
parameter values for $R_0$ and $1/\gamma$. Each parameter set will have 3
parameters: $p_{I0}$, $R_0$, and $1/\gamma$.

```yaml
baseline_parameters:
  p_infected_initial: 0.001

grid_parameters:
  R0: [2.0, 3.0]
  infectious_period: [0.5, 2.0]
```

### Example: nests

If you want to include nested values, use `nested_parameters`. The names in each
nest that match `grid_parameters` will be used to determine which part of the
grid we are in, and the rest of the parameters in the nest will be added in to
that part of the grid. Nested parameters can be used to make named scenarios:

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

## Replicates

A convenience function `replicated()` allows your to wrap your simulation
function `simulate()` with a seed and number of replicates. These parameters
(`seed` and `n_replicates`) must be present in the parameter set passed to
`replicated(simulate)()`. The wrapper will remove those values before passing
the remainder to `simulate()`. It will set the seed, then run that number of
replicates. Each output tibble from `simulate()` will have a `replicate` column
added.

For example:

```yaml
baseline_parameters:
  p_infected_initial: 0.001
  seed: 42
  n_replicates: 100

grid_parameters:
  R0: [2.0, 3.0]
  infectious_period: [0.5, 2.0]
```

This will still produce 4 parameter sets, but if passed to
`replicated(simulate)()`, it will produce 400 output tibbles.

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
