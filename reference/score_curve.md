# Map a raw metric value to a 0-100 quality sub-score

Piecewise-linear scoring curve anchored on a green (full marks, 100) and
amber (half marks, 50) threshold, extrapolated linearly to a hard 0
floor an equal step beyond amber, and clamped to `[0, 100]`. Returns
`NA` when the value or either threshold is `NA`, so undefined dimensions
drop out of the composite rather than scoring as 0.

## Usage

``` r
score_curve(x, green, amber, direction = c("higher_better", "lower_better"))
```

## Arguments

- x:

  Numeric raw metric value (may be `NA`).

- green:

  Threshold scoring 100.

- amber:

  Threshold scoring 50.

- direction:

  `"higher_better"` (larger is better) or `"lower_better"`.

## Value

A numeric sub-score in `[0, 100]`, or `NA_real_`.

## Examples

``` r
score_curve(0.82, green = 0.80, amber = 0.60, direction = "higher_better")
#> [1] 100
score_curve(0.40, green = 5,    amber = 10,   direction = "lower_better")
#> [1] 100
```
