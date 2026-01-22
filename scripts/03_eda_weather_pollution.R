# Phase 2: Weather vs. Pollution Analysis (EDA)
# Goal: Visualize correlations to justify adding weather controls

local_lib <- "c:/Users/vedan/.gemini/intro to data science/R_libs"
.libPaths(c(local_lib, .libPaths()))

library(dplyr)
library(readr)
library(ggplot2)
library(tidyr)
library(lubridate)
library(patchwork)

# Set up paths
base_dir <- "sheffield_openmeteo"
data_dir <- file.path(base_dir, "data")
viz_dir <- file.path(base_dir, "visualizations/phase2")
if (!dir.exists(viz_dir)) dir.create(viz_dir, recursive = TRUE)

message("======================================================================")
message("PHASE 2: WEATHER CORRELATION ANALYSIS")
message("======================================================================")

# 1. Load Data
input_file <- file.path(data_dir, "phase2_sheffield_daily_weather.csv")
data <- read_csv(input_file, show_col_types = FALSE) %>%
  filter(!is.na(no2_mean), !is.na(temp_mean))

# 2. Correlation Analysis
# ----------------------------------------------------------------
cor_mat <- data %>%
  select(no2_mean, pm2_5_mean, temp_mean, precip_sum, wind_speed_max) %>%
  cor(use = "complete.obs")

message("Correlations with NO2:")
print(cor_mat["no2_mean", ])

# 3. Visualizations
# ----------------------------------------------------------------

# A. Scatter Plots (Pollution vs Weather)
p1 <- ggplot(data, aes(x = wind_speed_max, y = no2_mean)) +
  geom_point(alpha = 0.3, color = "darkblue") +
  geom_smooth(method = "lm", color = "red") +
  labs(title = "Wind Speed vs. NO2", x = "Box Max Wind Speed (km/h)", y = "NO2") +
  theme_minimal()

p2 <- ggplot(data, aes(x = temp_mean, y = no2_mean)) +
  geom_point(alpha = 0.3, color = "darkorange") +
  geom_smooth(method = "loess", color = "red") +
  labs(title = "Temperature vs. NO2", x = "Mean Temp (C)", y = "NO2") +
  theme_minimal()

# B. Time Series Overlay
p3 <- data %>%
  select(date, no2_mean, wind_speed_max) %>%
  pivot_longer(-date, names_to = "measure", values_to = "value") %>%
  mutate(measure = factor(measure, labels = c("NO2", "Wind Speed"))) %>%
  ggplot(aes(x = date, y = value, color = measure)) +
  geom_line(alpha = 0.7) +
  facet_wrap(~measure, scales = "free_y", ncol = 1) +
  labs(title = "Temporal Relationship: High Wind events coincide with Low NO2", x = NULL, y = NULL) +
  theme_minimal() +
  theme(legend.position = "none")

# Combine
composite <- (p1 + p2) / p3 +
  plot_annotation(
    title = "Why Weather Matters: Meteorological Drivers of Pollution",
    subtitle = "Sheffield Data (2022-2025)",
    theme = theme(plot.title = element_text(face = "bold", size = 16))
  )

# Save
ggsave(file.path(viz_dir, "02_weather_correlations.png"), composite, width = 12, height = 10)
message(sprintf("Saved plot to %s", file.path(viz_dir, "02_weather_correlations.png")))
