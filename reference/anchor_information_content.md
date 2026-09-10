# Per-position anchor information content of equal-length peptides

Computes the Shannon information content (in bits) at one or more
aligned positions of a set of fixed-length peptide sequences, the
quantity that drives a sequence-logo's letter height. A sharp anchor
(e.g. a single residue dominating P2 or the C-terminus of HLA-I 9-mers)
yields high information; a flat, motif-less distribution yields ~0. This
is the data-only basis for the motif-clarity dimension of
[`score_sample_quality()`](https://davidgz1.github.io/HowMaHiCo/reference/score_sample_quality.md)
(no external binding predictor or HLA typing needed) and reuses the same
per-position frequency idea as
[`ggseqlogo_bylength()`](https://davidgz1.github.io/HowMaHiCo/reference/ggseqlogo_bylength.md).

## Usage

``` r
anchor_information_content(sequences, positions = c(2, -1), min_n = 10)
```

## Arguments

- sequences:

  Character vector of peptide sequences, all of the same length
  (shorter/longer entries and empty strings are dropped).

- positions:

  Integer vector of 1-based positions to score. Negative values count
  from the C-terminus (`-1` = last residue). Default `c(2, -1)` (the
  HLA-I P2 and PΩ anchors).

- min_n:

  Minimum number of usable sequences required; below this the estimate
  is too noisy and `NA` is returned. Default `10`.

## Value

The summed information content (bits) over `positions`, or `NA_real_`
when fewer than `min_n` equal-length sequences are available. The
per-residue maximum is `log2(20)` bits, so the sum over two positions
ranges `0`–`~8.6`.

## Examples

``` r
if (FALSE) { # \dontrun{
anchor_information_content(c("SLFIGLKEV", "GLFDSLKEA", "ALWGFFPVL"))
} # }
```
