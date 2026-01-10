# 06_interrupted_time_series.R
# Phase 3: Interrupted Time Series (ITS) Analysis
# Segmented regression for policy evaluation

local_lib <- "c:/Users/vedan/.gemini/intro to data science/R_libs"
.libPaths(c(local_lib, .libPaths()))

library(dplyr)
library(readr)
library(lubridate)
library(ggplot2)
library(broom)

# Load daily data
daily_data <- read_csv("sheffield_openmeteo/data/sheffield_daily.csv", show_col_types = FALSE)

# Parse date column
daily_data <- daily_data %>%
  mutate(date = as.Date(date))

# CAZ date
CAZ_DATE <- as.Date("2023-02-27")

# Remove rows with NA values in key columns
daily_data <- daily_data %>%
  filter(!is.na(date), !is.na(no2_mean), !is.na(pm2_5_mean), !is.na(pm10_mean))

# Prepare data for ITS
daily_data <- daily_data %>%
  mutate(
    # Time variable (days from start)
    time = as.numeric(date - min(date)),
    
    # Intervention indicator (0 = pre, 1 = post)
    intervention = if_else(date >= CAZ_DATE, 1, 0),
    
    # Time since intervention (0 before CAZ, days after CAZ post)
    time_since_intervention = if_else(date >= CAZ_DATE, 
                                      as.numeric(date - CAZ_DATE), 0)
  )

message("\n", strrep("=", 70))
message("INTERRUPTED TIME SERIES (ITS) ANALYSIS")
message(strrep("=", 70), "\n")

# Pollutants
pollutants <- c("no2_mean", "pm2_5_mean", "pm10_mean")
pollutant_labels <- c("NO2", "PM2.5", "PM10")

# Store results
its_results <- list()

# ============================================================================
# SEGMENTED REGRESSION MODELS
# ============================================================================

for (i in 1:length(pollutants)) {
  pollutant <- pollutants[i]
  label <- pollutant_labels[i]
  
  message(strrep("-", 70))
  message(sprintf("ITS ANALYSIS: %s", label))
  message(strrep("-", 70))
  
  # Model: Y = β0 + β1*time + β2*intervention + β3*time_since_intervention
  # β2 = immediate level change
  # β3 = slope change (trend difference)
  # Simplified model without factor controls to avoid issues
  
  formula_str <- paste0(pollutant, " ~ time + intervention + time_since_intervention")
  
  model <- lm(as.formula(formula_str), data = daily_data)
  
  # Extract coefficients
  coef_summary <- tidy(model, conf.int = TRUE)
  
  # Key coefficients
  beta_intervention <- coef_summary %>% filter(term == "intervention")
  beta_time_since <- coef_summary %>% filter(term == "time_since_intervention")
  
  # Calculate effects
  immediate_effect <- beta_intervention$estimate
  immediate_se <- beta_intervention$std.error
  immediate_p <- beta_intervention$p.value
  
  slope_change <- beta_time_since$estimate
  slope_se <- beta_time_since$std.error
  slope_p <- beta_time_since$p.value
  
  # Model fit
  r_squared <- summary(model)$r.squared
  adj_r_squared <- summary(model)$adj.r.squared
  
  message(sprintf("\n   Model R²: %.3f (Adjusted: %.3f)", r_squared, adj_r_squared))
  message(sprintf("\n   IMMEDIATE LEVEL CHANGE (β2):"))
  message(sprintf("      Estimate: %.3f (SE: %.3f)", immediate_effect, immediate_se))
  message(sprintf("      95%% CI: [%.3f, %.3f]", 
                  beta_intervention$conf.low, beta_intervention$conf.high))
  message(sprintf("      p-value: %.4f %s", immediate_p, 
                  if(immediate_p < 0.001) "***" else if(immediate_p < 0.01) "**" else if(immediate_p < 0.05) "*" else ""))
  
  message(sprintf("\n   SLOPE CHANGE (β3):"))
  message(sprintf("      Estimate: %.4f (SE: %.4f)", slope_change, slope_se))
  message(sprintf("      95%% CI: [%.4f, %.4f]", 
                  beta_time_since$conf.low, beta_time_since$conf.high))
  message(sprintf("      p-value: %.4f %s", slope_p,
                  if(slope_p < 0.001) "***" else if(slope_p < 0.01) "**" else if(slope_p < 0.05) "*" else ""))
  
  # Store results
  its_results[[label]] <- list(
    model = model,
    immediate_effect = immediate_effect,
    immediate_p = immediate_p,
    slope_change = slope_change,
    slope_p = slope_p,
    r_squared = r_squared
  )
  
  # Create ITS plot
  # Predict values for visualization
  daily_data$predicted <- predict(model, daily_data)
  
  # Create counterfactual (what would have happened without intervention)
  daily_data_counterfactual <- daily_data %>%
    mutate(
      intervention = 0,
      time_since_intervention = 0
    )
  daily_data$counterfactual <- predict(model, daily_data_counterfactual)
  
  p <- ggplot(daily_data, aes(x = date)) +
    # Actual data points (semi-transparent)
    geom_point(aes(y = !!sym(pollutant)), alpha = 0.3, size = 0.5, color = "gray40") +
    
    # Fitted regression lines
    geom_line(aes(y = predicted, color = "Fitted (with CAZ)"), size = 1.2) +
    geom_line(data = daily_data %>% filter(date >= CAZ_DATE),
              aes(y = counterfactual, color = "Counterfactual (no CAZ)"), 
              linetype = "dashed", size = 1.2) +
    
    # CAZ intervention line
    geom_vline(xintercept = CAZ_DATE, linetype = "solid", color = "darkgreen", size = 1) +
    annotate("text", x = CAZ_DATE, y = max(daily_data[[pollutant]], na.rm=TRUE),
             label = "CAZ", hjust = -0.2, color = "darkgreen", size = 5, fontface = "bold") +
    
    # Effect annotations
    annotate("text", x = CAZ_DATE + 200, y = min(daily_data[[pollutant]], na.rm=TRUE),
             label = sprintf("Level change: %.2f%s\nSlope change: %.4f%s",
                            immediate_effect, if(immediate_p < 0.05) "*" else "",
                            slope_change, if(slope_p < 0.05) "*" else ""),
             size = 4, hjust = 0, color = "darkblue") +
    
    scale_color_manual(values = c("Fitted (with CAZ)" = "steelblue", 
                                   "Counterfactual (no CAZ)" = "red")) +
    labs(
      title = paste("Interrupted Time Series:", label),
      subtitle = sprintf("R² = %.3f | Immediate effect: %.2f (p=%.4f) | Slope change: %.4f (p=%.4f)",
                        r_squared, immediate_effect, immediate_p, slope_change, slope_p),
      x = "Date",
      y = paste(label, "Concentration"),
      color = NULL
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 9, color = "gray30"),
      legend.position = "bottom"
    )
  
  # Save plot
  filename <- sprintf("sheffield_openmeteo/visualizations/its_%s.png",
                      tolower(gsub("\\.", "_", pollutant)))
  ggsave(filename, p, width = 12, height = 7, dpi = 300)
  message(sprintf("\n   ✓ Plot saved: %s\n", filename))
}

# ============================================================================
# SUMMARY TABLE
# ============================================================================

summary_table <- data.frame(
  Pollutant = pollutant_labels,
  R_Squared = sapply(its_results, function(x) round(x$r_squared, 3)),
  Immediate_Effect = sapply(its_results, function(x) round(x$immediate_effect, 3)),
  Immediate_P = sapply(its_results, function(x) round(x$immediate_p, 4)),
  Slope_Change = sapply(its_results, function(x) round(x$slope_change, 4)),
  Slope_P = sapply(its_results, function(x) round(x$slope_p, 4)),
  Significant = sapply(its_results, function(x) 
    if(x$immediate_p < 0.05 | x$slope_p < 0.05) "Yes" else "No")
)

write_csv(summary_table, "sheffield_openmeteo/reports/its_results.csv")

message(strrep("=", 70))
message("ITS ANALYSIS COMPLETE")
message(strrep("=", 70))
print(summary_table)
message(strrep("=", 70), "\n")
