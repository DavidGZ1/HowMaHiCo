# HowMaHiCo 0.3.0 (development version)

## Packaging & best-practices cleanup

* Declared the previously-undeclared base-package dependencies (`grDevices`,
  `graphics`, `stats`, `utils`) in `DESCRIPTION` `Imports`.
* The full exported function set is now part of the public reference: removed
  `@keywords internal` from every exported function (the package-overview page
  and the non-exported vendored helper stay internal), and listed every export
  in `_pkgdown.yml`.
* Internal code now uses the native R pipe (`|>`) throughout instead of magrittr
  `%>%`. **This raises the minimum R version to 4.1.0** (`Depends: R (>= 4.1.0)`).
* Added this `NEWS.md` changelog.

## Bug fixes

* `check_file_exists()` now names the conflicting file in its error/warning
  message (the filename was previously printed after `stop()`, so it never
  appeared).
* `check_output_exists()` no longer lists `upset_table_prot.csv` twice.
* The log2(Area) heatmap "saved in" message now reports the actual output path
  instead of a hardcoded `4_figures/...` string.

# HowMaHiCo 0.2.1

* Peptide motifs (seqlogo) now shown up to length 24 (was 22).
* Identification counts "Average ± sd" split into per-length individual plots and
  nested tabsets, with all-peptides vs selected-peptides shown separately.
* "Peptide ID distribution across RT, 1/k0 and m/z" refactored out of the
  template into `plot_pseudochromatogram()` and `plot_2d_distribution()`.
* Replaced hardcoded `scale_y_continuous()` breaks/labels with `n.breaks = 5` in
  `plot_bp_count_length()`, `plot_count_mean_sd()`, and
  `plot_overlap_intra_condition()`.
* Homogenized bar `alpha = 0.7` and added black outlines across plot functions.
* Fixed `count_ids_condition_bylengthrange()` dropping an existing `Condition`
  column before renaming.

# HowMaHiCo 0.2.0

* Completed Phases 1–6 of the conversion into a proper R package: functions moved
  into `R/`, report templates shipped under
  `inst/rmarkdown/templates/{01_mhc_report,02_mhc_upsets}/`, a testthat
  (edition 3) suite, roxygen `man/` pages, `_pkgdown.yml`, and CI (R-CMD-check +
  pkgdown).
* Added a proportion-by-length plot at the sample level to the "Total by Sample"
  section.
* `plot_peplength_hist()` density normalized by condition total rather than
  per-group.

# HowMaHiCo 0.1.4

* Fixed rendered `output_file` landing in the installed package library instead
  of the working directory.

# HowMaHiCo 0.1.3

* Named all report chunks and unified `fig.width = 8` across chunks.
* Added `plot_peplength_hist()` (a simpler length-distribution histogram without
  the boxplot overlay, facetable, two-color by `MHCclass`, density or absolute).

# HowMaHiCo 0.1.2

* Introduced `theme_howmahico()` and applied it across plot functions and report
  skeletons.
* `MHCclass` parameter with default length windows (MHC1: 8–13 AA, MHC2:
  12–25 AA) and a manual color/fill palette per class.
* Added a pre-flight check that every file named in the annotation table exists,
  a per-sample "Total by Sample" section, and a programmatically generated report
  title.

# HowMaHiCo 0.1.1

* Suppressed the progress bar in `get_annot_diann()`.

# HowMaHiCo 0.1.0

* First package-shaped release. Renamed the report templates to `01_mhc_report`
  and `02_mhc_upsets`; split `read_peaks_batch()` into read/parse/annotate
  matching the FragPipe/DIA-NN loader families; batch readers now read only the
  files referenced in the annotation table.
