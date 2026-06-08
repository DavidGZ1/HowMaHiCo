# Read one PEAKS `peptide.csv` export into long format

Reads `peptide.csv` from a PEAKS export subfolder, renames/derives the
core columns (`Sequence`, `Charge`, `Nter`/`Cter`, ...), pivots the
per-sample `Area#<sample>`/`ms2r_score_#<sample>`/... columns into long
format, and parses the ion-mobility column according to `instrument`.

## Usage

``` r
read_pep_peaks(filedir, folder_peaks_db, instrument = "tims_tof")
```

## Arguments

- filedir:

  Top-level directory containing `folder_peaks_db`.

- folder_peaks_db:

  PEAKS export subfolder name (relative to `filedir`) containing
  `peptide.csv`.

- instrument:

  One of `"tims_tof"` (parses the `X1_k0_Range` column directly into
  `invk0`), `"faims_orbi"`, or `"orbi"` (both repurpose Compensation
  Voltage `CV` as a stand-in for `invk0` — "not fully supported yet").

## Value

A long-format data frame with one row per peptide-sample observation,
including the parsed `invk0`/`invk0_start`/`invk0_end` columns.

## Examples

``` r
if (FALSE) { # \dontrun{
read_pep_peaks(getwd(), "JY_PEAKS_01", instrument = "tims_tof")
} # }
```
