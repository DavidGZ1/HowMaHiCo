# Descriptor columns of a property set

The named subsets of
[`peptide_properties()`](https://davidgz1.github.io/HowMaHiCo/reference/peptide_properties.md)
the `04_pepchem` report offers through its `PropertySet` param, so the
choice lives in the package rather than in a hand-maintained list inside
the template.

## Usage

``` r
pepchem_properties(set = c("core", "extended"))
```

## Arguments

- set:

  `"core"` or `"extended"`.

## Value

A character vector of column names of
[`peptide_properties()`](https://davidgz1.github.io/HowMaHiCo/reference/peptide_properties.md).

## Details

`"core"` is the set a QC read-through needs — peptide length,
hydrophobicity, isoelectric point and net charge. `"extended"` adds the
descriptors that need more interpretation (mass, Boman index,
hydrophobic moment, instability and aliphatic indices) plus the
amino-acid class fractions.

## Examples

``` r
pepchem_properties("core")
#> [1] "Length" "GRAVY"  "pI"     "Charge"
pepchem_properties("extended")
#>  [1] "Length"            "GRAVY"             "pI"               
#>  [4] "Charge"            "MW"                "Boman"            
#>  [7] "HydrophobicMoment" "InstabilityIndex"  "AliphaticIndex"   
#> [10] "frac_Tiny"         "frac_Small"        "frac_Aliphatic"   
#> [13] "frac_Aromatic"     "frac_NonPolar"     "frac_Polar"       
#> [16] "frac_Charged"      "frac_Basic"        "frac_Acidic"      
```
