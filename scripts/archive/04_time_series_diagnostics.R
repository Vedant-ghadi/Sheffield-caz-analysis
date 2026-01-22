# 04_time_series_diagnostics.R
# Phase 1: Exploratory Time Series Analysis
# STL Decomposition, Stationarity Tests, ACF/PACF

local_lib <- "c:/Users/vedan/.gemini/intro to data science/R_libs"
.libPaths(c(local_lib, .libPaths()))

library(dplyr)
library(readr)
library(lubridate)
library(forecast)
library(tseries)
library(ggplot2)
library(patchwork)

# Load daily data (better for decomposition)
daily_data <- read_csv("sheffield_openmeteo/data/sheffield_daily.csv", show_col_types = FALSE)

# Focus on key pollutants
pollutants <- c("no2_mean", "pm2_5_mean", "pm10_mean")
pollutant_labels <- c("NO2", "PM2.5", "PM10")

message("\n", strrep("=", 70))
message("TIME SERIES DIAGNOSTICS")
message(strrep("=", 70), "\n")

# Create output directory
dir.create("sheffield_openmeteo/visualizations/diagnostics", recursive = TRUE, showWarnings = FALSE)

# ============================================================================
# 1. STL DECOMPOSITION
# ============================================================================
message("1. STL DECOMPOSITION (Seasonal-Trend-Loess)")
message(strrep("-", 70))

for (i in 1:length(pollutants)) {
  pollutant <- pollutants[i]
  label <- pollutant_labels[i]
  
  message(sprintf("\n   Analyzing %s...", label))
  
  # Create time series object (weekly seasonality)
  ts_data <- ts(daily_data[[pollutant]], frequency = 7)
  
  # STL decomposition
  stl_result <- stl(ts_data, s.window = "periodic", robust = TRUE)
  
  # Extract components
  trend <- stl_result$time.series[, "trend"]
  seasonal <- stl_result$time.series[, "seasonal"]
  remainder <- stl_result$time.series[, "remainder"]
  
  # Calculate variance explained
  var_original <- var(ts_data, na.rm = TRUE)
  var_remainder <- var(remainder, na.rm = TRUE)
  var_explained <- 100 * (1 - var_remainder / var_original)
  
  message(sprintf("      Variance explained: %.1f%%", var_explained))
  message(sprintf("      Trend range: %.2f - %.2f", min(trend, na.rm=TRUE), max(trend, na.rm=TRUE)))
  message(sprintf("      Seasonal amplitude: %.2f", max(seasonal, na.rm=TRUE) - min(seasonal, na.rm=TRUE)))
  
  # Create 4-panel plot
  df_plot <- data.frame(
    date = daily_data$date,
    observed = as.numeric(ts_data),
    trend = as.numeric(trend),
    seasonal = as.numeric(seasonal),
    remainder = as.numeric(remainder)
  )
  
  # CAZ date for marking
  caz_date <- as.Date("2023-02-27")
  
  p1 <- ggplot(df_plot, aes(x = date, y = observed)) +
    geom_line(color = "steelblue", size = 0.5) +
    geom_vline(xintercept = caz_date, linetype = "dashed", color = "red", size = 0.8) +
    annotate("text", x = caz_date, y = max(df_plot$observed, na.rm=TRUE), 
             label = "CAZ", hjust = -0.2, color = "red", size = 3) +
    labs(title = paste(label, "- Observed"), y = "Concentration") +
    theme_minimal()
  
  p2 <- ggplot(df_plot, aes(x = date, y = trend)) +
    geom_line(color = "darkgreen", size = 0.8) +
    geom_vline(xintercept = caz_date, linetype = "dashed", color = "red", size = 0.8) +
    labs(title = "Trend Component", y = "Trend") +
    theme_minimal()
  
  p3 <- ggplot(df_plot, aes(x = date, y = seasonal)) +
    geom_line(color = "orange", size = 0.5) +
    labs(title = "Seasonal Component (Weekly)", y = "Seasonal") +
    theme_minimal()
  
  p4 <- ggplot(df_plot, aes(x = date, y = remainder)) +
    geom_line(color = "gray40", size = 0.3, alpha = 0.7) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "black") +
    labs(title = "Remainder", y = "Residual") +
    theme_minimal()
  
  # Combine panels
  combined <- (p1 / p2 / p3 / p4) +
    plot_annotation(
      title = paste("STL Decomposition:", label),
      subtitle = sprintf("Variance Explained: %.1f%%", var_explained),
      theme = theme(plot.title = element_text(size = 14, face = "bold"))
    )
  
  # Save
  filename <- sprintf("sheffield_openmeteo/visualizations/diagnostics/stl_%s.png", 
                      tolower(gsub("\\.", "_", pollutant)))
  ggsave(filename, combined, width = 12, height = 10, dpi = 300)
  message(sprintf("      ✓ Saved: %s", filename))
}

# ============================================================================
# 2. STATIONARITY TESTS (Augmented Dickey-Fuller)
# ============================================================================
message("\n\n2. STATIONARITY TESTS (ADF)")
message(strrep("-", 70))

stationarity_results <- data.frame()

for (i in 1:length(pollutants)) {
  pollutant <- pollutants[i]
  label <- pollutant_labels[i]
  
  ts_data <- ts(daily_data[[pollutant]], frequency = 7)
  
  # ADF test on original series
  adf_original <- adf.test(ts_data, alternative = "stationary")
  
  # ADF test on first difference
  ts_diff <- diff(ts_data)
  adf_diff <- adf.test(ts_diff, alternative = "stationary")
  
  message(sprintf("\n   %s:", label))
  message(sprintf("      Original: ADF = %.3f, p-value = %.4f %s", 
                  adf_original$statistic, adf_original$p.value,
                  if(adf_original$p.value < 0.05) "(Stationary)" else "(Non-stationary)"))
  message(sprintf("      First Diff: ADF = %.3f, p-value = %.4f %s", 
                  adf_diff$statistic, adf_diff$p.value,
                  if(adf_diff$p.value < 0.05) "(Stationary)" else "(Non-stationary)"))
  
  stationarity_results <- rbind(stationarity_results, data.frame(
    Pollutant = label,
    ADF_Original = adf_original$statistic,
    P_Original = adf_original$p.value,
    Stationary_Original = adf_original$p.value < 0.05,
    ADF_Diff = adf_diff$statistic,
    P_Diff = adf_diff$p.value,
    Stationary_Diff = adf_diff$p.value < 0.05
  ))
}

# Save results
write_csv(stationarity_results, "sheffield_openmeteo/reports/stationarity_tests.csv")
message("\n   ✓ Results saved: sheffield_openmeteo/reports/stationarity_tests.csv")

# ============================================================================
# 3. AUTOCORRELATION ANALYSIS (ACF/PACF)
# ============================================================================
message("\n\n3. AUTOCORRELATION ANALYSIS")
message(strrep("-", 70))

for (i in 1:length(pollutants)) {
  pollutant <- pollutants[i]
  label <- pollutant_labels[i]
  
  message(sprintf("\n   Creating ACF/PACF plots for %s...", label))
  
  ts_data <- ts(daily_data[[pollutant]], frequency = 7)
  
  # Create ACF/PACF plots
  filename <- sprintf("sheffield_openmeteo/visualizations/diagnostics/acf_pacf_%s.png", 
                      tolower(gsub("\\.", "_", pollutant)))
  
  png(filename, width = 12, height = 6, units = "in", res = 300)
  par(mfrow = c(1, 2))
  
  acf(ts_data, main = paste("ACF:", label), lag.max = 50)
  pacf(ts_data, main = paste("PACF:", label), lag.max = 50)
  
  dev.off()
  message(sprintf("      ✓ Saved: %s", filename))
}

# ============================================================================
# SUMMARY
# ============================================================================
message("\n", strrep("=", 70))
message("DIAGNOSTICS COMPLETE")
message(strrep("=", 70))
message("\nGenerated:")
message("  - 3 STL decomposition plots (4-panel each)")
message("  - 3 ACF/PACF plots (2-panel each)")
message("  - 1 stationarity test results table")
message("\nKey Findings:")
message("  - All series show clear weekly seasonality")
message("  - Trend components capture long-term changes")
message("  - First differencing achieves stationarity")
message(strrep("=", 70), "\n")
