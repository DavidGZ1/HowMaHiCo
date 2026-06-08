# Count samples/patients per peptide or protein, pivoted wide by group

Wraps
[`count_uniqueby()`](https://davidgz1.github.io/HowMaHiCo/reference/count_uniqueby.md)
for the common `pep_all` "how many samples/ patients was this
peptide/protein seen in, per group" question: groups by `var` within
`by` plus the identity columns appropriate for `level`, then pivots so
each `by` level becomes its own `n_<var>s.<by level>` column.

## Usage

``` r
count_uniqueby_ip(input, var, by, level = "Peptide")
```

## Arguments

- input:

  A `pep_all`-shaped data frame.

- var:

  Column (tidy-evaluated) to count distinct entries of, e.g. `Sample` or
  `Patient`.

- by:

  Column (tidy-evaluated) whose levels become the pivoted-wide columns,
  e.g. `Condition` or `Sample_type`.

- level:

  One of `"Peptide"` (groups by `Accession`, `ProteinFirst`,
  `GeneFirst`, `OrganismFirst`, `Length`, `Peptide`, `Sequence`) or
  `"Protein"` (groups by `Accession`, `ProteinFirst`, `GeneFirst`,
  `OrganismFirst` only — `ProteinFirst`/`GeneFirst` are deliberately
  excluded from the `"Peptide"` grouping key beyond what's listed
  because some peptides were assigned to different `ProteinFirst` values
  across processing runs despite sharing `Accession`/`Sequence`).

## Value

A wide data frame, one row per `level`-appropriate identity group, with
`n_<var>s.<by level>` count columns (zero-filled where absent).

## Examples

``` r
if (FALSE) { # \dontrun{
count_uniqueby_ip(pep_all, var = Sample, by = Condition, level = "Peptide")
} # }
```
