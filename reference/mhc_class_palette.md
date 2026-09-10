# Two-colour fill palette of an MHC class

The selected-vs-other length fill used across the report plots.
`"MHC1_mouse"` shares the `"MHC1"` palette (the same class, a different
species); an unrecognised class also falls back to it.

## Usage

``` r
mhc_class_palette(mhcclass = "MHC1")
```

## Arguments

- mhcclass:

  One of `"MHC1"`, `"MHC1_mouse"`, `"MHC2"`.

## Value

A length-2 character vector of hex colours, `c(in_window, other)`.

## Examples

``` r
mhc_class_palette("MHC2")
#> [1] "#21918c" "#440154"
```
