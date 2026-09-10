# Compare amino-acid frequencies between Conditions

The composition counterpart of
[`compare_pepchem()`](https://davidgz1.github.io/HowMaHiCo/reference/compare_pepchem.md):
each residue's frequency is computed **within each sample** (over that
sample's unique sequences), then compared across Conditions with the
same Kruskal-Wallis + pairwise Wilcoxon + BH machinery. Testing
per-sample frequencies rather than pooled residue counts avoids treating
the hundreds of thousands of residues in a Condition as independent
observations, which a chi-square on pooled counts would do.

## Usage

``` r
compare_aa_frequency(props, fdr = 0.05)
```

## Arguments

- props:

  Output of
  [`pepchem_by_sample()`](https://davidgz1.github.io/HowMaHiCo/reference/pepchem_by_sample.md);
  needs `Sequence`, `Sample` and `Condition`.

- fdr:

  Significance cut-off on the BH-adjusted p-values. Default `0.05`.

## Value

A data frame shaped like
[`compare_pepchem()`](https://davidgz1.github.io/HowMaHiCo/reference/compare_pepchem.md)'s
but keyed by `AA`, with an extra `Log2Ratio` column (log2 of the median
frequency ratio, `Group2 / Group1`). The Kruskal-Wallis table is
attached as `attr(, "kruskal")`.

## Examples

``` r
if (FALSE) { # \dontrun{
compare_aa_frequency(pepchem_by_sample(pep_short))
} # }
```
