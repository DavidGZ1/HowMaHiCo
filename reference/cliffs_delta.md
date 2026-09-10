# Cliff's delta effect size

The non-parametric effect size that pairs with a Wilcoxon rank-sum test:
the probability that a random value of `x` exceeds a random value of
`y`, minus the reverse. `0` means the distributions overlap completely,
`+1`/`-1` that they are fully separated. Unlike a difference of medians
it is scale-free, so descriptors on different units can be compared on
one axis.

## Usage

``` r
cliffs_delta(x, y)
```

## Arguments

- x, y:

  Numeric vectors. `NA`s are dropped.

## Value

A single number in `[-1, 1]`, or `NA_real_` when either vector is empty
after dropping `NA`s.

## Details

Computed from the rank sum (ties contribute 0.5), so it is O(n log n)
rather than the O(n\*m) pairwise definition.

## Examples

``` r
cliffs_delta(1:10, 1:10)
#> [1] 0
cliffs_delta(11:20, 1:10)
#> [1] 1
```
