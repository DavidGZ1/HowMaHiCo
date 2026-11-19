# Raw per-sample immunopeptidomics quality metrics

Computes, for each `Sample` in a `pep_all` table, the raw (un-scored)
quality signals consumed by
[`score_sample_quality()`](https://davidgz1.github.io/HowMaHiCo/reference/score_sample_quality.md).
Every metric is derived from the unified `pep_all` schema with no
external data.

## Usage

``` r
qc_metrics_by_sample(pep_all, shortpep_range = c(8, 13), mhcclass = "MHC1")
```

## Arguments

- pep_all:

  A unified `pep_all` data frame (see the package's `pep_all` schema):
  one row per peptide-sample observation, with at least `Sample`,
  `Peptide`, `Sequence`, `Length`, `Cter`, `Charge`, `Accession` and
  (optionally) `ppm`.

- shortpep_range:

  Length-2 numeric `c(min, max)`: the biologically expected
  ligand-length window (e.g. `c(8, 13)` for HLA-I, `c(12, 25)` for
  HLA-II).

- mhcclass:

  `"MHC1"`, `"MHC1_mouse"` or `"MHC2"`. For `"MHC2"` the
  canonical-length and anchor-motif metrics are returned as `NA` (no
  fixed-length anchor model), so they drop out of the composite
  downstream — `frac_nested_core` is the class-II motif dimension
  instead, and
  [`quality_thresholds_default()`](https://davidgz1.github.io/HowMaHiCo/reference/quality_thresholds_default.md)
  gives it the anchor metric's weight there. For `"MHC1_mouse"`,
  `frac_9mer` counts 8- **and** 9-mers (both canonical for murine H-2)
  and the anchor motif is scored on whichever of the two the sample has
  more of. `frac_charge_1_2` is the fraction of in-window observations
  at a plausible charge: 1+/2+ for MHC-I (and custom windows), but **2+
  to 4+ for `"MHC2"`**, whose 12-25-mers are rarely singly charged. The
  key is the same for every class.

## Value

A data frame with one row per `Sample` and columns: `frac_in_window`,
`frac_9mer`, `frac_cterm_KR`, `frac_cterm_KR_longonly`,
`anchor_information`, `frac_nested_core`, `median_abs_rt_error`,
`median_abs_im_error`, `frac_cross_class`, `frac_charge_1_2`,
`n_unique_pep`, `n_unique_pep_in_window`, `n_source_proteins`,
`median_abs_ppm`.

## Examples

``` r
if (FALSE) { # \dontrun{
qc_metrics_by_sample(pep_all, shortpep_range = c(8, 13), mhcclass = "MHC1")
} # }
```
