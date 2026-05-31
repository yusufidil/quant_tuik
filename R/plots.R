# =============================================================================
# R/plots.R
# Generate actual-vs-forecast plots for all 10 methods and save to PNG.
# =============================================================================

library(ggplot2)
library(lubridate)

#' Create a standardised actual-vs-forecast plot for a single method.
#'
#' @param df_train    Data frame (date, visitors) — training data
#' @param df_test     Data frame (date, visitors) — test period actuals
#' @param method_result  One element from run_all_methods()
#' @param save_path   Directory to save PNG files
#' @param show_train_fitted  Logical: overlay in-sample fitted line?
plot_method <- function(df_train, df_test, method_result,
                        save_path = "outputs/figures",
                        show_train_fitted = TRUE,
                        file_name = NULL) {

  method_name <- method_result$name
  h           <- nrow(df_test)

  # Build forecast data frame aligned to test dates
  fcast_vals <- method_result$forecast[1:h]
  df_fcast   <- data.frame(date     = df_test$date,
                            visitors = fcast_vals,
                            type     = "Forecast")

  # Actual test data
  df_test_plot <- data.frame(date     = df_test$date,
                              visitors = df_test$visitors,
                              type     = "Actual")

  # Recent training window (last 3 years for readability)
  df_train_recent <- df_train[df_train$date >= max(df_train$date) - 365*3, ]
  df_train_plot   <- data.frame(date     = df_train_recent$date,
                                 visitors = df_train_recent$visitors,
                                 type     = "Historical")

  # Combine all actuals (historical + test)
  df_actual_all <- rbind(
    data.frame(date = df_train_recent$date, visitors = df_train_recent$visitors, type = "Historical"),
    data.frame(date = df_test$date, visitors = df_test$visitors, type = "Actual (Test)")
  )

  p <- ggplot() +
    # Historical line
    geom_line(data = df_actual_all[df_actual_all$type == "Historical", ],
              aes(x = date, y = visitors / 1e6, colour = "Historical"), linewidth = 0.8) +
    # Test actuals
    geom_line(data = df_actual_all[df_actual_all$type == "Actual (Test)", ],
              aes(x = date, y = visitors / 1e6, colour = "Actual (Test)"), linewidth = 1.1) +
    geom_point(data = df_actual_all[df_actual_all$type == "Actual (Test)", ],
               aes(x = date, y = visitors / 1e6, colour = "Actual (Test)"), size = 2) +
    # Forecast
    geom_line(data = df_fcast,
              aes(x = date, y = visitors / 1e6, colour = "Forecast"), linewidth = 1.1, linetype = "dashed") +
    geom_point(data = df_fcast,
               aes(x = date, y = visitors / 1e6, colour = "Forecast"), size = 2, shape = 17) +
    scale_colour_manual(
      values = c(
        "Historical"    = "#6baed6",
        "Actual (Test)" = "#2171b5",
        "Forecast"      = "#d94701"
      ),
      breaks = c("Historical", "Actual (Test)", "Forecast")
    ) +
    scale_x_date(date_labels = "%b\n%Y", date_breaks = "3 months") +
    scale_y_continuous(labels = function(x) paste0(round(x, 1), "M")) +
    labs(
      title    = paste("Forecast:", method_name),
      subtitle = paste("Test period:", format(min(df_test$date), "%b %Y"),
                       "–", format(max(df_test$date), "%b %Y")),
      x        = NULL,
      y        = "Monthly Visitors (millions)",
      colour   = NULL,
      caption  = "Source: TÜİK Tourism Statistics (tuikr package)"
    ) +
    theme_bw(base_size = 12) +
    theme(
      plot.title    = element_text(face = "bold", size = 13),
      plot.subtitle = element_text(colour = "grey40"),
      legend.position = "top",
      legend.key.width = unit(1.5, "cm"),
      axis.text.x  = element_text(angle = 0, hjust = 0.5),
      panel.grid.minor = element_blank()
    )

  # Save
  dir.create(save_path, showWarnings = FALSE, recursive = TRUE)
  safe_name <- gsub("[^A-Za-z0-9_]", "_", method_name)
  if (is.null(file_name)) file_name <- paste0("forecast_", safe_name, ".png")
  file_path <- file.path(save_path, file_name)
  ggsave(file_path, plot = p, width = 9, height = 5, dpi = 150, bg = "white")
  message("Saved: ", file_path)
  invisible(p)
}


#' Generate and save all 10 method plots.
#'
#' @param df_train    Data frame (date, visitors)
#' @param df_test     Data frame (date, visitors)
#' @param all_methods Named list from run_all_methods()
#' @param save_path   Directory for PNG output
plot_all_methods <- function(df_train, df_test, all_methods,
                             save_path = "outputs/figures") {
  expected_names <- c(
    "Naïve" = "naive_forecast_plot.png",
    "Moving Average (k=3)" = "moving_average_plot.png",
    "Weighted Moving Average (k=3)" = "weighted_moving_average_plot.png",
    "Simple Exponential Smoothing" = "exponential_smoothing_plot.png",
    "Trend-Adjusted Exponential Smoothing" = "trend_adjusted_smoothing_plot.png",
    "Linear Trend Projection" = "trend_projection_plot.png",
    "Seasonal Indices" = "seasonal_indices_plot.png",
    "Additive Decomposition" = "additive_decomposition_plot.png",
    "Multiplicative Decomposition" = "multiplicative_decomposition_plot.png",
    "Regression (Trend + Seasonal Dummies)" = "regression_seasonal_dummy_plot.png"
  )

  for (nm in names(all_methods)) {
    file_name <- if (nm %in% names(expected_names)) expected_names[[nm]] else NULL
    tryCatch(
      plot_method(df_train, df_test, all_methods[[nm]], save_path, file_name = file_name),
      error = function(e) message("Plot failed for ", nm, ": ", conditionMessage(e))
    )
  }
  invisible(NULL)
}

plot_actual_series <- function(df_full, save_path = "outputs/figures") {
  p <- ggplot(df_full, aes(x = date, y = visitors / 1e6)) +
    geom_line(colour = "#2171b5", linewidth = 0.9) +
    geom_point(colour = "#2171b5", size = 1.2, alpha = 0.65) +
    scale_x_date(date_labels = "%Y", date_breaks = "1 year") +
    scale_y_continuous(labels = function(x) paste0(round(x, 1), "M")) +
    labs(
      title = "Monthly Incoming Visitors to Turkey",
      x = NULL,
      y = "Visitors (millions)",
      caption = "Source: TÜİK via tuikr"
    ) +
    theme_bw(base_size = 12) +
    theme(plot.title = element_text(face = "bold"),
          panel.grid.minor = element_blank())

  dir.create(save_path, showWarnings = FALSE, recursive = TRUE)
  ggsave(file.path(save_path, "actual_series_plot.png"),
         p, width = 10, height = 5, dpi = 150, bg = "white")
  invisible(p)
}

plot_superior_method <- function(df_full, forecast_date, forecast_value,
                                 best_model, save_path = "outputs/figures") {
  df_recent <- df_full[df_full$date >= max(df_full$date) %m-% months(36), ]
  df_fcast <- data.frame(date = forecast_date, visitors = forecast_value)

  p <- ggplot() +
    geom_line(data = df_recent,
              aes(x = date, y = visitors / 1e6, colour = "Actual"),
              linewidth = 1) +
    geom_point(data = df_recent,
               aes(x = date, y = visitors / 1e6, colour = "Actual"),
               size = 1.8, alpha = 0.75) +
    geom_point(data = df_fcast,
               aes(x = date, y = visitors / 1e6, colour = "Forecast"),
               size = 3, shape = 17) +
    geom_segment(data = data.frame(
      x = max(df_recent$date), xend = forecast_date,
      y = tail(df_recent$visitors, 1), yend = forecast_value
    ), aes(x = x, xend = xend, y = y / 1e6, yend = yend / 1e6,
           colour = "Forecast"), linewidth = 1.1, linetype = "dashed") +
    scale_colour_manual(values = c("Actual" = "#2171b5", "Forecast" = "#d94701")) +
    scale_x_date(date_labels = "%b %Y", date_breaks = "3 months") +
    scale_y_continuous(labels = function(x) paste0(round(x, 1), "M")) +
    labs(
      title = paste("Superior Method Forecast:", best_model),
      subtitle = paste("Next period:", format(forecast_date, "%B %Y")),
      x = NULL,
      y = "Visitors (millions)",
      colour = NULL
    ) +
    theme_bw(base_size = 12) +
    theme(plot.title = element_text(face = "bold"),
          legend.position = "top",
          axis.text.x = element_text(angle = 30, hjust = 1),
          panel.grid.minor = element_blank())

  dir.create(save_path, showWarnings = FALSE, recursive = TRUE)
  ggsave(file.path(save_path, "superior_method_plot.png"),
         p, width = 10, height = 5, dpi = 150, bg = "white")
  invisible(p)
}


#' Generate a composite overview plot: all forecasts on one chart.
#'
#' @param df_test      Test period actuals (date, visitors)
#' @param all_methods  Named list from run_all_methods()
#' @param save_path    Directory for PNG output
plot_all_forecasts_overlay <- function(df_test, all_methods,
                                       save_path = "outputs/figures") {
  h <- nrow(df_test)
  rows <- lapply(names(all_methods), function(nm) {
    fv <- all_methods[[nm]]$forecast[1:h]
    data.frame(date = df_test$date, visitors = fv, Method = nm)
  })
  df_fcast_all <- do.call(rbind, rows)

  df_actual <- data.frame(date = df_test$date, visitors = df_test$visitors)

  p <- ggplot() +
    geom_line(data = df_fcast_all,
              aes(x = date, y = visitors / 1e6, colour = Method, group = Method),
              linewidth = 0.7, linetype = "dashed", alpha = 0.8) +
    geom_line(data = df_actual,
              aes(x = date, y = visitors / 1e6),
              colour = "black", linewidth = 1.4) +
    geom_point(data = df_actual,
               aes(x = date, y = visitors / 1e6), colour = "black", size = 2) +
    scale_x_date(date_labels = "%b %Y", date_breaks = "2 months") +
    scale_y_continuous(labels = function(x) paste0(round(x, 1), "M")) +
    labs(
      title    = paste0("All 10 Forecasting Methods vs. Actual (Test Period ",
                         format(min(df_test$date), "%b %Y"), " – ",
                         format(max(df_test$date), "%b %Y"), ")"),
      x        = NULL,
      y        = "Monthly Visitors (millions)",
      colour   = "Method",
      caption  = "Black solid line = Actual observations"
    ) +
    theme_bw(base_size = 11) +
    theme(
      legend.position = "right",
      legend.text     = element_text(size = 8),
      plot.title      = element_text(face = "bold"),
      panel.grid.minor = element_blank(),
      axis.text.x     = element_text(angle = 30, hjust = 1)
    )

  dir.create(save_path, showWarnings = FALSE, recursive = TRUE)
  file_path <- file.path(save_path, "all_forecasts_overlay.png")
  ggsave(file_path, plot = p, width = 12, height = 6, dpi = 150, bg = "white")
  message("Saved: ", file_path)
  invisible(p)
}


#' Plot accuracy metric comparison bar chart (MAD and MAPE side by side).
#'
#' @param acc_table   Data frame from build_accuracy_table()
#' @param save_path   Directory for PNG output
plot_accuracy_comparison <- function(acc_table, save_path = "outputs/figures") {
  # MAD bar chart
  df_mad <- data.frame(
    Model = acc_table$Model,
    MAD   = acc_table$MAD
  )
  df_mad$Model <- factor(df_mad$Model,
                          levels = df_mad$Model[order(df_mad$MAD, decreasing = TRUE)])

  p_mad <- ggplot(df_mad, aes(x = Model, y = MAD / 1e3, fill = MAD)) +
    geom_col(width = 0.6) +
    geom_text(aes(label = round(MAD / 1e3, 1)), hjust = -0.1, size = 3.5) +
    scale_fill_gradient(low = "#74c476", high = "#d94701", guide = "none") +
    coord_flip() +
    labs(title = "Model Comparison by MAD",
         x = NULL, y = "MAD (000s visitors)",
         caption = "Lower is better") +
    theme_bw(base_size = 11) +
    theme(plot.title = element_text(face = "bold"),
          panel.grid.major.y = element_blank())

  dir.create(save_path, showWarnings = FALSE, recursive = TRUE)
  ggsave(file.path(save_path, "accuracy_MAD_comparison.png"),
         p_mad, width = 9, height = 6, dpi = 150, bg = "white")

  # MAPE bar chart
  df_mape <- data.frame(
    Model = acc_table$Model,
    MAPE  = acc_table$MAPE_pct
  )
  df_mape$Model <- factor(df_mape$Model,
                           levels = df_mape$Model[order(df_mape$MAPE, decreasing = TRUE)])

  p_mape <- ggplot(df_mape, aes(x = Model, y = MAPE, fill = MAPE)) +
    geom_col(width = 0.6) +
    geom_text(aes(label = paste0(round(MAPE, 1), "%")), hjust = -0.1, size = 3.5) +
    scale_fill_gradient(low = "#74c476", high = "#d94701", guide = "none") +
    coord_flip() +
    labs(title = "Model Comparison by MAPE",
         x = NULL, y = "MAPE (%)",
         caption = "Lower is better") +
    theme_bw(base_size = 11) +
    theme(plot.title = element_text(face = "bold"),
          panel.grid.major.y = element_blank())

  ggsave(file.path(save_path, "accuracy_MAPE_comparison.png"),
         p_mape, width = 9, height = 6, dpi = 150, bg = "white")

  message("Accuracy comparison plots saved.")
  invisible(list(mad = p_mad, mape = p_mape))
}
