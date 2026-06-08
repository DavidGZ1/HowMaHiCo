# Read a PEAKS QC `StatisticsTable.csv` covering several fractions

Variant of
[`read_qc_peaks()`](https://davidgz1.github.io/HowMaHiCo/reference/read_qc_peaks.md)
for a single PEAKS QC export that reports several fractions side by side
— pivots the per-fraction columns into long format and joins them onto
the corresponding annotation rows by `Fraction_peaks`.

## Usage

``` r
read_qc_peaks_single(folder_peaks_qc, annotation)
```

## Arguments

- folder_peaks_qc:

  PEAKS QC export folder containing `StatisticsTable.csv`.

- annotation:

  Annotation data frame; must contain `Condition`, `BioReplicate`,
  `TechReplicate`, `Sample`, `Sample_peaks`, `File_peaks_nb`,
  `Fraction_peaks`.

## Value

A data frame of per-fraction QC statistics joined to the matching
annotation rows.

## Examples

``` r
if (FALSE) { # \dontrun{
read_qc_peaks_single("JY_QC_PEAKS_01", annotation)
} # }
```
