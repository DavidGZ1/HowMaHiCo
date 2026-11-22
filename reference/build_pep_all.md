# Build (and optionally cache) the unified `pep_all` table from raw search output

Reads, parses, and annotates LC-MS search-engine output into the unified
long-format `pep_all` table, dispatching on `software` to the right
loader family (FragPipe / DIA-NN / PEAKS). This is the parsing step that
the `00_mhc_report` template runs inline; extracting it here lets the
focused report templates (`01_mhc_overview`, `02_prot_all`,
`03_lcms_qc`, `04_pepchem`, `05_quant_stats`) share one cached `pep_all`
instead of each re-parsing the raw files: run `build_pep_all()` once
(writing the `.rda` via `file_rda`), then render any subset of those
reports, each of which simply
[`load()`](https://rdrr.io/r/base/load.html)s the cache.

## Usage

``` r
build_pep_all(
  software,
  folder_data,
  annotation,
  shortpep_range = c(8, 13),
  instrument = "tims_tof",
  test_mode = FALSE,
  file_rda = NULL,
  dictionary = NULL
)
```

## Arguments

- software:

  One of `"fragpipe_dda_combined"`, `"fragpipe_dda_individual"`,
  `"diann"`, `"peaks_xpro"`, or `"custom"` — selects the loader branch
  (and, for FragPipe, the combined-vs-individual annotation mode).
  `"custom"` routes through the dictionary-driven parser (see
  `dictionary`).

- folder_data:

  Path to the folder holding the per-sample search output (the report's
  `FolderData`).

- annotation:

  Annotation data frame (e.g. from
  [`read_annot()`](https://davidgz1.github.io/HowMaHiCo/reference/read_annot.md));
  used to restrict the batch read to annotated samples and to join
  sample metadata.

- shortpep_range:

  Length-2 numeric vector `c(min, max)`; the biologically expected
  ligand-length window, forwarded to the `parse_*()` step to set
  `Length_range`.

- instrument:

  Instrument string (`"tims_tof"`, `"faims_orbi"`, `"orbi"`); only
  affects the PEAKS loader's ion-mobility handling.

- test_mode:

  If `TRUE`, the batch readers reduce each file to its first ~100 rows
  **per run** (fast iteration on a small but representative subset:
  every run, Condition and replicate of the experiment is still present,
  which a plain head-of-file truncation would not give for a combined
  export). Ignored by the PEAKS loader.

- file_rda:

  Optional path. When non-`NULL`, `pep_all` is
  [`save()`](https://rdrr.io/r/base/save.html)d there (as the object
  name `pep_all`) so report templates can
  [`load()`](https://rdrr.io/r/base/load.html) it.

- dictionary:

  Required when `software = "custom"`: either a path to a YAML parser
  dictionary or an already-loaded dictionary list (see
  [`read_dictionary()`](https://davidgz1.github.io/HowMaHiCo/reference/read_dictionary.md)
  /
  [`get_dictionary_template()`](https://davidgz1.github.io/HowMaHiCo/reference/get_dictionary_template.md)).
  Its `read:` block sets the per-sample filename and delimiter, and its
  `mode:` the annotation join. Ignored for the built-in loaders.

## Value

The `pep_all` data frame, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
annot <- read_annot("1_documentation/sample_annotation_dda_all.csv")
build_pep_all(
  software       = "fragpipe_dda_combined",
  folder_data    = "2_data",
  annotation     = annot,
  shortpep_range = c(8, 13),
  file_rda       = "2_data/dda_all_pep_all.rda"
)
# then render any focused report against the cache:
run_howmahico_report("01_mhc_overview", params = list(...), output_file = "01.html")
} # }
```
