# Provider sentence of a report header

The one-line attribution every report template prints under its
description. The organisation used to be hardcoded into each skeleton's
opening paragraph, which branded every rendered report of a
distributable package to a single platform; it is now the optional
`Provider` report param, and this helper turns that param into the
sentence.

## Usage

``` r
provider_line(provider = "")
```

## Arguments

- provider:

  Organisation or person that produced the report, as a single string.
  `""` (the param default), `NA` or `NULL` select the generic sentence.

## Value

A single string, ready to be emitted from an inline `\\Sexpr`-style
`` `r ...` `` expression in a report template.

## Details

An empty/unset `Provider` yields a neutral sentence naming no
organisation, so a report is never attributed to someone who did not
produce it.

## Examples

``` r
provider_line("Immunopeptidomics Platform (IPP)")
#> [1] "Provided by Immunopeptidomics Platform (IPP)."
provider_line("")
#> [1] "Generated with the HowMaHiCo R package."
```
