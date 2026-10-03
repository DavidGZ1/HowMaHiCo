# Translate PTM tokens into readable modification names

The `PTM` column of `pep_all` is search-engine-specific:

## Usage

``` r
translate_ptm(x, tol = 0.01, reference = ptm_reference())
```

## Arguments

- x:

  Character vector of PTM tokens. The payload is taken from inside `()`
  or `[]` when present, else the whole string. `NA` and `""` pass
  through.

- tol:

  Delta-mass matching tolerance in Da. The default `0.01` is wide enough
  for 2-decimal rounding (`[+15.99]`) and still separates
  near-neighbours such as Acetyl (42.010565) from Trimethyl (42.046950).

- reference:

  Lookup table; defaults to
  [`ptm_reference()`](https://davidgz1.github.io/HowMaHiCo/reference/ptm_reference.md).
  The first row within `tol` wins, so row order encodes the preference
  between mass-degenerate modifications.

## Value

A character vector the same length as `x`, with recognised tokens
replaced by their modification name.

## Details

- **DIA-NN** writes UniMod accessions — `(UniMod:35)`

- **FragPipe** writes monoisotopic delta masses behind a
  position+residue prefix — `2M(15.9949)`

- **PEAKS** writes the modification *name* — `Oxidation (M)` — and
  carries the delta mass in the peptide string instead; bracketed delta
  masses (`[+15.99]`) still turn up in some exports

This maps all of those onto one readable name, so PTM plots are
comparable across engines. Handling the delta-mass form matters because
it is what the project's default (FragPipe) data uses, and a token that
is already a name simply passes through unchanged.

Display-time only — `pep_all$PTM` itself is left raw, following the same
"data keys unchanged" rule as the report's renamed display labels.

Translation is name-only: the residue and position prefix (`2M` in
`2M(15.9949)`) is dropped, because the engines disagree on how they are
written, so equivalent modifications collapse onto a single plot row. A
token that matches nothing is returned **unchanged** rather than
becoming `NA`.

## See also

[`ptm_reference()`](https://davidgz1.github.io/HowMaHiCo/reference/ptm_reference.md)
for the table,
[`plot_ptm_heatmap()`](https://davidgz1.github.io/HowMaHiCo/reference/plot_ptm_heatmap.md)
which applies this at plot time.

## Examples

``` r
translate_ptm(c("(UniMod:35)", "2M(15.9949)", "[+15.99]", "N-term(42.0106)"))
#> [1] "Oxidation" "Oxidation" "Oxidation" "Acetyl"   
translate_ptm("(UniMod:9999)")   # unknown accession, returned unchanged
#> [1] "(UniMod:9999)"
```
