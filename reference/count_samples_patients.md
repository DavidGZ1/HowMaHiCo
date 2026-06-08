# Combined per-Patient/Sample_type/Condition sample-and-patient count summary

Runs
[`count_uniqueby_ip()`](https://davidgz1.github.io/HowMaHiCo/reference/count_uniqueby_ip.md)
five times (totals across all samples, totals across all patients, by
`Patient`, by `Sample_type`, by `Condition`) and column-binds the
results into one wide summary table — after checking that every variant
produced rows in the same identity-key order (otherwise the
[`cbind()`](https://rdrr.io/r/base/cbind.html) would silently misalign).

## Usage

``` r
count_samples_patients(input, level)
```

## Arguments

- input:

  A `pep_all`-shaped data frame with `Patient`/`Sample_type`/
  `Condition`/`Sample` columns (the project-specific patient-cohort
  annotation columns this summary was designed around).

- level:

  Forwarded to
  [`count_uniqueby_ip()`](https://davidgz1.github.io/HowMaHiCo/reference/count_uniqueby_ip.md)
  (`"Peptide"` or `"Protein"`).

## Value

A wide data frame: identity columns (per `level`) followed by every
`n_*` count column from each of the five summaries.

## Examples

``` r
if (FALSE) { # \dontrun{
count_samples_patients(pep_all, level = "Peptide")
} # }
```
