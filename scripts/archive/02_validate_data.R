# 02_validate_data.R
# Validate Sheffield air quality data completeness and quality

local_lib <- "c:/Users/vedan/.gemini/intro to data science/R_libs"
.libPaths(c(local_lib, .libPaths()))

library(dplyr)
library(readr)
library(lubridate)
library(ggplot2)

INPUT_FILE <- "sheffield_openmeteo/data/sheffield_raw.csv"
OUTPUT_DIR <- "sheffield_openmeteo/reports"

message("\n", strrep("=", 70))
message("DATA VALIDATION REPORT")
message(strrep("=", 70), "\n")

# Load data
data <- read_csv(INPUT_FILE, show_col_types = FALSE)

# Fix time parsing (Open-Meteo format)
data <- data %>%
  mutate(time = as.POSIXct(time, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))

message("1. BASIC STATISTICS")
message("   Total records: ", nrow(data))
message("   Date range: ", min(data$time, na.rm = TRUE), " to ", max(data$time, na.rm = TRUE))
message("   Duration: ", round(as.numeric(difftime(max(data$time, na.rm = TRUE), 
                                                    min(data$time, na.rm = TRUE), 
                                                    units = "days"))), " days\n")

# Check for gaps
message("2. TEMPORAL CONTINUITY")
time_diff <- as.numeric(diff(data$time), units = "hours")
gaps <- which(time_diff > 1)

if (length(gaps) > 0) {
  message("   ⚠ Found ", length(gaps), " gaps in hourly sequence")
  for (i in 1:min(5, length(gaps))) {
    gap_start <- data$time[gaps[i]]
    gap_end <- data$time[gaps[i] + 1]
    message("     Gap ", i, ": ", gap_start, " to ", gap_end)
  }
} else {
  message("   ✓ No gaps - continuous hourly data")
}

# Missing values
message("\n3. MISSING VALUES")
pollutants <- c("pm10", "pm2_5", "nitrogen_dioxide", "ozone", 
                "sulphur_dioxide", "carbon_monoxide", "european_aqi")

for (var in pollutants) {
  if (var %in% names(data)) {
    n_missing <- sum(is.na(data[[var]]))
    pct_missing <- round(100 * n_missing / nrow(data), 2)
    status <- if (pct_missing == 0) "✓" else "⚠"
    message(sprintf("   %s %s: %d missing (%.2f%%)", status, var, n_missing, pct_missing))
  }
}

# CAZ period check
message("\n4. CAZ PERIOD COVERAGE")
CAZ_DATE <- as.POSIXct("2023-02-27", tz = "UTC")
pre_caz <- data %>% filter(time < CAZ_DATE)
post_caz <- data %>% filter(time >= CAZ_DATE)

message("   Pre-CAZ records: ", nrow(pre_caz), " (", 
        round(as.numeric(difftime(max(pre_caz$time), min(pre_caz$time), units = "days"))), " days)")
message("   Post-CAZ records: ", nrow(post_caz), " (", 
        round(as.numeric(difftime(max(post_caz$time), min(post_caz$time), units = "days"))), " days)")

# Basic statistics
message("\n5. POLLUTANT STATISTICS (Pre-CAZ vs Post-CAZ)")
message(sprintf("%-20s %10s %10s %10s", "Pollutant", "Pre Mean", "Post Mean", "% Change"))
message(strrep("-", 50))

for (var in c("pm10", "pm2_5", "nitrogen_dioxide", "ozone")) {
  if (var %in% names(data)) {
    pre_mean <- mean(pre_caz[[var]], na.rm = TRUE)
    post_mean <- mean(post_caz[[var]], na.rm = TRUE)
    pct_change <- round(100 * (post_mean - pre_mean) / pre_mean, 1)
    message(sprintf("%-20s %10.2f %10.2f %9.1f%%", var, pre_mean, post_mean, pct_change))
  }
}

message("\n", strrep("=", 70))
message("VALIDATION COMPLETE")
message(strrep("=", 70))

# Save summary
sink(paste0(OUTPUT_DIR, "/validation_summary.txt"))
cat("Sheffield Air Quality Data Validation\n")
cat("Generated:", Sys.time(), "\n\n")
cat("Total Records:", nrow(data), "\n")
cat("Date Range:", as.character(min(data$time, na.rm = TRUE)), "to", 
    as.character(max(data$time, na.rm = TRUE)), "\n")
cat("\nPre-CAZ:", nrow(pre_caz), "records\n")
cat("Post-CAZ:", nrow(post_caz), "records\n")
sink()

message("\n✓ Validation report saved to: ", OUTPUT_DIR, "/validation_summary.txt")
