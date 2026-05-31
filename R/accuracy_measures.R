# =============================================================================
# R/accuracy_measures.R
# Implements 7 quantitative forecast accuracy metrics.
# =============================================================================

#' Compute all 7 accuracy metrics for a pair of actual and forecast vectors.
#'
#' @param actual    Numeric vector of observed values
#' @param forecast  Numeric vector of forecast values (same length)
#' @param model_name Character label for the method (used in output table)
#' @return Named vector with metrics: Error, Bias, MAD, MSE, MAPE, RSFE, TS
compute_accuracy <- function(actual, forecast, model_name = "Model") {
  stopifnot(length(actual) == length(forecast))
  n      <- length(actual)
  errors <- actual - forecast          # Forecast errors (e_t = A_t - F_t)

  # 1. Individual Forecast Errors (stored as a vector, summarised as last-period error)
  error_last <- errors[n]

  # 2. Bias  = mean(errors)  — positive = under-forecasting
  bias   <- mean(errors)

  # 3. MAD  = mean(|errors|)
  mad    <- mean(abs(errors))

  # 4. MSE  = mean(errors^2)
  mse    <- mean(errors^2)

  # 5. MAPE = mean(|errors/actual| * 100)
  mape   <- mean(abs(errors / actual) * 100)

  # 6. RSFE = Running Sum of Forecast Errors = sum(errors)
  rsfe   <- sum(errors)

  # 7. Tracking Signal = RSFE / MAD
  ts_val <- rsfe / mad

  c(
    Model          = model_name,
    Forecast_Error = round(error_last, 2),
    Bias           = round(bias,    2),
    MAD            = round(mad,     2),
    MSE            = round(mse,     0),
    MAPE_pct       = round(mape,    2),
    RSFE           = round(rsfe,    0),
    Tracking_Signal = round(ts_val, 3)
  )
}

#' Build the full accuracy comparison table for all 10 methods.
#'
#' @param actuals     Named list of actual vectors (one per test split)
#' @param forecasts   Named list of forecast vectors (names = method names)
#' @return Data frame with one row per method and columns for each metric
build_accuracy_table <- function(actual_vec, forecast_list, next_forecast_list = NULL) {
  rows <- lapply(names(forecast_list), function(nm) {
    fcast <- forecast_list[[nm]]
    # Align lengths (trim to shorter)
    n <- min(length(actual_vec), length(fcast))
    row <- compute_accuracy(actual_vec[1:n], fcast[1:n], model_name = nm)
    next_value <- if (!is.null(next_forecast_list) && nm %in% names(next_forecast_list)) {
      round(next_forecast_list[[nm]][1], 2)
    } else {
      NA_real_
    }
    c(row, Next_Period_Forecast = next_value)
  })
  df <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)

  # Convert numeric columns
  num_cols <- c("Forecast_Error","Bias","MAD","MSE","MAPE_pct","RSFE",
                "Tracking_Signal","Next_Period_Forecast")
  df[num_cols] <- lapply(df[num_cols], as.numeric)

  # Rank by MAD (ascending = better)
  df$Rank_MAD  <- rank(df$MAD,  ties.method = "min")
  df$Rank_MAPE <- rank(df$MAPE_pct, ties.method = "min")

  df
}

#' Select the best model based on minimum MAD.
#'
#' @param acc_table Data frame from build_accuracy_table()
#' @return Character name of the best method
select_best_model <- function(acc_table) {
  acc_table$Model[which.min(acc_table$MAD)]
}
