# Compare peptide descriptors between Conditions

Kruskal-Wallis across all Conditions plus a pairwise Wilcoxon rank-sum
test for every Condition pair, BH-corrected within each contrast, with
the median difference and
[`cliffs_delta()`](https://davidgz1.github.io/HowMaHiCo/reference/cliffs_delta.md)
as effect sizes.

## Usage

``` r
compare_pepchem(
  props,
  level = c("sample", "peptide"),
  properties = NULL,
  fdr = 0.05
)
```

## Arguments

- props:

  Output of
  [`pepchem_by_sample()`](https://davidgz1.github.io/HowMaHiCo/reference/pepchem_by_sample.md).

- level:

  `"sample"` (default) or `"peptide"` — see above.

- properties:

  Descriptor columns to test. `NULL` (default) uses every numeric
  non-annotation column.

- fdr:

  Significance cut-off applied to the BH-adjusted p-values. Default
  `0.05`.

## Value

A data frame with `Property`, `Level`, `Contrast`, `Group1`, `Group2`,
`n1`, `n2`, `Median1`, `Median2`, `MedianDiff`, `CliffsDelta`,
`p_value`, `p_adj` and `Significant`; the overall Kruskal-Wallis table
is attached as `attr(, "kruskal")`. Zero rows when fewer than two
Conditions are present.

## Details

`level` selects the unit of analysis, and the two tracks are **not**
interchangeable:

- `"sample"` (default) summarises each sample first (median descriptor
  over its unique sequences) and tests across samples. Samples are the
  real replicates, so this is the honest test — but it is low-powered:
  with three replicates per Condition a two-sided Wilcoxon cannot go
  below p = 0.1, so read the effect sizes, not only the p-values.

- `"peptide"` pools the unique sequences of a Condition and tests across
  peptides. Peptides from one sample are not independent, so this track
  is pseudo-replicated: its p-values are anti-conservative and it should
  be read as a *description* of the repertoire difference (through
  Cliff's delta), not as inference.

## Examples

``` r
if (FALSE) { # \dontrun{
compare_pepchem(pepchem_by_sample(pep_short), level = "sample")
} # }
```
