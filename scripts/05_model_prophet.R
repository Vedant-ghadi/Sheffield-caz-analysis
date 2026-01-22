# Phase 2: Weather-Normalized Prophet Model
# Goal: Re-evaluate CAZ impact after controlling for weather variations

local_lib <- "c:/Users/vedan/.gemini/intro to data science/R_libs"
.libPaths(c(local_lib, .libPaths()))

library(prophet)
library(dplyr)
library(readr)
library(ggplot2)
library(lubridate)

# Set up paths
base_dir <- "sheffield_openmeteo"
data_dir <- file.path(base_dir, "data")
viz_dir <- file.path(base_dir, "visualizations/phase2")
if (!dir.exists(viz_dir)) dir.create(viz_dir, recursive = TRUE)

message("======================================================================")
message("PHASE 2: WEATHER-NORMALIZED PROPHET MODELING")
message("======================================================================")

# 1. Load Data
# ----------------------------------------------------------------
input_file <- file.path(data_dir, "phase2_sheffield_daily_weather.csv")
data <- read_csv(input_file, show_col_types = FALSE)

CAZ_DATE <- as.Date("2023-02-27")

# Filter data
model_df <- data %>%
  filter(!is.na(no2_mean), !is.na(temp_mean)) %>%
  select(ds = date, y = no2_mean, temp_mean, precip_sum, wind_speed_max) 

# Split Train/Test
train_df <- model_df %>% filter(ds < CAZ_DATE)
test_df <- model_df %>% filter(ds >= CAZ_DATE)

message(sprintf("Training Data: %d days (Pre-CAZ)", nrow(train_df)))
message(sprintf("Testing Data: %d days (Post-CAZ)", nrow(test_df)))

# 2. Fit Weather Model
# ----------------------------------------------------------------
message("\nFitting Prophet model with weather regressors...")

# Initialize model
m <- prophet(daily.seasonality = FALSE, weekly.seasonality = TRUE, yearly.seasonality = TRUE, changepoint.prior.scale = 0.05)

# Add regressors (The Magic Part)
m <- add_regressor(m, "temp_mean")
m <- add_regressor(m, "precip_sum")
m <- add_regressor(m, "wind_speed_max")

# Fit
m <- fit.prophet(m, train_df)

# 3. Forecast Counterfactual
# ----------------------------------------------------------------
message("Generating counterfactual forecast...")

# Prediction dataframe must include future weather values (which we have!)
future <- model_df %>% select(ds, temp_mean, precip_sum, wind_speed_max)

forecast <- predict(m, future)

# 4. Calculate Impact
# ----------------------------------------------------------------
results <- forecast %>%
  select(ds, yhat, yhat_lower, yhat_upper) %>%
  left_join(model_df %>% select(ds, y), by = "ds") %>%
  filter(ds >= CAZ_DATE) %>%
  mutate(
    diff = y - yhat,
    diff_pct = (y - yhat) / yhat * 100,
    is_significant = y < yhat_lower
  )

mean_actual <- mean(results$y, na.rm = TRUE)
mean_pred <- mean(results$yhat, na.rm = TRUE)
reduction <- (mean_actual - mean_pred) / mean_pred * 100

message("\nRESULTS (Weather-Normalized):")
message(sprintf("Mean Actual NO2: %.2f", mean_actual))
message(sprintf("Mean Predicted NO2: %.2f (Counterfactual)", mean_pred))
message(sprintf("Reduction: %.1f%%", reduction))

# Compare with Phase 1 (Raw)
# Phase 1 was ~44.2%. If this is lower, weather explains some of it.
# If it stays high, the policy is robust.

# 5. Visualize
# ----------------------------------------------------------------
p <- ggplot(results, aes(x = ds)) +
  geom_ribbon(aes(ymin = yhat_lower, ymax = yhat_upper), fill = "blue", alpha = 0.2) +
  geom_line(aes(y = yhat, color = "Counterfactual (Expected)")) +
  geom_line(aes(y = y, color = "Actual")) +
  geom_vline(xintercept = CAZ_DATE, linetype = "dashed") +
  scale_color_manual(values = c("Actual" = "black", "Counterfactual (Expected)" = "blue")) +
  labs(
    title = "Weather-Normalized Impact of Sheffield CAZ",
    subtitle = sprintf("Controlling for Temp, Wind, Rain | Reduction: %.1f%%", abs(reduction)),
    y = "NO2 (ug/m3)", x = "Date"
  ) +
  theme_minimal()

ggsave(file.path(viz_dir, "03_prophet_weather_impact.png"), p, width = 10, height = 6)
message(sprintf("Saved plot to %s", file.path(viz_dir, "03_prophet_weather_impact.png")))

# Save numeric results
write_csv(results, file.path(base_dir, "reports/phase2_prophet_weather_results.csv"))
