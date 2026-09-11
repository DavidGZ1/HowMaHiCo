# Protein-level columns the search engine reported

Reports which engine-computed protein-level columns are present in a
`pep_all` table, so
[`build_prot_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_prot_all.md)
can carry them through and the report can show them next to the values
recomputed from peptides.

## Usage

``` r
prot_engine_columns(input)
```

## Arguments

- input:

  A `pep_all`-shaped data frame.

## Value

A named list with three character vectors: `quantity`, `qvalue` and
`annotation`. Any of them may be empty, and all three are empty when the
search engine reported nothing at protein level.

## Details

In practice this means DIA-NN, which reports protein-group quantities
(`PG.MaxLFQ` and friends) alongside every precursor. FragPipe's
`psm.tsv` reports no protein quantity — that lives in `protein.tsv`,
which this package does not read — and contributes annotation only;
PEAKS' `peptide.csv` and the custom-dictionary path contribute nothing.

## Examples

``` r
if (FALSE) { # \dontrun{
prot_engine_columns(pep_all)
} # }
```
