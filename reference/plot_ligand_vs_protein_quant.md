# Summed ligand intensity against the search engine's protein quantity

Compares the ligand intensity HowMaHiCo sums per source protein with the
protein quantity the search engine computed itself (DIA-NN's `PG.MaxLFQ`
and relatives), on log2 axes, with a Spearman correlation.

## Usage

``` r
plot_ligand_vs_protein_quant(prot_all, quant_col = NULL, title = NULL)
```

## Arguments

- prot_all:

  Output of
  [`build_prot_all()`](https://davidgz1.github.io/HowMaHiCo/reference/build_prot_all.md).

- quant_col:

  Engine quantity column to plot. `NULL` (default) picks the first one
  present, preferring MaxLFQ.

- title:

  Plot title. `NULL` (default) names the column used.

## Value

A ggplot object, or `NULL` when no engine quantity is available.

## Details

The point of the plot is the *disagreement*. Summed HLA-ligand intensity
is not a measure of source-protein abundance — presentation depends on
proteasomal processing, transport and binding affinity — so the two need
not track each other, and seeing how far they diverge is more
informative than being told they differ. Returns `NULL` when the search
engine reported no protein quantity, which is the case for FragPipe's
`psm.tsv`, PEAKS and the custom-dictionary path.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_ligand_vs_protein_quant(build_prot_all(pep_all))
} # }
```
