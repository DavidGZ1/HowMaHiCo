# Reference table of common peptide modifications

The lookup table behind
[`translate_ptm()`](https://davidgz1.github.io/HowMaHiCo/reference/translate_ptm.md):
UniMod accession, readable name and monoisotopic delta mass for the
modifications seen in LC-immunopeptidomics data. Rows are ordered **by
how commonly the modification occurs**, because delta-mass lookup takes
the first row within tolerance and a few modifications are
mass-degenerate (`Glu->pyro-Glu` / `Dehydrated` both -18.010565;
`Gln->pyro-Glu` / `Ammonia-loss` both -17.026549). Pass a reordered or
extended copy to
[`translate_ptm()`](https://davidgz1.github.io/HowMaHiCo/reference/translate_ptm.md)
to change that preference.

## Usage

``` r
ptm_reference()
```

## Value

A data frame with columns `accession` (integer UniMod accession), `name`
(readable modification name) and `mono_mass` (monoisotopic delta mass in
Da).

## See also

[`translate_ptm()`](https://davidgz1.github.io/HowMaHiCo/reference/translate_ptm.md),
which consumes this table.

## Examples

``` r
head(ptm_reference())
#>   accession            name  mono_mass
#> 1        35       Oxidation  15.994915
#> 2         4 Carbamidomethyl  57.021464
#> 3         1          Acetyl  42.010565
#> 4         7      Deamidated   0.984016
#> 5        21         Phospho  79.966331
#> 6        28   Gln->pyro-Glu -17.026549
subset(ptm_reference(), name == "Oxidation")
#>   accession      name mono_mass
#> 1        35 Oxidation  15.99492
```
