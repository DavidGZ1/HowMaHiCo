# Mean ± SD barplot of ID counts per Condition, faceted by length range

Replaces the inline ggbarplot body in the "Average +/- sd" loop of the
main report template. Filters out the `"others"` length range (only
plots the `"All peptides"` and the expected-length rows), then renders a
faceted barplot showing mean ± SD across BioReplicates per Condition.

## Usage

``` r
plot_count_mean_sd(df, level, lim_level)
```

## Arguments

- df:

  A counts data frame shaped like `counts_size` (one row per
  BioReplicate × Condition × Length_range, with `n_Peptides`,
  `n_Sequences`, `n_Proteins` columns).

- level:

  One of `"Peptides"`, `"Sequences"`, `"Proteins"`.

- lim_level:

  Upper y-axis limit (e.g. looked up from a `count_lim` table by
  `Level`/`"Limit_mean"`).

## Value

A `ggpubr` barplot with mean ± SD error bars and viridis fill.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_count_mean_sd(counts_size, "Peptides", lim_level = 30000)
} # }
```
