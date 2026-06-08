# Batch of UpSet plots across several variables

Runs
[`plot_upset()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_upset.md)
once per entry of `vars`, restricting `df` to the distinct
`(var, Compare)` combinations beforehand (via
[`select_unique()`](https://davidgz1.github.io/HowMaHiCo/reference/select_unique.md))
so each plot only sees the columns it needs, and titles each plot
`"<var> overlap by <Compare>"`.

## Usage

``` r
plot_upset_batch(
  df,
  vars,
  n_intersections = 20,
  Compare = "Condition",
  labels = "abs",
  lab.size = 2
)
```

## Arguments

- df:

  A `pep_all`-shaped data frame.

- vars:

  Character vector of column names to plot overlap for, e.g.
  `c("Peptide", "Sequence", "Accession")`.

- n_intersections:

  Maximum number of intersections to display per plot.

- Compare:

  Name (string) of the column defining the groups compared.

- labels:

  Forwarded to
  [`plot_upset()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_upset.md)
  (`"abs"`, `"perc"`, or other).

- lab.size:

  Forwarded to
  [`plot_upset()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_upset.md).

## Value

A named list of ggplot2/`ggupset` objects, one per entry of `vars`,
named `"<var>_by_<Compare>"`.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_upset_batch(pep_all, c("Peptide", "Sequence", "Accession"), Compare = "Condition")
} # }
```
