# Peptide-length window of an MHC class

Single source of truth for the "selected peptides" (`pep_short`) length
window used by every report template and by the quality-score engine.

## Usage

``` r
mhc_length_window(mhcclass = "MHC1", min = NULL, max = NULL)
```

## Arguments

- mhcclass:

  One of `"MHC1"` (default), `"MHC1_mouse"`, `"MHC2"`, or any other
  string to use the custom `min`/`max` window.

- min, max:

  Custom window bounds, used only when `mhcclass` is not one of the
  built-in classes.

## Value

An integer vector `c(lo, hi)`.

## Details

The built-in classes are the canonical ligand-length windows: `"MHC1"`
8-13 AAs (human HLA-I), `"MHC1_mouse"` **7-11 AAs** (murine H-2, whose
ligands run shorter — H-2Kb favours 8-mers), and `"MHC2"` 12-25 AAs. Any
other value falls back to the explicit `min`/`max` arguments, which is
how the `ShortPeptideLengthMin`/`ShortPeptideLengthMax` report params
take over for a custom window.

## Examples

``` r
mhc_length_window("MHC1")
#> [1]  8 13
mhc_length_window("MHC1_mouse")
#> [1]  7 11
mhc_length_window("custom", min = 9, max = 11)
#> [1]  9 11
```
