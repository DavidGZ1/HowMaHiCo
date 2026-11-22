# Per-sequence physicochemical descriptors

Computes the peptide-chemistry descriptors behind the `04_pepchem`
report. Duplicated sequences are computed once and returned once, so
this is safe to call with the whole `Sequence` column of a long
`pep_all` table.

## Usage

``` r
peptide_properties(sequences, ph = 7.4)
```

## Arguments

- sequences:

  Character vector of peptide sequences (unmodified, one-letter code).
  `NA` and empty strings are dropped.

- ph:

  pH at which the net `Charge` is computed. Default `7.4`.

## Value

A data frame with one row per **unique** sequence: `Sequence`, `Length`,
`GRAVY`, `MW`, `pI`, `Charge`, `Boman`, `HydrophobicMoment`,
`InstabilityIndex`, `AliphaticIndex` and one `frac_<class>` column per
amino-acid class. Zero rows when no usable sequence is supplied.

## Details

`GRAVY` is the grand average of hydropathy, the mean Kyte-Doolittle
value of the residues (Kyte & Doolittle 1982) and the standard
hydrophobicity summary for a peptide — exactly what
[`Peptides::hydrophobicity()`](https://rdrr.io/pkg/Peptides/man/hydrophobicity.html)
returns with `scale = "KyteDoolittle"`. `pI`, `Charge`, `Boman`,
`HydrophobicMoment`, `InstabilityIndex` and `AliphaticIndex` come from
the corresponding `Peptides` functions. The `frac_*` columns are the
fraction of residues in each amino-acid class (the classes
[`Peptides::aaComp()`](https://rdrr.io/pkg/Peptides/man/aaComp.html)
reports), derived here from the composition matrix rather than by
calling `aaComp()`, which returns a per-sequence list and does not
vectorise.

Non-standard residues (`X`, `B`, `Z`, `U`) are ignored by the
composition and the class fractions; the `Peptides` descriptors apply
their own rules.

## Examples

``` r
peptide_properties(c("SIINFEKL", "GILGFVFTL"))
#>    Sequence Length    GRAVY       MW       pI       Charge     Boman
#> 1  SIINFEKL      8 0.487500 963.1416 6.408784 -0.005127052  0.582500
#> 2 GILGFVFTL      9 2.266667 966.1881 6.099982 -0.005093736 -2.674444
#>   HydrophobicMoment InstabilityIndex AliphaticIndex frac_Tiny frac_Small
#> 1         0.3755167        -20.65000       146.2500 0.1250000  0.2500000
#> 2         0.2503661         20.85556       162.2222 0.3333333  0.4444444
#>   frac_Aliphatic frac_Aromatic frac_NonPolar frac_Polar frac_Charged frac_Basic
#> 1      0.3750000     0.1250000     0.5000000  0.5000000         0.25      0.125
#> 2      0.4444444     0.2222222     0.8888889  0.1111111         0.00      0.000
#>   frac_Acidic
#> 1       0.125
#> 2       0.000
```
