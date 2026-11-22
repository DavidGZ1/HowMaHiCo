# Source proteins identified per sample

How many distinct source proteins each sample contributes, grouped by
Condition. The protein counterpart of the identification counts in
`01_mhc_overview`, and the first thing to check before reading anything
else at protein level: a sample with far fewer source proteins is
usually a depth problem, not a biological one.

## Usage

``` r
plot_proteins_per_sample(prot_all, title = NULL)
```

## Arguments

- prot_all:

  Output of
  [`build_prot_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_prot_all.md).

- title:

  Plot title. `NULL` (default) uses a generic one.

## Value

A ggplot object, or `NULL` when `prot_all` has no rows.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_proteins_per_sample(build_prot_all(pep_short))
} # }
```
