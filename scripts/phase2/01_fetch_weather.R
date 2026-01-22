# Phase 2: Fetch Weather Data
# Fetch historical weather data for Sheffield to use as controls in air quality models

# Set local library path
local_lib <- "c:/Users/vedan/.gemini/intro to data science/R_libs"
.libPaths(c(local_lib, .libPaths()))

# Load libraries
library(httr)
library(jsonlite)
library(dplyr)
library(readr)
library(lubridate)

# Set up paths
base_dir <- "sheffield_openmeteo"
data_dir <- file.path(base_dir, "data")
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)

message("======================================================================")
message("PHASE 2: METEOROLOGICAL DATA EXTRACTION")
message("======================================================================")

# 1. Define Parameters
# ----------------------------------------------------------------
LAT <- 53.3811
LON <- -1.4701
START_DATE <- "2022-01-01"
END_DATE <- "2025-12-31"  # Matching our air quality data

# Open-Meteo Historical Weather API
url <- "https://archive-api.open-meteo.com/v1/archive"

# We request variables crucial for air quality modeling:
# - Temperature: Affects chemical reactions and domestic heating use
# - Precipitation/Rain: "Washout" effect cleans the air
# - Wind Speed: Dispersion effect (high wind = lower pollution)
# - Wind Direction: Identifies source (e.g., wind from highway vs park)
params <- list(
  latitude = LAT,
  longitude = LON,
  start_date = START_DATE,
  end_date = END_DATE,
  daily = "temperature_2m_mean,precipitation_sum,rain_sum,snowfall_sum,wind_speed_10m_max,wind_direction_10m_dominant",
  timezone = "Europe/London"
)

# 2. Fetch Data
# ----------------------------------------------------------------
message("Fetching weather data from Open-Meteo Archive API...")
message(sprintf("Location: Sheffield (%s, %s)", LAT, LON))
message(sprintf("Period: %s to %s", START_DATE, END_DATE))

response <- GET(url, query = params)

# Check status
if (status_code(response) != 200) {
  stop(sprintf("API request failed with status %d", status_code(response)))
}

# Parse JSON
content_text <- content(response, "text", encoding = "UTF-8")
data_json <- fromJSON(content_text)

# Extract daily data
weather_df <- as.data.frame(data_json$daily) %>%
  mutate(date = as.Date(time)) %>%
  select(
    date,
    temp_mean = temperature_2m_mean,
    precip_sum = precipitation_sum,
    wind_speed_max = wind_speed_10m_max,
    wind_dir = wind_direction_10m_dominant
  )

message(sprintf("Successfully fetched %d daily weather records", nrow(weather_df)))

# 3. Merge with Air Quality Data
# ----------------------------------------------------------------
aq_file <- file.path(data_dir, "sheffield_daily.csv")

if (!file.exists(aq_file)) {
  stop("Base air quality data file (sheffield_daily.csv) not found! Run Phase 1 scripts first.")
}

message("Loading existing air quality data...")
aq_data <- read_csv(aq_file, show_col_types = FALSE)

message("Merging weather data...")
merged_data <- aq_data %>%
  left_join(weather_df, by = "date")

# check for missing weather data
missing_weather <- merged_data %>% filter(is.na(temp_mean)) %>% nrow()
if (missing_weather > 0) {
  warning(sprintf("%d rows have missing weather data!", missing_weather))
} else {
  message("Merge successful! No missing weather data.")
}

# 4. Save Enhanced Dataset
# ----------------------------------------------------------------
# We save as a NEW file to preserve the Phase 1 data integrity
output_file <- file.path(data_dir, "phase2_sheffield_daily_weather.csv")
write_csv(merged_data, output_file)

message(sprintf("Saved enhanced dataset to: %s", output_file))
message("Phase 2 Step 1 Complete! Ready for analysis.")
