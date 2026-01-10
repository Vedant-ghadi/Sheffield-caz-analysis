# 05_arima_models.R
# Phase 2: ARIMA/SARIMA Forecasting
# Train on pre-CAZ, forecast post-CAZ, compare to actual

local_lib <- "c:/Users/vedan/.gemini/intro to data science/R_libs"
.libPaths(c(local_lib, .libPaths()))

library(dplyr)
library(readr)
library(forecast)
library(ggplot2)
library(patchwork)

# Load daily data
daily_data <- read_csv("sheffield_openmeteo/data/sheffield_daily.csv", show_col_types = FALSE)

# CAZ date
CAZ_DATE <- as.Date("2023-02-27")

# Split data
pre_caz <- daily_data %>% filter(date < CAZ_DATE)
post_caz <- daily_data %>% filter(date >= CAZ_DATE)

message("\n", strrep("=", 70))
message("ARIMA/SARIMA MODELING")
message(strrep("=", 70))
message("\nTraining period: ", min(pre_caz$date), " to ", max(pre_caz$date))
message("Forecast period: ", min(post_caz$date), " to ", max(post_caz$date))
message("Training days: ", nrow(pre_caz))
message("Forecast days: ", nrow(post_caz), "\n")

# Pollutants to model
pollutants <- c("no2_mean", "pm2_5_mean", "pm10_mean")
pollutant_labels <- c("NO2", "PM2.5", "PM10")

# Store results
model_results <- list()
forecast_plots <- list()

# ============================================================================
# BUILD MODELS
# ============================================================================

for (i in 1:length(pollutants)) {
  pollutant <- pollutants[i]
  label <- pollutant_labels[i]
  
  message(strrep("-", 70))
  message(sprintf("MODELING: %s", label))
  message(strrep("-", 70))
  
  # Create time series (weekly seasonality)
  ts_train <- ts(pre_caz[[pollutant]], frequency = 7)
  
  # Auto ARIMA with seasonality
  message("   Fitting auto.arima...")
  model <- auto.arima(ts_train, seasonal = TRUE, stepwise = FALSE, 
                      approximation = FALSE, trace = FALSE)
  
  message(sprintf("   Model: %s", paste(arimaorder(model), collapse=",")))
  message(sprintf("   AIC: %.2f", AIC(model)))
  message(sprintf("   BIC: %.2f", BIC(model)))
  
  # Forecast
  message("   Generating forecast...")
  fc <- forecast(model, h = nrow(post_caz))
  
  # Calculate metrics
  actual <- post_caz[[pollutant]]
  predicted <- as.numeric(fc$mean)
  
  rmse <- sqrt(mean((actual - predicted)^2, na.rm = TRUE))
  mae <- mean(abs(actual - predicted), na.rm = TRUE)
  mape <- mean(abs((actual - predicted) / actual) * 100, na.rm = TRUE)
  
  # Calculate CAZ effect
  mean_actual <- mean(actual, na.rm = TRUE)
  mean_forecast <- mean(predicted, na.rm = TRUE)
  caz_effect_absolute <- mean_actual - mean_forecast
  caz_effect_percent <- 100 * caz_effect_absolute / mean_forecast
  
  message(sprintf("   RMSE: %.2f", rmse))
  message(sprintf("   MAE: %.2f", mae))
  message(sprintf("   MAPE: %.2f%%", mape))
  message(sprintf("\n   CAZ EFFECT ESTIMATE:"))
  message(sprintf("   Actual mean: %.2f", mean_actual))
  message(sprintf("   Forecast mean: %.2f", mean_forecast))
  message(sprintf("   Difference: %.2f (%.1f%%)", caz_effect_absolute, caz_effect_percent))
  
  # Store results
  model_results[[label]] <- list(
    model = model,
    forecast = fc,
    actual = actual,
    predicted = predicted,
    rmse = rmse,
    mae = mae,
    mape = mape,
    caz_effect_absolute = caz_effect_absolute,
    caz_effect_percent = caz_effect_percent
  )
  
  # Create forecast plot
  df_plot <- data.frame(
    date = c(pre_caz$date, post_caz$date),
    value = c(pre_caz[[pollutant]], actual),
    type = c(rep("Training", nrow(pre_caz)), rep("Actual", nrow(post_caz)))
  )
  
  df_forecast <- data.frame(
    date = post_caz$date,
    forecast = predicted,
    lower80 = as.numeric(fc$lower[, 1]),
    upper80 = as.numeric(fc$upper[, 1]),
    lower95 = as.numeric(fc$lower[, 2]),
    upper95 = as.numeric(fc$upper[, 2])
  )
  
  p <- ggplot() +
    # Training data
    geom_line(data = df_plot %>% filter(type == "Training"),
              aes(x = date, y = value), color = "gray40", size = 0.5) +
    # Actual post-CAZ
    geom_line(data = df_plot %>% filter(type == "Actual"),
              aes(x = date, y = value), color = "steelblue", size = 0.8) +
    # Forecast (counterfactual)
    geom_line(data = df_forecast, aes(x = date, y = forecast), 
              color = "red", linetype = "dashed", size = 0.8) +
    # Confidence intervals
    geom_ribbon(data = df_forecast, aes(x = date, ymin = lower95, ymax = upper95),
                fill = "red", alpha = 0.1) +
    geom_ribbon(data = df_forecast, aes(x = date, ymin = lower80, ymax = upper80),
                fill = "red", alpha = 0.2) +
    # CAZ line
    geom_vline(xintercept = CAZ_DATE, linetype = "solid", color = "darkgreen", size = 1) +
    annotate("text", x = CAZ_DATE, y = max(df_plot$value, na.rm=TRUE), 
             label = "CAZ", hjust = -0.2, color = "darkgreen", size = 4, fontface = "bold") +
    # Effect annotation
    annotate("text", x = median(post_caz$date), y = min(df_plot$value, na.rm=TRUE),
             label = sprintf("Effect: %.1f%%", caz_effect_percent),
             size = 4, color = if(caz_effect_percent < 0) "darkgreen" else "red") +
    labs(
      title = paste("ARIMA Forecast:", label),
      subtitle = sprintf("Model: ARIMA%s | RMSE: %.2f | MAE: %.2f", 
                        paste(arimaorder(model), collapse=","), rmse, mae),
      x = "Date",
      y = paste(label, "Concentration")
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 10, color = "gray30")
    )
  
  forecast_plots[[label]] <- p
  
  # Save individual plot
  filename <- sprintf("sheffield_openmeteo/visualizations/arima_%s.png", 
                      tolower(gsub("\\.", "_", pollutant)))
  ggsave(filename, p, width = 12, height = 6, dpi = 300)
  message(sprintf("   ✓ Plot saved: %s\n", filename))
}

# ============================================================================
# SUMMARY TABLE
# ============================================================================

summary_table <- data.frame(
  Pollutant = pollutant_labels,
  Model = sapply(model_results, function(x) paste(arimaorder(x$model), collapse=",")),
  RMSE = sapply(model_results, function(x) round(x$rmse, 2)),
  MAE = sapply(model_results, function(x) round(x$mae, 2)),
  MAPE = sapply(model_results, function(x) round(x$mape, 1)),
  CAZ_Effect_Absolute = sapply(model_results, function(x) round(x$caz_effect_absolute, 2)),
  CAZ_Effect_Percent = sapply(model_results, function(x) round(x$caz_effect_percent, 1))
)

write_csv(summary_table, "sheffield_openmeteo/reports/arima_results.csv")

message(strrep("=", 70))
message("ARIMA MODELING COMPLETE")
message(strrep("=", 70))
print(summary_table)
message(strrep("=", 70), "\n")
