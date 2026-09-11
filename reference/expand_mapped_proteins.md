# Expand peptides onto every protein they map to

A short, non-tryptic HLA ligand frequently maps to more than one
protein. This returns the peptide-to-protein mapping implied by the
search engine's own list of mapped proteins, one row per (peptide row,
protein).

## Usage

``` r
expand_mapped_proteins(input, protein = "ProteinFirst")
```

## Arguments

- input:

  A `pep_all`-shaped data frame.

- protein:

  Column holding the leading protein. Default `"ProteinFirst"`.

## Value

`input` with the `protein` column replaced by one row per mapped
protein, plus a logical `Protein_shared` marking peptides that mapped to
more than one.

## Details

The list lives in a different column per engine — FragPipe's
`Mapped_Proteins`, DIA-NN's and PEAKS' `Accession` — with a different
separator, so the source is resolved from the `Found_By` column. When
the table carries no such list (PEAKS' peptide export, the
custom-dictionary path, or a FragPipe run whose `Mapped_Proteins` is
empty) the leading protein is returned with a warning, which is the same
answer `multi_mapping = "leading"` would give.

## Examples

``` r
if (FALSE) { # \dontrun{
expand_mapped_proteins(pep_all)
} # }
```
