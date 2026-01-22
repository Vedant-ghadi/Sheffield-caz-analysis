# 07_causal_impact.R
# Phase 4: Bayesian Causal Impact Analysis
# Using Google's CausalImpact package

local_lib <- "c:/Users/vedan/.gemini/intro to data science/R_libs"
.libPaths(c(local_lib, .libPaths()))

library(dplyr)
library(readr)
library(CausalImpact)
library(ggplot2)

# Load daily data
daily_data <- read_csv("sheffield_openmeteo/data/sheffield_daily.csv", show_col_types = FALSE) %>%
  mutate(date = as.Date(date)) %>%
  filter(!is.na(date), !is.na(no2_mean), !is.na(pm2_5_mean), !is.na(pm10_mean))

# CAZ date
CAZ_DATE <- as.Date("2023-02-27")

message("\n", strrep("=", 70))
message("BAYESIAN CAUSAL IMPACT ANALYSIS")
message(strrep("=", 70), "\n")

# Pollutants to analyze
pollutants <- c("no2_mean", "pm2_5_mean", "pm10_mean")
pollutant_labels <- c("NO2", "PM2.5", "PM10")

# Store results
causal_results <- list()

# ============================================================================
# CAUSAL IMPACT ANALYSIS
# ============================================================================

for (i in 1:length(pollutants)) {
  pollutant <- pollutants[i]
  label <- pollutant_labels[i]
  
  message(strrep("-", 70))
  message(sprintf("CAUSAL IMPACT: %s", label))
  message(strrep("-", 70))
  
  # Prepare data matrix (response + covariates)
  # Use O3 as control (less affected by traffic/CAZ)
  data_matrix <- daily_data %>%
    select(date, !!sym(pollutant), o3_mean) %>%
    arrange(date)
  
  # Convert to zoo time series
  ts_data <- zoo::zoo(data_matrix[, -1], order.by = data_matrix$date)
  
  # Define periods
  pre_period <- c(min(data_matrix$date), CAZ_DATE - 1)
  post_period <- c(CAZ_DATE, max(data_matrix$date))
  
  message(sprintf("   Pre-period: %s to %s", pre_period[1], pre_period[2]))
  message(sprintf("   Post-period: %s to %s", post_period[1], post_period[2]))
  
  # Run CausalImpact
  message("   Running Bayesian structural time series...")
  impact <- CausalImpact(ts_data, pre_period, post_period)
  
  # Extract summary (CausalImpact has specific structure)
  summary_obj <- summary(impact)
  
  # Get key metrics from summary report
  # CausalImpact summary has: Actual, Prediction, AbsEffect, RelEffect
  avg_actual <- impact$summary$Average[1]
  avg_pred <- impact$summary$Average[2]
  avg_effect_abs <- impact$summary$Average[3]
  avg_effect_rel <- impact$summary$Average[4]
  
  cum_effect_abs <- impact$summary$Cumulative[3]
  cum_effect_rel <- impact$summary$Cumulative[4]
  
  p_value <- impact$summary$p[1]
  
  message(sprintf("\n   AVERAGE CAUSAL EFFECT:"))
  message(sprintf("      Actual: %.2f", avg_actual))
  message(sprintf("      Predicted (no CAZ): %.2f", avg_pred))
  message(sprintf("      Absolute effect: %.2f", avg_effect_abs))
  message(sprintf("      Relative effect: %.1f%%", avg_effect_rel))
  message(sprintf("      p-value: %.3f %s", p_value,
                  if(p_value < 0.001) "***" else if(p_value < 0.01) "**" else if(p_value < 0.05) "*" else ""))
  
  message(sprintf("\n   CUMULATIVE EFFECT:"))
  message(sprintf("      Absolute: %.1f", cum_effect_abs))
  message(sprintf("      Relative: %.1f%%", cum_effect_rel))
  
  # Store results
  causal_results[[label]] <- list(
    impact = impact,
    avg_effect_abs = avg_effect_abs,
    avg_effect_rel = avg_effect_rel,
    cum_effect_abs = cum_effect_abs,
    cum_effect_rel = cum_effect_rel,
    p_value = p_value
  )
  
  # Save plot
  filename <- sprintf("sheffield_openmeteo/visualizations/causal_impact_%s.png",
                      tolower(gsub("\\.", "_", pollutant)))
  
  png(filename, width = 12, height = 8, units = "in", res = 300)
  plot(impact)
  dev.off()
  
  message(sprintf("\n   ✓ Plot saved: %s\n", filename))
}

# ============================================================================
# SUMMARY TABLE
# ============================================================================

summary_table <- data.frame(
  Pollutant = pollutant_labels,
  Avg_Effect_Abs = sapply(causal_results, function(x) {
    val <- x$avg_effect_abs
    if(is.null(val) || is.na(val)) return(NA) else return(round(val, 2))
  }),
  Avg_Effect_Rel = sapply(causal_results, function(x) {
    val <- x$avg_effect_rel
    if(is.null(val) || is.na(val)) return(NA) else return(round(val, 1))
  }),
  Cum_Effect_Abs = sapply(causal_results, function(x) {
    val <- x$cum_effect_abs
    if(is.null(val) || is.na(val)) return(NA) else return(round(val, 1))
  }),
  P_Value = sapply(causal_results, function(x) {
    val <- x$p_value
    if(is.null(val) || is.na(val)) return(NA) else return(round(val, 3))
  }),
  Significant = sapply(causal_results, function(x) {
    val <- x$p_value
    if(is.null(val) || is.na(val)) return("Unknown") 
    else if(val < 0.05) return("Yes") else return("No")
  })
)

write_csv(summary_table, "sheffield_openmeteo/reports/causal_impact_results.csv")

message(strrep("=", 70))
message("CAUSAL IMPACT ANALYSIS COMPLETE")
message(strrep("=", 70))
print(summary_table)
message(strrep("=", 70), "\n")
