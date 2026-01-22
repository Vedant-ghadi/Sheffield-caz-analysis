# 01_extract_openmeteo.R
# Extract Sheffield air quality data from Open-Meteo API (2022-2025)

# Setup
local_lib <- "c:/Users/vedan/.gemini/intro to data science/R_libs"
.libPaths(c(local_lib, .libPaths()))

library(httr)
library(jsonlite)
library(dplyr)
library(readr)
library(lubridate)

# Sheffield coordinates
LAT <- 53.3811
LON <- -1.4701

# Date range (covers pre/post CAZ)
START_DATE <- "2022-01-01"
END_DATE <- "2025-12-31"

# Pollutants to extract
HOURLY_VARS <- c(
  "pm10",
  "pm2_5", 
  "nitrogen_dioxide",
  "ozone",
  "sulphur_dioxide",
  "carbon_monoxide",
  "european_aqi"
)

# API endpoint
BASE_URL <- "https://air-quality-api.open-meteo.com/v1/air-quality"

message("\n", strrep("=", 70))
message("EXTRACTING SHEFFIELD AIR QUALITY DATA (Open-Meteo)")
message(strrep("=", 70))
message("Location: Sheffield (", LAT, ", ", LON, ")")
message("Period: ", START_DATE, " to ", END_DATE)
message("Variables: ", paste(HOURLY_VARS, collapse = ", "))
message(strrep("=", 70), "\n")

# Build API request
response <- GET(
  url = BASE_URL,
  query = list(
    latitude = LAT,
    longitude = LON,
    hourly = paste(HOURLY_VARS, collapse = ","),
    start_date = START_DATE,
    end_date = END_DATE,
    timezone = "Europe/London"
  )
)

# Check response
if (status_code(response) != 200) {
  stop("API Error: ", status_code(response), "\n", content(response, "text"))
}

message("✓ API request successful (Status: ", status_code(response), ")")

# Parse JSON
json_data <- fromJSON(content(response, "text", encoding = "UTF-8"))

# Extract hourly data
hourly_data <- as_tibble(json_data$hourly)

# Convert time - Open-Meteo returns ISO format strings
# Format: "2022-01-01T00:00" (no Z, already in specified timezone)
hourly_data <- hourly_data %>%
  mutate(
    time = as.POSIXct(time, format = "%Y-%m-%dT%H:%M", tz = "Europe/London")
  )

message("✓ Retrieved ", nrow(hourly_data), " hourly records")
message("  Date range: ", min(hourly_data$time), " to ", max(hourly_data$time))

# Save raw data
output_file <- "sheffield_openmeteo/data/sheffield_raw.csv"
write_csv(hourly_data, output_file)
message("✓ Saved to: ", output_file)

# Create backup
backup_file <- paste0("sheffield_openmeteo/data/backup/sheffield_raw_", format(Sys.Date(), "%Y%m%d"), ".csv")
write_csv(hourly_data, backup_file)
message("✓ Backup created: ", backup_file)

# Quick summary
message("\n", strrep("=", 70))
message("DATA SUMMARY")
message(strrep("=", 70))
message("Total records: ", nrow(hourly_data))
message("Date range: ", as.Date(min(hourly_data$time)), " to ", as.Date(max(hourly_data$time)))
message("Missing values per variable:")
for (var in HOURLY_VARS) {
  if (var %in% names(hourly_data)) {
    n_missing <- sum(is.na(hourly_data[[var]]))
    pct_missing <- round(100 * n_missing / nrow(hourly_data), 2)
    message(sprintf("  %s: %d (%.2f%%)", var, n_missing, pct_missing))
  }
}
message(strrep("=", 70))
