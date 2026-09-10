# Position-independent amino-acid composition

Residue counts and frequencies over a set of sequences, optionally split
by a grouping vector (Condition, Sample, ...). Non-standard residues are
dropped, so the frequencies of the 20 standard residues sum to 1 within
each group.

## Usage

``` r
aa_composition(sequences, groups = NULL, normalize = TRUE)
```

## Arguments

- sequences:

  Character vector of peptide sequences.

- groups:

  Optional grouping vector, the same length as `sequences` (factor
  levels are preserved). `NULL` (default) puts everything in one group
  called `"all"`.

- normalize:

  Add the within-group `Frequency` column. Default `TRUE`.

## Value

A long data frame with `Group`, `AA` (a factor over the 20 standard
residues, in the canonical order), `Count`, `n_Sequences` and — when
`normalize` is `TRUE` — `Frequency`.

## Examples

``` r
aa_composition(c("SIINFEKL", "GILGFVFTL"), groups = c("A", "B"))
#>    Group AA Count n_Sequences Frequency
#> 1      A  A     0           1 0.0000000
#> 2      A  R     0           1 0.0000000
#> 3      A  N     1           1 0.1250000
#> 4      A  D     0           1 0.0000000
#> 5      A  C     0           1 0.0000000
#> 6      A  Q     0           1 0.0000000
#> 7      A  E     1           1 0.1250000
#> 8      A  G     0           1 0.0000000
#> 9      A  H     0           1 0.0000000
#> 10     A  I     2           1 0.2500000
#> 11     A  L     1           1 0.1250000
#> 12     A  K     1           1 0.1250000
#> 13     A  M     0           1 0.0000000
#> 14     A  F     1           1 0.1250000
#> 15     A  P     0           1 0.0000000
#> 16     A  S     1           1 0.1250000
#> 17     A  T     0           1 0.0000000
#> 18     A  W     0           1 0.0000000
#> 19     A  Y     0           1 0.0000000
#> 20     A  V     0           1 0.0000000
#> 21     B  A     0           1 0.0000000
#> 22     B  R     0           1 0.0000000
#> 23     B  N     0           1 0.0000000
#> 24     B  D     0           1 0.0000000
#> 25     B  C     0           1 0.0000000
#> 26     B  Q     0           1 0.0000000
#> 27     B  E     0           1 0.0000000
#> 28     B  G     2           1 0.2222222
#> 29     B  H     0           1 0.0000000
#> 30     B  I     1           1 0.1111111
#> 31     B  L     2           1 0.2222222
#> 32     B  K     0           1 0.0000000
#> 33     B  M     0           1 0.0000000
#> 34     B  F     2           1 0.2222222
#> 35     B  P     0           1 0.0000000
#> 36     B  S     0           1 0.0000000
#> 37     B  T     1           1 0.1111111
#> 38     B  W     0           1 0.0000000
#> 39     B  Y     0           1 0.0000000
#> 40     B  V     1           1 0.1111111
```
