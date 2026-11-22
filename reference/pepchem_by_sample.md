# Per-sample peptide physicochemical descriptors

Entry point of the `04_pepchem` engine. Reduces a long `pep_all`-shaped
table to its distinct `Sequence` per `Sample` — the properties are
sequence-intrinsic, so counting every PSM would weight them by how often
a peptide happened to be re-sequenced — and joins on
[`peptide_properties()`](https://davidgz1.github.io/HowMaHiCo/reference/peptide_properties.md),
computed once over the unique sequences of the whole table.

## Usage

``` r
pepchem_by_sample(input, ph = 7.4)
```

## Arguments

- input:

  A `pep_all`-shaped data frame; needs `Sequence` and `Sample`, and
  carries `Condition`/`BioReplicate` through when present.

- ph:

  pH for the net-charge descriptor, passed to
  [`peptide_properties()`](https://davidgz1.github.io/HowMaHiCo/reference/peptide_properties.md).

## Value

A data frame with one row per (`Sample`, `Sequence`) pair: the
annotation columns, `Sequence`, and every descriptor column of
[`peptide_properties()`](https://davidgz1.github.io/HowMaHiCo/reference/peptide_properties.md).

## Examples

``` r
if (FALSE) { # \dontrun{
props <- pepchem_by_sample(pep_short)
} # }
```
