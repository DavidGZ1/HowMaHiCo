# Glossary of the `pep_all` columns

Reference table describing every core column of the unified `pep_all`
schema, plus the engine-specific caveats that are easy to misread
(DIA-NN's dummy `ppm`, its computed rather than observed `Mass`,
`Accession` being a protein *group* for some engines only). Rendered by
the reports' Glossary section and reproduced in the README, so the three
places that document the schema cannot drift apart.

## Usage

``` r
pep_all_glossary()
```

## Value

A data frame with columns `Column`, `Meaning` and `Notes`, in schema
order (sample identity, protein, peptide, scores/quantities,
modifications, physicochemical, provenance).

## Examples

``` r
pep_all_glossary()
#>            Column                                                  Meaning
#> 1       Condition                 Experimental group the sample belongs to
#> 2    BioReplicate                  Biological replicate within a Condition
#> 3   TechReplicate      Technical/injection replicate within a BioReplicate
#> 4          Sample  The analysed sample - the unit most plots are drawn per
#> 5       Sample_ID               Free-text human-readable sample identifier
#> 6       Accession         Protein accession(s) the peptide was assigned to
#> 7    ProteinFirst                             Leading protein of the group
#> 8       GeneFirst                           Leading gene name of the group
#> 9   OrganismFirst        Organism suffix parsed from the leading accession
#> 10        Peptide              Peptide as reported, modifications included
#> 11       Sequence           Stripped amino-acid sequence, no modifications
#> 12         Length                        Number of amino acids in Sequence
#> 13   Length_range       Whether Length falls in the expected ligand window
#> 14          Score                           Search-engine confidence score
#> 15           Area                       Precursor peak area (linear scale)
#> 16       Log2Area                                             log2 of Area
#> 17            PTM           Modification token(s) as the engine wrote them
#> 18         Charge                  Precursor charge state, formatted '+ n'
#> 19           Nter                                First residue of Sequence
#> 20           Cter                                 Last residue of Sequence
#> 21             RT                                           Retention time
#> 22          invk0                                       Ion mobility, 1/k0
#> 23           Mass                                           Precursor mass
#> 24            ppm                          Mass error in parts per million
#> 25            m_z                           Precursor mass-to-charge ratio
#> 26    Source_file                 Raw file / run the observation came from
#> 27 Source_File_ID                              Engine's own run identifier
#> 28   Precursor_Id                            Engine's precursor identifier
#> 29       Found_By                      Search engine that produced the row
#> 30      PeptideID Composite peptide identifier used for joins and counting
#>                                                                                                                     Notes
#> 1                                                          From the annotation table; factor order = annotation row order
#> 2                                                                                               From the annotation table
#> 3                                                                                               From the annotation table
#> 4                                                                                               From the annotation table
#> 5                                                    Optional; get_annot_sampleid() can fill it from a HyStar sample list
#> 6                    A protein GROUP for DIA-NN (';'-list) and PEAKS (':'-list); a single sp|ID|ENTRY string for FragPipe
#> 7                                                                                 Default protein key of build_prot_all()
#> 8                                                                                   Empty when the engine reports no gene
#> 9                                                                                                                        
#> 10                                                            Two peptidoforms of one sequence are two different peptides
#> 11                                                                            The 'sequences' counted in Venn/UpSet plots
#> 12                                                                                                                       
#> 13                                                 Window from MHCclass (or ShortPeptideLengthMin/Max); defines pep_short
#> 14 Engine-specific and NOT comparable across engines: FragPipe hyperscore, DIA-NN Q.Value (lower is better), PEAKS -10lgP
#> 15                                                              NA when the engine reported zero - see compute_log2area()
#> 16                                                                                NA for zero/absent Area in every loader
#> 17         UniMod accessions for DIA-NN, delta masses for FragPipe/PEAKS; translate_ptm() maps both to names at plot time
#> 18                                                                                                                       
#> 19                                                                                                                       
#> 20                                        C-terminal K/R fraction is a tryptic-background diagnostic in the quality score
#> 21                                                                                     Minutes, as reported by the engine
#> 22                                                 timsTOF only; FAIMS compensation voltage is substituted for faims_orbi
#> 23                           Observed/calibrated for FragPipe and PEAKS; COMPUTED from Precursor.Mz and charge for DIA-NN
#> 24          A hardcoded dummy 0 for DIA-NN, which reports no observed precursor m/z; dropped from the quality score there
#> 25                                                                                           The library value for DIA-NN
#> 26                                                                                        Extracted by extract_run_name()
#> 27                                                                                                                       
#> 28                                                                                                                 DIA-NN
#> 29                                              'FragPipe', 'DIA-NN', 'PEAKS', or the dictionary's value for custom input
#> 30                                                                                                                       
subset(pep_all_glossary(), Column %in% c("Peptide", "Sequence"))
#>      Column                                        Meaning
#> 10  Peptide    Peptide as reported, modifications included
#> 11 Sequence Stripped amino-acid sequence, no modifications
#>                                                          Notes
#> 10 Two peptidoforms of one sequence are two different peptides
#> 11                 The 'sequences' counted in Venn/UpSet plots
```
