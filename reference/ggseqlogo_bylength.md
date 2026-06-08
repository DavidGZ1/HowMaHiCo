# Sequence motif logo for peptides of a given length

Filters to peptides of `seq_length`, splits their sequences by `by`, and
renders a
[`ggseqlogo::ggseqlogo()`](https://rdrr.io/pkg/ggseqlogo/man/ggseqlogo.html)
motif per group. Warns when a `by` group has no sequences of the
requested length (and so is dropped from the plot).

## Usage

``` r
ggseqlogo_bylength(input, seq_length, by, ...)
```

## Arguments

- input:

  A `pep_all`-shaped data frame with `Length`/`Sequence` columns.

- seq_length:

  Peptide length to filter to (motifs require fixed-length alignment).

- by:

  Column name (string) to split sequences by, e.g. `"Condition"`.

- ...:

  Additional arguments passed to
  [`ggseqlogo::ggseqlogo()`](https://rdrr.io/pkg/ggseqlogo/man/ggseqlogo.html).

## Value

A `ggseqlogo` ggplot object, faceted by `by`.

## Examples

``` r
if (FALSE) { # \dontrun{
ggseqlogo_bylength(pep_short, seq_length = 9, by = "Condition")
} # }
```
