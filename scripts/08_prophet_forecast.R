# 08_prophet_forecast.R
# Prophet (Facebook) Forecasting Analysis
# Modern alternative to ARIMA - handles seasonality/holidays automatically

local_lib <- "c:/Users/vedan/.gemini/intro to data science/R_libs"
.libPaths(c(local_lib, .libPaths()))

library(dplyr)
library(readr)
library(prophet)
library(ggplot2)

# Load daily data
daily_data <- read_csv("sheffield_openmeteo/data/sheffield_daily.csv", show_col_types = FALSE) %>%
  mutate(date = as.Date(date)) %>%
  filter(!is.na(date), !is.na(no2_mean), !is.na(pm2_5_mean), !is.na(pm10_mean))

# CAZ date
CAZ_DATE <- as.Date("2023-02-27")

# Split data
pre_caz <- daily_data %>% filter(date < CAZ_DATE)
post_caz <- daily_data %>% filter(date >= CAZ_DATE)

message("\n", strrep("=", 70))
message("PROPHET FORECASTING ANALYSIS")
message(strrep("=", 70))
message("\nTraining period: ", min(pre_caz$date), " to ", max(pre_caz$date))
message("Forecast period: ", min(post_caz$date), " to ", max(post_caz$date))
message("Training days: ", nrow(pre_caz))
message("Forecast days: ", nrow(post_caz), "\n")

# Pollutants
pollutants <- c("no2_mean", "pm2_5_mean", "pm10_mean")
pollutant_labels <- c("NO2", "PM2.5", "PM10")

# Store results
prophet_results <- list()

# ============================================================================
# PROPHET MODELS
# ============================================================================

for (i in 1:length(pollutants)) {
  pollutant <- pollutants[i]
  label <- pollutant_labels[i]
  
  message(strrep("-", 70))
  message(sprintf("PROPHET FORECAST: %s", label))
  message(strrep("-", 70))
  
  # Prepare data for Prophet (requires 'ds' and 'y' columns)
  df_train <- data.frame(
    ds = pre_caz$date,
    y = pre_caz[[pollutant]]
  )
  
  # Fit Prophet model
  message("   Fitting Prophet model...")
  m <- prophet(df_train, 
               daily.seasonality = FALSE,
               weekly.seasonality = TRUE,
               yearly.seasonality = TRUE,
               changepoint.prior.scale = 0.05)  # Controls flexibility
  
  # Create future dataframe
  future <- data.frame(ds = post_caz$date)
  
  # Forecast
  message("   Generating forecast...")
  forecast <- predict(m, future)
  
  # Calculate metrics
  actual <- post_caz[[pollutant]]
  predicted <- forecast$yhat
  
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
  prophet_results[[label]] <- list(
    model = m,
    forecast = forecast,
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
    lower = forecast$yhat_lower,
    upper = forecast$yhat_upper
  )
  
  p <- ggplot() +
    # Training data
    geom_line(data = df_plot %>% filter(type == "Training"),
              aes(x = date, y = value), color = "gray40", size = 0.5) +
    # Actual post-CAZ
    geom_line(data = df_plot %>% filter(type == "Actual"),
              aes(x = date, y = value), color = "steelblue", size = 0.8) +
    # Prophet forecast
    geom_line(data = df_forecast, aes(x = date, y = forecast), 
              color = "red", linetype = "dashed", size = 0.8) +
    # Uncertainty intervals
    geom_ribbon(data = df_forecast, aes(x = date, ymin = lower, ymax = upper),
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
      title = paste("Prophet Forecast:", label),
      subtitle = sprintf("RMSE: %.2f | MAE: %.2f | MAPE: %.1f%%", rmse, mae, mape),
      x = "Date",
      y = paste(label, "Concentration")
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 10, color = "gray30")
    )
  
  # Save plot
  filename <- sprintf("sheffield_openmeteo/visualizations/prophet_%s.png", 
                      tolower(gsub("\\.", "_", pollutant)))
  ggsave(filename, p, width = 12, height = 6, dpi = 300)
  message(sprintf("   ✓ Plot saved: %s\n", filename))
}

# ============================================================================
# SUMMARY TABLE
# ============================================================================

summary_table <- data.frame(
  Pollutant = pollutant_labels,
  RMSE = sapply(prophet_results, function(x) round(x$rmse, 2)),
  MAE = sapply(prophet_results, function(x) round(x$mae, 2)),
  MAPE = sapply(prophet_results, function(x) round(x$mape, 1)),
  CAZ_Effect_Absolute = sapply(prophet_results, function(x) round(x$caz_effect_absolute, 2)),
  CAZ_Effect_Percent = sapply(prophet_results, function(x) round(x$caz_effect_percent, 1))
)

write_csv(summary_table, "sheffield_openmeteo/reports/prophet_results.csv")

message(strrep("=", 70))
message("PROPHET FORECASTING COMPLETE")
message(strrep("=", 70))
print(summary_table)
message(strrep("=", 70), "\n")
