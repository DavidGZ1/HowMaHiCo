# Four-way Venn diagram of a grouped variable

Splits `variable` by `group` (expects at most 4 groups —
[`ggvenn::ggvenn()`](https://yanlinlin82.github.io/ggvenn/reference/ggvenn.html)
is a 4-set Venn) and plots the overlap.

## Usage

``` r
plot_venn4(input, variable, group)
```

## Arguments

- input:

  A data frame containing `variable` and `group` columns.

- variable:

  Name (string) of the column whose overlap is plotted, e.g.
  `"Sequence"`.

- group:

  Name (string) of the grouping column that defines the Venn sets, e.g.
  `"Condition"`.

## Value

A `ggvenn` ggplot object.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_venn4(pep_all, "Sequence", "Condition")
} # }
```
