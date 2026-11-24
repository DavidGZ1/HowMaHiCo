# Build the parameter list of a HowMaHiCo report

Reads the parameters a report template declares in its YAML header, with
their default values, and overlays the values given in `...`. Use it to
get a `params` list outside a knit (to run a report's chunks at the
console with
[`report_setup()`](https://davidgz1.github.io/HowMaHiCo/reference/report_setup.md)
and the chunks of a skeleton copied by
[`get_report_template()`](https://davidgz1.github.io/HowMaHiCo/reference/get_report_template.md)).
[`run_howmahico_report()`](https://davidgz1.github.io/HowMaHiCo/reference/run_howmahico_report.md)
uses it too, so a misspelled parameter fails before the render starts,
with the list of valid names.

## Usage

``` r
report_params(template, ..., .params = list())
```

## Arguments

- template:

  Report template name, as for
  [`run_howmahico_report()`](https://davidgz1.github.io/HowMaHiCo/reference/run_howmahico_report.md)
  (names used before v0.27.0 are resolved with a warning).

- ...:

  Parameter values overriding the template defaults, as `Name = value`
  pairs.

- .params:

  Optional named list of parameter values, merged before `...` (handy
  for passing an existing list).

## Value

A named list holding every parameter the template declares.

## See also

[`report_setup()`](https://davidgz1.github.io/HowMaHiCo/reference/report_setup.md),
[`get_report_template()`](https://davidgz1.github.io/HowMaHiCo/reference/get_report_template.md)

## Examples

``` r
p <- report_params("03_lcms_qc", Subset = "dda_all", MHCclass = "MHC2")
p$MHCclass
#> [1] "MHC2"
names(p)
#>  [1] "SampleSet"             "Provider"              "DataAnalysisNames"    
#>  [4] "WetLabNames"           "FolderDocumentation"   "AnnotationFile"       
#>  [7] "Subset"                "FolderData"            "PepAllSource"         
#> [10] "PepAllFile"            "FolderResults"         "FolderFigures"        
#> [13] "ProjectDir"            "Instrument"            "Software"             
#> [16] "MHCclass"              "ShortPeptideLengthMin" "ShortPeptideLengthMax"
#> [19] "TestMode"              "ResultsOverwrite"      "PlotsSave"            
#> [22] "InteractivePlots"      "CsvSave"              
```
