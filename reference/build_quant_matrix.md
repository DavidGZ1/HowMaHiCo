# Build a feature x unit log2(Area) matrix from `pep_all`

Collapses the long `pep_all` table into the quantitative matrix consumed
by the statistics engine. `Area` is summed on the **linear** scale
across all precursors (charge states, source files) of a feature within
a sample — charge states are the same molecule, so summing, not
averaging, is the correct aggregation — and only then log2-transformed.
Values are subsequently averaged on the log2 scale across the samples
belonging to the same `unit`, so technical replicates collapse into
their biological replicate instead of being treated as independent
observations (pseudo-replication would inflate the residual degrees of
freedom and make every p-value anti-conservative).

## Usage

``` r
build_quant_matrix(input, feature = "Peptide", unit = "BioReplicate")
```

## Arguments

- input:

  A `pep_all`-shaped data frame (long format) with at least `Area`,
  `Sample`, `Condition` and the `feature`/`unit` columns.

- feature:

  Column used for matrix rows: `"Peptide"` (default, the modified
  peptide sequence — the analyte in immunopeptidomics), `"Sequence"`,
  `"PeptideID"` (precursor level) or `"ProteinFirst"` (parent protein).

- unit:

  Column used for matrix columns: `"BioReplicate"` (default, technical
  replicates averaged), `"Sample"` (every run its own column) or
  `"Condition"`.

## Value

A list with `mat` (numeric matrix of log2 intensities, rows named by
`feature`, columns ordered by the factor levels of `unit`, `NA`s
preserved) and `coldata` (one row per matrix column: `Unit`,
`Condition`, `BioReplicate`, `n_Samples`).

## Details

Missing values are kept as `NA` (never 0): `Area == 0` is already mapped
to `NA` by the loaders (`compute_log2area()`), and the downstream steps
distinguish "not detected" from "detected at low intensity".

## Examples

``` r
if (FALSE) { # \dontrun{
qm <- build_quant_matrix(pep_all, feature = "Peptide", unit = "BioReplicate")
dim(qm$mat)
} # }
```
