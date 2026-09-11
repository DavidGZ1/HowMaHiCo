# Engine-reported protein-level column names

The DIA-NN protein- and gene-level quantity and q-value columns that
[`parse_diann()`](https://davidgz1.github.io/HowMaHiCo/reference/parse_diann.md)
passes through, listed in one place so the loader's
[`dplyr::any_of()`](https://tidyselect.r-lib.org/reference/all_of.html)
selection and
[`prot_engine_columns()`](https://davidgz1.github.io/HowMaHiCo/reference/prot_engine_columns.md)
cannot drift apart.

## Usage

``` r
diann_protein_columns()
```

## Value

A character vector of column names.

## Details

Both DIA-NN naming generations are included — the fields were renamed
between releases (`PG.Quantity` became `PG.Abundance`, `PG.Normalised`
became `PG.NormalisedAbundance`) — so whichever spelling a report
carries is kept.

## Examples

``` r
diann_protein_columns()
#>  [1] "PG.Quantity"               "PG.Normalised"            
#>  [3] "PG.MaxLFQ"                 "PG.Abundance"             
#>  [5] "PG.NormalisedAbundance"    "PG.NormalizedAbundance"   
#>  [7] "Genes.Quantity"            "Genes.Normalised"         
#>  [9] "Genes.MaxLFQ"              "Genes.MaxLFQ.Unique"      
#> [11] "Genes.Abundance"           "Genes.NormalisedAbundance"
#> [13] "Protein.Q.Value"           "PG.Q.Value"               
#> [15] "Global.PG.Q.Value"         "GG.Q.Value"               
#> [17] "Lib.PG.Q.Value"           
```
