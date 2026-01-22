# Phase 2: Fetch HOURLY Weather Data
# Goal: Get hourly weather to match hourly air quality data

local_lib <- "c:/Users/vedan/.gemini/intro to data science/R_libs"
.libPaths(c(local_lib, .libPaths()))

library(httr)
library(jsonlite)
library(dplyr)
library(readr)
library(lubridate)

base_dir <- "sheffield_openmeteo"
data_dir <- file.path(base_dir, "data")

message("======================================================================")
message("PHASE 2: HOURLY WEATHER DATA EXTRACTION")
message("======================================================================")

# Parameters
LAT <- 53.3811
LON <- -1.4701
START_DATE <- "2022-01-01"
END_DATE <- "2025-12-31"

url <- "https://archive-api.open-meteo.com/v1/archive"

params <- list(
  latitude = LAT,
  longitude = LON,
  start_date = START_DATE,
  end_date = END_DATE,
  hourly = "temperature_2m,precipitation,wind_speed_10m,wind_direction_10m,relative_humidity_2m",
  timezone = "Europe/London"
)

message("Fetching hourly weather data...")
message(sprintf("Period: %s to %s", START_DATE, END_DATE))

response <- GET(url, query = params)

if (status_code(response) != 200) {
  stop(sprintf("API failed with status %d", status_code(response)))
}

content_text <- content(response, "text", encoding = "UTF-8")
data_json <- fromJSON(content_text)

# Extract hourly data
weather_df <- as.data.frame(data_json$hourly) %>%
  mutate(datetime = as.POSIXct(time, tz = "Europe/London")) %>%
  select(
    datetime,
    temp = temperature_2m,
    precip = precipitation,
    wind_speed = wind_speed_10m,
    wind_dir = wind_direction_10m,
    humidity = relative_humidity_2m
  )

message(sprintf("Fetched %d hourly records", nrow(weather_df)))

# Load hourly air quality data
aq_file <- file.path(data_dir, "sheffield_processed.csv")
aq_data <- read_csv(aq_file, show_col_types = FALSE)

message("Merging with air quality data...")
merged_data <- aq_data %>%
  left_join(weather_df, by = "datetime")

missing <- merged_data %>% filter(is.na(temp)) %>% nrow()
if (missing > 0) {
  warning(sprintf("%d rows missing weather!", missing))
} else {
  message("Merge successful!")
}

# Save
output_file <- file.path(data_dir, "phase2_sheffield_hourly_weather.csv")
write_csv(merged_data, output_file)

message(sprintf("Saved: %s", output_file))
message("Ready for hourly LSTM training!")
