# Print a plot, skipping ones that were never built

Looks up `input` by the name it was called with (via
`deparse(substitute())`) and only prints it if an object of that name
exists in the calling environment — the print-time counterpart to
[`ggsave_rawr()`](https://davidgz1.github.io/HowMaHiCo/reference/ggsave_rawr.md),
so a report chunk can unconditionally request a plot's display even when
it was conditionally skipped upstream.

## Usage

``` r
ggprint_rawr(input)
```

## Arguments

- input:

  The object to print (NSE: its variable name is used to check
  existence, not its value).

## Value

The printed object (invisibly), or a warning if it does not exist.

## Examples

``` r
if (FALSE) { # \dontrun{
ggprint_rawr(p_corr_log2area_all)
} # }
```
