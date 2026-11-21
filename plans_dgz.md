# plans\_dgz.md - HowMaHiCo

## What this is

Plans by DGZ to improve HowMaHiCo.

Instructions: when prompted, you can read this file and provide a plan to do the pending tasks in "to do". When something is done, move it to the end of "Done". Do not consider the points in "In standby", until they are moved to "to do"

## To do
* reports became too modular and the overview is now redundant. merge reports 1,2,4, 5, 9 and reduce redundancy, then becomes report 01_mhc_overview. Then reorder the other reports, do not change their names:
  * 8 becomes report 2
  * 3 remains 3
  * 7 becomes 4
  * 6 becomes 5


### Road to the EuPA 2026 abstract (example/abstract_eupa2026_v3.md)

Gap analysis of the package (v0.18.0) against the submitted abstract text, in
priority order. Tier A must be true before the abstract is submitted, tier B
before the meeting, tier C is wording-vs-code mismatches that can be closed
either by implementing or by re-wording the abstract.

**Tier A — blocking, the abstract makes these promises explicitly**

* make the GitHub repo public. The abstract prints
  https://github.com/DavidGZ1/HowMaHiCo, which currently 404s (`gh repo view`:
  `isPrivate: true`), and GitHub Pages will not serve `gh-pages` from a private
  repo, so https://davidgz1.github.io/HowMaHiCo/ is dead too. While there: add a
  CITATION.cff, and mint a Zenodo DOI so the poster has something citable.
  **Partly done (2026-11-19):** repo description, homepage (the pkgdown URL) and
  topics are set via `gh repo edit`. Still for DGZ: flip the visibility to
  public, CITATION.cff / Zenodo DOI / first GitHub release.
* **DONE (v0.23.0)** — license conflict resolved: relicensed to `GPL (>= 2)`
  (not plain GPL-3: Peptides, gplots and ggcorrplot are GPL-2 *only*).
* abstract housekeeping: the affiliation is still the placeholder
  `[Affiliation: institution, city, country]`; decide whether the submission
  carries the institutional address or DESCRIPTION's
  `davidgz.science@gmail.com`.

**Tier B — needed before the meeting; the abstract's Results/Conclusions rest on them**

* demonstration dataset + actual results. The Results paragraph is capability
  prose with no numbers, no figure and no comparison, and the only shipped data
  is `inst/extdata/sim_fragpipe_dda` (462 *synthetic* peptides, FragPipe DDA
  only) — fine for tests, not for a poster panel. Need at least one real dataset
  rendered end to end, class 1 *and* class 2 (the advanced-plans "JY hla1 and
  hla2 from Annica and Julian" item), ideally with a PRIDE accession so the QC
  claims are reproducible. Highest-value single panel: the quality score
  separating a genuine immunopeptidome from a failed pulldown / whole-proteome
  negative control — that is the figure that demonstrates "how MHC is the
  dataset".
  dataset class 1: annotation in example\1_documentation, data in \2_data\sim_fragpipe_dda_hla1
  dataset class 2: annotation in example\1_documentation, data in \2_data\sim_fragpipe_dda_hla2
  **Simulated demonstration DONE (v0.26.0)**: both datasets above are
  MaHiCoInSilico simulations, not the real JY data. `demo/eupa2026_demo.R`
  (tracked, Rbuildignored) renders all reports for both and simulates a
  tryptic-contamination titration (class-1 pulldown blended with whole-proteome
  peptides, p = 0 ... 1, LOD 1e6) plus a class-1 + 25 % class-2 mix. Outputs:
  example/3_results/eupa2026/ (34 html reports, demo\_summary.md,
  runs\_summary.csv) and example/4_figures/eupa2026/panel\_A\_titration.png +
  panel\_B\_classes.png. Numbers (median composite): class 1 90.7 Pass, class 2
  70 Pass, titration 90.7 / 88.9 / 82.5 / 75.3 / 62 / 49.2 / 35 at 0 / 5 / 10 /
  25 / 50 / 75 / 100 % tryptic (Pass -> Warning at 50 %, Fail at 100 %),
  class 1 + 25 % class 2 80.6 with cross-class 0.28 (vs 0.04). **Still open:
  the REAL dataset** (JY hla1/hla2, ideally with a PRIDE accession).
* **DONE (v0.25.0, `09_overview`)** — general-overview report for the biologically focused user (the
  advanced-plans "Simple summary of HowMaHiCo ala HowDirty" item). The abstract
  promises "a general-overview report for biologically focused users and another
  for deeper evaluation by the LC-MS expert"; what exists is 8 thematic slices
  plus `00_mhc_report`, a ~1300-line all-in-one that is the opposite of an
  overview (and the legacy report where the Overlap intra-Condition bug is still
  uncorrected). `03_lcms_qc` already covers the expert half. Scope: one page —
  counts, length-window fidelity, quality score, red flags.
* **DONE (v0.24.0)** — cross-experiment comparison, claimed in the Conclusions but not implemented:
  one render = one subset, and nothing stacks the per-sample score CSVs that
  `05_quality_score` writes into a trend view. Add a `compare_runs()` reading N
  score tables (+ a longitudinal/trend plot per metric) so the sentence becomes
  true.

**Tier C — code does not match the wording; implement or re-word**

* **DONE (v0.21.0)** - "interactive HTML" is overstated. Interactivity today = tabsets + floating TOC,
  DT tables in 06/07/08, and exactly two `ggplotly()` calls (00_mhc_report
  L996/L1034, 04_quant L118/L156); every other plot is a static raster. Either
  land the standby `InteractivePlots` toggle for the plots that are *not* inside
  `results='asis'` loops (correlation, PCA, volcano, dynamic range, completeness
  are the easy ones) or soften the abstract to "self-contained, navigable HTML".
* **DONE (v0.20.0)** — class 2 in the title vs. the quality score: for `MHCclass = "MHC2"`,
  `qc_metrics_by_sample()` returns NA for `frac_9mer` and `anchor_information`
  (no fixed-length anchor model), so they drop out of the composite — the "motif
  clarity" the Results paragraph names is not delivered for class 2, although
  the title claims "class 1 and class 2". Either add a register-free class-2
  motif metric (positional entropy over a sliding 9-mer core) or qualify the
  sentence.
* **DONE (v0.20.0)** — mass error is absent for DIA-NN (`ppm` is a hardcoded 0 dummy, documented and
  dropped from the score), so "identification QC such as score and mass error"
  is hollow for the DIA audience. Derivable from `Precursor.Mz` vs the
  theoretical m/z of sequence + PTM if it is worth making real.
* **DONE (v0.19.0)** — PTM profiles are unreadable as shipped: UniMod codes for
  DIA-NN, bare delta masses for FragPipe/PEAKS. `R/ptm.R` (`ptm_reference()` +
  `translate_ptm()`) now translates both forms, wired into
  `plot_ptm_heatmap(translate = TRUE)`.
* **DONE (v0.22.0)** — verify PEAKS Xpro before it appears in print. It did not
  work: `read_peaks_batch()` filtered export folders by the per-sample key
  (`Sample_peaks`) instead of `Sample_folder`, and pasted an absolute
  `FolderData` behind `getwd()`. Both fixed, both now failing loudly, and
  `inst/extdata/sim_peaks_xpro/` + tests cover the path end to end. **Still open
  for DGZ**: run it against a REAL PEAKS 11/Xpro export — a simulated one cannot
  prove column-name parity.
* "for both non-coders and advanced programmers" is present tense in the
  Background, but the workflow needs R, a hand-edited annotation CSV and a render
  call; `get_pipeline_script()` + demo mode soften it, and Docker/Shiny are
  correctly labelled "planned". Low risk — re-read it once the Shiny tier exists.
* **DONE (v0.19.0)** — finish the glossaries, which the abstract's
  reproducibility framing leans on: `pep_all_glossary()` +
  `inst/rmarkdown/shared/glossary.Rmd` now generate both the in-report glossary
  (in all ten templates) and the README table from one function. Still open for
  DGZ: read the 30 descriptions and correct anything that is wrong.


## In standby
* peptide position within the parent protein (the third part of the physicochemical-properties item) — deferred; it is the only part that needs a user-supplied search FASTA, since no loader carries a position column (FragPipe psm.tsv, DIA-NN report.tsv and PEAKS peptide.csv all lack one). Full design recorded in CLAUDE.md under "Deferred designs".
* implement safeguard when some conditions or replicates give 0 areas, currently throwing error — moved to standby (no repro available; e.g. CHEB\_001 all dda dataset not in repo). The all-NA Area/CV and all-NA correlation cases are already guarded in the report chunks; the partial (some groups 0/NA) failure needs a repro to target.
* InteractivePlots (TRUE/FALSE) toggle to render compatible plots via ggplotly — deferred: most compatible plots print inside results='asis' tabset loops where embedding plotly htmlwidgets (vs static ggplots) is finicky and only render-verifiable, which we don't do in-session. Groundwork ready: plotly already in Imports + loaded in shared setup.Rmd; ggplotly already used for the correlation plots (04\_quant L110/L143). Skip ggseqlogo / ggupset / ggvenn / ggarrange composites / base plot\_heatmap.
* Calculate an fdr for length distribution. What’s the probability of detecting the length distribution vs. the background proteome?
* Total by Condition /BioReplicate / Sample in tabs
* more explicit errors, e.g.,  when files are not found
* autogenerate Sample by concatenating the others
* bioreplicate as numbers or text, without condition, gets merged afterwards
* maybe generate a report in long format
* include whole folder with dia-quant-output when diann



### to be done by DGZ
* Check and complete glosary - NOW GENERATED: the 30 column descriptions live in
  pep\_all\_glossary() (R/report-helpers.R) and feed both the in-report glossary
  (inst/rmarkdown/shared/glossary.Rmd, in all ten templates) and the README
  table. They were written by Claude from the loaders + CLAUDE.md, so read them
  once and correct anything wrong; the tests only check that every required
  column IS documented, never that the text is right (v0.19.0)
* check/add functionality for peaks Xpro - the two blocking bugs are fixed and
  covered by a simulated export (v0.22.0), but **run it on a real PEAKS 11/Xpro
  export**: a simulated peptide.csv cannot prove column-name parity (-10lgP,
  "1/k0 Range", Area#<sample>, PTM spelling) with what PEAKS actually writes,
  and nothing has ever been read from a genuine Xpro export. Check in particular
  whether one export folder really holds all samples (the layout the fix now
  assumes) or whether your exports are one folder per sample
* **review the provisional class-2 quality-score thresholds** (v0.20.0):
  frac\_nested\_core is scored green >= 0.50 / amber >= 0.30 at weight 3 for
  MHCclass = "MHC2" (quality\_thresholds\_default() in R/quality-score.R). Those
  numbers are a judgement call, not literature values - no published nested-core
  fraction was used. Either calibrate them on a real HLA-II dataset (the JY hla2
  data in advanced plans) or tell users to run ThresholdMode = "qc\_relative",
  which the report already recommends. Also sanity-check the biology: is "shares
  a 9-mer with another ligand of the same sample" the nesting signal you would
  use, or would a longer/shorter k, or a per-family size, be better?
* **review the DIA calibration thresholds** (v0.20.0): median\_abs\_rt\_error
  green 0.5 / amber 1.5 min and median\_abs\_im\_error green 0.010 / amber 0.030
  1/k0, both weight 0.5. These are instrument- and gradient-dependent, so the
  defaults are only placeholders - set them from your own timsTOF runs, or leave
  them to qc\_relative mode. Also confirm Predicted.RT is in minutes on the same
  scale as RT in your DIA-NN version (the metric is a plain absolute difference)
* **read the in-report Methods/Glossary prose added in v0.19.0-v0.22.0**: the
  new nested-core and RT/IM paragraphs in 05\_quality\_score, the corrected PTM
  note in 00\_mhc\_report/01\_id\_counts, and the counting-units section of
  glossary.Rmd. All written by Claude; they state biology and should be read by
  you before the abstract is submitted
* **check the v0.22.0 abstract edits** in example/abstract\_eupa2026\_v3.md: the
  motif-clarity sentence now reads "anchor-position information content for
  class 1, nested binding cores for class 2" and the identification-QC sentence
  now distinguishes DDA mass error from DIA RT/ion-mobility calibration error.
  Both are accurate as to what the code does, but they are longer - trim to the
  word limit as you see fit
* **decide on the InteractivePlots default** (v0.21.0): it is FALSE, so reports
  look exactly as before unless asked. If interactivity is the selling point of
  the abstract, consider flipping the default to TRUE - but check the file sizes
  first (each plotly widget embeds its own JSON; the existing all-in-one reports
  are already 8-10 MB)
* 2do by me, check Overlap intra-Condition seems to be showing peptides in sequences, and sequences+proteins in proteins - corrected in the individual reports, but not in the legacy main report
* reorder plots in a way that makes more sense
* manual checking and re-writing text by me
* check way sample\_annotation is named in the reports, should be the same as in the example
* check which column is used as quant for each software
* get\_report\_template change param order, start with template then file
* **review the 09\_overview red-flag rules** (v0.25.0): overview\_red\_flags()
  in R/quality-score.R flags (a) a Fail (High) / Warning (Medium) composite,
  (b) any scored dimension with a sub-score < 50, i.e. past amber (High at 0),
  (c) a sample with < 0.5 x the experiment median of unique peptides
  (depth\_ratio = 0.5 is my choice, not a literature value) and (d) a Condition
  with a single BioReplicate (Low). On the simulated MHC-I data the only flags
  are Medium "Charge 1+/2+" (0.66 vs amber 0.70) - likely a quirk of the
  simulation, but check that rule against your real data. Are these the flags
  a biologist needs, and is the severity right?
* **read the 09\_overview prose** (v0.25.0): all captions were written by Claude
  and state biology - e.g. "MHC class I ligands pile up at 8-11 amino acids,
  usually with a sharp 9-mer peak", "MHC class II ... typically 13-17 amino
  acids", Pass >= 70 = "a typical immunopeptidome", Fail < 40 = "a failed
  pulldown or a non-MHC sample". Also check the "Where to go next" table and
  whether 09\_overview is the right name/number for the report you would hand
  out first
* **try compare\_runs() on real runs** (v0.24.0): render 05\_quality\_score for
  two or more real subsets, then compare\_runs(<results folders>) |>
  plot\_run\_trend(). Check that the default run labels ("SampleSet | Subset")
  and the default metrics (composite score, length in window, unique peptides in
  window) are the ones you want, and whether a dedicated cross-run report
  template is worth adding
* **confirm the license wording** (v0.23.0): DESCRIPTION is now GPL (>= 2) and
  LICENSE.md the GPL-2 text; the README License section explains why (Peptides,
  gplots, ggcorrplot are GPL-2 only; ggupset is GPL-3). If the abstract or
  poster says "MIT" or just "open-source", align it. Remember to check a new
  dependency's licence before adding it
* **check the EuPA demo panels and numbers** (v0.26.0):
  example/4_figures/eupa2026/panel\_A\_titration.png, panel\_B\_classes.png and
  example/3_results/eupa2026/demo\_summary.md. Choices to confirm: LOD = 1e6
  for the mixed runs (picked so the per-sample tryptic share tracks the blend
  proportion), the titration steps, and the panel metrics/titles. They are
  simulated data, so say so on the poster
* **anchor motif clarity rewards tryptic C-termini** (found v0.26.0): in the
  titration it falls 3.9 -> 2.9 bits up to 75 % tryptic, then REBOUNDS to 3.5
  bits at 100 %, because pure tryptic 9-mers all end in K/R, which looks like a
  sharp PΩ anchor. The composite still falls monotonically (other dimensions
  dominate). Decide whether to fix (e.g. compute it on 9-mers not ending in
  K/R, or P2 only; both cost alleles with K/R anchors such as HLA-A\*03/A\*11
  some signal) or keep and mention it
* **review the class-II charge cut-offs** (v0.26.0): for MHCclass = "MHC2",
  frac\_charge\_1\_2 now counts 2+ to 4+ (label "Charge 2+ to 4+") with
  provisional green 0.80 / amber 0.60 - not literature values. The simulated
  class-2 data has 0.81, so it lands exactly at Pass (composite 70.0); check
  the charge distribution of your real HLA-II data



## advanced plans

* include MaHiCoBench dataset for LFQbench-style plots
* Dataset: use the JY hla1 and hla2 from Annica and Julian
* MaHiCoInSilico: simulate NESTED HLA-II families (ragged length variants around a
  shared 9-mer core). It currently draws class-II peptides independently, so
  frac\_nested\_core is ~0 on simulated class-2 data and that weight-3 dimension
  cannot be demonstrated (found by the v0.26.0 EuPA demo)
* Simple summary of HowMaHiCo ala HowDirty
* Push a v1 and publication with this dataset before adding many more functionalities
* Maybe switch TechRep to InjRep
* Standardize headers, include a function to convert from old to new headers
* Wheremahico = peptide distribution in the protein. Add a widget to show location of peptides in specific protein
* Whichmahico = detect which alleles
* Ismahico= binding prediction
* HowConta = summary of common contaminants
* Another idea: hla allotyping from hla peptides in the ip data
* include code for nc.
* add tag for nc. exclusive, shared with up, up exclusive



## Done

* deal with code possibly buried in a folder, e.g. as option in setup:

opts\_knit$set(root.dir = normalizePath(".."))

* libraries not being loaded: kableExtra, ggpubr, viridis, plotly, openxlsx, dplyr
* standardize function names:

  * loaders as read\_software for individual files and read\_software\_batch for multiple inputs
  * read\_software\_batch include the option to provide the annotation and only read files referenced in the table, or a simple vector
  * also rename the parse functions
* I ran a test in a parallel session. There is an error on chunk 20, rownames\_to\_column function was not found. library(tibble) is missing.
* convert 00\_extract\_sample\_info\_fragpipe to functions in loaders-fragpipe
* I moved the original folders and their contents to example. Check that it doesn't break anything, and also add that folder itself to .gitignore
* add :

get\_report\_template <- function(file = "HowMaHiCoReportTemplate", edit = FALSE, create\_dir = FALSE) {

&#x20; rmarkdown::draft(file = file,

&#x20;                  template = "howmahico-report",

&#x20;                  edit = edit,

&#x20;                  package = "HowMaHiCo",

&#x20;                  create\_dir = create\_dir)

}

* correct mentions of "suffix" to "subset"
* check if it is possible to simplify the params entered in howmahico-report, provide a plan
* the batch readers currently read all the files in the data folder, then drop what is not in the annotation table. provide a plan to only read what is needed.
* read\_peaks\_batch has to be split because it currently includes the parser inside
* update readme and documentation following the example in example/0\\\_code/00\\\_pipeline\\\_example
* rename templates howmahico-report to 01\\\_mhc\\\_report, and howmahico-upsets to 02\\\_mhc\\\_upsets, the required functions and documentation
* implement default modes for:

  * MHC1, ShortPeptideLengthMin = 8, ShortPeptideLengthMax = 13
  * MHC2, ShortPeptideLengthMin = 12, ShortPeptideLengthMax = 25
* standardize report title by generating it programmatically. Include: template name, SampleSet, subset, MHCclass, date
* Adapt color/fill palette for all the plots where the shortpep\_range is used as aesthetic. Use manual scale instead of viridis. If MHCclass = MHC1, use c("#fde725", "#440154"); If MHCclass = MHC2, use c("#21918c", "#440154"). If custom lengths, use the same palette as MHC1
* in the pipeline (in example and also documentation), include a step to check if all the files named in the annotation table exist. print the list of files missing, and then stop with an error.
* in 01\_mhc\_report, add a section replicating section "## Total by Condition", but the x axis should be each sample
* homogenize the theme across the plotting functions: created theme\_howmahico, applied to all plotting functions and report skeletons. Also homogenized font sizes for labels, axes, and annotations.
* homogenize fig.width across all the chunks to 8.
* add names to chunks
* peptide length distribution, create a simpler function without the boxplot on top. This should facilitate using facet instead of ggarrange, include the option to color bars using two colors, based on the MHCclass. Also include option to show density or absolute numbers. In report, include both versions as sub-sections within a .{tabset}
* add Proportion by length at sample level to ## Total by Sample
* some plots use scale\_y\_continous with fixed breaks and labels. Changed to n.breaks = 5 in plot\_bp\_count\_length, plot\_count\_mean\_sd, plot\_overlap\_intra\_condition
* Peptide motifs: show up to length = 24 (was 22)
* # Identification counts ## Average +/- sd: all peptides and selected peptides shown separately in nested tabsets
* "# Peptide ID distribution across RT, 1/k0 and m/z": extracted to plot\_pseudochromatogram() and plot\_2d\_distribution(); skeleton simplified to 1-2 lines per chunk
* 2do by me,Identification counts, average +/-sd, split into individual plots for each length
* add to the readme as optional subpoint in complete the annotation csv: complete the annotation table with the Sample\_ID from the Hystar sample list using get\_annot\_sampleid
* de-vendor get\_dirs\_index\_peaks: removed the vendored/deltaProtR provenance, renamed R/vendored-deltaprotr.R to R/loaders-peaks-dirs.R, converted its pipes to |> (v0.3.0)
* unify the two report templates (01\_mhc\_report, 02\_mhc\_upsets skeleton.Rmd) on the native |> pipe (181 %>% converted; verified via knitr::purl + parse) (v0.3.0)
* 2do by me change purple color of length plots to a dimmer one
* Overlap intra-Condition (across replicates), split into individual plots for each length: plot\_overlap\_intra\_condition() refactored to single-plot (df, id\_col, title); report section now All peptides / Selected peptides nested tabsets (v0.5.0)
* Peptides identified per charge +1 to +4, one plot for all peptides (pep\_all) and one for selected length (pep\_short), shown in an All / Selected tabset (v0.5.0)
* multi-report framework instead of one big report: exported build\_pep\_all() (parse+cache step), shared inst/rmarkdown/shared/setup.Rmd child, and four focused templates 03\_id\_counts / 04\_overlaps / 05\_lcms\_qc / 06\_quant rendered against the cached pep\_all; 01\_mhc\_report kept unchanged for retrocompatibility (v0.6.0)
* PTM profile moved from 05\_lcms\_qc to 03\_id\_counts, and extended to show all peptides (pep\_all) alongside selected (pep\_short) in an All/Selected tabset (v0.6.1)
* renumbered all report templates: 01\_mhc\_report->00\_mhc\_report, 02\_mhc\_upsets->00\_mhc\_upsets, 03\_id\_counts->01\_id\_counts, 04\_overlaps->02\_overlaps, 05\_lcms\_qc->03\_lcms\_qc, 06\_quant->04\_quant (v0.7.0)
* lcms\_qc RT/1k0/m\_z distribution section rewritten to a single looped results='asis' chunk (config list of views x peptide sets) instead of 8 hand-written chunks (v0.7.0)
* fixed "Duplicate chunk label 'setup'" parse error in the focused reports: shared setup.Rmd had a fenced r-chunk example inside its leading HTML comment (knitr parses chunks even in comments -> recursive re-include); comment is now prose + regression guard test (v0.7.1)
* focused reports gained PepAllSource param (cached / rda / build) so each can load the default cache, load an explicit .rda (PepAllFile), or self-build from raw results via build\_pep\_all(); default = cached = prior behavior (v0.8.0)
* added simulated FragPipe data (inst/extdata/sim\_fragpipe\_dda, moved out of data/) + test-sim-fragpipe.R: build\_pep\_all assertion + first end-to-end render test of a focused report (v0.8.0)
* unified parser using dictionaries with option to enter a custom entry from other software: dictionary-driven parse\_unified() + read\_custom\_batch() + annotate\_unified() + read\_dictionary()/get\_dictionary\_template(), wired into build\_pep\_all(software="custom", dictionary=...); YAML dictionaries in inst/extdata/dictionaries (custom\_template + fragpipe/diann/peaks reference); built-in loaders untouched; test-parse-unified.R round-trips against the FragPipe loader (v0.9.0)
* immunopeptidomics sample quality score (HowDirty-inspired, inverted): R/quality-score.R (score\_sample\_quality + qc\_metrics\_by\_sample + anchor\_information\_content + score\_curve + quality\_thresholds\_default + calibrate\_thresholds\_from\_qc), plot\_quality\_heatmap/plot\_quality\_composite, focused report 05\_quality\_score; thresholds from literature defaults or in-experiment QC samples (annotation QC column, ThresholdMode=qc\_relative); non-tryptic K/R signal split into low-weight diagnostic + out-of-window scored metric; no external data/deps; test-quality-score.R covers score\_curve/anchor\_information\_content (v0.10.0)
* cross-class MHC1<->MHC2 contamination metric: frac\_cross\_class (fraction of peptides in the other class's length window outside the current one; .cross\_class\_range helper; lower\_better, low weight, NA for custom windows) + plot\_cross\_class\_length per-sample length histogram with cross-class region highlighted, wired into qc\_metrics\_by\_sample/quality\_thresholds\_default and the 05\_quality\_score report (v0.11.0)
* Average +/- sd per BioReplicate: new section in 01\_id\_counts mirroring per-Condition; plot\_count\_mean\_sd() gained group\_var arg (default "Condition", pass "BioReplicate") (v0.12.0)
* "Selected peptides" report headers now show the active length window (e.g. "(8 to 13 AAs)") from shortpep\_range across the focused templates (v0.12.0)
* renamed "Proteins" ID-level headers/labels to "Parent proteins" in 01\_id\_counts/02\_overlaps (display only; data keys + plot axis labels unchanged; counts\_labels display vector added alongside counts\_levels) (v0.12.0)
* Proportion by length pulled into its own 2nd-level section in 01\_id\_counts with Condition/BioReplicate/Sample tabs (was nested under Total-by-Condition/Sample) (v0.12.0)
* Overlap intra-Condition: added a percentage variant section in 02\_overlaps; plot\_overlap\_intra\_condition() gained value arg ("count" default / "percent") (v0.12.0)
* improve the readme: made Step 2 a bare annotation skeleton (no sample\_list.xlsx needed; removed the duplicated get\_annot\_sampleid that also lived in Step 3, now the single optional mention); added a note under Step 3 that the annotation table controls inclusion (only listed samples are read/reported) and ordering (factor levels = CSV row order); added an "Edit these for your run" callout listing the must-change params before the Step 5 render example
* pseudochromatogram color by density: plot\_pseudochromatogram() now fills RT bars by peptide Count (continuous viridis gradient) instead of per-Condition colour, keeping the facet-per-Condition layout (v0.13.0)
* pseudomobilogram: new plot\_pseudomobilogram() (count vs invk0/1k0, configurable binwidth, default 0.2, bars coloured by count, faceted by Condition); wired into 03\_lcms\_qc view config (new "Pseudomobilograms" tab) and 00\_mhc\_report distribution section (all/selected) (v0.13.0)
* Peptides identified per charge, add black lines on bars: plot\_charge\_proportions() geom\_bar gained color = "black" (v0.13.0)
* plot unclustered motifs from 7 to 25: motif length window extended to 7–25 AAs (was capped at 24); section retitled "Peptide motifs (7 to 25 AAs)" in 01\_id\_counts and 00\_mhc\_report (v0.13.0)
* add subset suffix to all the results: shared setup.Rmd (and the two 00\_\* reports) derive result\_prefix (= Subset, NULL when unset), passed to every write.csv\_rawr()/write\_input\_params() and prepended to seq\_by\_condition.xlsx, so result filenames carry the subset (e.g. dda\_all\_pep\_all.csv); input\_params combines subset + report name to stay collision-free (v0.13.0)
* bigger font
* mouse MHC1 option (7 to 11 AAs): new MHCclass value `MHC1_mouse`; windows/palettes moved to R/report-helpers.R (mhc\_length\_window / mhc\_class\_palette / mhc\_classes), replacing 3 duplicated lists in the skeletons + the copy inside .cross\_class\_range(); quality score follows (frac\_9mer counts 8+9-mers with the "8/9-mer fraction" label and higher cut-offs, anchor scored on the dominant of the two, cross-class window from the 7-11 window) (v0.15.0)
* safeguard in get\_annot\_sampleid: warns when nothing matched (showing example Source\_file values from both sides) and when only some rows matched (naming the dropped ones); new keep\_all = TRUE argument left-joins so no annotation row is lost (v0.15.0)
* fixed combn(conditions, 2) aborting every report with a single Condition: new exported condition\_pairs() (empty list for 1 Condition, self = TRUE for the overlap-matrix diagonal) used by the shared setup + 00\_mhc\_report/00\_mhc\_upsets/02\_overlaps; guarded by an end-to-end single-Condition render test (v0.15.0)
* test mode for combined exports: files are read in full and reduced to ~100 rows PER RUN (subsample\_testmode() in R/utils-loaders.R, run column auto-detected from Run/Spectrum) instead of the first 100 lines of the file, so every run/Condition/replicate survives; wrong "first 50 lines" warning fixed (v0.15.0)
* safeguard when all area = 0: get\_mat\_log2area() returns a 0 x n matrix with a warning instead of erroring in select(all\_of()), and the correlation chunks of 04\_quant/00\_mhc\_report test for the empty/all-NA case before calling cor() (which errors with 'x' is empty) and before computing the colour limits (v0.15.0)
* homogenized sample annotation tables across software: canonical `Sample_folder` column accepted by read\_annot() and mirrored into Sample\_fp (verbatim) / Sample\_peaks (PEAKS-normalized) so the loaders are untouched and legacy CSVs still load; get\_annot\_fragpipe()/get\_annot\_diann() emit Sample\_folder and PEAKS gained get\_annot\_peaks() (v0.15.0)
* advanced statistics / quantification report: new `06_quant_stats` template + `R/quant-stats.R` engine (build\_quant\_matrix, filter\_quant, normalize\_quant, impute\_quant, test\_differential, test\_detection, combine\_quant\_results, summarise\_significant, permanova\_condition) comparing peptide Area between Conditions with limma moderated t (Welch t fallback; limma in Suggests) + Fisher presence/absence track for condition-exclusive ligands; includes data completeness plots, normalization diagnostics, dynamic range, PCA, heatmaps with and without clustering, volcano/MA/p-value plots and significance summaries, plus an in-report "Methods & justification" section (v0.14.0)
* data completeness plots: plot\_completeness() (per unit / per feature) + plot\_missing\_heatmap() presence-absence map, in 06\_quant\_stats (v0.14.0)
* quantitative report heatmap with and without clustering, dynamic range, volcano plots: plot\_quant\_heatmap(cluster = TRUE/FALSE), plot\_dynamic\_range(), plot\_volcano()/plot\_ma(), all in 06\_quant\_stats (v0.14.0)
* fixed run\_howmahico\_report("05\_quality\_score") being unreachable (template documented but missing from the match.arg choices); 05 and 06 registered + regression guard test that every shipped template dir is offered (v0.14.0)
* peptide physicochemical properties report: new `07_pepchem` template + `R/pepchem.R` engine (peptide\_properties, pepchem\_properties, aa\_composition, aa\_position\_frequency, pepchem\_by\_sample, summarise\_pepchem, aggregate\_pepchem, cliffs\_delta, compare\_pepchem, compare\_aa\_frequency) comparing amino-acid composition (overall / per sample / enrichment vs. the pooled composition), per-position residue frequency (dominant length + N-/C-terminal profile across all lengths) and per-peptide descriptors (GRAVY, pI, charge, MW, Boman, hydrophobic moment, instability/aliphatic index, AA class fractions) between Conditions. Descriptors are summarised per SAMPLE and then tested across samples (Kruskal-Wallis + pairwise Wilcoxon, BH, MedianDiff + Cliff's delta), with a pooled peptide-level track reported alongside as explicitly descriptive; new plots plot\_aa\_composition / plot\_aa\_position\_heatmap / plot\_property\_distribution / plot\_property\_sample\_summary / plot\_property\_effectsize; new dependency Peptides (CRAN, Rcpp only) in Imports, justified as the canonical GRAVY implementation. Position-within-the-protein moved to standby (v0.16.0)
* the provider in the templates context is now the optional `Provider` param: all 9 templates declare it and render the attribution through the new exported provider\_line() (R/report-helpers.R), which falls back to a generic sentence naming no organisation when empty; removed the hardcoded "Immunopeptidomics Platform (IPP)" text, the personal @dkfz.de contact block and the "Code author: DGZ" lines, and gave 00\_mhc\_upsets the description + Code version lines it lacked. Guarded by a test that every template declares the common params and that none hardcodes an organisation/author/contact, plus a render test checking the header in both directions (v0.17.0)
* runnable R code as a guide through: new inst/scripts/howmahico\_pipeline.R + exported get\_pipeline\_script() (sibling of get\_report\_template()/get\_dictionary\_template()), a commented walkthrough from raw search output to rendered reports that renders via run\_howmahico\_report() rather than opening a template; starts in demo mode (RUN\_DEMO = TRUE) running end-to-end against the shipped sim\_fragpipe\_dda dataset with no user data — verified: 7 focused reports in ~1 min. Plus the package's first vignette (vignettes/howmahico.Rmd, VignetteBuilder: knitr), which gives the pkgdown site an Articles tab (v0.17.0)
* more detailed instructions in the readme: FIXED the headline run\_howmahico\_report() example, which passed a Title param no template declares — rmarkdown errors on undeclared params, so it failed on copy-paste; added a Quickstart, a table of what each of the 9 reports produces, a full parameter reference (common + focused-only + the 05/06/07 sets), an output section (always-written vs CsvSave/PlotsSave tiers) and a troubleshooting table; corrected stale claims (07\_pepchem missing everywhere, "mid-conversion on dev", "~40 functions" vs 118 exports, the numbered project folders shown as repo contents, RStudio listed as a requirement instead of pandoc) (v0.17.0)
* export a prot_all report with information condensed at the protein level: new `R/prot-all.R` engine (build\_prot\_all -> one row per protein x Sample with ligand counts, unique-peptide counts from the previously unused Is\_Unique/Proteotypic flags, and Area summed on the LINEAR scale; summarise\_prot\_all, top\_source\_proteins, expand\_mapped\_proteins, prot\_engine\_columns, diann\_protein\_columns) + the `08_prot_all` report (source proteins per sample, ligands-per-protein distribution, top source proteins, detection breadth, protein-level intensity) with 5 new plots. Protein key is a param (ProteinFeature: ProteinFirst default / GeneFirst / Accession) and MultiMapping (leading default / all) chooses how a ligand mapping to several proteins is counted. **Engine-reported protein data is carried through when available** (DIA-NN PG.*/Genes.* quantities + q-values, already in pep\_all but unused), by a unique-within-group rule that returns NA rather than averaging; plot\_ligand\_vs\_protein\_quant compares it against summed ligand Area. parse\_diann's protein-column select moved to any\_of(diann\_protein\_columns()) so either DIA-NN naming generation (PG.Quantity vs PG.Abundance) survives instead of being dropped or aborting the parse. Descriptive only; no length normalisation (needs the FASTA, in standby). Also fixed: docs/ was missing from .Rbuildignore (R CMD check note after building the pkgdown site locally) (v0.18.0)
* for PTM plots, translate unimod code into modification name: new R/ptm.R with ptm\_reference() (curated UniMod accession / name / monoisotopic delta-mass table, ordered by commonness so the first match within tolerance wins on mass-degenerate pairs like Glu->pyro-Glu / Dehydrated) + translate\_ptm() (vectorised over the unique tokens; payload read from inside ()/[], dispatched on UniMod-accession vs signed decimal, unmatched tokens returned UNCHANGED rather than NA), wired into plot\_ptm\_heatmap() as translate = TRUE (+ reference pass-through) applied where the tokens are already split so both the count and proportion branches inherit it. Both dialects are handled because a UniMod-only translation would be a silent no-op on the default FragPipe data. Display-time only — pep\_all$PTM stays raw. Also fixed the wrong note in 00\_mhc\_report/01\_id\_counts ("Fragpipe and DIA-NN ... UniMode PTM codes"; it is FragPipe and PEAKS that write delta masses). New test-ptm.R covers all three dialects, the Acetyl/Trimethyl tolerance boundary, PEAKS' 2-decimal rounding, pass-through of unknown/NA/"" and the reference-order rule (v0.19.0)
* readme: add a glossary of the column headers in pep\_all + finish the in-report glossary: new pep\_all\_glossary() (R/report-helpers.R, 30 rows, including the misreadable parts — DIA-NN dummy ppm, computed-not-observed Mass, Accession-as-protein-group, engine-specific Score) feeding both the new shared child inst/rmarkdown/shared/glossary.Rmd (included by all ten templates before their Session & provenance footer; counting units explained with the length window interpolated from shortpep\_range) and the README's new Glossary section. Replaces 00\_mhc\_report's hardcoded prose, which claimed a 12-20 AA MHC-II window (the real one is 12-25) and named 3\_results/4\_figures regardless of the run's params. Guarded by two tests: every validate\_pep\_all() required column is documented, and so is every column the reports consume from a real build\_pep\_all() run on the sim data (v0.19.0)
* class-2 motif metric + DIA identification QC: new frac\_nested\_core metric (internal .nested\_core\_fraction(): fraction of in-window ligands sharing a 9-mer - the MHC-II binding-core length - with another ligand of the same sample; one (k-mer, sequence) pair at most so internal repeats cannot make a sequence nested with itself; NA below two assessable sequences). quality\_thresholds\_default("MHC2") promotes it to the anchor metric's weight (3, label "Nested-core families") because anchor\_information/frac\_9mer are both NA for class II; weight-0 diagnostic for MHC1/MHC1\_mouse. Metric keys identical across classes. Plus median\_abs\_rt\_error / median\_abs\_im\_error (internal .median\_abs\_delta()): DIA-NN's Precursor.Mz is the LIBRARY value and report.tsv has no observed precursor m/z, so the dummy ppm cannot be repaired - its Predicted.RT/Predicted.IM (already in pep\_all, unused) give the DIA analogue instead, NA for FragPipe/PEAKS and NA when every difference is 0. Both substitutions documented in 05\_quality\_score's Methods; tests cover the maths, the per-class promotion, the guards, and that every scored threshold row exists in the metrics table (v0.20.0)
* InteractivePlots (TRUE/FALSE) toggle to render compatible plots via ggplotly: new param on all ten templates; ggprint\_rawr() gained an interactive arg returning plotly::ggplotly() (caller-frame name resolution and the not-generated guard kept), the shared setup + the two 00\_* templates derive interactive\_plots <- isTRUE(params$InteractivePlots), and the 34 call sites that print from ORDINARY chunks pass it. Plots inside results='asis' tabset loops stay static on purpose (a widget printed from such a loop silently renders EMPTY without a tagList/knit\_print dance - the same reason those loops use kable not DT), guarded by a test that walks every skeleton's chunks. Unconvertible classes (ggpubr composites, seqlogos, objects already widgets) are returned unchanged, so asking for interactivity cannot break a report. 05\_quality\_score's three bare prints and the four ggplotly() calls on the correlation matrices now route through the same helper, the latter with interactive = TRUE hardcoded to keep their behaviour. Verified by rendering 05\_quality\_score with the toggle on AND off and asserting the widget containers + embedded plotly library are present in one and absent in the other (v0.21.0)
* check/add functionality for peaks Xpro: FOUND BROKEN and fixed - read\_peaks\_batch() filtered the export FOLDERS by annotation$Sample\_peaks, which is the PER-SAMPLE key (a PEAKS export folder holds several samples as Area#<sample> columns, and those suffixes are what annotate\_peaks() joins on), so an annotation that could be joined matched no folder at all (empty read -> "object 'Accession' not found" in parse\_peaks()) while one naming the folder gave a silent 0-row join; folder selection now uses Sample\_folder (falling back to Sample\_peaks for one-folder-per-sample layouts) and both halves of the trap error out naming the two keys. Second bug: read\_peaks(filedir = getwd(), folder\_peaks\_db = <indexed path>) pasted an ABSOLUTE FolderData behind the working directory (the reports document absolute paths, and system.file() returns them) - now split with dirname()/basename(). Both were invisible because PEAKS had no end-to-end fixture, so v0.22.0 ships inst/extdata/sim\_peaks\_xpro/ (462 simulated peptides x 6 samples in real PEAKS shape: one export folder, -10lgP, 1/k0 Range, Area#<sample>, PEAKS-style oxidation) + tests. get\_annot\_peaks() documents that one row per folder is not one row per sample. Remaining for DGZ: run it on a real PEAKS 11/Xpro export (v0.22.0)
* corrected the v0.19.0 PTM documentation: PEAKS writes the modification NAME in its PTM column ("Oxidation (M)") and keeps the delta mass in the peptide string - it is FragPipe (delta mass) and DIA-NN (UniMod) that need translating. translate\_ptm() already passed names through unchanged; the docs, the two report notes and the test comments were wrong, and a test now pins the pass-through so a PEAKS name cannot be mangled into a mass match (v0.22.0)
* abstract wording (example/abstract\_eupa2026\_v3.md): motif clarity now attributed to anchor information content for class 1 and nested binding cores for class 2, and the identification-QC sentence distinguishes DDA mass error from DIA retention-time/ion-mobility calibration error (v0.22.0)
* resolve the license conflict: relicensed MIT -> GPL (>= 2). Auditing every dependency found more than Peptides/limma: Peptides, gplots and ggcorrplot are GPL-2 ONLY, ggupset is GPL-3, limma/ggpubr GPL (>= 2). Plain GPL-3 (the option on the table) would itself have clashed with the GPL-2-only three, so the package now uses R's own terms, GPL-2 or later, compatible with each. LICENSE.md = GPL-2 text (usethis::use_gpl_license(2, include_future = TRUE)), MIT LICENSE stub removed, README License section explains the choice; also closes the standby "license discrepancies" item (v0.23.0)
* cross-experiment comparison: new R/compare-runs.R with compare_runs() (stacks the <Subset>_scores.csv tables of N 05_quality_score renders - csv paths, results folders or score data frames; labels runs from the companion *_05_quality_score_input_params.csv as "SampleSet | Subset" and attaches MHCclass/ThresholdMode/render_timestamp/package_version; input or timestamp order; column union; WARNS on mixed MHCclass/ThresholdMode since composites are then not comparable) + summarise_runs() (per run x metric n/median/IQR + Pass/Warning/Fail counts) + plot_run_trend() (panel per metric, runs on x, box or median-trend line, QC samples as triangles, optional color_by). The 05 score csv gained a Condition column. No report template for it yet - the function + plot make the abstract's sentence true (v0.24.0)
* general-overview report for the biologically focused user: new `09_overview` template, one page for the biologist - at-a-glance table (samples, Conditions, unique peptides all/in-window, source proteins, median score, Pass/Warning/Fail, red-flag counts), ligands per sample in/out of the length window, length histogram, composite quality score, a plain-language Red flags section and a "where to go next" table pointing at 01-08. New exported overview_red_flags() (Fail/Warning composite; any SCORED dimension past amber, worded by its label, High at sub-score 0; sample < 0.5 x median unique peptides; Condition with a single BioReplicate) and qc_samples_from_annotation() (the QCColumn lookup 05 inlined, now shared by 05 and 09). Writes <Subset>_red_flags.csv. Render test in test-sim-fragpipe.R + unit tests in test-overview.R (v0.25.0)
* demonstration dataset, simulated part: demo/eupa2026_demo.R renders the simulated class-1/class-2 FragPipe datasets (all reports) and simulates with MaHiCoInSilico a tryptic-contamination titration (0-100 %, LOD 1e6) and a class-1 + 25 % class-2 mix, then builds the poster panels with compare_runs()/plot_run_trend() and writes demo_summary.md. The composite falls monotonically 90.7 -> 35 along the titration (Fail only for the pure proteome) and cross-class rises to 0.28 in the mix. Running it found two bugs, both fixed: frac_charge_1_2 was MHC-I-only (class II is mostly 2+ to 4+, so genuine class-II scored 0 there; now class-aware, class 2 composite 55 -> 70), and charges were read from factor LEVEL CODES (as.numeric on the "+ n" factor) so with no 1+ present 2+ read as 1+, in get_charge_group() and the PEAKS PeptideID; now .charge_number(). The real dataset stays open (v0.26.0)
* report 6, clustered heatmap did not show the clusters: plot\_quant\_heatmap(cluster = TRUE) only reordered the tiles. It now draws the unit dendrogram over a Condition colour bar, the feature dendrogram on the left, and cuts the features into n\_clusters groups (new HeatmapClusters param, default 4) separated by white lines and labelled C1 (top) onwards; the assignment comes back as attr(p, "clusters") and is exported as heatmap\_clusters.csv with CsvSave. The clustered view is a ggarrange composite (static even with InteractivePlots); the unclustered view is unchanged and still plotly-convertible. No new dependency (dendrogram segments from hclust by the internal .dendro\_segments()) (v0.26.1)
* report 7: integer-valued descriptors (Length) are drawn as histograms (one bar per value, each Condition summing to 1) instead of a kernel density; continuous descriptors keep the density. New exported pepchem\_glossary() (meaning, how to read it for MHC ligands, how it is computed, for every peptide\_properties() column; frac\_* rows generated from the residue classes actually used) rendered by the shared glossary child in 07\_pepchem only (v0.26.1)
