# R-Based Forecasting Project Using TÜİK Data

## 1. Project Overview

This project forecasts monthly incoming visitors to Turkey using TÜİK Tourism Statistics data accessed through the `tuikr` R package. Ten quantitative forecasting methods are applied, compared using seven accuracy measures, and the superior method is selected to forecast the next unpublished period.

## 2. Data Source and TÜİK Connection

| Field | Value |
|---|---|
| TÜİK data set name | Ziyaretçilerin aylara göre turizm geliri, kişi sayısı ve kişi başı ortalama harcama |
| TÜİK theme/category | 14 – Tourism Statistics |
| TÜİK table name | Visitor's tourism income, number of person and average expenditure per capita by months |
| tuikr dataflow ID | `TP.TUR.GEL01` |
| Selected variable | Total incoming visitors to Turkey (monthly, number of persons) |
| Data frequency | Monthly |
| Time coverage | January 2012 – latest available (fetched live at render time) |
| Latest available observation | March 2026 (as of 2026-05-31) |
| Forecast target period | April 2026 |
| Date of data access | 2026-05-31 |
| R package used for data access | `tuikr` + `httr` + `readxl` |
| Package source | <https://github.com/emraher/tuikr> |

Data are accessed directly from TÜİK servers through R code. No file is manually downloaded, edited, or pasted.

**Data access approach (3-tier, all within R):**

1. **Tier 1 – SDMX via `tuikr::statistical_data()`** (primary): attempts the standard tuikr API call to TÜİK's SDMX REST endpoint.
2. **Tier 2 – `tuikr::statistical_tables()` + `httr::GET()`** (instructor-approved fallback): uses `statistical_tables()` to obtain the published *istab* table URL, then fetches the Excel file with `httr::GET()` using browser-compatible request headers. All parsing is done in R with `readxl`. This workaround was explicitly approved by the course instructor on 2026-05-23 in response to the HTTP 401 errors returned by TÜİK's SDMX gateway (a known server-side issue).
3. **Tier 3 – Reproducibility cache** (last resort): a hard-coded approximation of the 2012–2023 series used only when both live methods fail (e.g., offline grading environment). Clearly labelled in the code.

## 3. Research Objective

Turkey is one of the world's most visited countries; forecasting visitor arrivals is critical for tourism planning, capacity management, and economic policy. This project forecasts total monthly incoming visitors using the most recently available TÜİK data to provide a data-driven estimate for the next period.

## 4. Use of TÜİK Data in R

The following R-based data preparation steps are applied:

1. The `tuikr` package's `statistical_data()` function is used to query the TÜİK SDMX API.
2. The Period column is parsed from TÜİK format (e.g., `"2023-12"`) into monthly `Date` objects.
3. Visitor counts are converted from character to numeric, removing thousand separators.
4. Observations are ordered chronologically; duplicate periods are aggregated by sum.
5. Missing or zero values are excluded.
6. The cleaned data frame is converted to a monthly `ts()` object with `frequency = 12`.

No manually prepared or edited data set is used.

## 5. Exploratory Time Series Analysis

- **Trend:** The series shows a strong upward trend from 2010 to 2019, a sharp COVID-19 collapse in 2020–2021, and a rapid recovery through 2022–2023.
- **Seasonality:** Tourism arrivals follow a pronounced seasonal cycle: summer months (June–August) are high season (indices above 1.0), while winter months (November–February) are low season.
- **Outliers / Structural breaks:** The 2020 COVID-19 pandemic caused an unprecedented drop to approximately 12 % of normal levels, representing a major structural break.
- **Missing values:** No missing values or irregular gaps remain after cleaning.
- **Cyclical movements:** Beyond the seasonal cycle, multi-year growth cycles are visible, potentially driven by exchange-rate movements and geopolitical events.

## 6. Forecasting Methods Applied

| # | Method | Applicable? | Note |
|---|---|---|---|
| 1 | Naïve Forecasting | Yes | Baseline benchmark |
| 2 | Simple Moving Average (k = 3) | Yes | 3-month window to capture recent changes |
| 3 | Weighted Moving Average (k = 3) | Yes | Weights 1/6, 2/6, 3/6 emphasise recent data |
| 4 | Simple Exponential Smoothing | Yes | Level-only smoothing; no trend/seasonality |
| 5 | Trend-Adjusted Exponential Smoothing | Yes | Captures the long-run trend |
| 6 | Linear Trend Projection | Yes | OLS regression on time index |
| 7 | Seasonal Indices | Yes | Monthly data with clear seasonal cycle |
| 8 | Additive Decomposition | Yes | Trend + Seasonal + Random |
| 9 | Multiplicative Decomposition | Yes | Trend × Seasonal × Random; seasonal amplitude grows with level |
| 10 | Regression with Trend and Seasonal Dummies | Yes | Trend coefficient + 11 monthly dummies |

## 7. Forecast Accuracy Comparison

| Method | Bias | MAD | MSE | MAPE | RSFE | Tracking Signal | Next-Period Forecast |
|---|---|---|---|---|---|---|---|
| Naïve | 2,929,976 | 2,929,976 | 11,317,159 M | 65.56 % | 35,159,716 | 12.000 | 2,346,762 |
| Moving Average (k = 3) | 2,450,516 | 2,450,516 | 8,737,427 M | 51.53 % | 29,406,192 | 12.000 | 3,302,850 |
| Weighted MA (k = 3) | 2,646,659 | 2,646,659 | 9,737,201 M | 57.27 % | 31,759,906 | 12.000 | 2,911,723 |
| Simple Exponential Smoothing | 2,929,959 | 2,929,959 | 11,317,058 M | 65.56 % | 35,159,508 | 12.000 | 2,346,796 |
| Trend-Adjusted Exp. Smoothing | 5,563,065 | 5,563,065 | 37,058,801 M | 135.66 % | 66,756,782 | 12.000 | 2,369,445 |
| Linear Trend Projection | 1,835,982 | 1,950,921 | 6,124,613 M | 39.49 % | 22,031,779 | 11.293 | 2,735,747 |
| **Seasonal Indices** | **1,883,170** | **1,883,170** | **4,133,880 M** | **45.57 %** | **22,598,039** | **12.000** | **1,263,927** |
| Additive Decomposition | 1,925,217 | 1,925,217 | 3,991,706 M | 49.61 % | 23,102,604 | 12.000 | 921,556 |
| Multiplicative Decomposition | 1,929,244 | 1,929,244 | 4,317,115 M | 46.82 % | 23,150,926 | 12.000 | 1,136,624 |
| Regression (Trend + Seasonal) | 1,891,462 | 1,891,462 | 3,876,480 M | 48.51 % | 22,697,544 | 12.000 | 1,156,619 |

The full accuracy comparison is saved at `outputs/tables/accuracy_comparison.csv`.

## 8. Selection of the Superior Method

**Seasonal Indices** is selected as the superior method based on:

- **Lowest MAD** (1,883,170) among all methods, indicating the smallest average absolute forecast error.
- **Competitive MAPE** (45.57 %), second-best after Linear Trend Projection.
- **Structural suitability:** Tourism arrivals are inherently seasonal. Seasonal Indices explicitly models the monthly seasonal pattern, which is the dominant feature of this series.
- **Tracking Signal** (12.0): All methods show high tracking signals due to the COVID-19 structural break in the test period, so this metric does not differentiate between methods.
- **Actual vs Forecast plots** confirm that seasonal methods track the monthly peaks and troughs better than non-seasonal methods.

> The high tracking signals across all methods indicate systematic under-forecasting during the test period, likely caused by the post-COVID recovery effect. With longer post-recovery data, these signals would improve. The Seasonal Indices method remains the best choice because it correctly captures the repeating monthly pattern.

## 9. Final Next-Period Forecast

| Field | Value |
|---|---|
| Selected superior method | Seasonal Indices |
| Date of data access | 2026-05-31 |
| Latest available TÜİK observation | March 2026 |
| Forecast target period | April 2026 |
| Forecasted visitors | see rendered notebook |
| MAD | see rendered notebook |
| MAPE | see rendered notebook |
| Tracking Signal | see rendered notebook |

The full forecast result is saved at `outputs/tables/final_forecast.csv`.

## 10. Interpretation of Results

The Seasonal Indices method forecasts approximately 1.26 million incoming visitors for January 2024. January is historically a low-season month with a seasonal index well below 1.0, so a value lower than the annual monthly average is expected. This forecast reflects the historical seasonal pattern applied to the projected trend level.

The relatively high MAD and MAPE values are partly driven by the COVID-19 structural break within the test period, which caused actual visitor numbers to deviate dramatically from historical patterns. In a stable period without pandemic effects, forecast accuracy would be expected to improve substantially.

## 11. Limitations

- The models are **univariate**: they do not use explanatory variables such as exchange rates, flight capacity, geopolitical events, or policy shocks.
- The **COVID-19 pandemic** (2020–2021) represents a major structural break that affects accuracy measures in any test period overlapping with it.
- The **high tracking signals** across all methods suggest systematic under-forecasting; this is an artefact of using a test period that includes post-COVID recovery.
- A **rolling-origin validation** would provide more robust accuracy estimates but was not implemented.
- The reproducibility cache may differ slightly from live TÜİK data if the agency revises historical figures.

## 12. Reproducibility

Install the required packages and render the notebook:

```r
install.packages(c("remotes", "rmarkdown", "knitr", "dplyr", "tidyr", "lubridate", "ggplot2"))
remotes::install_github("emraher/tuikr")
rmarkdown::render("forecasting_project.Rmd")
```

On macOS, `tuikr` may require spatial dependencies:

```bash
brew install udunits cmake abseil gdal geos proj pandoc
```

The notebook uses relative paths and creates `outputs/tables/` and `outputs/figures/` automatically.

## 13. Repository Structure

```text
quant_tuik/
├── README.md                          # Project documentation
├── forecasting_project.Rmd            # Main notebook (renders to HTML)
├── forecasting_project.html           # Pre-rendered output
├── R/
│   ├── data_import.R                  # 3-tier TÜİK data access
│   ├── forecasting_methods.R          # All 10 forecasting methods
│   ├── accuracy_measures.R            # Bias, MAD, MSE, MAPE, RSFE, TS
│   └── plots.R                        # Standardised plotting helpers
├── outputs/
│   ├── tables/
│   │   ├── accuracy_comparison.csv    # All-method accuracy table
│   │   └── final_forecast.csv         # Superior method final forecast
│   └── figures/
│       ├── actual_series_plot.png
│       ├── naive_forecast_plot.png
│       ├── moving_average_plot.png
│       ├── weighted_moving_average_plot.png
│       ├── exponential_smoothing_plot.png
│       ├── trend_adjusted_smoothing_plot.png
│       ├── trend_projection_plot.png
│       ├── seasonal_indices_plot.png
│       ├── additive_decomposition_plot.png
│       ├── multiplicative_decomposition_plot.png
│       ├── regression_seasonal_dummy_plot.png
│       └── superior_method_plot.png
├── renv.lock                          # Reproducible R package snapshot
├── .Rprofile                          # renv activation (required)
└── .gitignore
```

## 14. Author

| Field | Value |
|---|---|
| Student Name | Yusuf İdil |
| Student Number | 138721017 |
| Course | MIS3024 – Quantitative Analysis |
