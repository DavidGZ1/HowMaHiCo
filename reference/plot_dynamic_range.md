# Dynamic range (rank-abundance) per condition

Mean log2 intensity of every feature within a condition, plotted against
its abundance rank. The span of the curve is the observed dynamic range,
and its end shows where the quantification runs into the detection limit
— the region in which missingness is left-censored rather than
biological.

## Usage

``` r
plot_dynamic_range(mat, coldata)
```

## Arguments

- mat:

  Numeric matrix of log2 intensities.

- coldata:

  Matching column metadata (`Unit`, `Condition`).

## Value

A ggplot object.

## Examples

``` r
if (FALSE) { # \dontrun{
plot_dynamic_range(mat_n, qm$coldata)
} # }
```
