# Glossary of the physicochemical descriptors

One row per descriptor column of
[`peptide_properties()`](https://davidgz1.github.io/HowMaHiCo/reference/peptide_properties.md):
what it measures, how to read it for MHC ligands, and how it is
computed. It is the single source of the descriptor documentation the
`04_pepchem` report renders in its glossary (through
`inst/rmarkdown/shared/glossary.Rmd`), next to the
[`pep_all_glossary()`](https://davidgz1.github.io/HowMaHiCo/reference/pep_all_glossary.md)
table.

## Usage

``` r
pepchem_glossary(ph = 7.4)
```

## Arguments

- ph:

  pH quoted for the net `Charge` descriptor (the report's `ChargePh`
  param). Default `7.4`.

## Value

A data frame with columns `Descriptor`, `Meaning`, `Interpretation` and
`Computed`, one row per descriptor column of
[`peptide_properties()`](https://davidgz1.github.io/HowMaHiCo/reference/peptide_properties.md)
(all but `Sequence`).

## Details

The `frac_*` rows are generated from the amino-acid classes the
composition code uses, so the residues listed can never drift from what
is computed.

## Examples

``` r
pepchem_glossary()
#>           Descriptor
#> 1             Length
#> 2              GRAVY
#> 3                 MW
#> 4                 pI
#> 5             Charge
#> 6              Boman
#> 7  HydrophobicMoment
#> 8   InstabilityIndex
#> 9     AliphaticIndex
#> 10         frac_Tiny
#> 11        frac_Small
#> 12    frac_Aliphatic
#> 13     frac_Aromatic
#> 14     frac_NonPolar
#> 15        frac_Polar
#> 16      frac_Charged
#> 17        frac_Basic
#> 18       frac_Acidic
#>                                                                                      Meaning
#> 1                                                                      Number of amino acids
#> 2                Grand average of hydropathy: mean Kyte-Doolittle hydropathy of the residues
#> 3                                                                     Molecular weight in Da
#> 4                                  Isoelectric point: the pH at which the net charge is zero
#> 5                                                           Theoretical net charge at pH 7.4
#> 6  Boman index: potential to bind other proteins (sum of residue solubility values / length)
#> 7                       Amphipathicity: hydrophobic moment of the sequence as an alpha-helix
#> 8                                   Guruprasad instability index, from dipeptide composition
#> 9                             Relative volume occupied by aliphatic side chains (A, V, I, L)
#> 10                                    Fraction of residues in the Tiny class (A, C, G, S, T)
#> 11                       Fraction of residues in the Small class (A, C, D, G, N, P, S, T, V)
#> 12                                  Fraction of residues in the Aliphatic class (A, I, L, V)
#> 13                                   Fraction of residues in the Aromatic class (F, H, W, Y)
#> 14              Fraction of residues in the NonPolar class (A, C, F, G, I, L, M, P, V, W, Y)
#> 15                       Fraction of residues in the Polar class (D, E, H, K, N, Q, R, S, T)
#> 16                                 Fraction of residues in the Charged class (D, E, H, K, R)
#> 17                                         Fraction of residues in the Basic class (H, K, R)
#> 18                                           Fraction of residues in the Acidic class (D, E)
#>                                                                                                                                      Interpretation
#> 1                                   MHC-I ligands peak at 9 AAs (8-11 for most alleles; 8 for mouse H-2Kb); MHC-II ligands are 12-25 AAs and ragged
#> 2                                       Positive = hydrophobic, negative = hydrophilic. Shifts with allele anchor preferences and with LC retention
#> 3                                                                  Tracks Length closely; useful mainly to spot unusual composition at fixed length
#> 4                                                                        Basic anchors (K/R, e.g. HLA-A*03/A*11) raise it; acidic residues lower it
#> 5                                                                   Related to, but not the same as, the precursor charge state the instrument sees
#> 6                                          Higher (about > 2.5) suggests higher protein-binding potential; low or negative for hydrophobic peptides
#> 7                                               High values mean one face hydrophobic, the other polar. Mostly descriptive for short linear ligands
#> 8  Above 40 is called 'unstable' for proteins; the cut-off was not derived for short peptides, so compare between Conditions rather than against 40
#> 9                                                                              Higher with I/L/V-rich peptides, e.g. hydrophobic C-terminal anchors
#> 10                                                                        Compare between Conditions; classes overlap, so fractions do not sum to 1
#> 11                                                                        Compare between Conditions; classes overlap, so fractions do not sum to 1
#> 12                                                                        Compare between Conditions; classes overlap, so fractions do not sum to 1
#> 13                                                                        Compare between Conditions; classes overlap, so fractions do not sum to 1
#> 14                                                                        Compare between Conditions; classes overlap, so fractions do not sum to 1
#> 15                                                                        Compare between Conditions; classes overlap, so fractions do not sum to 1
#> 16                                                                        Compare between Conditions; classes overlap, so fractions do not sum to 1
#> 17                                                                        Compare between Conditions; classes overlap, so fractions do not sum to 1
#> 18                                                                        Compare between Conditions; classes overlap, so fractions do not sum to 1
#>                                                                     Computed
#> 1                                                            nchar(Sequence)
#> 2  Peptides::hydrophobicity(scale = "KyteDoolittle") (Kyte & Doolittle 1982)
#> 3                                            Peptides::mw() (average masses)
#> 4                                           Peptides::pI() (EMBOSS pK scale)
#> 5           Peptides::charge(pH = 7.4) (Lehninger pK scale); set by ChargePh
#> 6                                             Peptides::boman() (Boman 2003)
#> 7  Peptides::hmoment() (Eisenberg scale, 100 degrees per residue, window 11)
#> 8                            Peptides::instaIndex() (Guruprasad et al. 1990)
#> 9                                             Peptides::aIndex() (Ikai 1980)
#> 10         Residue counts / number of standard residues (X, B, Z, U ignored)
#> 11         Residue counts / number of standard residues (X, B, Z, U ignored)
#> 12         Residue counts / number of standard residues (X, B, Z, U ignored)
#> 13         Residue counts / number of standard residues (X, B, Z, U ignored)
#> 14         Residue counts / number of standard residues (X, B, Z, U ignored)
#> 15         Residue counts / number of standard residues (X, B, Z, U ignored)
#> 16         Residue counts / number of standard residues (X, B, Z, U ignored)
#> 17         Residue counts / number of standard residues (X, B, Z, U ignored)
#> 18         Residue counts / number of standard residues (X, B, Z, U ignored)
subset(pepchem_glossary(), Descriptor == "GRAVY")
#>   Descriptor
#> 2      GRAVY
#>                                                                       Meaning
#> 2 Grand average of hydropathy: mean Kyte-Doolittle hydropathy of the residues
#>                                                                                                Interpretation
#> 2 Positive = hydrophobic, negative = hydrophilic. Shifts with allele anchor preferences and with LC retention
#>                                                                    Computed
#> 2 Peptides::hydrophobicity(scale = "KyteDoolittle") (Kyte & Doolittle 1982)
```
