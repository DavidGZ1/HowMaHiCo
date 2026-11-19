# Plain-language red flags for the overview report

Turns a
[`score_sample_quality()`](https://davidgz1.github.io/HowMaHiCo/reference/score_sample_quality.md)
table into a short list of problems worth a biologist's attention, each
with a severity and a sentence of detail. It powers the "Red flags"
section of `09_overview`. The rules are deliberately few and
transparent:

## Usage

``` r
overview_red_flags(
  scores,
  thresholds = quality_thresholds_default(),
  depth_ratio = 0.5,
  pep_all = NULL
)
```

## Arguments

- scores:

  Output of
  [`score_sample_quality()`](https://davidgz1.github.io/HowMaHiCo/reference/score_sample_quality.md).

- thresholds:

  The scoring table the scores were computed with (default
  [`quality_thresholds_default()`](https://davidgz1.github.io/HowMaHiCo/reference/quality_thresholds_default.md));
  supplies the labels, weights and cut-offs.

- depth_ratio:

  Fraction of the median unique-peptide count below which a sample is
  flagged as shallow (default 0.5).

- pep_all:

  Optional `pep_all` table, used for the replicate check.

## Value

A data frame with columns `Sample`, `Severity` (factor `High` \>
`Medium` \> `Low`), `Flag` and `Detail`, ordered by severity. It has
zero rows when nothing is flagged.

## Details

- a sample whose composite score is **Fail** (\< 40, `High`) or
  **Warning** (40-70, `Medium`);

- any **scored** quality dimension (weight \> 0) whose sub-score falls
  below 50, i.e. past its amber threshold. This is `High` when the
  sub-score is 0 and `Medium` otherwise, and it covers cross-class
  contamination, tryptic background, length-window fidelity and the
  rest;

- a sample with fewer than `depth_ratio` times the experiment's median
  number of unique peptides (`Medium`). This is a relative test, so it
  needs at least two samples;

- with `pep_all`, a Condition with a single BioReplicate (`Low`), where
  replicate variability cannot be judged. `Sample` is `NA` for this
  experiment-level flag.

## Examples

``` r
if (FALSE) { # \dontrun{
scores <- score_sample_quality(pep_all, c(8, 13), "MHC1")
overview_red_flags(scores, pep_all = pep_all)
} # }
```
