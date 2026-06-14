# Get the HowMaHiCo templates

This is a wrapper using rmarkdown::draft to get the HowMaHiCo templates
template copied in the working directory

## Usage

``` r
get_report_template(
  file = "HowMaHiCoReportTemplate",
  template = "00_mhc_report",
  edit = FALSE,
  create_dir = FALSE
)
```

## Arguments

- file:

  name of the report file to be copied.

- template:

  name of the template file to be used.

- edit:

  flag.

- create_dir:

  flag if directory should be created.

## Value

None

## Examples

``` r
if (FALSE) { # \dontrun{
get_report_template(file = "HowMaHiCoReportTemplate", template = "00_mhc_report", edit = TRUE, create_dir = FALSE)
} # }
```
