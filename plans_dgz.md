# plans\_dgz.md - HowMaHiCo

## What this is

Plans by DGZ to improve HowMaHiCo.

Instructions: when prompted, you can read this file and provide a plan to do the pending tasks in "to do". When something is done, move it to the end of "Done". Do not consider the points in "In standby", until they are moved to "to do"

## To do

### Road to the EuPA 2026 abstract (example/abstract_eupa2026_v3.md)

Gap analysis of the package (v0.18.0) against the submitted abstract text, in
priority order. Tier A must be true before the abstract is submitted, tier B
before the meeting, tier C is wording-vs-code mismatches that can be closed
either by implementing or by re-wording the abstract.

**Tier A — blocking, the abstract makes these promises explicitly**

* make the GitHub repo public. The abstract prints
  https://github.com/DavidGZ1/HowMaHiCo, which currently 404s (`gh repo view`:
  `isPrivate: true`), and GitHub Pages will not serve `gh-pages` from a private
  repo, so https://davidgz1.github.io/HowMaHiCo/ is dead too. While there: fill
  in the empty repo description + homepage field, add a CITATION.cff, and mint a
  Zenodo DOI so the poster has something citable.
* resolve the license conflict (was already in standby, now blocking "open-source
  R package"): DESCRIPTION says MIT but `Imports: Peptides` is GPL-2 and
  `Suggests: limma` is GPL >= 2. Pick one — relicense to GPL-3, or drop
  `Peptides` to Suggests / reimplement the two descriptors actually used (GRAVY,
  pI; ~30 lines) and keep MIT.
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
* general-overview report for the biologically focused user (the
  advanced-plans "Simple summary of HowMaHiCo ala HowDirty" item). The abstract
  promises "a general-overview report for biologically focused users and another
  for deeper evaluation by the LC-MS expert"; what exists is 8 thematic slices
  plus `00_mhc_report`, a ~1300-line all-in-one that is the opposite of an
  overview (and the legacy report where the Overlap intra-Condition bug is still
  uncorrected). `03_lcms_qc` already covers the expert half. Scope: one page —
  counts, length-window fidelity, quality score, red flags.
* cross-experiment comparison, claimed in the Conclusions but not implemented:
  one render = one subset, and nothing stacks the per-sample score CSVs that
  `05_quality_score` writes into a trend view. Add a `compare_runs()` reading N
  score tables (+ a longitudinal/trend plot per metric) so the sentence becomes
  true.

**Tier C — code does not match the wording; implement or re-word**

* "interactive HTML" is overstated. Interactivity today = tabsets + floating TOC,
  DT tables in 06/07/08, and exactly two `ggplotly()` calls (00_mhc_report
  L996/L1034, 04_quant L118/L156); every other plot is a static raster. Either
  land the standby `InteractivePlots` toggle for the plots that are *not* inside
  `results='asis'` loops (correlation, PCA, volcano, dynamic range, completeness
  are the easy ones) or soften the abstract to "self-contained, navigable HTML".
* class 2 in the title vs. the quality score: for `MHCclass = "MHC2"`,
  `qc_metrics_by_sample()` returns NA for `frac_9mer` and `anchor_information`
  (no fixed-length anchor model), so they drop out of the composite — the "motif
  clarity" the Results paragraph names is not delivered for class 2, although
  the title claims "class 1 and class 2". Either add a register-free class-2
  motif metric (positional entropy over a sliding 9-mer core) or qualify the
  sentence.
* mass error is absent for DIA-NN (`ppm` is a hardcoded 0 dummy, documented and
  dropped from the score), so "identification QC such as score and mass error"
  is hollow for the DIA audience. Derivable from `Precursor.Mz` vs the
  theoretical m/z of sequence + PTM if it is worth making real.
* **DONE (v0.19.0)** — PTM profiles are unreadable as shipped: UniMod codes for
  DIA-NN, bare delta masses for FragPipe/PEAKS. `R/ptm.R` (`ptm_reference()` +
  `translate_ptm()`) now translates both forms, wired into
  `plot_ptm_heatmap(translate = TRUE)`.
* verify PEAKS Xpro before it appears in print: "check/add functionality for
  peaks Xpro" is still open on the DGZ list, and PEAKS is the only engine with
  no shipped example dataset (fixtures only).
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
* check and deal with license discrepancies between howmahico, peptides, limma



### to be done by DGZ

* Check and complete glosary
* check/add functionality for peaks Xpro
* 2do by me, check Overlap intra-Condition seems to be showing peptides in sequences, and sequences+proteins in proteins - corrected in the individual reports, but not in the legacy main report
* reorder plots in a way that makes more sense
* manual checking and re-writing text by me
* check way sample\_annotation is named in the reports, should be the same as in the example
* check which column is used as quant for each software
* get\_report\_template change param order, start with template then file



## advanced plans

* include MaHiCoBench dataset for LFQbench-style plots
* Dataset: use the JY hla1 and hla2 from Annica and Julian
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
