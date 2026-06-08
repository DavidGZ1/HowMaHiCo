# UpSet plot of overlap between groups for a given variable

Counts, for each distinct value of `vars`, the set of `Compare` groups
it appears in, and renders an UpSet-style intersection plot via
[`ggupset::scale_x_upset()`](https://rdrr.io/pkg/ggupset/man/scale_x_upset.html),
optionally annotated with absolute or percentage intersection-size
labels.

## Usage

``` r
plot_upset(
  df,
  vars,
  n_intersections = 10,
  Compare = "Condition",
  labels = "abs",
  lab.size = 2
)
```

## Arguments

- df:

  A `pep_all`-shaped data frame.

- vars:

  Column (tidy-evaluated) whose distinct values define the items being
  compared, e.g. `Sequence`.

- n_intersections:

  Maximum number of intersections to display.

- Compare:

  Name (string) of the column defining the groups compared (becomes the
  upset's set membership axis), e.g. `"Condition"`.

- labels:

  One of `"abs"` (absolute intersection counts, the default), `"perc"`
  (percentage of the total), or any other value to omit the per-bar
  count labels entirely.

- lab.size:

  Text size of the per-bar count/percentage labels.

## Value

A ggplot2/`ggupset` object with an intersection-count bar chart and a
caption reporting the total unique count and intersections shown.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_upset(pep_all, Sequence, n_intersections = 10, Compare = "Condition")
} # }
```
