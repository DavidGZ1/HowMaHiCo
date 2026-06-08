# HowMaHiCo's shared ggplot theme

A
[`ggpubr::theme_pubr()`](https://rpkgs.datanovia.com/ggpubr/reference/theme_pubr.html)
variant used across every report plot: blank facet strip backgrounds,
small strip/axis/legend text, and a bold plot title — all sized to fit
the report's compact figure layout.

## Usage

``` r
theme_rawr(base_size = 8)
```

## Arguments

- base_size:

  Base font size, passed to
  [`ggpubr::theme_pubr()`](https://rpkgs.datanovia.com/ggpubr/reference/theme_pubr.html).

## Value

A ggplot2 theme object, addable to a plot with `+`.

## Examples

``` r
if (FALSE) { # \dontrun{
ggplot(pep_all, aes(Length)) + geom_histogram() + theme_rawr()
} # }
```
