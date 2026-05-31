# =============================================================================
# R/forecasting_methods.R
# 10 quantitative forecasting methods applied to a monthly time series.
# All functions return a named list: $fitted (in-sample), $forecast (out-of-sample)
# =============================================================================

# ── Helper ────────────────────────────────────────────────────────────────────
#' Return NA-padded vector of length n (for methods that need a burn-in).
pad_na <- function(x, n) c(rep(NA, n), x)


# ─────────────────────────────────────────────────────────────────────────────
# Method 1: Naïve Forecasting
#   F_{t+1} = A_t  (last observed value)
# ─────────────────────────────────────────────────────────────────────────────
naive_forecast <- function(train_ts, h = 12) {
  n        <- length(train_ts)
  fitted   <- c(NA, as.numeric(train_ts[-n]))   # F_t = A_{t-1}
  fcast    <- rep(as.numeric(train_ts)[n], h)
  list(fitted = fitted, forecast = fcast, name = "Naïve")
}


# ─────────────────────────────────────────────────────────────────────────────
# Method 2: Simple Moving Average (k = 3 months)
# ─────────────────────────────────────────────────────────────────────────────
moving_average_forecast <- function(train_ts, k = 3, h = 12) {
  x      <- as.numeric(train_ts)
  n      <- length(x)
  fitted <- rep(NA, n)
  for (i in (k+1):n) {
    fitted[i] <- mean(x[(i-k):(i-1)])
  }
  last_window <- x[(n-k+1):n]
  fcast <- rep(mean(last_window), h)
  list(fitted = fitted, forecast = fcast, name = "Moving Average (k=3)")
}


# ─────────────────────────────────────────────────────────────────────────────
# Method 3: Weighted Moving Average (k = 3, weights = c(1,2,3)/6)
# ─────────────────────────────────────────────────────────────────────────────
weighted_ma_forecast <- function(train_ts, k = 3, h = 12) {
  x      <- as.numeric(train_ts)
  n      <- length(x)
  w      <- (1:k) / sum(1:k)            # linearly increasing weights
  fitted <- rep(NA, n)
  for (i in (k+1):n) {
    fitted[i] <- sum(w * x[(i-k):(i-1)])
  }
  last_window <- x[(n-k+1):n]
  fcast <- rep(sum(w * last_window), h)
  list(fitted = fitted, forecast = fcast, name = "Weighted Moving Average (k=3)")
}


# ─────────────────────────────────────────────────────────────────────────────
# Method 4: Simple Exponential Smoothing
#   F_{t+1} = α·A_t + (1-α)·F_t
# ─────────────────────────────────────────────────────────────────────────────
ses_forecast <- function(train_ts, alpha = NULL, h = 12) {
  library(stats)
  fit    <- HoltWinters(train_ts, beta = FALSE, gamma = FALSE,
                        alpha = alpha)
  fvals  <- as.numeric(fitted(fit)[, "xhat"])
  # Pad leading NA to match original length
  fitted_full <- c(rep(NA, length(train_ts) - length(fvals)), fvals)
  fcast  <- as.numeric(predict(fit, n.ahead = h))
  list(fitted = fitted_full, forecast = fcast,
       name   = "Simple Exponential Smoothing",
       alpha  = fit$alpha)
}


# ─────────────────────────────────────────────────────────────────────────────
# Method 5: Holt's Linear (Trend-Adjusted) Exponential Smoothing
#   Level: L_t = α·A_t + (1-α)(L_{t-1}+T_{t-1})
#   Trend: T_t = β(L_t - L_{t-1}) + (1-β)T_{t-1}
# ─────────────────────────────────────────────────────────────────────────────
holt_forecast <- function(train_ts, alpha = NULL, beta = NULL, h = 12) {
  fit   <- HoltWinters(train_ts, gamma = FALSE,
                       alpha = alpha, beta = beta)
  fvals <- as.numeric(fitted(fit)[, "xhat"])
  fitted_full <- c(rep(NA, length(train_ts) - length(fvals)), fvals)
  fcast <- as.numeric(predict(fit, n.ahead = h))
  list(fitted = fitted_full, forecast = fcast,
       name   = "Trend-Adjusted Exponential Smoothing",
       alpha  = fit$alpha, beta = fit$beta)
}


# ─────────────────────────────────────────────────────────────────────────────
# Method 6: Linear Trend Projection (OLS regression on time index)
#   F_t = a + b·t
# ─────────────────────────────────────────────────────────────────────────────
linear_trend_forecast <- function(train_ts, h = 12) {
  x     <- as.numeric(train_ts)
  n     <- length(x)
  t_idx <- 1:n
  mdl   <- lm(x ~ t_idx)
  a     <- coef(mdl)[1]; b <- coef(mdl)[2]
  fitted_vals <- as.numeric(predict(mdl))
  fcast <- a + b * (n + 1:h)
  list(fitted = fitted_vals, forecast = fcast,
       name   = "Linear Trend Projection",
       intercept = a, slope = b)
}


# ─────────────────────────────────────────────────────────────────────────────
# Method 7: Seasonal Indices (Classical Decomposition approach)
#   Deseasonalise → fit linear trend → reseasonalise
# ─────────────────────────────────────────────────────────────────────────────
seasonal_index_forecast <- function(train_ts, h = 12) {
  x    <- as.numeric(train_ts)
  n    <- length(x)
  freq <- frequency(train_ts)

  # Compute monthly seasonal indices
  mat  <- matrix(x, ncol = freq, byrow = TRUE)
  col_means  <- colMeans(mat, na.rm = TRUE)
  grand_mean <- mean(col_means)
  si         <- col_means / grand_mean        # seasonal index per period

  # Deseasonalise
  x_deseas <- x / si[((seq_along(x)-1) %% freq) + 1]

  # Fit linear trend to deseasonalised data
  t_idx <- 1:n
  mdl   <- lm(x_deseas ~ t_idx)
  a     <- coef(mdl)[1]; b <- coef(mdl)[2]

  # In-sample fitted
  trend_fit   <- a + b * t_idx
  fitted_vals <- trend_fit * si[((t_idx - 1) %% freq) + 1]

  # Forecast
  t_fcast <- (n + 1):(n + h)
  si_fcast <- si[((t_fcast - 1) %% freq) + 1]
  fcast   <- (a + b * t_fcast) * si_fcast

  list(fitted = fitted_vals, forecast = fcast, name = "Seasonal Indices",
       seasonal_indices = si)
}


# ─────────────────────────────────────────────────────────────────────────────
# Method 8: Additive Decomposition Forecast
#   Actual = Trend + Seasonal + Irregular
#   Forecast = Trend + Seasonal (project trend forward)
# ─────────────────────────────────────────────────────────────────────────────
additive_decomp_forecast <- function(train_ts, h = 12) {
  decomp <- decompose(train_ts, type = "additive")
  trend  <- as.numeric(decomp$trend)
  seas   <- as.numeric(decomp$seasonal)
  x      <- as.numeric(train_ts)
  n      <- length(x)
  freq   <- frequency(train_ts)

  # Fit linear trend to the trend component (ignoring NAs at edges)
  t_idx     <- 1:n
  trend_noNA <- trend[!is.na(trend)]
  t_noNA     <- t_idx[!is.na(trend)]
  mdl       <- lm(trend_noNA ~ t_noNA)
  a         <- coef(mdl)[1]; b <- coef(mdl)[2]

  trend_full  <- a + b * t_idx
  fitted_vals <- trend_full + seas

  # Forecast: extend trend + repeat seasonal pattern
  t_fcast  <- (n + 1):(n + h)
  si_fcast <- seas[((t_fcast - 1) %% freq) + 1]
  fcast    <- (a + b * t_fcast) + si_fcast

  list(fitted = fitted_vals, forecast = fcast,
       name = "Additive Decomposition")
}


# ─────────────────────────────────────────────────────────────────────────────
# Method 9: Multiplicative Decomposition Forecast
#   Actual = Trend × Seasonal × Irregular
# ─────────────────────────────────────────────────────────────────────────────
multiplicative_decomp_forecast <- function(train_ts, h = 12) {
  decomp <- decompose(train_ts, type = "multiplicative")
  trend  <- as.numeric(decomp$trend)
  seas   <- as.numeric(decomp$seasonal)
  x      <- as.numeric(train_ts)
  n      <- length(x)
  freq   <- frequency(train_ts)

  t_idx     <- 1:n
  trend_noNA <- trend[!is.na(trend)]
  t_noNA     <- t_idx[!is.na(trend)]
  mdl       <- lm(trend_noNA ~ t_noNA)
  a         <- coef(mdl)[1]; b <- coef(mdl)[2]

  trend_full  <- a + b * t_idx
  fitted_vals <- trend_full * seas

  t_fcast  <- (n + 1):(n + h)
  si_fcast <- seas[((t_fcast - 1) %% freq) + 1]
  fcast    <- (a + b * t_fcast) * si_fcast

  list(fitted = fitted_vals, forecast = fcast,
       name = "Multiplicative Decomposition")
}


# ─────────────────────────────────────────────────────────────────────────────
# Method 10: Regression with Trend + Seasonal Dummy Variables
#   F_t = β_0 + β_1·t + β_2·M2 + β_3·M3 + ... + β_12·M12
# ─────────────────────────────────────────────────────────────────────────────
regression_trend_seasonal_forecast <- function(train_ts, h = 12) {
  x     <- as.numeric(train_ts)
  n     <- length(x)
  freq  <- frequency(train_ts)
  t_idx <- 1:n

  # Create seasonal dummy variables (Jan = reference)
  month_of <- ((t_idx - 1) %% freq) + 1
  dummies  <- model.matrix(~ factor(month_of))[, -1, drop = FALSE]   # drop intercept col
  colnames(dummies) <- paste0("M", 2:freq)

  mdl_df <- data.frame(y = x, t = t_idx, dummies)
  mdl    <- lm(y ~ ., data = mdl_df)

  fitted_vals <- as.numeric(predict(mdl))

  # Forecast
  t_fcast     <- (n + 1):(n + h)
  mo_fcast    <- ((t_fcast - 1) %% freq) + 1
  dum_fcast   <- model.matrix(~ factor(mo_fcast, levels = 1:freq))[, -1, drop = FALSE]
  colnames(dum_fcast) <- paste0("M", 2:freq)
  new_df      <- data.frame(t = t_fcast, dum_fcast)
  fcast       <- as.numeric(predict(mdl, newdata = new_df))

  list(fitted = fitted_vals, forecast = fcast,
       name = "Regression (Trend + Seasonal Dummies)",
       model = mdl)
}


# ─────────────────────────────────────────────────────────────────────────────
# Run all 10 methods and return a consolidated list
# ─────────────────────────────────────────────────────────────────────────────
#' @param train_ts  ts object (monthly, freq=12)
#' @param h         forecast horizon (default 12 months)
#' @return Named list of method results
run_all_methods <- function(train_ts, h = 12) {
  methods <- list(
    naive_forecast(train_ts, h),
    moving_average_forecast(train_ts, k = 3, h),
    weighted_ma_forecast(train_ts, k = 3, h),
    ses_forecast(train_ts, h = h),
    holt_forecast(train_ts, h = h),
    linear_trend_forecast(train_ts, h),
    seasonal_index_forecast(train_ts, h),
    additive_decomp_forecast(train_ts, h),
    multiplicative_decomp_forecast(train_ts, h),
    regression_trend_seasonal_forecast(train_ts, h)
  )
  names(methods) <- sapply(methods, `[[`, "name")
  methods
}
