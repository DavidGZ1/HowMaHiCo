# Print a plot, skipping ones that were never built

The print-time counterpart to
[`ggsave_rawr()`](https://davidgz1.github.io/HowMaHiCo/reference/ggsave_rawr.md),
so a report chunk can unconditionally request a plot's display even when
it was conditionally skipped upstream. A bare symbol is looked up by
name in the **calling** environment; any other expression
(`plots[[nm]]`, a computed plot) is evaluated and judged by its value,
so `NULL` counts as "not generated".

## Usage

``` r
ggprint_rawr(input)
```

## Arguments

- input:

  The object to print. When it is a bare variable name, that name is
  used to check existence rather than the value.

## Value

The object, so a knitr chunk prints it; invisible `NULL` with a warning
when it was never generated.

## Examples

``` r
if (FALSE) { # \dontrun{
ggprint_rawr(p_corr_log2area_all)
} # }
```
