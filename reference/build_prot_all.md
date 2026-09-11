# Condense `pep_all` to one row per protein and sample

Builds the `prot_all` table behind the `08_prot_all` report: for every
(protein, `Sample`) pair, how many ligands it contributes and their
summed intensity, plus the protein annotation and any protein-level
value the search engine itself reported.

## Usage

``` r
build_prot_all(
  input,
  protein = c("ProteinFirst", "GeneFirst", "Accession"),
  multi_mapping = c("leading", "all"),
  engine_columns = TRUE
)
```

## Arguments

- input:

  A `pep_all`-shaped data frame.

- protein:

  Grouping column: `"ProteinFirst"` (default), `"GeneFirst"` or
  `"Accession"`. Which is appropriate depends on the search engine — see
  the report's methods section.

- multi_mapping:

  `"leading"` (default) counts each peptide once, for its leading
  protein; `"all"` counts it for every protein it maps to, via
  [`expand_mapped_proteins()`](https://davidgz1.github.io/HowMaHiCo/reference/expand_mapped_proteins.md).
  Under `"all"` the per-protein peptide counts deliberately no longer
  sum to the number of peptides in the dataset.

- engine_columns:

  Carry through the protein-level columns the search engine reported
  (see
  [`prot_engine_columns()`](https://davidgz1.github.io/HowMaHiCo/reference/prot_engine_columns.md)).
  Default `TRUE`.

## Value

A data frame with one row per (protein, `Sample`): `Protein`, `Sample`,
`Condition`, `BioReplicate`, the protein annotation columns present in
`input`, `n_Peptides`, `n_Sequences`, `n_Peptides_unique`,
`n_Peptides_shared`, `Area`, `Log2Area`, plus any engine-reported
columns. Zero rows, correctly typed, when `input` has none.

## Details

`Area` is summed on the **linear** scale within a sample and
log2-transformed afterwards, matching
[`build_quant_matrix()`](https://davidgz1.github.io/HowMaHiCo/reference/build_quant_matrix.md).
Note that the older `get_mat_log2area(pep_all, ProteinFirst, ...)` route
used by `00_mhc_report` and `04_quant` instead *averages* `Log2Area`;
the two are not interchangeable.

## Examples

``` r
if (FALSE) { # \dontrun{
prot_all <- build_prot_all(pep_short)
build_prot_all(pep_short, protein = "GeneFirst", multi_mapping = "all")
} # }
```
