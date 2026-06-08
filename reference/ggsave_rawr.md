# Save a ggplot to a folder, skipping plots that were never built

Looks up `input` by the name it was called with (via
`deparse(substitute())`) and only calls
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
if an object of that name exists in the calling environment — this lets
report chunks unconditionally call
`ggsave_rawr(p_some_plot, "some_plot", folder = FolderFigures)` even
when `p_some_plot` was conditionally skipped upstream (e.g. no non-NA
correlation to plot), without erroring.

## Usage

``` r
ggsave_rawr(input, file, folder, width = 8, height = 10)
```

## Arguments

- input:

  The plot object to save (NSE: its variable name is used to check
  existence, not its value).

- file:

  Output file name, without extension; saved as `<file>.png` under
  `folder`.

- folder:

  Destination directory for the png.

- width, height:

  Figure dimensions in cm, passed to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).

## Value

Invisible `NULL`; called for its side effect of writing a png (or
warning that it was skipped).

## Details

Reconciles two near-duplicate report-inline variants (one hardcoding
`"4_figures"`, the other a `width = n_conditions + 5` default and a
chunk-local `FolderFigures`) into a single canonical version that takes
`folder`/`width`/`height` as ordinary explicit arguments — callers
compute and pass whatever values their report context needs.

## Examples

``` r
if (FALSE) { # \dontrun{
ggsave_rawr(p_peplength_all, "peplength_all", folder = FolderFigures)
} # }
```
