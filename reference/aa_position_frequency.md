# Per-position amino-acid frequency

The position x residue frequency table a sequence logo draws, returned
as data instead of a plot — the numeric complement to
[`ggseqlogo_bylength()`](https://davidgz1.github.io/HowMaHiCo/reference/ggseqlogo_bylength.md)
and the generalisation of
[`anchor_information_content()`](https://davidgz1.github.io/HowMaHiCo/reference/anchor_information_content.md),
which collapses this same table to Shannon bits.

## Usage

``` r
aa_position_frequency(
  sequences,
  length = NULL,
  positions = NULL,
  groups = NULL,
  min_n = 10
)
```

## Arguments

- sequences:

  Character vector of peptide sequences.

- length:

  Peptide length to restrict to, or `NULL` (default) for the modal
  length when `positions` is also `NULL`, and for "all lengths" when
  `positions` is given.

- positions:

  Integer vector of positions to profile, or `NULL` (default) for all
  positions of the fixed `length`.

- groups:

  Optional grouping vector, the same length as `sequences`.

- min_n:

  Minimum number of usable sequences per group; a group below this is
  dropped, since its frequencies would be noise. Default `10`.

## Value

A long data frame with `Group`, `Position` (integer, as supplied, so
negatives are preserved), `PositionLabel` (an ordered factor), `AA`,
`Count`, `n_Sequences` and `Frequency`. Zero rows when nothing is
usable.

## Details

Two modes:

- `length` given (or both `length` and `positions` `NULL`, which picks
  the modal length): only peptides of that length are used and every
  position `1..length` is profiled. This is the mode for an anchor-motif
  heatmap.

- `positions` given with `length = NULL`: peptides of **all** lengths
  are used and each position is resolved against that peptide's own
  length, so `c(1, 2, -2, -1)` profiles the two N-terminal and two
  C-terminal residues across a mixed-length set.

Negative positions count from the C-terminus (`-1` is the last residue).

## Examples

``` r
if (FALSE) { # \dontrun{
aa_position_frequency(pep_short$Sequence, groups = pep_short$Condition)
aa_position_frequency(pep_short$Sequence, positions = c(1, 2, -2, -1))
} # }
```
