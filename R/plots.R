#' Peptide length distribution: boxplot + count histogram
#'
#' @param input A `pep_all`-shaped data frame with a `Length` column.
#' @param title Plot title.
#' @param ylimits,xlimits Optional length-2 numeric vectors overriding the
#'   automatically derived axis limits (count-based `ylimits`, rounded up to
#'   the nearest 1000; length-based `xlimits`, rounded up to the nearest 10).
#'
#' @return A `ggpubr`-arranged figure (boxplot above a count histogram) with
#'   the title annotated above.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' plot_peplength(pep_all, title = "All peptides")
#' }
plot_peplength <- function(input, title, ylimits = NULL, xlimits = NULL){
  max_count <- input %>% dplyr::group_by(Length) %>% dplyr::count() %>% max()
  max_x <- max(input$Length)
  if(is.null(ylimits)){
    ylimits <- c(0, ceiling(max_count / 1000) * 1000)
  }else{
    ylimits <- ylimits
  }
  if(is.null(xlimits)){
    xlimits <- c(0, ceiling(max_x / 10) * 10)
  }else{
    xlimits <- xlimits
  }

  p_length_bp <-
    input %>%
    ggplot2::ggplot(ggplot2::aes(x = Length)) +
    ggplot2::geom_boxplot(color = "#39568CFF", outlier.size = 0.5) +
    ggplot2::stat_boxplot(geom = 'errorbar', width = 0.5) +
    ggpubr::theme_pubr() +
    ggpubr::clean_theme() +
    ggplot2::theme(strip.background = ggplot2::element_blank(), strip.text = ggplot2::element_text(face = "bold", size = 2)) +
    ggplot2::scale_x_continuous(limits = xlimits, breaks = seq(0, xlimits[2], by = 1))
  p_length_hist <-
    input %>%
    ggplot2::ggplot(ggplot2::aes(x = Length)) +
    ggplot2::geom_histogram(fill = "#39568CFF", binwidth = 1) +
    ggplot2::scale_y_continuous(limits = ylimits, breaks = seq(0, ylimits[2], by = 1000)) +
    ggplot2::scale_x_continuous(limits = xlimits, breaks = seq(0, xlimits[2], by = 3)) +
    ggplot2::ylab("Peptide count") +
    ggplot2::xlab("Peptide length") +
    theme_rawr()
  ggpubr::ggarrange(p_length_bp, p_length_hist, nrow = 2, heights = c(0.15, 0.85), align = "v") %>%
    ggpubr::annotate_figure(top = ggpubr::text_grob(title, face = "bold", size = 8))
}

#' Peptide length distribution: boxplot + density histogram
#'
#' Density-axis counterpart to [plot_peplength()] — same boxplot-over-histogram
#' layout, but the lower panel shows `..density..` rather than raw counts (and
#' so has no `ylimits`).
#'
#' @param input A `pep_all`-shaped data frame with a `Length` column.
#' @param title Plot title.
#' @param ylimits,xlimits Optional length-2 numeric vectors overriding the
#'   automatically derived axis limits. `ylimits` is currently unused (kept for
#'   signature parity with [plot_peplength()]).
#'
#' @return A `ggpubr`-arranged figure (boxplot above a density histogram) with
#'   the title annotated above.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' plot_peplength_dens(pep_all, title = "All peptides")
#' }
plot_peplength_dens <- function(input, title, ylimits = NULL, xlimits = NULL){
  max_count <- input %>% dplyr::group_by(Length) %>% dplyr::count() %>% max()
  max_x <- max(input$Length)
  if(is.null(ylimits)){
    ylimits <- c(0, ceiling(max_count / 1000) * 1000)
  }else{
    ylimits <- ylimits
  }
  if(is.null(xlimits)){
    xlimits <- c(0, ceiling(max_x / 10) * 10)
  }else{
    xlimits <- xlimits
  }

  p_length_bp <-
    input %>%
    ggplot2::ggplot(ggplot2::aes(x = Length)) +
    ggplot2::geom_boxplot(color = "#39568CFF", outlier.size = 0.5) +
    ggplot2::stat_boxplot(geom = 'errorbar', width = 0.5) +
    ggpubr::theme_pubr() +
    ggpubr::clean_theme() +
    ggplot2::theme(strip.background = ggplot2::element_blank(), strip.text = ggplot2::element_text(face = "bold", size = 2)) +
    ggplot2::scale_x_continuous(limits = xlimits, breaks = seq(0, xlimits[2], by = 1))
  p_length_hist <-
    input %>%
    ggplot2::ggplot(ggplot2::aes(x = Length, y = ..density..)) +
    ggplot2::geom_histogram(fill = "#39568CFF", binwidth = 1) +
    ggplot2::scale_x_continuous(limits = xlimits, breaks = seq(0, xlimits[2], by = 3)) +
    ggplot2::xlab("Peptide length") +
    theme_rawr()
  ggpubr::ggarrange(p_length_bp, p_length_hist, nrow = 2, heights = c(0.15, 0.85), align = "v") %>%
    ggpubr::annotate_figure(top = ggpubr::text_grob(title, face = "bold", size = 8))
}

#' Peptide mass distribution: boxplot + density histogram with apex annotation
#'
#' Finds the distribution apex (mode of the kernel density estimate, per
#' <http://ianmadd.github.io/pages/PeakDensityDistribution.html>) and annotates
#' it on the histogram panel.
#'
#' @param input A `pep_all`-shaped data frame with a `Mass` column.
#' @param title Plot title.
#' @param xlimits Optional length-2 numeric vector overriding the x-axis limits
#'   on both panels.
#'
#' @return A `ggpubr`-arranged figure (boxplot above a density histogram with
#'   an "Apex = ..." annotation) with the title annotated above.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' plot_pepmass(pep_all, title = "All peptides")
#' }
plot_pepmass <- function(input, title, xlimits = NULL){
  ## Finding apex based on http://ianmadd.github.io/pages/PeakDensityDistribution.html
  max_dens_x <- density(input$Mass)$x[which.max(density(input$Mass)$y)] # Find distribution apex
  max_dens_y <- density(input$Mass)$y[which.max(density(input$Mass)$y)] # Find distribution apex

  p_mass_bp <-
    input %>%
    ggplot2::ggplot(ggplot2::aes(x = Mass)) +
    ggplot2::geom_boxplot(color = "#39568CFF", outlier.size = 0.5) +
    ggplot2::stat_boxplot(geom = 'errorbar', width = 0.5) +
    ggpubr::theme_pubr() +
    ggpubr::clean_theme() +
    ggplot2::theme(strip.background = ggplot2::element_blank(), strip.text = ggplot2::element_text(face = "bold"))

  p_mass_hist <-
    input %>%
    ggplot2::ggplot(ggplot2::aes(x = Mass)) +
    ggplot2::geom_histogram(ggplot2::aes(y = ..density..), fill = "#39568CFF", color = "white",
                            binwidth = 50, size = 0.1) +
    ggplot2::geom_density(color = "black", size = 0.5, alpha = 0.5) +
    ggplot2::annotate("text", color = "black", size = 3,
                      x = max_dens_x * 1.1, hjust = 0, y = max_dens_y * 1.1,
                      label = paste0("Apex = ", round(max_dens_x, 1))) +
    ggplot2::ylab("Density") +
    ggplot2::xlab("Peptide Mass (Da)") +
    theme_rawr()
  if(!is.null(xlimits)){
    p_mass_bp <- p_mass_bp + ggplot2::scale_x_continuous(limits = xlimits)
    p_mass_hist <- p_mass_hist + ggplot2::scale_x_continuous(limits = xlimits)
  }


  ggpubr::ggarrange(p_mass_bp, p_mass_hist, nrow = 2, heights = c(0.15, 0.85), align = "v") %>%
    ggpubr::annotate_figure(top = ggpubr::text_grob(title, face = "bold", size = 10))
}

#' Peptide m/z distribution: boxplot + density histogram with apex annotation
#'
#' `m_z` counterpart to [plot_pepmass()] — identical layout and apex-finding
#' logic, applied to the `m_z` column instead of `Mass`.
#'
#' @param input A `pep_all`-shaped data frame with an `m_z` column.
#' @param title Plot title.
#' @param xlimits Optional length-2 numeric vector overriding the x-axis limits
#'   on both panels.
#'
#' @return A `ggpubr`-arranged figure (boxplot above a density histogram with
#'   an "Apex = ..." annotation) with the title annotated above.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' plot_pepmz(pep_all, title = "All peptides")
#' }
plot_pepmz <- function(input, title, xlimits = NULL){
  ## Finding apex based on http://ianmadd.github.io/pages/PeakDensityDistribution.html
  max_dens_x <- density(input$m_z)$x[which.max(density(input$m_z)$y)] # Find distribution apex
  max_dens_y <- density(input$m_z)$y[which.max(density(input$m_z)$y)] # Find distribution apex


  p_mass_bp <-
    input %>%
    ggplot2::ggplot(ggplot2::aes(x = m_z)) +
    ggplot2::geom_boxplot(color = "#39568CFF", outlier.size = 0.5) +
    ggplot2::stat_boxplot(geom = 'errorbar', width = 0.5) +
    ggpubr::theme_pubr() +
    ggpubr::clean_theme() +
    ggplot2::theme(strip.background = ggplot2::element_blank(), strip.text = ggplot2::element_text(face = "bold"))
  p_mass_hist <-
    input %>%
    ggplot2::ggplot(ggplot2::aes(x = m_z)) +
    ggplot2::geom_histogram(ggplot2::aes(y = ..density..), fill = "#39568CFF", color = "white",
                            binwidth = 50, size = 0.1) +
    ggplot2::geom_density(color = "black", size = 0.5, alpha = 0.5) +
    ggplot2::annotate("text", color = "black", size = 3,
                      x = max_dens_x * 1.1, hjust = 0.5, y = max_dens_y * 1.1,
                      label = paste0("Apex = ", round(max_dens_x, 1))) +
    ggplot2::ylab("Density") +
    ggplot2::xlab("Peptide m/z") +
    theme_rawr()

  if(!is.null(xlimits)){
    p_mass_bp <- p_mass_bp + ggplot2::scale_x_continuous(limits = xlimits)
    p_mass_hist <- p_mass_hist + ggplot2::scale_x_continuous(limits = xlimits)
  }

  ggpubr::ggarrange(p_mass_bp, p_mass_hist, nrow = 2, heights = c(0.15, 0.85), align = "v") %>%
    ggpubr::annotate_figure(top = ggpubr::text_grob(title, face = "bold", size = 10))
}

#' Stacked bar chart of total ID counts per Condition, split by length range
#'
#' Plots `n_<level>` (`level` one of `"Peptides"`/`"Sequences"`/`"Proteins"`)
#' against `Condition`, filled by `Length_range`, with a `"Total=..."`
#' annotation above each bar reporting the `"All peptides"` row's count.
#'
#' The original report-inline version closed over three chunk-local globals
#' (`count_lim`, `counts_size_total`, `shortpep_range`); this migrated version
#' threads them through as explicit arguments — `lim_level` (the y-axis upper
#' limit looked up from `count_lim` by the caller) and `shortpep_range`
#' (defaulted to the standard 8-13 AA HLA-I window). The `counts_size_total`
#' closure reference is replaced by `df` itself, since every call site already
#' passes `counts_size_total` as `df` — these were always the same object.
#'
#' @param df A counts data frame with `Condition`, `Length_range`, and an
#'   `n_<level>` column (e.g. the output of `count_ids_condition_bylengthrange`-
#'   style summaries, including an `"All peptides"` total row per `Condition`).
#' @param level One of `"Peptides"`, `"Sequences"`, `"Proteins"` — selects the
#'   `n_<level>` column to plot and labels the y-axis.
#' @param lim_level Upper y-axis limit (e.g. looked up from a `count_lim`
#'   table by `Level`/`"Limit_total"`).
#' @param shortpep_range Length-2 vector `c(min, max)` used to label the
#'   `"others"` `Length_range` class as `"< min OR > max AAs"`.
#'
#' @return A `ggpubr` bar chart (`ggbarplot`) with per-bar count labels, a
#'   `"Total=..."` annotation, and a viridis fill scale.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' plot_bp_count_length(counts_size_total, "Peptides", lim_level = 50000, shortpep_range = c(8, 13))
#' }
plot_bp_count_length <- function(df, level, lim_level, shortpep_range = c(8, 13)){
  nlevel <- paste0("n_", level)
  df %>%
    dplyr::filter(Length_range != "All peptides") %>%
    droplevels() %>%
    dplyr::mutate(Length_range = dplyr::recode(Length_range,
                                                others = paste0("< ", shortpep_range[1], " OR > ", shortpep_range[2], " AAs"))) %>%
    ggpubr::ggbarplot(x = "Condition", y = nlevel, fill = "Length_range", group = "Length_range",
                      label = TRUE, alpha = 0.5,
                      lab.vjust = 1.5,
                      lab.nb.digits = 0, lab.size = 2.5) +
    ggplot2::geom_text(data = df %>% dplyr::filter(Length_range == "All peptides"),
                       ggplot2::aes(label = paste0("Total=\n", get(nlevel))),
                       nudge_y = 300 + lim_level / 10,
                       size = 2.5, alpha = 0.8,
                       parse = FALSE) +
    theme_rawr() +
    ggplot2::scale_y_continuous(limits = c(0, lim_level), breaks = seq(0, lim_level, 5000),
                                labels = scales::label_number(suffix = " k", scale = 1e-3)) +
    ggplot2::ylab(paste0("Nb ", level)) +
    ggplot2::xlab("Condition") +
    ggpubr::rotate_x_text(70) +
    ggplot2::labs(fill = "Length") +
    ggplot2::scale_fill_viridis_d(end = 1) +
    ggplot2::theme(legend.position = "right") +
    ggplot2::ggtitle(paste0("Unique ", level, " (total, comparing lengths)"))
}

#' Four-way Venn diagram of a grouped variable
#'
#' Splits `variable` by `group` (expects at most 4 groups — [ggvenn::ggvenn()]
#' is a 4-set Venn) and plots the overlap.
#'
#' @param input A data frame containing `variable` and `group` columns.
#' @param variable Name (string) of the column whose overlap is plotted, e.g.
#'   `"Sequence"`.
#' @param group Name (string) of the grouping column that defines the Venn
#'   sets, e.g. `"Condition"`.
#'
#' @return A `ggvenn` ggplot object.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' plot_venn4(pep_all, "Sequence", "Condition")
#' }
plot_venn4 <- function(input, variable, group){
  output <- input %>%
    dplyr::arrange(variable) %>%
    with(., split(get(variable), get(group))) %>%
    ggvenn::ggvenn(text_size = 3,
                   set_name_size = 3,
                   fill_alpha = 0.5,
                   fill_color = c("#440154FF", "#39568CFF", "#1F968BFF", "#FDE725FF"),
                   label_sep = "_") +
    ggplot2::theme(plot.margin = ggplot2::margin(0, 0, 0, 0, "cm"),
                   plot.title = ggplot2::element_text(size = 10, face = "bold"))
  return(output)
}

#' UpSet plot of overlap between groups for a given variable
#'
#' Counts, for each distinct value of `vars`, the set of `Compare` groups it
#' appears in, and renders an UpSet-style intersection plot via
#' [ggupset::scale_x_upset()], optionally annotated with absolute or
#' percentage intersection-size labels.
#'
#' @param df A `pep_all`-shaped data frame.
#' @param vars Column (tidy-evaluated) whose distinct values define the items
#'   being compared, e.g. `Sequence`.
#' @param n_intersections Maximum number of intersections to display.
#' @param Compare Name (string) of the column defining the groups compared
#'   (becomes the upset's set membership axis), e.g. `"Condition"`.
#' @param labels One of `"abs"` (absolute intersection counts, the default),
#'   `"perc"` (percentage of the total), or any other value to omit the
#'   per-bar count labels entirely. Defaults to `"perc"`.
#' @param lab.size Text size of the per-bar count/percentage labels.
#' @param plot.margin Plot margin, as unit.
#'
#' @return A ggplot2/`ggupset` object with an intersection-count bar chart and
#'   a caption reporting the total unique count and intersections shown.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' plot_upset(pep_all, Sequence, n_intersections = 10, Compare = "Condition")
#' }
plot_upset <- 
  function(df, vars, n_intersections = 10, Compare = "Condition", labels = "perc", lab.size = 2, 
             plot.margin = ggplot2:unit(c(0.2,0.2,0.2,0.2), "cm")){
  ## prepare data
  df[, "Compare"] <- df[, Compare]
  df_distinct <- df %>%
    dplyr::distinct(Compare, {{ vars }}, .keep_all = FALSE)
  df_distinct_total <- df_distinct %>% dplyr::pull({{ vars }}) %>% dplyr::n_distinct()
  ## plot
  upset_table <- df_distinct %>%
    dplyr::group_by({{ vars }}) %>%
    dplyr::summarize(Compare = list(as.character(Compare)), .groups = "drop")
  p_upset <- upset_table %>%
    ggplot2::ggplot(ggplot2::aes(x = Compare)) +
    ggplot2::geom_bar(fill = "#39568CFF") +
    ggupset::scale_x_upset(n_intersections = n_intersections) +
    ggplot2::scale_y_continuous(limits = ~range(.x*1.15, 0)) +
    ggplot2::theme_bw(base_size = 8) +
    ggplot2::theme(plot.margin = plot.margin) +
    ggupset::theme_combmatrix(
      combmatrix.panel.point.color.fill = "#39568CFF",
      combmatrix.panel.line.size = 0,
      combmatrix.label.make_space = TRUE) +
    ggplot2::labs(caption = paste0("Total unique = ", df_distinct_total, "    Max. intersections shown = ", n_intersections))
  if(labels == "perc"){
    p_upset <- p_upset +
      ggplot2::geom_text(stat = "count", ggplot2::aes(label = ggplot2::after_stat(paste0(round(100 * count / sum(count), 1), "%"))),
                         vjust = -0.2, size = lab.size)
  }
  if(labels == "abs"){
    p_upset <- p_upset +
      ggplot2::geom_text(stat = "count", ggplot2::aes(label = ggplot2::after_stat(count)),
                         vjust = -0.2, size = lab.size)
  }
  return(p_upset)
}

#' Batch of UpSet plots across several variables
#'
#' Runs [plot_upset()] once per entry of `vars`, restricting `df` to the
#' distinct `(var, Compare)` combinations beforehand (via [select_unique()]) so
#' each plot only sees the columns it needs, and titles each plot
#' `"<var> overlap by <Compare>"`.
#'
#' @param df A `pep_all`-shaped data frame.
#' @param vars Character vector of column names to plot overlap for, e.g.
#'   `c("Peptide", "Sequence", "Accession")`.
#' @param n_intersections Maximum number of intersections to display per plot.
#' @param Compare Name (string) of the column defining the groups compared.
#' @param labels Forwarded to [plot_upset()] (`"abs"`, `"perc"`, or other). Defaults to `"perc"`.
#' @param lab.size Forwarded to [plot_upset()].
#' @param plot.margin Forwarded to [plot_upset()].
#'
#' @return A named list of ggplot2/`ggupset` objects, one per entry of `vars`,
#'   named `"<var>_by_<Compare>"`.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' plot_upset_batch(pep_all, c("Peptide", "Sequence", "Accession"), Compare = "Condition")
#' }
plot_upset_batch <-   function(df, vars, n_intersections = 20, Compare = "Condition", labels = "perc", lab.size = 2,
           plot.margin = unit(c(0.2,0.2,0.2,0.2), "cm")){
  output <-
    lapply(vars, function(x){
      df %>%
        select_unique(var = x, Compare) %>%
        plot_upset(., var, n_intersections = n_intersections, Compare = Compare,
                   labels = labels, lab.size = lab.size, plot.margin = plot.margin) +
        ggplot2::ggtitle(paste0(x, " overlap by ", Compare))
    })
  names(output) <- paste0(vars, "_by_", Compare)
  return(output)
}

#' Sequence motif logo for peptides of a given length
#'
#' Filters to peptides of `seq_length`, splits their sequences by `by`, and
#' renders a [ggseqlogo::ggseqlogo()] motif per group. Warns when a `by` group
#' has no sequences of the requested length (and so is dropped from the plot).
#'
#' @param input A `pep_all`-shaped data frame with `Length`/`Sequence` columns.
#' @param seq_length Peptide length to filter to (motifs require fixed-length
#'   alignment).
#' @param by Column name (string) to split sequences by, e.g. `"Condition"`.
#' @param ... Additional arguments passed to [ggseqlogo::ggseqlogo()].
#'
#' @return A `ggseqlogo` ggplot object, faceted by `by`.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' ggseqlogo_bylength(pep_short, seq_length = 9, by = "Condition")
#' }
ggseqlogo_bylength <- function(input, seq_length, by, ...){
  ## Get sequences and groups
  input_filtered <- input %>%
    dplyr::filter(Length == seq_length) %>%
    dplyr::select(dplyr::all_of(by), Sequence) %>%
    unique %>% droplevels
  ## Check if some groups were droped due to not having sequences
  by_input <- input %>% dplyr::pull(by) %>% unique
  by_input_filtered <- input_filtered %>% dplyr::pull(by) %>% unique
  if(length(by_input) != length(by_input_filtered)){
    print(paste0("The following groups were droped because no Sequence with Length = ", seq_length, " was found: ", paste(by_input[!by_input %in% by_input_filtered]), "\n", collapse = ", "))

  }
  ## Get in list format
  input_filtered_list <- lapply(split(input_filtered[-1], input_filtered[, by]), function(x) x[x != ""])
  ## plot
  input_filtered_list %>%
    ggseqlogo::ggseqlogo(scales = "free", ...) +
    ggplot2::theme(plot.background = ggplot2::element_rect(fill = "white"))
}

#' Clustered heatmap of a numeric matrix, saved directly to png
#'
#' Wraps [gplots::heatmap.2()] with complete-linkage/Euclidean clustering, a
#' diverging RdBu palette sized to the data range, row side-colors from
#' `cutree()` cluster assignment, and column side-colors derived from
#' `annotation`'s `group` column — then writes the result straight to `file`
#' as a png (the function has no return value; it is called for this side
#' effect).
#'
#' @param mat Numeric matrix to cluster and plot (e.g. output of
#'   [get_mat_log2area()]).
#' @param annotation Annotation data frame; must contain the `level` and
#'   `group` columns (`level` matches `mat`'s column names, `group` colors
#'   them).
#' @param level Column (string) in `annotation` matching `mat`'s columns.
#' @param group Column (string) in `annotation` used to color columns.
#' @param n_clust Number of row clusters to cut the dendrogram into.
#' @param width,height,units,res Passed to [grDevices::png()].
#' @param keysize Passed to [gplots::heatmap.2()].
#' @param file Output png file path.
#' @param ... Additional arguments passed to [gplots::heatmap.2()].
#'
#' @return Invisible `NULL`; called for its side effect of writing `file`.
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' plot_heatmap(mat_log2area, annotation, level = "Sample", group = "Condition",
#'              file = file.path("4_figures", "hm_pep_all_log2area_br_nonscaled.png"))
#' }
plot_heatmap <- function(mat, annotation, level, group, n_clust = 5, width = 24, height = 24, units = "cm", res = 100, keysize = 0.9, file, ...){
  # Simple heatmap using heatmap.2
  # mat = matrix of numeric functions
  # https://www.datanovia.com/en/lessons/heatmap-in-r-static-and-interactive-visualization/#enhanced-heat-maps-heatmap.2

  bins_palette <- ifelse(diff(range(mat)) > 100, 100, diff(range(mat)))

  palette_hm <- grDevices::colorRampPalette(RColorBrewer::brewer.pal(11, "RdBu"))(bins_palette)

  # set the custom distance and clustering functions
  hclustfunc <- function(x) hclust(x, method = "complete")
  distfunc <- function(x) dist(x, method = "euclidean")

  # perform clustering on rows and columns
  cl.row <- hclustfunc(distfunc(mat))
  cl.col <- hclustfunc(distfunc(t(mat)))

  # extract cluster assignments; i.e. k=8 (rows) k=5 (columns)
  gr.row <- cutree(cl.row, n_clust)
  ## Use Condition to color the columns
  gr.col <-
    annotation %>%
    dplyr::select(dplyr::all_of(c(level, group))) %>% dplyr::distinct() %>%
    dplyr::mutate(Condition = as.integer(as.factor(get(group)))) %>%
    tibble::column_to_rownames(level) %>%
    t
  # get colors
  col1 <- viridis::magma(n_clust)
  col2 <- viridis::viridis(max(t(gr.col)))

  grDevices::png(filename = file, width = width, height = height, units = units, res = res)
  par(oma = c(4, 2, 2, 2))
  gplots::heatmap.2(mat, hclustfun = hclustfunc, distfun = distfunc,
                    col = palette_hm, trace = "none",
                    RowSideColors = col1[gr.row], ColSideColors = col2[gr.col], keysize = keysize, ...)
  grDevices::dev.off()
  message(paste0("Heatmap saved in ", file.path("4_figures", "hm_pep_all_log2area_br_nonscaled.png")))

}

#' Stacked bar chart of peptide proportions by `Length_range` and `Condition`
#'
#' Plots the table produced by [count_ids_condition_bylengthrange()] as a
#' stacked proportion bar chart per condition, with percentage labels.
#'
#' @param input Output of [count_ids_condition_bylengthrange()].
#' @param level2plot Which `Level` to plot — one of `"Peptides.Modified"`,
#'   `"Peptides"`, `"Proteins"`.
#' @param label_size Text size for the percentage labels (`geom_text`); mirrors
#'   the report's `PlotTextLabelSize` param.
#'
#' @return A ggplot2 stacked bar chart.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' plot_prop_length_condition(count_ids_condition_bylengthrange(pep_all))
#' }
plot_prop_length_condition <- function(input, level2plot = "Peptides", label_size = 1.6){
  input %>%
    dplyr::filter(Length_range != "All peptides",
                  Level == level2plot) %>%
    droplevels %>%
    ggplot2::ggplot(ggplot2::aes(x = Condition, y = Proportion, group = Length_range)) +
    ggplot2::geom_bar(stat = "identity",
                      ggplot2::aes(fill = Length_range),
                      position = ggplot2::position_stack()) +
    ggplot2::geom_text(ggplot2::aes(label = Percentage, y = CumProportion - 0.015), size = label_size) +
    theme_rawr() +
    ggplot2::scale_y_continuous(breaks = seq(0, 1, 0.25), labels = c("0", "", "50", "", "100"), limits = c(0, 1.02)) +
    ggplot2::labs(fill = "Length") +
    ggplot2::ylab("% Peptides") +
    ggplot2::scale_fill_viridis_d(end = 1, alpha = 0.5) +
    ggplot2::theme(legend.position = "right") +
    ggplot2::guides(fill = ggplot2::guide_legend(override.aes = list(size = 0.3)))
}

#' Stacked bar chart of charge-state proportions by group
#'
#' Plots the table produced by [get_proportion_charge()] as a stacked
#' proportion bar chart, with percentage labels.
#'
#' @param input Output of [get_proportion_charge()].
#' @param variable Grouping column for the x-axis (tidy-evaluated), e.g.
#'   `Condition`.
#' @param label_size Text size for the percentage labels (`geom_text`); mirrors
#'   the report's `PlotTextLabelSize` param.
#'
#' @return A ggplot2 stacked bar chart.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' plot_charge_proportions(get_proportion_charge(counts_charge_condition), Condition)
#' }
plot_charge_proportions <- function(input, variable, label_size = 1.6){
  input %>%
    dplyr::filter(Charge_group != "Total",
                  Level == "Peptides") %>%
    droplevels %>%
    dplyr::arrange(Charge_group) %>%
    dplyr::mutate(PositionProp = dplyr::case_when(Charge_group == "+ 1" ~ CumProportion - 0.02,
                                                   Charge_group == "+ 2" ~ CumProportion * 0.9,
                                                   TRUE ~ CumProportion * 0.9)) %>%
    ggplot2::ggplot(ggplot2::aes(x = {{ variable }}, y = Proportion, fill = Charge_group, group = Charge_group)) +
    ggplot2::geom_bar(stat = "identity", alpha = 0.5) +
    ggplot2::geom_text(ggplot2::aes(label = Percentage, y = Proportion),
                       size = label_size, position = ggplot2::position_stack(vjust = 0.8)) +
    ggplot2::scale_y_continuous(breaks = seq(0, 2, 0.25), labels = c("0", "", "50", "", "100", "", "150", "", "200")) + # removed since for fragpipe total may be 100%, due to multiple charges assigned
    theme_rawr() +
    ggplot2::scale_fill_viridis_d(end = 0.7, name = "Charge") +
    ggplot2::scale_color_viridis_d(end = 0.7, name = "Charge") +
    ggplot2::theme(legend.position = "right") +
    ggplot2::guides(fill = ggplot2::guide_legend(override.aes = list(size = 0.3))) +
    ggplot2::ylab("% Peptides")
}

#' Violin + boxplot of Area %CV by group
#'
#' Plots the table produced by [summarise_area()] as violin/boxplot pairs per
#' group, with a dashed reference line at 20% CV and an "n = ..." label
#' annotating each group's peptide count.
#'
#' @param input Output of [summarise_area()].
#' @param by Grouping column for the x-axis (tidy-evaluated), e.g. `Condition`.
#' @param label_size Text size for the "n = ..." annotation (`stat_summary`);
#'   mirrors the report's `PlotTextLabelSize` param.
#'
#' @return A ggplot2 violin/boxplot figure.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' plot_violin_areacv(summarise_area(pep_all, Condition), Condition)
#' }
plot_violin_areacv <- function(input, by, label_size = 1.6){
  ## get ylim
  cv_ylim <- ceiling(max(input$Area_CV, na.rm = TRUE) * 12) / 10
  ## plot
  input %>%
    ggplot2::ggplot(ggplot2::aes(x = {{ by }}, y = Area_CV)) +
    ggplot2::geom_violin(ggplot2::aes(fill = {{ by }}), alpha = 0.5, color = NA,
                         width = 0.9, size = 0.2) +
    ggplot2::stat_boxplot(geom = 'errorbar', width = 0.1, size = 0.2) +
    ggplot2::geom_boxplot(width = 0.2, outlier.alpha = 0, alpha = 0, size = 0.25, outliers = TRUE) +
    ggplot2::geom_hline(yintercept = 0.2, linetype = "dashed", alpha = 0.5) +
    ggplot2::stat_summary(fun.data = function(x) data.frame(y = cv_ylim, label = paste0("n = ", length(x))),
                          geom = "text", size = label_size, vjust = 1.5) + # n = peptides IDed in all the replicates
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                                name = "Area %CV", breaks = seq(0, cv_ylim, by = 0.25), limits = c(0, cv_ylim)) +
    theme_rawr() +
    ggplot2::scale_fill_viridis_d(begin = 0, end = 1) +
    ggpubr::rotate_x_text(70)
}

#' Pearson correlation heatmap of log2(Area)
#'
#' Plots a correlation matrix (e.g. `cor(., method = "pearson")`) with
#' [ggcorrplot::ggcorrplot()], using a diverging red-white-blue gradient whose
#' breaks/limits/midpoint are derived directly from `mat`'s value range — a
#' symmetric `[-1, 1]` matrix gets the `(-1, 1, mid = 0)` scale, anything else
#' gets a `[0, 1]`-anchored scale with `mid = 0.7`.
#'
#' @param mat A correlation matrix (output of [stats::cor()]).
#'
#' @return A `ggcorrplot` ggplot object.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' plot_corr(cor(pep_all_log2area_tr, method = "pearson", use = "pairwise.complete.obs"))
#' }
plot_corr <- function(mat){
  # derive the gradient's breaks/limits/midpoint from mat's own range
  corrarea_lim <- c(floor(min(mat, na.rm = TRUE)), ceiling(max(mat, na.rm = TRUE)))
  corrarea_mid <- ifelse(all(corrarea_lim == c(-1, 1)), 0, 0.7)
  if(all(corrarea_lim == c(-1, 1))){
    corrarea_breaks <- seq(-1, 1, 0.2)
  }else{
    corrarea_breaks <- seq(0, 1, 0.1)
  }

  mat %>%
    ggcorrplot::ggcorrplot(hc.order = FALSE) +
    ggplot2::scale_x_discrete(limits = rev) +
    ggplot2::scale_y_discrete(limits = rev) +
    ggplot2::scale_fill_gradient2(low = "darkred", mid = "white", high = "darkblue",
                                  breaks = corrarea_breaks,
                                  limit = corrarea_lim, midpoint = corrarea_mid) +
    ggplot2::theme(plot.background = ggplot2::element_rect(fill = "white")) +
    ggplot2::theme(plot.title = ggplot2::element_text(size = 8),
                   axis.text.x = ggplot2::element_text(size = 6),
                   axis.text.y = ggplot2::element_text(size = 6)) +
    ggpubr::rotate_x_text(65)
}

#' Mean ± SD barplot of ID counts per Condition, faceted by length range
#'
#' Replaces the inline ggbarplot body in the "Average +/- sd" loop of the main
#' report template. Filters out the `"others"` length range (only plots the
#' `"All peptides"` and the expected-length rows), then renders a faceted
#' barplot showing mean ± SD across BioReplicates per Condition.
#'
#' @param df A counts data frame shaped like `counts_size` (one row per
#'   BioReplicate × Condition × Length_range, with `n_Peptides`,
#'   `n_Sequences`, `n_Proteins` columns).
#' @param level One of `"Peptides"`, `"Sequences"`, `"Proteins"`.
#' @param lim_level Upper y-axis limit (e.g. looked up from a `count_lim`
#'   table by `Level`/`"Limit_mean"`).
#'
#' @return A `ggpubr` barplot with mean ± SD error bars and viridis fill.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' plot_count_mean_sd(counts_size, "Peptides", lim_level = 30000)
#' }
plot_count_mean_sd <- function(df, level, lim_level) {
  nlevel <- paste0("n_", level)
  df %>%
    dplyr::filter(Length_range != "others") %>%
    droplevels() %>%
    ggpubr::ggbarplot(x = "Condition", y = nlevel, fill = "Condition",
                      facet.by = "Length_range", add = "mean_sd", scales = "free_x",
                      label = TRUE, alpha = 0.5,
                      lab.vjust = -2, lab.nb.digits = 0, lab.size = 2.5, nrow = 2) +
    theme_rawr() +
    ggplot2::scale_y_continuous(limits = c(0, lim_level),
                                breaks = seq(0, lim_level, 5000),
                                labels = scales::label_number(suffix = " k", scale = 1e-3)) +
    ggplot2::ylab(paste0("Nb ", level)) +
    ggplot2::xlab("Condition") +
    ggpubr::rotate_x_text(70) +
    ggplot2::labs(fill = "Condition") +
    ggplot2::scale_fill_viridis_d(end = 1) +
    ggplot2::theme(legend.position = "none") +
    ggplot2::ggtitle(paste0("Unique ", level, " (mean +/- sd)"))
}

#' Stacked overlap barplot (all vs short peptides) for one ID level
#'
#' Builds two barplots — one for `pep_all` and one for `pep_short` — showing
#' how many IDs were detected in 1, 2, 3, … replicates per Condition, then
#' combines them vertically with [ggpubr::ggarrange()]. Works for Peptides,
#' Sequences, or Proteins by dispatching on `id_col`.
#'
#' @param pep_all,pep_short `pep_all`-shaped data frames (all and length-
#'   filtered peptides respectively).
#' @param id_col Column defining the ID level: `"Peptide"`, `"Sequence"`, or
#'   `"Accession"`.
#' @param shortpep_range Length-2 numeric vector `c(min, max)` used only to
#'   build the subtitle of the lower panel.
#'
#' @return A [ggpubr::ggarrange()] figure (upper: all peptides; lower: short
#'   peptides) with a shared legend.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' plot_overlap_intra_condition(pep_all, pep_short, "Peptide")
#' plot_overlap_intra_condition(pep_all, pep_short, "Accession")
#' }
plot_overlap_intra_condition <- function(pep_all, pep_short, id_col,
                                         shortpep_range = c(8, 13)) {
  n_col  <- dplyr::case_when(id_col == "Peptide"   ~ "n_Peptides",
                              id_col == "Sequence"  ~ "n_Sequences",
                              id_col == "Accession" ~ "n_Accessions")
  ylabel <- dplyr::case_when(id_col == "Peptide"   ~ "Nb Peptides",
                              id_col == "Sequence"  ~ "Nb Sequences",
                              id_col == "Accession" ~ "Nb Proteins")
  title_all <- dplyr::case_when(
    id_col == "Peptide"   ~ "All Peptides",
    id_col == "Sequence"  ~ "All Sequences",
    id_col == "Accession" ~ "Proteins from all peptides")
  title_short <- dplyr::case_when(
    id_col == "Peptide"   ~ paste0("Selected peptides (", shortpep_range[1], " to ", shortpep_range[2], " AAs)"),
    id_col == "Sequence"  ~ paste0("Selected Sequences (", shortpep_range[1], " to ", shortpep_range[2], " AAs)"),
    id_col == "Accession" ~ paste0("Proteins from ", shortpep_range[1], " to ", shortpep_range[2], " AAs"))
  nudge <- if (id_col == "Accession") 200 else 300
  tot_col <- paste0("total_", sub("n_", "", n_col))

  .make_overlap_df <- function(df) {
    df %>%
      dplyr::select(Condition, Sample, dplyr::all_of(id_col)) %>%
      unique() %>%
      dplyr::group_by(Condition, .data[[id_col]]) %>%
      dplyr::summarize(n_Samples = dplyr::n_distinct(Sample), .groups = "drop") %>%
      dplyr::group_by(Condition, n_Samples) %>%
      dplyr::summarize(n_ids = dplyr::n_distinct(.data[[id_col]]), .groups = "drop") %>%
      dplyr::rename_with(.fn = ~n_col, .cols = "n_ids") %>%
      dplyr::mutate(n_Samples = as.factor(n_Samples)) %>%
      dplyr::arrange(Condition, dplyr::desc(n_Samples)) %>%
      dplyr::group_by(Condition) %>%
      dplyr::mutate(
        tot_val = sum(.data[[n_col]]),
        perc    = paste0(round(100 * .data[[n_col]] / sum(.data[[n_col]]), 1), "%"),
        cum     = cumsum(.data[[n_col]])) %>%
      dplyr::rename_with(.fn = ~tot_col, .cols = "tot_val")
  }

  .make_bar <- function(df_ov, title) {
    ylim_ov <- ceiling(max(df_ov[[tot_col]]) * 1.2 / 100) * 100
    df_ov %>%
      ggpubr::ggbarplot(x = "Condition", y = n_col, fill = "n_Samples",
                        label = FALSE, lab.pos = "in",
                        lab.nb.digits = 0, lab.size = 2.5, alpha = 0.8) +
      ggplot2::geom_text(ggplot2::aes(y = .data[["cum"]], label = .data[["perc"]]),
                         size = 2.5, nudge_y = -nudge) +
      ggplot2::geom_text(ggplot2::aes(y = .data[[tot_col]], label = .data[[tot_col]]),
                         size = 2.5, nudge_y = nudge) +
      theme_rawr() +
      ggplot2::ylab(ylabel) +
      ggplot2::xlab("Condition") +
      ggpubr::rotate_x_text(70) +
      ggplot2::scale_y_continuous(
        limits = c(0, ylim_ov),
        breaks = seq(0, ylim_ov, 5000),
        labels = scales::label_number(suffix = " k", scale = 1e-3)) +
      ggplot2::scale_fill_viridis_d(begin = 0.2, end = 0.8, name = "ID in n Replicates") +
      ggplot2::ggtitle(title)
  }

  df_all_ov   <- .make_overlap_df(pep_all)
  df_short_ov <- .make_overlap_df(pep_short)
  bp_all      <- .make_bar(df_all_ov,   title_all)
  bp_short    <- .make_bar(df_short_ov, title_short)
  ggpubr::ggarrange(
    bp_all   + ggpubr::rremove("xlab") + ggpubr::rremove("x.text"),
    bp_short,
    nrow = 2, heights = c(0.4, 0.6), align = "v",
    common.legend = TRUE, legend = "right")
}

#' Violin + overlaid boxplot of Score or mass error per Condition and charge
#'
#' Creates a `ChargeSimple` column ("+1" vs ">= +2"), then renders a
#' [ggpubr::ggviolin()] faceted by charge group with an overlaid boxplot and
#' error bars.
#'
#' @param df A `pep_all`-shaped data frame with `Charge` and `y_var` columns.
#' @param y_var Column name (string) to plot on the y-axis, e.g. `"Score"` or
#'   `"ppm"`.
#' @param title Plot title.
#'
#' @return A `ggpubr` violin/boxplot figure, faceted by `ChargeSimple`.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' plot_qc_violin(pep_all, "Score", "Score distribution, and boxplot")
#' plot_qc_violin(pep_all, "ppm",   "Mass error distribution, and boxplot")
#' }
plot_qc_violin <- function(df, y_var, title) {
  df %>%
    dplyr::mutate(ChargeSimple = as.factor(
      dplyr::case_when(Charge == "+ 1" ~ "+ 1", TRUE ~ ">= +2"))) %>%
    ggpubr::ggviolin(x = "Condition", y = y_var, fill = "Condition",
                     facet.by = "ChargeSimple", nrow = 2) +
    ggplot2::geom_boxplot(fill = NA, outlier.shape = NA, width = 0.5) +
    ggplot2::stat_boxplot(geom = "errorbar", width = 0.5) +
    ggplot2::ggtitle(title) +
    ggplot2::theme_minimal(base_size = 9) +
    ggplot2::theme(strip.background = ggplot2::element_blank(),
                   strip.text       = ggplot2::element_text(face = "bold"),
                   plot.background  = ggplot2::element_rect(fill = "white"),
                   legend.position  = "none") +
    ggpubr::rotate_x_text(70) +
    ggplot2::scale_fill_viridis_d()
}

#' Boxplot of Score or mass error per Condition and charge
#'
#' Creates a `ChargeSimple` column ("+1" vs ">= +2"), then renders a
#' [ggpubr::ggboxplot()] faceted by charge group.
#'
#' @param df A `pep_all`-shaped data frame with `Charge` and `y_var` columns.
#' @param y_var Column name (string) to plot on the y-axis, e.g. `"Score"` or
#'   `"ppm"`.
#' @param title Plot title.
#'
#' @return A `ggpubr` boxplot figure, faceted by `ChargeSimple`.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' plot_qc_box(pep_all, "Score", "Score boxplot")
#' plot_qc_box(pep_all, "ppm",   "Mass error boxplot")
#' }
plot_qc_box <- function(df, y_var, title) {
  df %>%
    dplyr::mutate(ChargeSimple = as.factor(
      dplyr::case_when(Charge == "+ 1" ~ "+ 1", TRUE ~ ">= +2"))) %>%
    ggpubr::ggboxplot(x = "Condition", y = y_var, color = "Condition",
                      facet.by = "ChargeSimple", nrow = 2) +
    ggplot2::stat_boxplot(geom = "errorbar", width = 0.5) +
    ggplot2::ggtitle(title) +
    ggplot2::theme_minimal(base_size = 9) +
    ggplot2::theme(strip.background = ggplot2::element_blank(),
                   strip.text       = ggplot2::element_text(face = "bold"),
                   plot.background  = ggplot2::element_rect(fill = "white"),
                   legend.position  = "none") +
    ggpubr::rotate_x_text(70) +
    ggplot2::scale_color_viridis_d()
}

#' Heatmap of PTM counts or proportions for length-filtered peptides
#'
#' Cleans PTM annotation strings, splits multi-PTM entries (`;`/`,` delimited),
#' and renders a [ggplot2::geom_tile()] heatmap of PTM counts or proportions
#' per Condition. All data preparation is handled internally — only `pep_short`
#' (the length-filtered peptide table) is needed.
#'
#' @param pep_short Length-filtered `pep_all`-shaped data frame (e.g. the
#'   `pep_short` object created in the report's `initialize` chunk).
#' @param type `"count"` (default) for absolute peptide counts per PTM, or
#'   `"proportion"` for the percentage of PTM-modified vs total peptides.
#' @param shortpep_range Length-2 numeric vector `c(min, max)` — used only for
#'   the `"proportion"` subtitle (the denominator is computed directly from
#'   `pep_short`).
#'
#' @return A ggplot2 tile heatmap.
#'
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' plot_ptm_heatmap(pep_short, type = "count")
#' plot_ptm_heatmap(pep_short, type = "proportion", shortpep_range = c(8, 13))
#' }
plot_ptm_heatmap <- function(pep_short, type = c("count", "proportion"),
                              shortpep_range = c(8, 13)) {
  type <- match.arg(type)

  pep_short_ptm <-
    pep_short %>%
    dplyr::filter(PTM != "") %>%
    dplyr::mutate(PTM = gsub(" ", "", PTM)) %>%
    tidyr::separate_rows(PTM, sep = ";|,") %>%
    dplyr::mutate(PTM = trimws(PTM, "left", "[0-9]+"))

  count_df <-
    pep_short_ptm %>%
    tidyr::separate_rows(PTM, sep = ";|,") %>%
    dplyr::group_by(Condition, PTM) %>%
    dplyr::summarise(n_Peptides  = dplyr::n_distinct(Peptide),
                     n_Sequences = dplyr::n_distinct(Sequence),
                     n_Proteins  = dplyr::n_distinct(Accession),
                     SumArea     = sum(Area, na.rm = TRUE),
                     .groups = "drop") %>%
    tidyr::complete(PTM, Condition) %>%
    dplyr::mutate(dplyr::across(where(is.numeric), ~ifelse(is.na(.x), 0, .x)))

  if (type == "count") {
    count_df %>%
      ggplot2::ggplot(ggplot2::aes(y = PTM, x = Condition, fill = n_Peptides)) +
      ggplot2::geom_tile() +
      ggplot2::geom_text(ggplot2::aes(label = n_Peptides)) +
      viridis::scale_fill_viridis(alpha = 0.9, option = "D", begin = 0.1) +
      theme_rawr() +
      ggpubr::rotate_x_text(35) +
      ggplot2::ggtitle("PTM profile, counts of modified peptides")
  } else {
    totals_df <-
      pep_short %>%
      dplyr::group_by(Condition) %>%
      dplyr::summarise(n_Peptides = dplyr::n_distinct(Peptide), .groups = "drop") %>%
      dplyr::mutate(PTM = "Total")

    count_df %>%
      dplyr::select(PTM, Condition, n_Peptides) %>%
      dplyr::bind_rows(totals_df) %>%
      dplyr::group_by(Condition) %>%
      dplyr::mutate(prop_Peptides = round(n_Peptides / n_Peptides[PTM == "Total"], 4)) %>%
      dplyr::mutate(perc_Peptides = .data[["prop_Peptides"]] * 100) %>%
      dplyr::filter(PTM != "Total") %>%
      droplevels() %>%
      ggplot2::ggplot(ggplot2::aes(y = PTM, x = Condition, fill = .data[["perc_Peptides"]])) +
      ggplot2::geom_tile() +
      ggplot2::geom_text(ggplot2::aes(label = paste0(.data[["perc_Peptides"]], "%")), size = 2.5) +
      viridis::scale_fill_viridis(alpha = 0.9, option = "D", begin = 0.1) +
      theme_rawr() +
      ggpubr::rotate_x_text(35) +
      ggplot2::ggtitle("PTM profile, proportion of modified peptides vs total")
  }
}
