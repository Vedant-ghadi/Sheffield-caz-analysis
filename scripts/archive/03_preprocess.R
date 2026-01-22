# 03_preprocess.R
# Preprocess Sheffield data for time series analysis

local_lib <- "c:/Users/vedan/.gemini/intro to data science/R_libs"
.libPaths(c(local_lib, .libPaths()))

library(dplyr)
library(readr)
library(lubridate)

INPUT_FILE <- "sheffield_openmeteo/data/sheffield_raw.csv"
OUTPUT_FILE <- "sheffield_openmeteo/data/sheffield_processed.csv"

message("\n", strrep("=", 70))
message("PREPROCESSING SHEFFIELD DATA")
message(strrep("=", 70), "\n")

# Load data
data <- read_csv(INPUT_FILE, show_col_types = FALSE)

# Parse time
data <- data %>%
  mutate(time = as.POSIXct(time, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))

message("1. Adding temporal features...")

# Add temporal features
data <- data %>%
  mutate(
    date = as.Date(time),
    year = year(time),
    month = month(time),
    day = day(time),
    hour = hour(time),
    dow = wday(time, label = TRUE),  # Day of week
    week = week(time),
    quarter = quarter(time),
    
    # Season (meteorological)
    season = case_when(
      month %in% c(12, 1, 2) ~ "Winter",
      month %in% c(3, 4, 5) ~ "Spring",
      month %in% c(6, 7, 8) ~ "Summer",
      month %in% c(9, 10, 11) ~ "Autumn"
    ),
    
    # Weekend indicator
    is_weekend = dow %in% c("Sat", "Sun"),
    
    # Rush hour indicator (7-9 AM, 4-6 PM on weekdays)
    is_rush_hour = !is_weekend & (hour %in% c(7, 8, 16, 17))
  )

message("   ✓ Added: year, month, day, hour, dow, week, quarter, season")
message("   ✓ Added: is_weekend, is_rush_hour")

# CAZ indicator
message("\n2. Adding CAZ intervention indicator...")
CAZ_DATE <- as.Date("2023-02-27")

data <- data %>%
  mutate(
    caz_period = if_else(date >= CAZ_DATE, "Post-CAZ", "Pre-CAZ"),
    caz_indicator = if_else(date >= CAZ_DATE, 1, 0),
    days_since_caz = as.numeric(date - CAZ_DATE)
  )

pre_count <- sum(data$caz_indicator == 0)
post_count <- sum(data$caz_indicator == 1)
message("   ✓ Pre-CAZ: ", pre_count, " records")
message("   ✓ Post-CAZ: ", post_count, " records")

# Create daily aggregates for some analyses
message("\n3. Creating daily aggregates...")
daily_data <- data %>%
  group_by(date, caz_period, caz_indicator) %>%
  summarise(
    pm10_mean = mean(pm10, na.rm = TRUE),
    pm2_5_mean = mean(pm2_5, na.rm = TRUE),
    no2_mean = mean(nitrogen_dioxide, na.rm = TRUE),
    o3_mean = mean(ozone, na.rm = TRUE),
    
    pm10_max = max(pm10, na.rm = TRUE),
    pm2_5_max = max(pm2_5, na.rm = TRUE),
    no2_max = max(nitrogen_dioxide, na.rm = TRUE),
    
    .groups = "drop"
  ) %>%
  mutate(
    year = year(date),
    month = month(date),
    dow = wday(date, label = TRUE),
    season = case_when(
      month(date) %in% c(12, 1, 2) ~ "Winter",
      month(date) %in% c(3, 4, 5) ~ "Spring",
      month(date) %in% c(6, 7, 8) ~ "Summer",
      month(date) %in% c(9, 10, 11) ~ "Autumn"
    )
  )

message("   ✓ Created daily dataset: ", nrow(daily_data), " days")

# Save both datasets
message("\n4. Saving processed data...")
write_csv(data, OUTPUT_FILE)
message("   ✓ Hourly data: ", OUTPUT_FILE)

daily_output <- "sheffield_openmeteo/data/sheffield_daily.csv"
write_csv(daily_data, daily_output)
message("   ✓ Daily data: ", daily_output)

# Summary
message("\n", strrep("=", 70))
message("PREPROCESSING COMPLETE")
message(strrep("=", 70))
message("Hourly records: ", nrow(data))
message("Daily records: ", nrow(daily_data))
message("Features added: ", ncol(data) - 8, " new columns")
message(strrep("=", 70), "\n")
