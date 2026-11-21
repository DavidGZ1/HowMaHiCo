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
#'
#' @examples
#' \dontrun{
#' plot_peplength(pep_all, title = "All peptides")
#' }
#' @keywords internal
plot_peplength <- function(input, title, ylimits = NULL, xlimits = NULL){
  max_count <- input |> dplyr::group_by(Length) |> dplyr::count() |> max()
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
    input |>
    ggplot2::ggplot(ggplot2::aes(x = Length)) +
    ggplot2::geom_boxplot(color = "#39568CFF", outlier.size = 0.5) +
    ggplot2::stat_boxplot(geom = 'errorbar', width = 0.5) +
    ggpubr::theme_pubr() +
    ggpubr::clean_theme() +
    ggplot2::theme(strip.background = ggplot2::element_blank(), strip.text = ggplot2::element_text(face = "bold", size = 2)) +
    ggplot2::scale_x_continuous(limits = xlimits, breaks = seq(0, xlimits[2], by = 1))
  p_length_hist <-
    input |>
    ggplot2::ggplot(ggplot2::aes(x = Length)) +
    ggplot2::geom_histogram(fill = "#39568CFF", binwidth = 1) +
    ggplot2::scale_y_continuous(limits = ylimits, breaks = seq(0, ylimits[2], by = 1000)) +
    ggplot2::scale_x_continuous(limits = xlimits, breaks = seq(0, xlimits[2], by = 3)) +
    ggplot2::ylab("Peptide count") +
    ggplot2::xlab("Peptide length") +
    theme_howmahico()
  ggpubr::ggarrange(p_length_bp, p_length_hist, nrow = 2, heights = c(0.15, 0.85), align = "v") |>
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
#' @export
#'
#' @examples
#' \dontrun{
#' plot_peplength_dens(pep_all, title = "All peptides")
#' }
plot_peplength_dens <- function(input, title, ylimits = NULL, xlimits = NULL){
  max_count <- input |> dplyr::group_by(Length) |> dplyr::count() |> max()
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
    input |>
    ggplot2::ggplot(ggplot2::aes(x = Length)) +
    ggplot2::geom_boxplot(color = "#39568CFF", outlier.size = 0.5) +
    ggplot2::stat_boxplot(geom = 'errorbar', width = 0.5) +
    ggpubr::theme_pubr() +
    ggpubr::clean_theme() +
    ggplot2::theme(strip.background = ggplot2::element_blank(), strip.text = ggplot2::element_text(face = "bold", size = 2)) +
    ggplot2::scale_x_continuous(limits = xlimits, breaks = seq(0, xlimits[2], by = 1))
  p_length_hist <-
    input |>
    ggplot2::ggplot(ggplot2::aes(x = Length, y = ..density..)) +
    ggplot2::geom_histogram(fill = "#39568CFF", binwidth = 1) +
    ggplot2::scale_x_continuous(limits = xlimits, breaks = seq(0, xlimits[2], by = 3)) +
    ggplot2::xlab("Peptide length") +
    theme_howmahico()
  ggpubr::ggarrange(p_length_bp, p_length_hist, nrow = 2, heights = c(0.15, 0.85), align = "v") |>
    ggpubr::annotate_figure(top = ggpubr::text_grob(title, face = "bold", size = 8))
}

#' Peptide length histogram faceted by Condition
#'
#' Faceted histogram of peptide lengths across conditions, with bars coloured by
#' whether each length falls within `shortpep_range` ("X to Y AAs") or outside
#' ("others"). Replaces the [plot_peplength_dens()] + `lapply` + `ggarrange`
#' approach in the report with a single `facet_wrap` call.
#'
#' @param input A `pep_all`-shaped data frame with `Length` and `Condition`
#'   columns. Typically `pep_all_unique` (one row per peptide–condition pair).
#' @param shortpep_range Length-2 integer vector giving the inclusive range
#'   `[min, max]` that defines the "in-range" fill category. Default `c(8, 13)`.
#' @param type One of `"density"` (y-axis = relative frequency) or `"count"`
#'   (y-axis = raw count). Matched via [match.arg()].
#' @param palette Named character vector of length 2 mapping the range label
#'   (`"X to Y AAs"`) and `"others"` to colours. When `NULL`, falls back to
#'   [ggplot2::scale_fill_viridis_d()].
#' @param xlimits Length-2 numeric vector for the x-axis limits. Default
#'   `c(5, 25)`.
#'
#' @return A `ggplot` object.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_peplength_hist(pep_all_unique, shortpep_range = c(8, 13),
#'                     type = "density", palette = c("8 to 13 AAs" = "#fde725",
#'                                                    others = "#440154"))
#' }
plot_peplength_hist <- function(input, shortpep_range = c(8, 13),
                                type = c("density", "count"),
                                palette = NULL, xlimits = c(5, 25)) {
  type <- match.arg(type)
  range_label <- paste0(shortpep_range[1], " to ", shortpep_range[2], " AAs")
  # Pre-compute counts and normalise by condition total so density reflects the
  # full distribution (not each fill group independently).
  df <- input |>
    dplyr::mutate(
      in_range = factor(
        ifelse(Length >= shortpep_range[1] & Length <= shortpep_range[2],
               range_label, "others"),
        levels = c(range_label, "others")
      )
    ) |>
    dplyr::count(Condition, Length, in_range) |>
    dplyr::group_by(Condition) |>
    dplyr::mutate(density = n / sum(n)) |>
    dplyr::ungroup()
  y_var <- if (type == "density") "density" else "n"
  y_lab <- if (type == "density") "Density" else "Count"
  p <- ggplot2::ggplot(df, ggplot2::aes(x = Length, y = .data[[y_var]],
                                        fill = in_range)) +
    ggplot2::geom_col(color = "black", alpha = 0.5) +
    ggplot2::facet_wrap(~Condition) +
    ggplot2::scale_x_continuous(limits = xlimits,
                                breaks = seq(xlimits[1], xlimits[2], 3)) +
    ggplot2::xlab("Peptide length (AAs)") +
    ggplot2::ylab(y_lab) +
    ggplot2::labs(fill = "Length") +
    theme_howmahico()
  if (!is.null(palette)) {
    p <- p + ggplot2::scale_fill_manual(values = palette)
  } else {
    p <- p + ggplot2::scale_fill_viridis_d(end = 1)
  }
  p
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
    input |>
    ggplot2::ggplot(ggplot2::aes(x = Mass)) +
    ggplot2::geom_boxplot(color = "#39568CFF", outlier.size = 0.5) +
    ggplot2::stat_boxplot(geom = 'errorbar', width = 0.5) +
    ggpubr::theme_pubr() +
    ggpubr::clean_theme() +
    ggplot2::theme(strip.background = ggplot2::element_blank(), strip.text = ggplot2::element_text(face = "bold"))

  p_mass_hist <-
    input |>
    ggplot2::ggplot(ggplot2::aes(x = Mass)) +
    ggplot2::geom_histogram(ggplot2::aes(y = ..density..), fill = "#39568CFF", color = "white",
                            binwidth = 50, size = 0.1) +
    ggplot2::geom_density(color = "black", size = 0.5, alpha = 0.5) +
    ggplot2::annotate("text", color = "black", size = 3,
                      x = max_dens_x * 1.1, hjust = 0, y = max_dens_y * 1.1,
                      label = paste0("Apex = ", round(max_dens_x, 1))) +
    ggplot2::ylab("Density") +
    ggplot2::xlab("Peptide Mass (Da)") +
    theme_howmahico()
  if(!is.null(xlimits)){
    p_mass_bp <- p_mass_bp + ggplot2::scale_x_continuous(limits = xlimits)
    p_mass_hist <- p_mass_hist + ggplot2::scale_x_continuous(limits = xlimits)
  }


  ggpubr::ggarrange(p_mass_bp, p_mass_hist, nrow = 2, heights = c(0.15, 0.85), align = "v") |>
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
    input |>
    ggplot2::ggplot(ggplot2::aes(x = m_z)) +
    ggplot2::geom_boxplot(color = "#39568CFF", outlier.size = 0.5) +
    ggplot2::stat_boxplot(geom = 'errorbar', width = 0.5) +
    ggpubr::theme_pubr() +
    ggpubr::clean_theme() +
    ggplot2::theme(strip.background = ggplot2::element_blank(), strip.text = ggplot2::element_text(face = "bold"))
  p_mass_hist <-
    input |>
    ggplot2::ggplot(ggplot2::aes(x = m_z)) +
    ggplot2::geom_histogram(ggplot2::aes(y = ..density..), fill = "#39568CFF", color = "white",
                            binwidth = 50, size = 0.1) +
    ggplot2::geom_density(color = "black", size = 0.5, alpha = 0.5) +
    ggplot2::annotate("text", color = "black", size = 3,
                      x = max_dens_x * 1.1, hjust = 0.5, y = max_dens_y * 1.1,
                      label = paste0("Apex = ", round(max_dens_x, 1))) +
    ggplot2::ylab("Density") +
    ggplot2::xlab("Peptide m/z") +
    theme_howmahico()

  if(!is.null(xlimits)){
    p_mass_bp <- p_mass_bp + ggplot2::scale_x_continuous(limits = xlimits)
    p_mass_hist <- p_mass_hist + ggplot2::scale_x_continuous(limits = xlimits)
  }

  ggpubr::ggarrange(p_mass_bp, p_mass_hist, nrow = 2, heights = c(0.15, 0.85), align = "v") |>
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
#' @param x_var Column name for the x-axis (default `"Condition"`). Pass
#'   `"Sample"` for a per-sample version of the plot.
#' @param palette Optional named character vector mapping `Length_range` values
#'   to fill colours (e.g. `c("8 to 13 AAs" = "#fde725", "others" = "#440154")`).
#'   When `NULL` (default) `scale_fill_viridis_d()` is used.
#'
#' @return A `ggpubr` bar chart (`ggbarplot`) with per-bar count labels, a
#'   `"Total=..."` annotation, and a viridis or manual fill scale.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_bp_count_length(counts_size_total, "Peptides", lim_level = 50000, shortpep_range = c(8, 13))
#' }
plot_bp_count_length <- function(df, level, lim_level, shortpep_range = c(8, 13),
                                  x_var = "Condition", palette = NULL){
  nlevel <- paste0("n_", level)
  p <- df |>
    dplyr::filter(Length_range != "All peptides") |>
    droplevels() |>
    ggpubr::ggbarplot(x = x_var, y = nlevel, fill = "Length_range", group = "Length_range",
                      label = TRUE, alpha = 0.5,
                      lab.vjust = 1.5,
                      lab.nb.digits = 0, lab.size = 2.5) +
    ggplot2::geom_text(data = df |> dplyr::filter(Length_range == "All peptides"),
                       ggplot2::aes(label = paste0("Total=\n", get(nlevel))),
                       nudge_y = 300 + lim_level / 10,
                       size = 2.5, alpha = 0.8,
                       parse = FALSE) +
    theme_howmahico() +
    ggplot2::scale_y_continuous(limits = c(0, lim_level), 
                                # breaks = seq(0, lim_level, 5000),
                                # labels = scales::label_number(suffix = " k", scale = 1e-3)
                                n.breaks = 5) +
    ggplot2::ylab(paste0("Nb ", level)) +
    ggplot2::xlab(x_var) +
    ggpubr::rotate_x_text(70) +
    ggplot2::labs(fill = "Length") +
    ggplot2::theme(legend.position = "right") +
    ggplot2::ggtitle(paste0("Unique ", level, " (total, comparing lengths)"))
  if (!is.null(palette)) {
    p <- p + ggplot2::scale_fill_manual(values = palette)
  } else {
    p <- p + ggplot2::scale_fill_viridis_d(end = 1)
  }
  p
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
#'
#' @examples
#' \dontrun{
#' plot_venn4(pep_all, "Sequence", "Condition")
#' }
#' @keywords internal
plot_venn4 <- function(input, variable, group){
  output <- input |>
    dplyr::arrange(variable) |>
    (\(d) with(d, split(get(variable), get(group))))() |>
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
#' @export
#'
#' @examples
#' \dontrun{
#' plot_upset(pep_all, Sequence, n_intersections = 10, Compare = "Condition")
#' }
plot_upset <- 
  function(df, vars, n_intersections = 10, Compare = "Condition", labels = "perc", lab.size = 2, 
             plot.margin = ggplot2::unit(c(0.2,0.2,0.2,0.2), "cm")){
  ## prepare data
  df[, "Compare"] <- df[, Compare]
  df_distinct <- df |>
    dplyr::distinct(Compare, {{ vars }}, .keep_all = FALSE)
  df_distinct_total <- df_distinct |> dplyr::pull({{ vars }}) |> dplyr::n_distinct()
  ## plot
  upset_table <- df_distinct |>
    dplyr::group_by({{ vars }}) |>
    dplyr::summarize(Compare = list(as.character(Compare)), .groups = "drop")
  p_upset <- upset_table |>
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
#' @export
#'
#' @examples
#' \dontrun{
#' plot_upset_batch(pep_all, c("Peptide", "Sequence", "Accession"), Compare = "Condition")
#' }
plot_upset_batch <-   function(df, vars, n_intersections = 20, Compare = "Condition", labels = "perc", lab.size = 2,
           plot.margin = ggplot2::unit(c(0.2,0.2,0.2,0.2), "cm")){
  output <-
    lapply(vars, function(x){
      df |>
        dplyr::select(var = dplyr::all_of(x), dplyr::all_of(Compare)) |>
        unique() |>
        droplevels() |>
        plot_upset(var, n_intersections = n_intersections, Compare = Compare,
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
#' @export
#'
#' @examples
#' \dontrun{
#' ggseqlogo_bylength(pep_short, seq_length = 9, by = "Condition")
#' }
ggseqlogo_bylength <- function(input, seq_length, by, ...){
  ## Get sequences and groups
  input_filtered <- input |>
    dplyr::filter(Length == seq_length) |>
    dplyr::select(dplyr::all_of(by), Sequence) |>
    unique() |> droplevels()
  ## Check if some groups were droped due to not having sequences
  by_input <- input |> dplyr::pull(by) |> unique()
  by_input_filtered <- input_filtered |> dplyr::pull(by) |> unique()
  if(length(by_input) != length(by_input_filtered)){
    print(paste0("The following groups were droped because no Sequence with Length = ", seq_length, " was found: ", paste(by_input[!by_input %in% by_input_filtered]), "\n", collapse = ", "))

  }
  ## Get in list format
  input_filtered_list <- lapply(split(input_filtered[-1], input_filtered[, by]), function(x) x[x != ""])
  ## plot
  input_filtered_list |>
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
#'
#' @examples
#' \dontrun{
#' plot_heatmap(mat_log2area, annotation, level = "Sample", group = "Condition",
#'              file = file.path("4_figures", "hm_pep_all_log2area_br_nonscaled.png"))
#' }
#' @keywords internal
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
    annotation |>
    dplyr::select(dplyr::all_of(c(level, group))) |> dplyr::distinct() |>
    dplyr::mutate(Condition = as.integer(as.factor(get(group)))) |>
    tibble::column_to_rownames(level) |>
    t()
  # get colors
  col1 <- viridis::magma(n_clust)
  col2 <- viridis::viridis(max(t(gr.col)))

  grDevices::png(filename = file, width = width, height = height, units = units, res = res)
  par(oma = c(4, 2, 2, 2))
  gplots::heatmap.2(mat, hclustfun = hclustfunc, distfun = distfunc,
                    col = palette_hm, trace = "none",
                    RowSideColors = col1[gr.row], ColSideColors = col2[gr.col], keysize = keysize, ...)
  grDevices::dev.off()
  message("Heatmap saved in ", file)

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
#' @param palette Optional named character vector mapping `Length_range` values
#'   to fill colours. When `NULL` (default) `scale_fill_viridis_d()` is used.
#' @param x_var Name of the column to map to the x-axis. Default `"Condition"`;
#'   pass `"Sample"` for the sample-level proportion plot.
#'
#' @return A ggplot2 stacked bar chart.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_prop_length_condition(count_ids_condition_bylengthrange(pep_all))
#' plot_prop_length_condition(count_ids_condition_bylengthrange(pep_all, "Sample"),
#'                            x_var = "Sample")
#' }
plot_prop_length_condition <- function(input, level2plot = "Peptides", label_size = 3,
                                        palette = NULL, x_var = "Condition"){
  p <- input |>
    dplyr::filter(Length_range != "All peptides",
                  Level == level2plot) |>
    droplevels() |>
    ggplot2::ggplot(ggplot2::aes(x = .data[[x_var]], y = Proportion, group = Length_range)) +
    ggplot2::geom_bar(stat = "identity",
                      ggplot2::aes(fill = Length_range),
                      position = ggplot2::position_stack(),
                      alpha = 0.5, 
                      color = "black") +
    ggplot2::geom_text(ggplot2::aes(label = Percentage, y = CumProportion - 0.015), size = label_size) +
    theme_howmahico() +
    ggplot2::scale_y_continuous(breaks = seq(0, 1, 0.25), labels = c("0", "", "50", "", "100"), limits = c(0, 1.02)) +
    ggplot2::labs(fill = "Length") +
    ggplot2::xlab(x_var) +
    ggplot2::ylab("% Peptides") +
    ggplot2::theme(legend.position = "right") +
    ggplot2::guides(fill = ggplot2::guide_legend(override.aes = list(size = 0.3)))
  if (!is.null(palette)) {
    p <- p + ggplot2::scale_fill_manual(values = scales::alpha(palette, 1))
  } else {
    p <- p + ggplot2::scale_fill_viridis_d(end = 1, alpha = 0.5)
  }
  p
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
#' @export
#'
#' @examples
#' \dontrun{
#' plot_charge_proportions(get_proportion_charge(counts_charge_condition), Condition)
#' }
plot_charge_proportions <- function(input, variable, label_size = 3){
  input |>
    dplyr::filter(Charge_group != "Total",
                  Level == "Peptides") |>
    droplevels() |>
    dplyr::arrange(Charge_group) |>
    dplyr::mutate(PositionProp = dplyr::case_when(Charge_group == "+ 1" ~ CumProportion - 0.02,
                                                   Charge_group == "+ 2" ~ CumProportion * 0.9,
                                                   TRUE ~ CumProportion * 0.9)) |>
    ggplot2::ggplot(ggplot2::aes(x = {{ variable }}, y = Proportion, fill = Charge_group, group = Charge_group)) +
    ggplot2::geom_bar(stat = "identity", alpha = 0.5, color = "black") +
    ggplot2::geom_text(ggplot2::aes(label = Percentage, y = Proportion),
                       size = label_size, position = ggplot2::position_stack(vjust = 0.8)) +
    ggplot2::scale_y_continuous(breaks = seq(0, 2, 0.25), labels = c("0", "", "50", "", "100", "", "150", "", "200")) + # removed since for fragpipe total may be 100%, due to multiple charges assigned
    theme_howmahico() +
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
#' @export
#'
#' @examples
#' \dontrun{
#' plot_violin_areacv(summarise_area(pep_all, Condition), Condition)
#' }
plot_violin_areacv <- function(input, by, label_size = 3){
  ## get ylim
  cv_ylim <- ceiling(max(input$Area_CV, na.rm = TRUE) * 12) / 10
  ## plot
  input |>
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
    theme_howmahico() +
    ggplot2::scale_fill_viridis_d(begin = 0, end = 1) +
    ggpubr::rotate_x_text(70)
}

#' Peptide ID pseudochromatogram: count vs RT, faceted by Condition
#'
#' Bars are coloured by their own peptide count (a density gradient), so dense
#' RT regions stand out within each Condition facet.
#'
#' @param input A `pep_all`-shaped data frame with `RT`, `Peptide`, `Condition`.
#' @param title Plot title string.
#' @param ncol Number of facet columns.
#'
#' @return A ggplot2 bar chart.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_pseudochromatogram(pep_all, "All peptides identified", ncol = 3)
#' }
plot_pseudochromatogram <- function(input, title, ncol = 3) {
  input |>
    dplyr::mutate(RT = round(RT, 0)) |>
    dplyr::group_by(Condition, RT) |>
    dplyr::summarise(Count = dplyr::n_distinct(Peptide), .groups = "drop") |>
    ggplot2::ggplot(ggplot2::aes(x = RT, y = Count, fill = Count)) +
    ggplot2::geom_bar(stat = "identity") +
    ggplot2::ylab("Peptides") +
    ggplot2::xlab("RT (min)") +
    ggplot2::ggtitle(title) +
    theme_howmahico() +
    ggplot2::facet_wrap(~Condition, ncol = ncol) +
    ggplot2::scale_fill_viridis_c(name = "Peptides")
}

#' Peptide ID pseudomobilogram: count vs 1/k0, faceted by Condition
#'
#' Ion-mobility analogue of [plot_pseudochromatogram()]: bins peptides by their
#' `invk0` (1/k0) value and plots the per-bin peptide count, coloured by count
#' (a density gradient), faceted by Condition.
#'
#' @param input A `pep_all`-shaped data frame with `invk0`, `Peptide`,
#'   `Condition`.
#' @param title Plot title string.
#' @param ncol Number of facet columns.
#' @param binwidth 1/k0 bin width. Default `0.2`.
#'
#' @return A ggplot2 bar chart.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_pseudomobilogram(pep_all, "All peptides identified", ncol = 3)
#' }
plot_pseudomobilogram <- function(input, title, ncol = 3, binwidth = 0.2) {
  input |>
    dplyr::mutate(invk0_bin = floor(invk0 / binwidth) * binwidth) |>
    dplyr::group_by(Condition, invk0_bin) |>
    dplyr::summarise(Count = dplyr::n_distinct(Peptide), .groups = "drop") |>
    ggplot2::ggplot(ggplot2::aes(x = invk0_bin, y = Count, fill = Count)) +
    ggplot2::geom_col(width = binwidth) +
    ggplot2::ylab("Peptides") +
    ggplot2::xlab("1/k0") +
    ggplot2::ggtitle(title) +
    theme_howmahico() +
    ggplot2::facet_wrap(~Condition, ncol = ncol) +
    ggplot2::scale_fill_viridis_c(name = "Peptides")
}

#' 2D binned heatmap for any two continuous peptide properties
#'
#' @param input A `pep_all`-shaped data frame.
#' @param x_var,y_var Column names (strings) for the x and y axes.
#' @param binwidth Length-2 numeric `c(x_width, y_width)` passed to
#'   [ggplot2::geom_bin_2d()].
#' @param title Plot title string.
#' @param x_lab,y_lab Axis labels; default to `x_var`/`y_var`.
#' @param ncol Number of facet columns.
#'
#' @return A ggplot2 heatmap.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_2d_distribution(pep_all, "m_z", "invk0", c(10, 0.025), "All peptides",
#'                      x_lab = "m/z", y_lab = "1/k0", ncol = 3)
#' }
plot_2d_distribution <- function(input, x_var, y_var, binwidth, title,
                                 x_lab = x_var, y_lab = y_var, ncol = 3) {
  ggplot2::ggplot(input, ggplot2::aes(x = .data[[x_var]], y = .data[[y_var]])) +
    ggplot2::geom_bin_2d(binwidth = binwidth) +
    ggplot2::scale_fill_viridis_c(option = "plasma") +
    ggplot2::ylab(y_lab) +
    ggplot2::xlab(x_lab) +
    ggplot2::ggtitle(title) +
    theme_howmahico() +
    ggplot2::facet_wrap(~Condition, ncol = ncol) +
    ggplot2::scale_color_viridis_d()
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

  mat |>
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
#' @param group_var Name of the column mapped to the x-axis (and fill), across
#'   which the mean ± SD is computed. Default `"Condition"` (mean across the
#'   replicate samples per Condition); pass `"BioReplicate"` for a per-
#'   BioReplicate variant (mean across the TechReplicate samples per
#'   BioReplicate).
#'
#' @return A `ggpubr` barplot with mean ± SD error bars and viridis fill.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_count_mean_sd(counts_size, "Peptides", lim_level = 30000)
#' plot_count_mean_sd(counts_size, "Peptides", 30000, group_var = "BioReplicate")
#' }
plot_count_mean_sd <- function(df, level, lim_level, group_var = "Condition") {
  nlevel <- paste0("n_", level)
  df |>
    dplyr::filter(Length_range != "others") |>
    droplevels() |>
    ggpubr::ggbarplot(x = group_var, y = nlevel, fill = group_var,
                      facet.by = "Length_range", add = "mean_sd", scales = "free_x",
                      label = TRUE, alpha = 0.5,
                      lab.vjust = -2, lab.nb.digits = 0, lab.size = 2.5, nrow = 2) +
    theme_howmahico() +
    ggplot2::scale_y_continuous(limits = c(0, lim_level),
                                # breaks = seq(0, lim_level, 5000),
                                # labels = scales::label_number(suffix = " k", scale = 1e-3)
                                n.breaks = 5) +
    ggplot2::ylab(paste0("Nb ", level)) +
    ggplot2::xlab(group_var) +
    ggpubr::rotate_x_text(70) +
    ggplot2::labs(fill = group_var) +
    ggplot2::scale_fill_viridis_d(end = 1) +
    ggplot2::theme(legend.position = "none") +
    ggplot2::ggtitle(paste0("Unique ", level, " (mean +/- sd)"))
}

#' Overlap barplot for one ID level
#'
#' Builds a barplot showing how many IDs were detected in 1, 2, 3, …
#' replicates per Condition, for a single `pep_all`-shaped data frame. Works for
#' Peptides, Sequences, or Proteins by dispatching on `id_col`. Call it once per
#' length subset (e.g. all peptides, then length-selected peptides) to get an
#' individual plot for each.
#'
#' @param df A `pep_all`-shaped data frame (e.g. `pep_all`, or the
#'   length-filtered `pep_short`).
#' @param id_col Column defining the ID level: `"Peptide"`, `"Sequence"`, or
#'   `"Accession"`.
#' @param title Plot title. When `NULL` (default), a generic id-based label
#'   (`"Nb Peptides"` etc.) is used.
#' @param shortpep_range Length-2 numeric vector `c(min, max)`; retained for API
#'   compatibility (no longer used to build a subtitle now that all/short are
#'   plotted separately).
#' @param value Y-axis mode: `"count"` (default, absolute number of IDs) or
#'   `"percent"` (the share of each Condition's IDs found in 1, 2, … replicates,
#'   stacked to 100%).
#'
#' @return A ggplot2 barplot of IDs by number of replicates, per Condition.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_overlap_intra_condition(pep_all, "Peptide", title = "All Peptides")
#' plot_overlap_intra_condition(pep_short, "Accession")
#' plot_overlap_intra_condition(pep_all, "Peptide", value = "percent")
#' }
plot_overlap_intra_condition <- function(df, id_col, title = NULL,
                                         shortpep_range = c(8, 13),
                                         value = c("count", "percent")) {
  value <- match.arg(value)
  n_col  <- dplyr::case_when(id_col == "Peptide"   ~ "n_Peptides",
                              id_col == "Sequence"  ~ "n_Sequences",
                              id_col == "Accession" ~ "n_Accessions")
  ylabel <- dplyr::case_when(id_col == "Peptide"   ~ "Nb Peptides",
                              id_col == "Sequence"  ~ "Nb Sequences",
                              id_col == "Accession" ~ "Nb Proteins")
  if (is.null(title)) title <- ylabel
  nudge <- if (id_col == "Accession") 200 else 300
  tot_col <- paste0("total_", sub("n_", "", n_col))

  df_ov <- df |>
    dplyr::select(Condition, Sample, dplyr::all_of(id_col)) |>
    unique() |>
    dplyr::group_by(Condition, .data[[id_col]]) |>
    dplyr::summarize(n_Samples = dplyr::n_distinct(Sample), .groups = "drop") |>
    dplyr::group_by(Condition, n_Samples) |>
    dplyr::summarize(n_ids = dplyr::n_distinct(.data[[id_col]]), .groups = "drop") |>
    dplyr::rename_with(.fn = ~n_col, .cols = "n_ids") |>
    dplyr::mutate(n_Samples = as.factor(n_Samples)) |>
    dplyr::arrange(Condition, dplyr::desc(n_Samples)) |>
    dplyr::group_by(Condition) |>
    dplyr::mutate(
      tot_val  = sum(.data[[n_col]]),
      perc     = paste0(round(100 * .data[[n_col]] / sum(.data[[n_col]]), 1), "%"),
      perc_num = 100 * .data[[n_col]] / sum(.data[[n_col]]),
      cum      = cumsum(.data[[n_col]]),
      cum_perc = cumsum(perc_num)) |>
    dplyr::rename_with(.fn = ~tot_col, .cols = "tot_val")

  if (value == "percent") {
    df_ov |>
      ggpubr::ggbarplot(x = "Condition", y = "perc_num", fill = "n_Samples",
                        label = FALSE, lab.pos = "in",
                        lab.nb.digits = 0, lab.size = 2.5, alpha = 0.5) +
      ggplot2::geom_text(ggplot2::aes(y = .data[["cum_perc"]], label = .data[["perc"]]),
                         size = 2.5, nudge_y = -3) +
      theme_howmahico() +
      ggplot2::ylab(sub("^Nb ", "% ", ylabel)) +
      ggplot2::xlab("Condition") +
      ggpubr::rotate_x_text(70) +
      ggplot2::scale_y_continuous(limits = c(0, 100), n.breaks = 5) +
      ggplot2::scale_fill_viridis_d(begin = 0.2, end = 0.8, name = "ID in n Replicates") +
      ggplot2::ggtitle(title)
  } else {
    ylim_ov <- ceiling(max(df_ov[[tot_col]]) * 1.2 / 100) * 100
    df_ov |>
      ggpubr::ggbarplot(x = "Condition", y = n_col, fill = "n_Samples",
                        label = FALSE, lab.pos = "in",
                        lab.nb.digits = 0, lab.size = 2.5, alpha = 0.5) +
      ggplot2::geom_text(ggplot2::aes(y = .data[["cum"]], label = .data[["perc"]]),
                         size = 2.5, nudge_y = -nudge) +
      ggplot2::geom_text(ggplot2::aes(y = .data[[tot_col]], label = .data[[tot_col]]),
                         size = 2.5, nudge_y = nudge) +
      theme_howmahico() +
      ggplot2::ylab(ylabel) +
      ggplot2::xlab("Condition") +
      ggpubr::rotate_x_text(70) +
      ggplot2::scale_y_continuous(limits = c(0, ylim_ov), n.breaks = 5) +
      ggplot2::scale_fill_viridis_d(begin = 0.2, end = 0.8, name = "ID in n Replicates") +
      ggplot2::ggtitle(title)
  }
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
#' @export
#'
#' @examples
#' \dontrun{
#' plot_qc_violin(pep_all, "Score", "Score distribution, and boxplot")
#' plot_qc_violin(pep_all, "ppm",   "Mass error distribution, and boxplot")
#' }
plot_qc_violin <- function(df, y_var, title) {
  df |>
    dplyr::mutate(ChargeSimple = as.factor(
      dplyr::case_when(Charge == "+ 1" ~ "+ 1", TRUE ~ ">= +2"))) |>
    ggpubr::ggviolin(x = "Condition", y = y_var, fill = "Condition",
                     facet.by = "ChargeSimple", nrow = 2) +
    ggplot2::geom_boxplot(fill = NA, outlier.shape = NA, width = 0.5) +
    ggplot2::stat_boxplot(geom = "errorbar", width = 0.5) +
    ggplot2::ggtitle(title) +
    theme_howmahico() +
    ggplot2::theme(legend.position = "none") +
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
#' @export
#'
#' @examples
#' \dontrun{
#' plot_qc_box(pep_all, "Score", "Score boxplot")
#' plot_qc_box(pep_all, "ppm",   "Mass error boxplot")
#' }
plot_qc_box <- function(df, y_var, title) {
  df |>
    dplyr::mutate(ChargeSimple = as.factor(
      dplyr::case_when(Charge == "+ 1" ~ "+ 1", TRUE ~ ">= +2"))) |>
    ggpubr::ggboxplot(x = "Condition", y = y_var, color = "Condition",
                      facet.by = "ChargeSimple", nrow = 2) +
    ggplot2::stat_boxplot(geom = "errorbar", width = 0.5) +
    ggplot2::ggtitle(title) +
    theme_howmahico() +
    ggplot2::theme(legend.position = "none") +
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
#' @param translate Translate the PTM tokens to readable modification names via
#'   [translate_ptm()] (default `TRUE`). The raw tokens are engine-specific —
#'   UniMod accessions for DIA-NN, delta masses for FragPipe and PEAKS — so
#'   without this the same modification reads differently per engine. Set
#'   `FALSE` to plot the tokens as the search engine wrote them.
#' @param reference Modification lookup table passed to [translate_ptm()];
#'   defaults to [ptm_reference()]. Ignored when `translate = FALSE`.
#'
#' @return A ggplot2 tile heatmap.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_ptm_heatmap(pep_short, type = "count")
#' plot_ptm_heatmap(pep_short, type = "proportion", shortpep_range = c(8, 13))
#' plot_ptm_heatmap(pep_short, translate = FALSE)   # raw engine tokens
#' }
plot_ptm_heatmap <- function(pep_short, type = c("count", "proportion"),
                              shortpep_range = c(8, 13), translate = TRUE,
                              reference = ptm_reference()) {
  type <- match.arg(type)

  pep_short_ptm <-
    pep_short |>
    dplyr::filter(PTM != "") |>
    dplyr::mutate(PTM = gsub(" ", "", PTM)) |>
    tidyr::separate_rows(PTM, sep = ";|,") |>
    dplyr::mutate(PTM = trimws(PTM, "left", "[0-9]+"))

  # Translate once here, where the multi-PTM strings are already split into one
  # token per row, so both the count and the proportion branch below inherit it.
  if (translate)
    pep_short_ptm <- pep_short_ptm |>
      dplyr::mutate(PTM = translate_ptm(PTM, reference = reference))

  count_df <-
    pep_short_ptm |>
    tidyr::separate_rows(PTM, sep = ";|,") |>
    dplyr::group_by(Condition, PTM) |>
    dplyr::summarise(n_Peptides  = dplyr::n_distinct(Peptide),
                     n_Sequences = dplyr::n_distinct(Sequence),
                     n_Proteins  = dplyr::n_distinct(Accession),
                     SumArea     = sum(Area, na.rm = TRUE),
                     .groups = "drop") |>
    tidyr::complete(PTM, Condition) |>
    dplyr::mutate(dplyr::across(where(is.numeric), ~ifelse(is.na(.x), 0, .x)))

  if (type == "count") {
    count_df |>
      ggplot2::ggplot(ggplot2::aes(y = PTM, x = Condition, fill = n_Peptides)) +
      ggplot2::geom_tile() +
      ggplot2::geom_text(ggplot2::aes(label = n_Peptides)) +
      viridis::scale_fill_viridis(alpha = 0.9, option = "D", begin = 0.1) +
      theme_howmahico() +
      ggpubr::rotate_x_text(35) +
      ggplot2::ggtitle("PTM profile, counts of modified peptides")
  } else {
    totals_df <-
      pep_short |>
      dplyr::group_by(Condition) |>
      dplyr::summarise(n_Peptides = dplyr::n_distinct(Peptide), .groups = "drop") |>
      dplyr::mutate(PTM = "Total")

    count_df |>
      dplyr::select(PTM, Condition, n_Peptides) |>
      dplyr::bind_rows(totals_df) |>
      dplyr::group_by(Condition) |>
      dplyr::mutate(prop_Peptides = round(n_Peptides / n_Peptides[PTM == "Total"], 4)) |>
      dplyr::mutate(perc_Peptides = .data[["prop_Peptides"]] * 100) |>
      dplyr::filter(PTM != "Total") |>
      droplevels() |>
      ggplot2::ggplot(ggplot2::aes(y = PTM, x = Condition, fill = .data[["perc_Peptides"]])) +
      ggplot2::geom_tile() +
      ggplot2::geom_text(ggplot2::aes(label = paste0(.data[["perc_Peptides"]], "%")), size = 2.5) +
      viridis::scale_fill_viridis(alpha = 0.9, option = "D", begin = 0.1) +
      theme_howmahico() +
      ggpubr::rotate_x_text(35) +
      ggplot2::ggtitle("PTM profile, proportion of modified peptides vs total")
  }
}

#' Traffic-light heatmap of per-sample quality sub-scores
#'
#' Renders the `score_<metric>` columns of a [score_sample_quality()] table as a
#' samples × metrics tile heatmap, filled on a red→amber→green 0–100 gradient and
#' annotated with the rounded sub-score. Metric rows are labelled with their
#' human-readable names and QC samples are marked with a trailing asterisk.
#'
#' @param scores Output of [score_sample_quality()].
#' @param thresholds Scoring table used to label/order the metric rows (default
#'   [quality_thresholds_default()]).
#'
#' @return A ggplot2 tile heatmap.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_quality_heatmap(score_sample_quality(pep_all, c(8, 13), "MHC1"))
#' }
plot_quality_heatmap <- function(scores, thresholds = quality_thresholds_default()) {
  score_metrics <- thresholds$metric[paste0("score_", thresholds$metric) %in% names(scores)]
  labels <- stats::setNames(thresholds$label, thresholds$metric)[score_metrics]

  long <- scores |>
    dplyr::mutate(Sample = ifelse(.data[["is_QC"]],
                                  paste0(as.character(Sample), " *"),
                                  as.character(Sample))) |>
    dplyr::select(Sample, dplyr::all_of(paste0("score_", score_metrics))) |>
    tidyr::pivot_longer(cols = -Sample, names_to = "metric", values_to = "score",
                        names_prefix = "score_") |>
    dplyr::mutate(
      Sample = factor(Sample, levels = unique(Sample)),
      Metric = factor(labels[metric], levels = rev(unname(labels))))

  ggplot2::ggplot(long, ggplot2::aes(x = Sample, y = Metric, fill = score)) +
    ggplot2::geom_tile(color = "white") +
    ggplot2::geom_text(ggplot2::aes(label = ifelse(is.na(score), "NA", round(score))),
                       size = 2.5) +
    ggplot2::scale_fill_gradientn(colours = c("#d7191c", "#fdae61", "#1a9641"),
                                  limits = c(0, 100), na.value = "grey85",
                                  name = "Score") +
    ggplot2::xlab("Sample") + ggplot2::ylab(NULL) +
    theme_howmahico() +
    ggpubr::rotate_x_text(70) +
    ggplot2::ggtitle("Quality sub-scores (0-100)")
}

#' Per-sample composite quality-score bar chart
#'
#' Plots the `composite_score` of a [score_sample_quality()] table as a bar per
#' sample, coloured by traffic-light `category` (Pass/Warning/Fail), with dashed
#' reference lines at the 70 (Pass) and 40 (Warning) cut-offs. QC samples are
#' marked with a trailing asterisk.
#'
#' @param scores Output of [score_sample_quality()].
#'
#' @return A ggplot2 bar chart.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_quality_composite(score_sample_quality(pep_all, c(8, 13), "MHC1"))
#' }
plot_quality_composite <- function(scores) {
  cat_colors <- c(Pass = "#1a9641", Warning = "#fdae61", Fail = "#d7191c")
  df <- scores |>
    dplyr::mutate(Sample = ifelse(.data[["is_QC"]],
                                  paste0(as.character(Sample), " *"),
                                  as.character(Sample))) |>
    dplyr::arrange(dplyr::desc(.data[["composite_score"]])) |>
    dplyr::mutate(Sample = factor(Sample, levels = Sample))

  ggplot2::ggplot(df, ggplot2::aes(x = Sample, y = .data[["composite_score"]],
                                   fill = .data[["category"]])) +
    ggplot2::geom_col(alpha = 0.85, color = "black", linewidth = 0.2) +
    ggplot2::geom_text(ggplot2::aes(label = .data[["composite_score"]]),
                       vjust = -0.4, size = 2.5) +
    ggplot2::geom_hline(yintercept = 70, linetype = "dashed", alpha = 0.5) +
    ggplot2::geom_hline(yintercept = 40, linetype = "dotted", alpha = 0.5) +
    ggplot2::scale_fill_manual(values = cat_colors, drop = FALSE, name = "Category") +
    ggplot2::scale_y_continuous(limits = c(0, 105), n.breaks = 6) +
    ggplot2::xlab("Sample") + ggplot2::ylab("Composite score") +
    theme_howmahico() +
    ggpubr::rotate_x_text(70) +
    ggplot2::ggtitle("Composite quality score per sample")
}

#' Per-sample peptide-length histogram highlighting cross-class contamination
#'
#' Faceted (by `Sample`) count histogram of distinct-peptide lengths, with each
#' length bar coloured by region: the current class's expected window, the
#' **cross-class** region (the other MHC class's length range falling outside the
#' current window — i.e. MHC-II ligands contaminating an MHC-I pulldown, or vice
#' versa), and everything else. Visualises the `frac_cross_class` metric of
#' [score_sample_quality()]. For a custom length window (MHCclass neither `"MHC1"`
#' nor `"MHC2"`) the cross-class region is undefined and an informative empty plot
#' is returned.
#'
#' @param pep_all A unified `pep_all` data frame with `Sample`, `Peptide`,
#'   `Length`.
#' @param shortpep_range Length-2 numeric `c(min, max)` — the current class's
#'   expected ligand-length window.
#' @param mhcclass `"MHC1"` or `"MHC2"`.
#'
#' @return A ggplot2 faceted histogram.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_cross_class_length(pep_all, shortpep_range = c(8, 13), mhcclass = "MHC1")
#' }
plot_cross_class_length <- function(pep_all, shortpep_range = c(8, 13), mhcclass = "MHC1") {
  cross_rng <- .cross_class_range(mhcclass, shortpep_range)
  if (is.null(cross_rng)) {
    return(
      ggplot2::ggplot() +
        ggplot2::annotate("text", x = 0, y = 0,
                          label = "Cross-class contamination is undefined\nfor a custom length window (MHCclass must be MHC1 or MHC2).") +
        ggplot2::theme_void()
    )
  }

  cur_lab <- paste0("Current (", shortpep_range[1], "-", shortpep_range[2], " AAs)")
  cross_lab <- paste0("Cross-class (", cross_rng[1], "-", cross_rng[2], " AAs)")
  region_levels <- c(cur_lab, cross_lab, "Other")

  df <- pep_all |>
    dplyr::distinct(Sample, Peptide, Length) |>
    dplyr::mutate(region = factor(dplyr::case_when(
      Length >= shortpep_range[1] & Length <= shortpep_range[2] ~ cur_lab,
      Length >= cross_rng[1] & Length <= cross_rng[2] ~ cross_lab,
      TRUE ~ "Other"), levels = region_levels)) |>
    dplyr::count(Sample, Length, region)

  region_colors <- stats::setNames(c("#2c7fb8", "#d7191c", "grey75"), region_levels)

  ggplot2::ggplot(df, ggplot2::aes(x = Length, y = n, fill = region)) +
    ggplot2::geom_col(color = "black", linewidth = 0.1, alpha = 0.85) +
    ggplot2::facet_wrap(~Sample, scales = "free_y") +
    ggplot2::scale_fill_manual(values = region_colors, drop = FALSE, name = "Length region") +
    ggplot2::scale_x_continuous(n.breaks = 8) +
    ggplot2::xlab("Peptide length (AAs)") + ggplot2::ylab("Unique peptides") +
    theme_howmahico() +
    ggplot2::ggtitle("Peptide length distribution and cross-class contamination")
}

# ---- quantitative-statistics plots (05_quant_stats) -------------------------

#' Data completeness of a quantitative matrix
#'
#' Two views of the missingness structure that governs every downstream test:
#' `type = "unit"` shows how many features are quantified in each unit (sample or
#' bioreplicate), `type = "feature"` how many units each feature is quantified in
#' — the distribution that the [filter_quant()] cut-off acts on.
#'
#' @param mat Numeric matrix from [build_quant_matrix()].
#' @param coldata Matching column metadata (`Unit`, `Condition`).
#' @param type `"unit"` (default) or `"feature"`.
#'
#' @return A ggplot object.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_completeness(qm$mat, qm$coldata, type = "unit")
#' }
plot_completeness <- function(mat, coldata, type = c("unit", "feature")) {
  type <- match.arg(type)

  if (type == "unit") {
    df <- data.frame(Unit = factor(colnames(mat), levels = colnames(mat)),
                     Count = as.integer(colSums(!is.na(mat))))
    df$Condition <- coldata$Condition[match(as.character(df$Unit), as.character(coldata$Unit))]
    return(
      ggplot2::ggplot(df, ggplot2::aes(x = Unit, y = Count, fill = Condition)) +
        ggplot2::geom_bar(stat = "identity", alpha = 0.8, color = "black") +
        ggplot2::geom_text(ggplot2::aes(label = Count), vjust = -0.4, size = 2.5) +
        ggplot2::scale_y_continuous(n.breaks = 5) +
        viridis::scale_fill_viridis(discrete = TRUE, end = 0.9) +
        ggplot2::xlab(NULL) + ggplot2::ylab("Quantified features") +
        theme_howmahico() + ggpubr::rotate_x_text(70) +
        ggplot2::ggtitle("Quantified features per unit")
    )
  }

  n_obs <- as.integer(rowSums(!is.na(mat)))
  df <- as.data.frame(table(factor(n_obs, levels = seq_len(ncol(mat)))))
  names(df) <- c("n_units", "Count")
  ggplot2::ggplot(df, ggplot2::aes(x = n_units, y = Count)) +
    ggplot2::geom_bar(stat = "identity", alpha = 0.8, color = "black", fill = "#440154") +
    ggplot2::geom_text(ggplot2::aes(label = Count), vjust = -0.4, size = 2.5) +
    ggplot2::scale_y_continuous(n.breaks = 5) +
    ggplot2::xlab("Units in which the feature is quantified") + ggplot2::ylab("Features") +
    theme_howmahico() +
    ggplot2::ggtitle("Feature completeness")
}

#' Presence/absence map of a quantitative matrix
#'
#' Tile map of quantified (dark) versus missing (light) values, features sorted by
#' completeness, so a block of condition-specific missingness is visible at a
#' glance and can be told apart from random dropout.
#'
#' @param mat Numeric matrix from [build_quant_matrix()].
#' @param coldata Matching column metadata (`Unit`, `Condition`).
#' @param max_features Maximum number of features drawn (the most complete ones
#'   are kept, with a note in the subtitle). Default `3000`.
#'
#' @return A ggplot object.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_missing_heatmap(qm$mat, qm$coldata)
#' }
plot_missing_heatmap <- function(mat, coldata, max_features = 3000) {
  ord <- order(rowSums(!is.na(mat)), decreasing = TRUE)
  subtitle <- NULL
  if (length(ord) > max_features) {
    subtitle <- paste0("showing the ", max_features, " most complete of ", nrow(mat), " features")
    ord <- ord[seq_len(max_features)]
  }
  sub_mat <- mat[ord, , drop = FALSE]

  df <- expand.grid(Feature = seq_len(nrow(sub_mat)),
                    Unit = factor(colnames(sub_mat), levels = colnames(sub_mat)))
  df$Detected <- ifelse(!is.na(as.vector(sub_mat)), "quantified", "missing")

  ggplot2::ggplot(df, ggplot2::aes(x = Unit, y = Feature, fill = Detected)) +
    ggplot2::geom_raster() +
    ggplot2::scale_fill_manual(values = c(quantified = "#440154", missing = "grey88")) +
    ggplot2::scale_y_reverse() +
    ggplot2::xlab(NULL) + ggplot2::ylab("Features (sorted by completeness)") +
    theme_howmahico() + ggpubr::rotate_x_text(70) +
    ggplot2::ggtitle("Presence / absence map", subtitle = subtitle)
}

#' Intensity distribution per unit (normalization diagnostic)
#'
#' Boxplots or densities of the log2 intensities of every unit. Comparing the
#' same plot before and after [normalize_quant()] is what makes the chosen
#' normalization auditable rather than a black box.
#'
#' @param mat Numeric matrix of log2 intensities.
#' @param coldata Matching column metadata (`Unit`, `Condition`).
#' @param type `"box"` (default) or `"density"`.
#' @param title Plot title. Default `NULL`.
#'
#' @return A ggplot object.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_intensity_dist(mat_n, qm$coldata, title = "After median normalization")
#' }
plot_intensity_dist <- function(mat, coldata, type = c("box", "density"), title = NULL) {
  type <- match.arg(type)
  df <- data.frame(Unit = factor(rep(colnames(mat), each = nrow(mat)), levels = colnames(mat)),
                   Log2Area = as.vector(mat))
  df <- df[!is.na(df$Log2Area), , drop = FALSE]
  df$Condition <- coldata$Condition[match(as.character(df$Unit), as.character(coldata$Unit))]

  p <- if (type == "box") {
    ggplot2::ggplot(df, ggplot2::aes(x = Unit, y = Log2Area, fill = Condition)) +
      ggplot2::geom_boxplot(alpha = 0.6, outlier.size = 0.3) +
      ggplot2::xlab(NULL) + ggplot2::ylab("log2(Area)") +
      ggpubr::rotate_x_text(70)
  } else {
    ggplot2::ggplot(df, ggplot2::aes(x = Log2Area, color = Unit, linetype = Condition)) +
      ggplot2::geom_density(na.rm = TRUE) +
      ggplot2::xlab("log2(Area)") + ggplot2::ylab("Density")
  }
  p +
    viridis::scale_fill_viridis(discrete = TRUE, end = 0.9) +
    viridis::scale_color_viridis(discrete = TRUE, end = 0.9) +
    theme_howmahico() +
    ggplot2::ggtitle(title)
}

#' Dynamic range (rank-abundance) per condition
#'
#' Mean log2 intensity of every feature within a condition, plotted against its
#' abundance rank. The span of the curve is the observed dynamic range, and its
#' end shows where the quantification runs into the detection limit — the region
#' in which missingness is left-censored rather than biological.
#'
#' @param mat Numeric matrix of log2 intensities.
#' @param coldata Matching column metadata (`Unit`, `Condition`).
#'
#' @return A ggplot object.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_dynamic_range(mat_n, qm$coldata)
#' }
plot_dynamic_range <- function(mat, coldata) {
  grp <- as.character(coldata$Condition)[match(colnames(mat), as.character(coldata$Unit))]
  df <- do.call(rbind, lapply(unique(grp), function(g) {
    v <- rowMeans(mat[, grp == g, drop = FALSE], na.rm = TRUE)
    v <- sort(v[is.finite(v)], decreasing = TRUE)
    if (length(v) == 0) return(NULL)
    data.frame(Condition = g, Rank = seq_along(v), Log2Area = unname(v))
  }))
  if (is.null(df) || nrow(df) == 0) return(NULL)
  df$Condition <- factor(df$Condition, levels = levels(coldata$Condition))

  ggplot2::ggplot(df, ggplot2::aes(x = Rank, y = Log2Area, color = Condition)) +
    ggplot2::geom_line(linewidth = 0.6) +
    viridis::scale_color_viridis(discrete = TRUE, end = 0.9) +
    ggplot2::scale_y_continuous(n.breaks = 6) +
    ggplot2::xlab("Abundance rank") + ggplot2::ylab("Mean log2(Area)") +
    theme_howmahico() +
    ggplot2::ggtitle("Dynamic range")
}

#' Principal component analysis of a quantitative matrix
#'
#' Unsupervised overview of the quantitative data: whether the units group by
#' condition at all, before any per-feature claim is made. The PCA runs on
#' complete features only (a rotation cannot be computed with missing values), so
#' the number of features used is reported in the subtitle.
#'
#' @param mat Numeric matrix of log2 intensities (optionally imputed).
#' @param coldata Matching column metadata (`Unit`, `Condition`).
#' @param type `"scores"` (default, PC1 vs PC2), `"scree"` (explained variance)
#'   or `"loadings"` (features contributing most to `pc`).
#' @param pc Principal components to display, length 2 for `"scores"`
#'   (default `c(1, 2)`); the first element selects the component for
#'   `"loadings"`.
#' @param n_loadings Number of features shown by `type = "loadings"`. Default `15`.
#'
#' @return A ggplot object, or `NULL` (with a warning) when fewer than two
#'   complete features or fewer than three units are available.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_pca(mat_n, qm$coldata)
#' }
plot_pca <- function(mat, coldata, type = c("scores", "scree", "loadings"),
                     pc = c(1, 2), n_loadings = 15) {
  type <- match.arg(type)
  complete <- mat[stats::complete.cases(mat), , drop = FALSE]
  if (nrow(complete) < 2 || ncol(complete) < 3) {
    warning("plot_pca(): not enough complete features or units for a PCA.", call. = FALSE)
    return(NULL)
  }
  pca <- stats::prcomp(t(complete), center = TRUE, scale. = FALSE)
  var_expl <- 100 * pca$sdev^2 / sum(pca$sdev^2)
  subtitle <- paste0(nrow(complete), " features quantified in every unit")

  if (type == "scree") {
    k <- min(10, length(var_expl))
    df <- data.frame(PC = factor(paste0("PC", seq_len(k)), levels = paste0("PC", seq_len(k))),
                     Variance = var_expl[seq_len(k)])
    return(
      ggplot2::ggplot(df, ggplot2::aes(x = PC, y = Variance)) +
        ggplot2::geom_bar(stat = "identity", alpha = 0.8, color = "black", fill = "#440154") +
        ggplot2::geom_text(ggplot2::aes(label = paste0(round(Variance, 1), "%")),
                           vjust = -0.4, size = 2.5) +
        ggplot2::xlab(NULL) + ggplot2::ylab("Explained variance (%)") +
        theme_howmahico() +
        ggplot2::ggtitle("PCA scree plot", subtitle = subtitle)
    )
  }

  if (type == "loadings") {
    load <- pca$rotation[, pc[1]]
    top <- utils::head(order(abs(load), decreasing = TRUE), n_loadings)
    df <- data.frame(Feature = factor(names(load)[top], levels = rev(names(load)[top])),
                     Loading = unname(load[top]))
    return(
      ggplot2::ggplot(df, ggplot2::aes(x = Loading, y = Feature, fill = Loading > 0)) +
        ggplot2::geom_bar(stat = "identity", alpha = 0.8, color = "black") +
        ggplot2::scale_fill_manual(values = c(`TRUE` = "#b2182b", `FALSE` = "#2166ac"),
                                   guide = "none") +
        ggplot2::xlab(paste0("PC", pc[1], " loading")) + ggplot2::ylab(NULL) +
        theme_howmahico() +
        ggplot2::ggtitle(paste0("Top ", n_loadings, " PC", pc[1], " loadings"), subtitle = subtitle)
    )
  }

  df <- data.frame(Unit = rownames(pca$x),
                   PCx = pca$x[, pc[1]], PCy = pca$x[, pc[2]])
  df$Condition <- coldata$Condition[match(df$Unit, as.character(coldata$Unit))]
  ggplot2::ggplot(df, ggplot2::aes(x = PCx, y = PCy, color = Condition, label = Unit)) +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::geom_text(vjust = -0.8, size = 2.5, show.legend = FALSE) +
    viridis::scale_color_viridis(discrete = TRUE, end = 0.9) +
    ggplot2::xlab(paste0("PC", pc[1], " (", round(var_expl[pc[1]], 1), "%)")) +
    ggplot2::ylab(paste0("PC", pc[2], " (", round(var_expl[pc[2]], 1), "%)")) +
    theme_howmahico() +
    ggplot2::ggtitle("PCA scores", subtitle = subtitle)
}

#' Heatmap of a quantitative matrix, clustered or in annotation order
#'
#' ggplot2 tile heatmap of the most variable features, drawn either with
#' hierarchical clustering of both dimensions (`cluster = TRUE`) or in the order
#' given by the annotation table (`cluster = FALSE`) — the two views answer
#' different questions: whether the data cluster by condition on their own, and
#' how the conditions look side by side as designed. Unlike [plot_heatmap()],
#' which writes a png through `gplots::heatmap.2`, this returns an object that
#' can be printed inside a knitted tabset.
#'
#' The clustered view makes the clustering visible rather than only using it to
#' order the tiles: the unit (column) dendrogram is drawn above a Condition
#' colour bar, the feature (row) dendrogram on the left, and the features are
#' cut into `n_clusters` groups ([stats::cutree()]), separated by white lines and
#' labelled `C1`, `C2`, ... from top to bottom. The feature-to-cluster
#' assignment is attached as `attr(p, "clusters")` so a report can export it.
#'
#' @param mat Numeric matrix of log2 intensities.
#' @param coldata Matching column metadata (`Unit`, `Condition`).
#' @param cluster Cluster rows and columns (`TRUE`, default) or keep the
#'   annotation order (`FALSE`).
#' @param top_n Number of most variable features to show. Default `500`.
#' @param center_rows Subtract the feature mean, so the colour encodes the log2
#'   ratio to the feature average rather than absolute abundance. Default `TRUE`.
#' @param n_clusters Number of feature clusters drawn in the clustered view
#'   (capped at the number of features). Default `4`.
#' @param title Plot title. Default `NULL` (auto-generated).
#'
#' @return For `cluster = FALSE` (or when clustering is not possible: fewer than
#'   three features or units), a ggplot object. For the clustered view, a
#'   `ggpubr::ggarrange()` composite (dendrogram + Condition bar over the
#'   heatmap) carrying `attr(, "clusters")`, a data frame with `Feature` and
#'   `Cluster` in display order. `NULL` (with a warning) when the matrix is
#'   empty.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' p <- plot_quant_heatmap(mat_n, qm$coldata, cluster = TRUE, top_n = 300)
#' head(attr(p, "clusters"))
#' }
plot_quant_heatmap <- function(mat, coldata, cluster = TRUE, top_n = 500,
                               center_rows = TRUE, n_clusters = 4, title = NULL) {
  if (nrow(mat) == 0 || ncol(mat) == 0) {
    warning("plot_quant_heatmap(): empty matrix.", call. = FALSE)
    return(NULL)
  }
  row_sd <- apply(mat, 1, stats::sd, na.rm = TRUE)
  keep <- utils::head(order(row_sd, decreasing = TRUE, na.last = NA), min(top_n, nrow(mat)))
  sub_mat <- mat[sort(keep), , drop = FALSE]
  if (center_rows)
    sub_mat <- sweep(sub_mat, 1, rowMeans(sub_mat, na.rm = TRUE), FUN = "-")

  lim <- suppressWarnings(max(abs(sub_mat), na.rm = TRUE))
  if (!is.finite(lim) || lim == 0) lim <- 1
  fill_scale <- ggplot2::scale_fill_gradientn(
    colours = rev(RColorBrewer::brewer.pal(11, "RdBu")),
    limits = c(-lim, lim), na.value = "grey88",
    name = if (center_rows) "log2 ratio\nto feature mean" else "log2(Area)")

  hr <- hc <- NULL
  if (cluster && nrow(sub_mat) > 2 && ncol(sub_mat) > 2) {
    # hclust cannot take NAs; fill them with the feature minimum for the
    # ordering only (the plotted values keep their NAs)
    filled <- sub_mat
    row_min <- suppressWarnings(apply(filled, 1, min, na.rm = TRUE))
    row_min[!is.finite(row_min)] <- 0
    filled[is.na(filled)] <- row_min[row(filled)[is.na(filled)]]
    hr <- tryCatch(stats::hclust(stats::dist(filled)), error = function(e) NULL)
    hc <- tryCatch(stats::hclust(stats::dist(t(filled))), error = function(e) NULL)
  }

  if (is.null(hr) || is.null(hc))
    return(.quant_heatmap_plain(sub_mat, fill_scale, center_rows,
                                title = if (is.null(title))
                                  paste0(if (cluster) "Clustered" else "Unclustered", " heatmap")
                                else title))

  .quant_heatmap_clustered(sub_mat, coldata, hr, hc, fill_scale,
                           n_clusters = n_clusters,
                           title = if (is.null(title)) "Clustered heatmap" else title)
}

# The unclustered (annotation-order) heatmap: one ggplot, so it stays
# convertible by ggplotly() when InteractivePlots is on.
.quant_heatmap_plain <- function(sub_mat, fill_scale, center_rows, title) {
  df <- expand.grid(Feature = rownames(sub_mat), Unit = colnames(sub_mat),
                    stringsAsFactors = FALSE)
  df$Value <- as.vector(sub_mat)
  df$Feature <- factor(df$Feature, levels = rownames(sub_mat))
  df$Unit <- factor(df$Unit, levels = colnames(sub_mat))

  ggplot2::ggplot(df, ggplot2::aes(x = Unit, y = Feature, fill = Value)) +
    ggplot2::geom_raster() +
    fill_scale +
    ggplot2::xlab(NULL) +
    ggplot2::ylab(paste0("Top ", nrow(sub_mat), " variable features")) +
    theme_howmahico() + ggpubr::rotate_x_text(70) +
    ggplot2::theme(axis.text.y = ggplot2::element_blank(),
                   axis.ticks.y = ggplot2::element_blank()) +
    ggplot2::ggtitle(title)
}

# Segment coordinates of an hclust dendrogram: leaves sit at 1..n in
# `hc$order` (height 0), each merge at the midpoint of its two children and at
# its merge height. Returns x, y, xend, yend (x = leaf axis, y = height).
.dendro_segments <- function(hc) {
  n <- length(hc$order)
  pos <- integer(n)
  pos[hc$order] <- seq_len(n)
  m <- hc$merge
  node_x <- numeric(nrow(m))
  node_y <- hc$height
  coord <- function(i) if (i < 0) c(pos[-i], 0) else c(node_x[i], node_y[i])
  segs <- vector("list", nrow(m))
  for (j in seq_len(nrow(m))) {
    a <- coord(m[j, 1])
    b <- coord(m[j, 2])
    h <- node_y[j]
    node_x[j] <- (a[1] + b[1]) / 2
    segs[[j]] <- data.frame(x = c(a[1], b[1], a[1]), y = c(a[2], b[2], h),
                            xend = c(a[1], b[1], b[1]), yend = c(h, h, h))
  }
  do.call(rbind, segs)
}

# The clustered heatmap: column dendrogram + Condition bar on top, row
# dendrogram + cluster bands inside the heatmap panel. Two plots are needed
# because the Condition bar and the value gradient both use the fill scale.
.quant_heatmap_clustered <- function(sub_mat, coldata, hr, hc, fill_scale,
                                     n_clusters, title) {
  nr <- nrow(sub_mat)
  nc <- ncol(sub_mat)
  # first feature of hr$order drawn at the top
  feature_order <- rownames(sub_mat)[hr$order]
  unit_order <- colnames(sub_mat)[hc$order]
  feature_y <- stats::setNames(rev(seq_len(nr)), feature_order)

  k <- max(1L, min(as.integer(n_clusters), nr))
  cl <- stats::cutree(hr, k = k)[feature_order]
  # renumber so C1 is the top block, C2 the next, ...
  cl_lab <- match(cl, unique(cl))
  clusters <- data.frame(Feature = feature_order,
                         Cluster = factor(paste0("C", cl_lab),
                                          levels = paste0("C", seq_len(k))),
                         stringsAsFactors = FALSE)

  # x layout shared by both panels: row dendrogram | tiles | cluster labels
  dend_w <- max(nc * 0.25, 0.8)
  gap <- max(nc * 0.02, 0.05)
  lab_w <- max(nc * 0.10, 0.6)
  x_lim <- c(0.5 - gap - dend_w, nc + 0.5 + lab_w)

  df <- expand.grid(Feature = rownames(sub_mat), Unit = colnames(sub_mat),
                    stringsAsFactors = FALSE)
  df$Value <- as.vector(sub_mat)
  df$x <- match(df$Unit, unit_order)
  df$y <- unname(feature_y[df$Feature])

  # row dendrogram: leaf position -> y, height -> leftwards x
  rseg <- .dendro_segments(hr)
  rmax <- max(c(rseg$y, rseg$yend), 1e-12)
  row_dend <- data.frame(
    x    = 0.5 - gap - rseg$y / rmax * dend_w,
    xend = 0.5 - gap - rseg$yend / rmax * dend_w,
    y    = nr + 1 - rseg$x,
    yend = nr + 1 - rseg$xend)

  # cluster bands: boundaries between runs + a label at each run's middle
  runs <- rle(cl_lab)
  ends <- cumsum(runs$lengths)
  starts <- ends - runs$lengths + 1
  bounds <- if (length(ends) > 1) nr - ends[-length(ends)] + 0.5 else numeric(0)
  lab_df <- data.frame(x = nc + 0.5 + lab_w * 0.15,
                       y = nr + 1 - (starts + ends) / 2,
                       label = paste0("C", runs$values))

  p_main <- ggplot2::ggplot(df, ggplot2::aes(x = x, y = y, fill = Value)) +
    ggplot2::geom_raster() +
    fill_scale +
    ggplot2::geom_segment(data = row_dend, inherit.aes = FALSE,
                          ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
                          linewidth = 0.2, colour = "grey30") +
    ggplot2::geom_text(data = lab_df, inherit.aes = FALSE,
                       ggplot2::aes(x = x, y = y, label = label),
                       hjust = 0, size = 3.2) +
    ggplot2::scale_x_continuous(breaks = seq_len(nc), labels = unit_order) +
    ggplot2::coord_cartesian(xlim = x_lim, ylim = c(0.5, nr + 0.5), expand = FALSE) +
    ggplot2::xlab(NULL) + ggplot2::ylab(NULL) +
    theme_howmahico() + ggpubr::rotate_x_text(70) +
    ggplot2::theme(axis.text.y = ggplot2::element_blank(),
                   axis.ticks.y = ggplot2::element_blank(),
                   axis.line = ggplot2::element_blank(),
                   panel.grid = ggplot2::element_blank(),
                   legend.position = "bottom",
                   plot.margin = ggplot2::margin(0, 5.5, 5.5, 5.5))
  if (length(bounds) > 0)
    p_main <- p_main +
      ggplot2::annotate("segment", x = 0.5, xend = nc + 0.5, y = bounds,
                        yend = bounds, colour = "white", linewidth = 0.8)

  # column dendrogram (y 1.15 .. 4) over the Condition bar (y 0 .. 1)
  cseg <- .dendro_segments(hc)
  cmax <- max(c(cseg$y, cseg$yend), 1e-12)
  col_dend <- data.frame(x = cseg$x, xend = cseg$xend,
                         y = 1.15 + cseg$y / cmax * 2.85,
                         yend = 1.15 + cseg$yend / cmax * 2.85)
  cond <- if (!is.null(coldata) && all(c("Unit", "Condition") %in% names(coldata)))
    as.character(coldata$Condition[match(unit_order, as.character(coldata$Unit))])
  else rep(NA_character_, nc)
  cond_levels <- if (!is.null(coldata) && "Condition" %in% names(coldata))
    unique(as.character(if (is.factor(coldata$Condition)) levels(coldata$Condition)
                        else coldata$Condition))
  else character(0)
  cond_levels <- intersect(cond_levels, cond)
  if (length(cond_levels) == 0) cond_levels <- unique(cond)
  bar_df <- data.frame(x = seq_len(nc), y = 0.5,
                       Condition = factor(cond, levels = cond_levels))

  p_top <- ggplot2::ggplot() +
    ggplot2::geom_tile(data = bar_df,
                       ggplot2::aes(x = x, y = y, fill = Condition),
                       height = 1, colour = "white", linewidth = 0.3) +
    ggplot2::geom_segment(data = col_dend,
                          ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
                          linewidth = 0.3, colour = "grey30") +
    viridis::scale_fill_viridis(discrete = TRUE, end = 0.9, name = NULL,
                                na.value = "grey70") +
    ggplot2::coord_cartesian(xlim = x_lim, ylim = c(0, 4.1), expand = FALSE) +
    ggplot2::theme_void() +
    ggplot2::theme(legend.position = "top",
                   plot.title = ggplot2::element_text(face = "bold", size = 14),
                   plot.margin = ggplot2::margin(5.5, 5.5, 0, 5.5)) +
    ggplot2::ggtitle(title,
                     subtitle = paste0("Top ", nr, " variable features, cut into ",
                                       k, " cluster", if (k > 1) "s" else "",
                                       " (C1 = top block)"))

  p <- ggpubr::ggarrange(p_top, p_main, ncol = 1, heights = c(0.3, 1),
                         align = "v")
  attr(p, "clusters") <- clusters
  p
}

#' Volcano plot of a differential-abundance result
#'
#' Standard volcano (log2 fold change against -log10 adjusted p-value) of one
#' contrast, with the condition-exclusive features from the presence/absence
#' track drawn as triangles at the plot margin: their fold change is undefined,
#' so they cannot sit on the x axis, but they are usually the most interesting
#' hits in an immunopeptidomics comparison and must stay visible.
#'
#' @param results Output of [combine_quant_results()], filtered to a single
#'   contrast (or containing several, in which case the plot is facetted).
#' @param fdr Adjusted p-value cut-off drawn as a horizontal line. Default `0.05`.
#' @param log2fc Absolute fold-change cut-off drawn as vertical lines. Default `1`.
#' @param title Plot title. Default `NULL` (the contrast name).
#'
#' @return A ggplot object.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_volcano(subset(results, Contrast == "TREAT_vs_CTRL"))
#' }
plot_volcano <- function(results, fdr = 0.05, log2fc = 1, title = NULL) {
  status_colors <- c(up = "#b2182b", down = "#2166ac", exclusive_up = "#d6604d",
                     exclusive_down = "#4393c3", ns = "grey70")
  quant <- results[!is.na(results$logFC) & !is.na(results$adj.P.Val), , drop = FALSE]
  excl  <- results[is.na(results$logFC) & !is.na(results$Exclusive_in), , drop = FALSE]

  x_max <- if (nrow(quant) > 0) max(abs(quant$logFC), na.rm = TRUE) else 1
  y_max <- if (nrow(quant) > 0) max(-log10(quant$adj.P.Val), na.rm = TRUE) else 1
  if (!is.finite(x_max) || x_max == 0) x_max <- 1
  if (!is.finite(y_max) || y_max == 0) y_max <- 1

  quant$x <- quant$logFC
  quant$y <- -log10(quant$adj.P.Val)
  p <- ggplot2::ggplot(quant, ggplot2::aes(x = x, y = y, color = Status)) +
    ggplot2::geom_point(size = 0.9, alpha = 0.7)

  if (nrow(excl) > 0) {
    excl$x <- ifelse(excl$Status == "exclusive_down", -x_max * 1.15, x_max * 1.15)
    excl$y <- pmin(-log10(pmax(excl$adj.P.Val_det, .Machine$double.xmin)), y_max * 1.05)
    excl$y[!is.finite(excl$y)] <- y_max * 1.05
    p <- p + ggplot2::geom_point(data = excl,
                                 ggplot2::aes(x = x, y = y, color = Status),
                                 shape = 17, size = 1.6, alpha = 0.8)
  }

  if (dplyr::n_distinct(results$Contrast) > 1)
    p <- p + ggplot2::facet_wrap(~ Contrast)

  p +
    ggplot2::geom_hline(yintercept = -log10(fdr), linetype = "dashed", color = "grey40") +
    ggplot2::geom_vline(xintercept = c(-log2fc, log2fc), linetype = "dashed", color = "grey40") +
    ggplot2::scale_color_manual(values = status_colors, drop = FALSE, name = NULL) +
    ggplot2::xlab("log2 fold change (test vs reference)") +
    ggplot2::ylab("-log10(adjusted p-value)") +
    theme_howmahico() +
    ggplot2::ggtitle(if (is.null(title)) unique(results$Contrast)[1] else title,
                     subtitle = if (nrow(excl) > 0)
                       "triangles at the margins: detected in one condition only (Fisher test)" else NULL)
}

#' MA plot of a differential-abundance result
#'
#' Fold change against average abundance — the diagnostic that shows whether the
#' fold changes are intensity-dependent, i.e. whether the normalization did its
#' job.
#'
#' @param results Output of [combine_quant_results()] (one or several contrasts).
#' @param log2fc Absolute fold-change cut-off drawn as horizontal lines.
#'   Default `1`.
#' @param title Plot title. Default `NULL` (the contrast name).
#'
#' @return A ggplot object.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_ma(subset(results, Contrast == "TREAT_vs_CTRL"))
#' }
plot_ma <- function(results, log2fc = 1, title = NULL) {
  status_colors <- c(up = "#b2182b", down = "#2166ac", exclusive_up = "#d6604d",
                     exclusive_down = "#4393c3", ns = "grey70")
  df <- results[!is.na(results$logFC) & !is.na(results$AveExpr), , drop = FALSE]

  p <- ggplot2::ggplot(df, ggplot2::aes(x = AveExpr, y = logFC, color = Status)) +
    ggplot2::geom_point(size = 0.9, alpha = 0.7) +
    ggplot2::geom_hline(yintercept = 0, color = "grey40") +
    ggplot2::geom_hline(yintercept = c(-log2fc, log2fc), linetype = "dashed", color = "grey40")
  if (dplyr::n_distinct(df$Contrast) > 1) p <- p + ggplot2::facet_wrap(~ Contrast)

  p +
    ggplot2::scale_color_manual(values = status_colors, drop = FALSE, name = NULL) +
    ggplot2::xlab("Average log2(Area)") + ggplot2::ylab("log2 fold change") +
    theme_howmahico() +
    ggplot2::ggtitle(if (is.null(title)) unique(df$Contrast)[1] else title)
}

#' P-value histogram (test calibration diagnostic)
#'
#' Histogram of the raw p-values of one contrast. A well-behaved test gives a
#' uniform histogram with a spike near zero; a hump towards 1, or a wave, means
#' the model assumptions are violated (wrong design, unaccounted batch, over-
#' aggressive imputation) and the FDR is not trustworthy.
#'
#' @param results Output of [test_differential()] or [combine_quant_results()].
#' @param title Plot title. Default `NULL` (the contrast name).
#'
#' @return A ggplot object.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_pvalue_hist(subset(results, Contrast == "TREAT_vs_CTRL"))
#' }
plot_pvalue_hist <- function(results, title = NULL) {
  df <- results[!is.na(results$P.Value), , drop = FALSE]
  p <- ggplot2::ggplot(df, ggplot2::aes(x = P.Value)) +
    ggplot2::geom_histogram(binwidth = 0.025, boundary = 0, alpha = 0.8,
                            color = "black", fill = "#440154")
  if (dplyr::n_distinct(df$Contrast) > 1) p <- p + ggplot2::facet_wrap(~ Contrast)

  p +
    ggplot2::scale_y_continuous(n.breaks = 5) +
    ggplot2::xlab("Raw p-value") + ggplot2::ylab("Features") +
    theme_howmahico() +
    ggplot2::ggtitle(if (is.null(title)) unique(df$Contrast)[1] else title)
}

#' Significant-feature counts per contrast
#'
#' Bar chart of the [summarise_significant()] table: how many features change in
#' each direction, and how many are condition-exclusive, per comparison.
#'
#' @param summary_df Output of [summarise_significant()].
#'
#' @return A ggplot object.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_sig_summary(summarise_significant(results))
#' }
plot_sig_summary <- function(summary_df) {
  status_colors <- c(up = "#b2182b", down = "#2166ac", exclusive_up = "#d6604d",
                     exclusive_down = "#4393c3")
  df <- summary_df |>
    tidyr::pivot_longer(cols = dplyr::any_of(names(status_colors)),
                        names_to = "Status", values_to = "Count") |>
    dplyr::mutate(Status = factor(Status, levels = names(status_colors)))

  ggplot2::ggplot(df, ggplot2::aes(x = Contrast, y = Count, fill = Status)) +
    ggplot2::geom_bar(stat = "identity", position = ggplot2::position_dodge(width = 0.9),
                      alpha = 0.85, color = "black") +
    ggplot2::geom_text(ggplot2::aes(label = Count),
                       position = ggplot2::position_dodge(width = 0.9),
                       vjust = -0.4, size = 2.5) +
    ggplot2::scale_fill_manual(values = status_colors, drop = FALSE, name = NULL) +
    ggplot2::scale_y_continuous(n.breaks = 5) +
    ggplot2::xlab(NULL) + ggplot2::ylab("Features") +
    theme_howmahico() + ggpubr::rotate_x_text(70) +
    ggplot2::ggtitle("Significant features per contrast")
}

# ---- physicochemical-property plots (04_pepchem) ----------------------------

#' Amino-acid composition across groups
#'
#' Draws the [aa_composition()] table three ways. `"bar"` and `"heatmap"` show
#' the residue frequency itself; `"enrichment"` shows log2 of each group's
#' frequency over the pooled frequency of the whole table, which puts every
#' residue on a common, centred axis and makes a compositional shift between
#' Conditions visible without an external proteome background.
#'
#' @param comp Output of [aa_composition()] (needs `Frequency`).
#' @param type `"bar"` (default), `"heatmap"` or `"enrichment"`.
#' @param title Plot title. `NULL` (default) picks one from `type`.
#'
#' @return A ggplot object, or `NULL` when `comp` has no rows.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_aa_composition(aa_composition(pep_short$Sequence, pep_short$Condition))
#' }
plot_aa_composition <- function(comp, type = c("bar", "heatmap", "enrichment"),
                                title = NULL) {
  type <- match.arg(type)
  if (is.null(comp) || nrow(comp) == 0 || !"Frequency" %in% names(comp)) return(NULL)
  df <- comp[!is.na(comp$Frequency), , drop = FALSE]
  if (nrow(df) == 0) return(NULL)

  if (type == "enrichment") {
    # pooled frequency over every group = the internal reference
    pooled <- stats::aggregate(Count ~ AA, data = df, FUN = sum)
    pooled$Reference <- pooled$Count / sum(pooled$Count)
    df$Reference <- pooled$Reference[match(as.character(df$AA),
                                           as.character(pooled$AA))]
    df$Log2Enrichment <- log2(df$Frequency / df$Reference)
    lim <- max(abs(df$Log2Enrichment), na.rm = TRUE)
    return(
      ggplot2::ggplot(df, ggplot2::aes(x = .data[["AA"]], y = .data[["Group"]],
                                       fill = .data[["Log2Enrichment"]])) +
        ggplot2::geom_tile(color = "white", linewidth = 0.2) +
        ggplot2::scale_fill_gradient2(low = "#2166ac", mid = "grey95",
                                      high = "#b2182b", midpoint = 0,
                                      limits = c(-lim, lim),
                                      name = "log2(freq / pooled)") +
        ggplot2::xlab("Amino acid") + ggplot2::ylab(NULL) +
        theme_howmahico() +
        ggplot2::ggtitle(if (is.null(title))
          "Amino-acid enrichment vs. the pooled composition" else title))
  }

  if (type == "heatmap")
    return(
      ggplot2::ggplot(df, ggplot2::aes(x = .data[["AA"]], y = .data[["Group"]],
                                       fill = .data[["Frequency"]])) +
        ggplot2::geom_tile(color = "white", linewidth = 0.2) +
        viridis::scale_fill_viridis(name = "Frequency", end = 0.95) +
        ggplot2::xlab("Amino acid") + ggplot2::ylab(NULL) +
        theme_howmahico() +
        ggplot2::ggtitle(if (is.null(title))
          "Amino-acid composition" else title))

  ggplot2::ggplot(df, ggplot2::aes(x = .data[["AA"]], y = .data[["Frequency"]],
                                   fill = .data[["Group"]])) +
    ggplot2::geom_bar(stat = "identity", position = ggplot2::position_dodge(width = 0.9),
                      alpha = 0.85, color = "black", linewidth = 0.2) +
    viridis::scale_fill_viridis(discrete = TRUE, end = 0.9, name = NULL) +
    ggplot2::scale_y_continuous(n.breaks = 5) +
    ggplot2::xlab("Amino acid") + ggplot2::ylab("Frequency") +
    theme_howmahico() +
    ggplot2::ggtitle(if (is.null(title)) "Amino-acid composition" else title)
}

#' Per-position amino-acid frequency heatmap
#'
#' Tile map of the [aa_position_frequency()] table: position on the x axis,
#' residue on the y axis, one facet per group. This is the numeric complement to
#' the sequence logos in the `01_mhc_overview` report — a logo scales letters by
#' information content and so hides which residue a flat position prefers, while
#' the heatmap keeps every frequency readable and comparable across Conditions.
#'
#' @param freq Output of [aa_position_frequency()].
#' @param ncol Facet columns. Default `3`.
#' @param title Plot title. `NULL` (default) builds one from the peptide length
#'   recorded on `freq`.
#'
#' @return A ggplot object, or `NULL` when `freq` has no rows.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_aa_position_heatmap(aa_position_frequency(pep_short$Sequence,
#'                                                groups = pep_short$Condition))
#' }
plot_aa_position_heatmap <- function(freq, ncol = 3, title = NULL) {
  if (is.null(freq) || nrow(freq) == 0) return(NULL)
  len <- attr(freq, "length")
  if (is.null(title))
    title <- if (is.null(len)) "Per-position amino-acid frequency"
             else paste0("Per-position amino-acid frequency (", len, "-mers)")

  p <- ggplot2::ggplot(freq, ggplot2::aes(x = .data[["PositionLabel"]],
                                          y = .data[["AA"]],
                                          fill = .data[["Frequency"]])) +
    ggplot2::geom_tile(color = "white", linewidth = 0.2) +
    viridis::scale_fill_viridis(name = "Frequency", end = 0.95)
  if (dplyr::n_distinct(freq$Group) > 1)
    p <- p + ggplot2::facet_wrap(~ Group, ncol = ncol)

  p +
    ggplot2::xlab("Position") + ggplot2::ylab("Amino acid") +
    theme_howmahico() +
    ggplot2::ggtitle(title)
}

#' Distribution of one peptide descriptor across Conditions
#'
#' Per-peptide distribution of a single descriptor, coloured by Condition. This
#' is the *repertoire* view: every unique sequence of a Condition contributes one
#' value, so the spread is between-peptide, not between-replicate — read
#' [plot_property_sample_summary()] alongside it for the replicate view.
#'
#' With `type = "density"`, a descriptor that only takes whole-number values
#' (peptide `Length`) is drawn as a histogram with one bar per value, scaled so
#' each Condition's bars sum to 1. A kernel density would draw bumps between
#' values that cannot occur. Continuous descriptors keep the density curve.
#'
#' @param props Output of [pepchem_by_sample()].
#' @param var Name (string) of the descriptor column to draw.
#' @param type `"density"` (default) or `"violin"`.
#' @param title Plot title. `NULL` (default) uses `var`.
#'
#' @return A ggplot object, or `NULL` when the column is absent or all missing.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_property_distribution(props, "GRAVY")
#' }
plot_property_distribution <- function(props, var, type = c("density", "violin"),
                                       title = NULL) {
  type <- match.arg(type)
  if (is.null(props) || !var %in% names(props) || !"Condition" %in% names(props))
    return(NULL)
  df <- props[!is.na(props[[var]]), , drop = FALSE]
  if (nrow(df) == 0) return(NULL)
  if (is.null(title)) title <- var

  p <- if (type == "violin") {
    ggplot2::ggplot(df, ggplot2::aes(x = .data[["Condition"]], y = .data[[var]],
                                     fill = .data[["Condition"]])) +
      ggplot2::geom_violin(alpha = 0.8, color = "black", linewidth = 0.2,
                           scale = "width") +
      ggplot2::geom_boxplot(width = 0.12, outlier.shape = NA, alpha = 0.9,
                            linewidth = 0.2) +
      viridis::scale_fill_viridis(discrete = TRUE, end = 0.9, name = NULL) +
      ggplot2::xlab(NULL) + ggplot2::ylab(var) +
      ggpubr::rotate_x_text(70)
  } else if (.is_whole_number(df[[var]])) {
    # integer-valued descriptor (e.g. Length): a kernel density would draw
    # bumps between values that cannot occur, so draw one bar per value; the
    # density scaling (binwidth 1) makes each Condition's bars sum to 1
    ggplot2::ggplot(df, ggplot2::aes(x = .data[[var]],
                                     fill = .data[["Condition"]])) +
      ggplot2::geom_histogram(ggplot2::aes(y = ggplot2::after_stat(density)),
                              binwidth = 1, position = "dodge",
                              color = "black", linewidth = 0.2) +
      viridis::scale_fill_viridis(discrete = TRUE, end = 0.9, name = NULL) +
      ggplot2::scale_x_continuous(breaks = scales::breaks_width(
        max(1, ceiling(diff(range(df[[var]])) / 15)))) +
      ggplot2::xlab(var) + ggplot2::ylab("Fraction of peptides")
  } else {
    ggplot2::ggplot(df, ggplot2::aes(x = .data[[var]],
                                     color = .data[["Condition"]])) +
      ggplot2::geom_density(linewidth = 0.6) +
      viridis::scale_color_viridis(discrete = TRUE, end = 0.9, name = NULL) +
      ggplot2::xlab(var) + ggplot2::ylab("Density")
  }

  p + ggplot2::scale_y_continuous(n.breaks = 5) + theme_howmahico() +
    ggplot2::ggtitle(title)
}

# TRUE when every (non-missing) value is a whole number, i.e. the descriptor
# can only take integer values and is better drawn as a histogram.
.is_whole_number <- function(x, tol = 1e-8) {
  x <- x[is.finite(x)]
  length(x) > 0 && all(abs(x - round(x)) < tol)
}

#' Per-Condition mean +/- sd of a descriptor across samples
#'
#' Draws the [aggregate_pepchem()] table for one descriptor: each point is a
#' sample's median, the bar and error bar are the mean +/- sd **across samples**.
#' This is the replicate-respecting summary — the error bar answers "how
#' reproducible is this Condition", which a per-peptide distribution cannot.
#'
#' @param summ Output of [aggregate_pepchem()].
#' @param var Descriptor to draw (a value of the `Property` column).
#' @param points Optional per-sample table from [summarise_pepchem()], overlaid
#'   as jittered points. Default `NULL`.
#' @param title Plot title. `NULL` (default) uses `var`.
#'
#' @return A ggplot object, or `NULL` when the descriptor is absent.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_property_sample_summary(aggregate_pepchem(sample_summary), "GRAVY")
#' }
plot_property_sample_summary <- function(summ, var, points = NULL, title = NULL) {
  if (is.null(summ) || nrow(summ) == 0) return(NULL)
  df <- summ[as.character(summ$Property) == var, , drop = FALSE]
  if (nrow(df) == 0) return(NULL)
  if (is.null(title)) title <- var

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data[["Condition"]],
                                        y = .data[["Mean"]],
                                        fill = .data[["Condition"]])) +
    ggplot2::geom_bar(stat = "identity", alpha = 0.85, color = "black",
                      linewidth = 0.2) +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = .data[["Mean"]] - .data[["SD"]],
                                        ymax = .data[["Mean"]] + .data[["SD"]]),
                           width = 0.2, linewidth = 0.3)

  if (!is.null(points) && nrow(points) > 0) {
    pts <- points[as.character(points$Property) == var, , drop = FALSE]
    if (nrow(pts) > 0)
      p <- p + ggplot2::geom_jitter(data = pts,
                                    ggplot2::aes(x = .data[["Condition"]],
                                                 y = .data[["Median"]]),
                                    inherit.aes = FALSE, width = 0.12,
                                    size = 1.2, alpha = 0.8)
  }

  p +
    viridis::scale_fill_viridis(discrete = TRUE, end = 0.9, name = NULL) +
    ggplot2::scale_y_continuous(n.breaks = 5) +
    ggplot2::xlab(NULL) + ggplot2::ylab(paste0(var, " (mean +/- sd of sample medians)")) +
    theme_howmahico() + ggpubr::rotate_x_text(70) +
    ggplot2::ggtitle(title)
}

#' Effect sizes of the between-condition comparison
#'
#' Tile map of [cliffs_delta()] per descriptor (or residue) and contrast, outlined
#' where the BH-adjusted p-value passes `fdr`. Cliff's delta is scale-free, so
#' descriptors on different units (GRAVY, pI, molecular weight) share one axis and
#' can be ranked against each other — which a table of median differences cannot
#' do.
#'
#' @param stats Output of [compare_pepchem()] or [compare_aa_frequency()].
#' @param fdr Significance cut-off; `NULL` uses the value recorded on `stats`.
#' @param title Plot title. `NULL` (default) picks a generic one.
#'
#' @return A ggplot object, or `NULL` when `stats` has no rows.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_property_effectsize(compare_pepchem(props))
#' }
plot_property_effectsize <- function(stats, fdr = NULL, title = NULL) {
  if (is.null(stats) || nrow(stats) == 0) return(NULL)
  key <- if ("Property" %in% names(stats)) "Property" else
         if ("AA" %in% names(stats)) "AA" else names(stats)[1]
  if (is.null(fdr)) fdr <- attr(stats, "fdr")
  if (is.null(fdr)) fdr <- 0.05

  df <- stats[!is.na(stats$CliffsDelta), , drop = FALSE]
  if (nrow(df) == 0) return(NULL)
  df$Flag <- ifelse(!is.na(df$p_adj) & df$p_adj < fdr, "yes", "no")

  ggplot2::ggplot(df, ggplot2::aes(x = .data[["Contrast"]], y = .data[[key]],
                                   fill = .data[["CliffsDelta"]])) +
    ggplot2::geom_tile(ggplot2::aes(color = .data[["Flag"]]), linewidth = 0.5) +
    ggplot2::scale_fill_gradient2(low = "#2166ac", mid = "grey95", high = "#b2182b",
                                  midpoint = 0, limits = c(-1, 1),
                                  name = "Cliff's delta") +
    ggplot2::scale_color_manual(values = c(yes = "black", no = "white"),
                                drop = FALSE, guide = "none") +
    ggplot2::xlab(NULL) + ggplot2::ylab(NULL) +
    theme_howmahico() + ggpubr::rotate_x_text(70) +
    ggplot2::ggtitle(if (is.null(title))
      paste0("Effect size per contrast (outlined: BH p < ", fdr, ")") else title)
}

# ---- protein-level plots (02_prot_all) --------------------------------------

#' Source proteins identified per sample
#'
#' How many distinct source proteins each sample contributes, grouped by
#' Condition. The protein counterpart of the identification counts in
#' `01_mhc_overview`, and the first thing to check before reading anything else at
#' protein level: a sample with far fewer source proteins is usually a depth
#' problem, not a biological one.
#'
#' @param prot_all Output of [build_prot_all()].
#' @param title Plot title. `NULL` (default) uses a generic one.
#'
#' @return A ggplot object, or `NULL` when `prot_all` has no rows.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_proteins_per_sample(build_prot_all(pep_short))
#' }
plot_proteins_per_sample <- function(prot_all, title = NULL) {
  if (is.null(prot_all) || nrow(prot_all) == 0) return(NULL)

  df <- prot_all |>
    dplyr::group_by(dplyr::across(dplyr::any_of(c("Sample", "Condition")))) |>
    dplyr::summarise(n_Proteins = dplyr::n_distinct(.data$Protein), .groups = "drop")
  if (nrow(df) == 0) return(NULL)

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data[["Sample"]],
                                        y = .data[["n_Proteins"]]))
  p <- if ("Condition" %in% names(df))
    p + ggplot2::geom_bar(ggplot2::aes(fill = .data[["Condition"]]),
                          stat = "identity", alpha = 0.85, color = "black",
                          linewidth = 0.2) +
      viridis::scale_fill_viridis(discrete = TRUE, end = 0.9, name = NULL)
  else
    p + ggplot2::geom_bar(stat = "identity", alpha = 0.85, color = "black",
                          linewidth = 0.2, fill = "#440154")

  p +
    ggplot2::geom_text(ggplot2::aes(label = .data[["n_Proteins"]]),
                       vjust = -0.4, size = 2.5) +
    ggplot2::scale_y_continuous(n.breaks = 5) +
    ggplot2::xlab(NULL) + ggplot2::ylab("Source proteins") +
    theme_howmahico() + ggpubr::rotate_x_text(70) +
    ggplot2::ggtitle(if (is.null(title)) "Source proteins per sample" else title)
}

#' Distribution of ligands per source protein
#'
#' How many peptides each source protein contributes. In an immunopeptidome this
#' distribution is strongly skewed — most proteins yield a single ligand and a
#' small number yield many — so it is the shape, not the mean, that carries the
#' information.
#'
#' @param prot_all Output of [build_prot_all()].
#' @param type `"histogram"` (default) or `"violin"`.
#' @param title Plot title. `NULL` (default) uses a generic one.
#'
#' @return A ggplot object, or `NULL` when `prot_all` has no rows.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_peptides_per_protein(build_prot_all(pep_short))
#' }
plot_peptides_per_protein <- function(prot_all, type = c("histogram", "violin"),
                                      title = NULL) {
  type <- match.arg(type)
  if (is.null(prot_all) || nrow(prot_all) == 0) return(NULL)

  group_cols <- intersect(c("Protein", "Condition"), names(prot_all))
  df <- prot_all |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_cols))) |>
    dplyr::summarise(n_Peptides = sum(.data$n_Peptides, na.rm = TRUE),
                     .groups = "drop") |>
    dplyr::filter(.data$n_Peptides > 0)
  if (nrow(df) == 0) return(NULL)
  if (is.null(title)) title <- "Ligands per source protein"

  has_cond <- "Condition" %in% names(df)

  if (type == "violin") {
    if (!has_cond) return(NULL)
    return(
      ggplot2::ggplot(df, ggplot2::aes(x = .data[["Condition"]],
                                       y = .data[["n_Peptides"]],
                                       fill = .data[["Condition"]])) +
        ggplot2::geom_violin(alpha = 0.8, color = "black", linewidth = 0.2,
                             scale = "width") +
        ggplot2::geom_boxplot(width = 0.12, outlier.shape = NA, alpha = 0.9,
                              linewidth = 0.2) +
        viridis::scale_fill_viridis(discrete = TRUE, end = 0.9, name = NULL) +
        ggplot2::scale_y_continuous(n.breaks = 5) +
        ggplot2::xlab(NULL) + ggplot2::ylab("Ligands per protein") +
        theme_howmahico() + ggpubr::rotate_x_text(70) +
        ggplot2::ggtitle(title))
  }

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data[["n_Peptides"]])) +
    ggplot2::geom_histogram(binwidth = 1, alpha = 0.85, color = "black",
                            linewidth = 0.2, fill = "#440154")
  if (has_cond && dplyr::n_distinct(df$Condition) > 1)
    p <- p + ggplot2::facet_wrap(~ Condition)

  p +
    ggplot2::scale_y_continuous(n.breaks = 5) +
    ggplot2::xlab("Ligands per protein") + ggplot2::ylab("Source proteins") +
    theme_howmahico() +
    ggplot2::ggtitle(title)
}

#' Ranked bar chart of the most prolific source proteins
#'
#' Draws the [top_source_proteins()] table: which proteins contribute the most
#' ligands (or the most intensity) across the dataset.
#'
#' @param top_tbl Output of [top_source_proteins()].
#' @param by Column to plot: `"n_Peptides"` (default) or `"Area"`.
#' @param title Plot title. `NULL` (default) uses a generic one.
#'
#' @return A ggplot object, or `NULL` when `top_tbl` has no rows.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_top_proteins(top_source_proteins(prot_all, n = 25))
#' }
plot_top_proteins <- function(top_tbl, by = c("n_Peptides", "Area"),
                              title = NULL) {
  by <- match.arg(by)
  if (is.null(top_tbl) || nrow(top_tbl) == 0 || !by %in% names(top_tbl))
    return(NULL)
  df <- top_tbl[!is.na(top_tbl[[by]]), , drop = FALSE]
  if (nrow(df) == 0) return(NULL)

  df$Protein <- factor(as.character(df$Protein),
                       levels = as.character(df$Protein)[order(df[[by]])])
  ylab <- if (by == "n_Peptides") "Ligands" else "Summed ligand Area"

  ggplot2::ggplot(df, ggplot2::aes(x = .data[["Protein"]], y = .data[[by]])) +
    ggplot2::geom_bar(stat = "identity", alpha = 0.85, color = "black",
                      linewidth = 0.2, fill = "#21918c") +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(n.breaks = 5) +
    ggplot2::xlab(NULL) + ggplot2::ylab(ylab) +
    theme_howmahico() +
    ggplot2::ggtitle(if (is.null(title))
      paste0("Top source proteins by ", ylab) else title)
}

#' How widely each source protein is detected
#'
#' Counts source proteins by the number of samples — and, when available,
#' Conditions — they were identified in. The left-hand end of this distribution
#' is the one-sample-only tail, which at protein level is usually driven by
#' single-ligand identifications rather than by biology.
#'
#' @param prot_all Output of [build_prot_all()].
#' @param by `"Sample"` (default) or `"Condition"`.
#' @param title Plot title. `NULL` (default) uses a generic one.
#'
#' @return A ggplot object, or `NULL` when `prot_all` has no rows.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_protein_detection(build_prot_all(pep_short))
#' }
plot_protein_detection <- function(prot_all, by = c("Sample", "Condition"),
                                   title = NULL) {
  by <- match.arg(by)
  if (is.null(prot_all) || nrow(prot_all) == 0 || !by %in% names(prot_all))
    return(NULL)

  df <- prot_all |>
    dplyr::group_by(.data$Protein) |>
    dplyr::summarise(n_Detected = dplyr::n_distinct(.data[[by]]), .groups = "drop") |>
    dplyr::count(.data$n_Detected, name = "n_Proteins")
  if (nrow(df) == 0) return(NULL)

  ggplot2::ggplot(df, ggplot2::aes(x = factor(.data[["n_Detected"]]),
                                   y = .data[["n_Proteins"]])) +
    ggplot2::geom_bar(stat = "identity", alpha = 0.85, color = "black",
                      linewidth = 0.2, fill = "#fde725") +
    ggplot2::geom_text(ggplot2::aes(label = .data[["n_Proteins"]]),
                       vjust = -0.4, size = 2.5) +
    ggplot2::scale_y_continuous(n.breaks = 5) +
    ggplot2::xlab(paste0(by, "s the protein was detected in")) +
    ggplot2::ylab("Source proteins") +
    theme_howmahico() +
    ggplot2::ggtitle(if (is.null(title))
      paste0("Source-protein detection across ", tolower(by), "s") else title)
}

#' Summed ligand intensity against the search engine's protein quantity
#'
#' Compares the ligand intensity HowMaHiCo sums per source protein with the
#' protein quantity the search engine computed itself (DIA-NN's `PG.MaxLFQ` and
#' relatives), on log2 axes, with a Spearman correlation.
#'
#' The point of the plot is the *disagreement*. Summed HLA-ligand intensity is
#' not a measure of source-protein abundance — presentation depends on
#' proteasomal processing, transport and binding affinity — so the two need not
#' track each other, and seeing how far they diverge is more informative than
#' being told they differ. Returns `NULL` when the search engine reported no
#' protein quantity, which is the case for FragPipe's `psm.tsv`, PEAKS and the
#' custom-dictionary path.
#'
#' @param prot_all Output of [build_prot_all()].
#' @param quant_col Engine quantity column to plot. `NULL` (default) picks the
#'   first one present, preferring MaxLFQ.
#' @param title Plot title. `NULL` (default) names the column used.
#'
#' @return A ggplot object, or `NULL` when no engine quantity is available.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' plot_ligand_vs_protein_quant(build_prot_all(pep_all))
#' }
plot_ligand_vs_protein_quant <- function(prot_all, quant_col = NULL,
                                         title = NULL) {
  if (is.null(prot_all) || nrow(prot_all) == 0) return(NULL)

  if (is.null(quant_col)) {
    preferred <- c("PG.MaxLFQ", "PG.Abundance", "PG.NormalisedAbundance",
                   "PG.NormalizedAbundance", "PG.Normalised", "PG.Quantity",
                   "Genes.MaxLFQ", "Genes.Quantity")
    available <- intersect(preferred, names(prot_all))
    if (length(available) == 0) return(NULL)
    quant_col <- available[1]
  }
  if (!quant_col %in% names(prot_all)) return(NULL)

  df <- prot_all[!is.na(prot_all$Area) & prot_all$Area > 0 &
                   !is.na(prot_all[[quant_col]]) & prot_all[[quant_col]] > 0,
                 , drop = FALSE]
  if (nrow(df) < 3) return(NULL)

  df$Ligand_log2 <- log2(df$Area)
  df$Engine_log2 <- log2(as.numeric(df[[quant_col]]))
  rho <- suppressWarnings(stats::cor(df$Ligand_log2, df$Engine_log2,
                                     method = "spearman", use = "complete.obs"))

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data[["Engine_log2"]],
                                        y = .data[["Ligand_log2"]]))
  p <- if ("Condition" %in% names(df))
    p + ggplot2::geom_point(ggplot2::aes(color = .data[["Condition"]]),
                            alpha = 0.6, size = 1.2) +
      viridis::scale_color_viridis(discrete = TRUE, end = 0.9, name = NULL)
  else
    p + ggplot2::geom_point(alpha = 0.6, size = 1.2, color = "#440154")

  p +
    ggplot2::scale_x_continuous(n.breaks = 5) +
    ggplot2::scale_y_continuous(n.breaks = 5) +
    ggplot2::xlab(paste0("log2(", quant_col, ") - reported by the search engine")) +
    ggplot2::ylab("log2(summed ligand Area)") +
    ggplot2::labs(caption = paste0("Spearman rho = ", round(rho, 3),
                                   "   n = ", nrow(df), " protein-sample pairs")) +
    theme_howmahico() +
    ggplot2::ggtitle(if (is.null(title))
      paste0("Ligand intensity vs. ", quant_col) else title)
}

#' Compare quality metrics across runs
#'
#' Plots the stacked score table from [compare_runs()] with one panel per
#' metric (free y axes) and the runs on the x axis, in their factor order:
#' input order, or render time for `compare_runs(order = "timestamp")`. Each
#' sample is a point, and QC samples are drawn as triangles. `type = "box"` adds
#' a box per run. `type = "line"` instead joins the run medians, which reads as
#' a trend when the runs are repeated measurements of the same standard.
#'
#' @param runs_tbl Output of [compare_runs()].
#' @param metrics Metric columns to plot (default: composite score, length-window
#'   fidelity and in-window depth). Panels are labelled with the metric names of
#'   [quality_thresholds_default()].
#' @param type `"box"` (default) or `"line"`.
#' @param color_by Optional column to colour the points by (e.g. `"Condition"`,
#'   which `01_mhc_overview` writes into its score csv). `NULL` for none.
#'
#' @return A ggplot2 object.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' runs <- compare_runs(c("3_results/qc_week1", "3_results/qc_week2"),
#'                      order = "timestamp")
#' plot_run_trend(runs, type = "line")
#' }
plot_run_trend <- function(runs_tbl,
                           metrics = c("composite_score", "frac_in_window",
                                       "n_unique_pep_in_window"),
                           type = c("box", "line"),
                           color_by = NULL) {
  type <- match.arg(type)
  missing <- setdiff(metrics, names(runs_tbl))
  if (length(missing) > 0)
    stop("Metric(s) not in the run table: ", paste(missing, collapse = ", "))
  if (!is.null(color_by) && !color_by %in% names(runs_tbl))
    stop("'color_by' column '", color_by, "' is not in the run table.")
  labels <- .run_metric_labels(runs_tbl)
  panel <- ifelse(metrics %in% names(labels), labels[metrics], metrics)

  df <- runs_tbl
  df$is_QC <- if ("is_QC" %in% names(df)) as.logical(df$is_QC) %in% TRUE else FALSE
  df$Colour <- if (is.null(color_by)) "all" else as.character(df[[color_by]])
  long <- df |>
    dplyr::select(Run, Sample, is_QC, Colour, dplyr::all_of(metrics)) |>
    tidyr::pivot_longer(dplyr::all_of(metrics), names_to = "metric", values_to = "value") |>
    dplyr::filter(!is.na(value)) |>
    dplyr::mutate(Metric = factor(unname(panel[match(metric, metrics)]), levels = unname(panel)))

  p <- ggplot2::ggplot(long, ggplot2::aes(x = Run, y = value))
  if (type == "box") {
    p <- p + ggplot2::geom_boxplot(outlier.shape = NA, fill = "grey92", width = 0.6)
  } else {
    p <- p + ggplot2::stat_summary(ggplot2::aes(group = 1), fun = stats::median,
                                   geom = "line", colour = "grey40") +
      ggplot2::stat_summary(fun = stats::median, geom = "point",
                            shape = 95, size = 8, colour = "grey40")
  }
  p <- p +
    ggplot2::geom_point(ggplot2::aes(shape = is_QC, colour = Colour),
                        position = ggplot2::position_jitter(width = 0.12, height = 0, seed = 1),
                        size = 1.8, alpha = 0.8) +
    ggplot2::scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 17),
                                labels = c(`FALSE` = "Sample", `TRUE` = "QC sample"),
                                name = NULL) +
    ggplot2::facet_wrap(~Metric, scales = "free_y") +
    ggplot2::xlab("Run") + ggplot2::ylab(NULL) +
    theme_howmahico() +
    ggpubr::rotate_x_text(45) +
    ggplot2::ggtitle("Quality metrics across runs")
  if (is.null(color_by)) {
    p + ggplot2::scale_colour_manual(values = c(all = "black"), guide = "none")
  } else {
    p + ggplot2::labs(colour = color_by)
  }
}
