# Classify charge states into `+1`/`+2`/`>= +3` groups

Classify charge states into `+1`/`+2`/`>= +3` groups

## Usage

``` r
get_charge_group(input)
```

## Arguments

- input:

  A `pep_all`-shaped data frame with a `Charge` column (coercible to
  numeric, e.g. the `"+ 2"`-style factor produced by the loaders).

## Value

`input` with `Charge` coerced to numeric and a new `Charge_group` factor
column (`"+ 1"`, `"+ 2"`, `">= +3"`).

## Examples

``` r
if (FALSE) { # \dontrun{
get_charge_group(pep_all)
} # }
```
