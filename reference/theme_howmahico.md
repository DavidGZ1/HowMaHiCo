# HowMaHiCo's unified ggplot theme

A
[`ggplot2::theme_minimal()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)
variant applied consistently across all package plot functions and
report templates. Standardises strip/axis/legend/title font sizes and
sets a white plot background.

## Usage

``` r
theme_howmahico(base_size = 10)
```

## Arguments

- base_size:

  Base font size (points). Default 10.

## Value

A ggplot2 theme object, addable to a plot with `+`.

## Examples

``` r
if (FALSE) { # \dontrun{
ggplot(pep_all, aes(Length)) + geom_histogram() + theme_howmahico()
} # }
```
