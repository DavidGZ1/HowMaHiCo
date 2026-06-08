# Read one PEAKS QC `StatisticsTable.csv` into a one-row summary

Read one PEAKS QC `StatisticsTable.csv` into a one-row summary

## Usage

``` r
read_qc_peaks(folder_peaks_qc, sample)
```

## Arguments

- folder_peaks_qc:

  PEAKS QC export subfolder containing `StatisticsTable.csv`.

- sample:

  Sample name to record in the output's `Sample` column.

## Value

A one-row data frame of QC statistics, with `Sample` prepended.

## Examples

``` r
if (FALSE) { # \dontrun{
read_qc_peaks("JY_QC_PEAKS_01", sample = "JY_01")
} # }
```
