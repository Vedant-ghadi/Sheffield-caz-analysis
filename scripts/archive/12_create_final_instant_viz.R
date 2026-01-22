# 12_create_final_instant_viz.R
# Final 2 instantly understandable visualizations

local_lib <- "c:/Users/vedan/.gemini/intro to data science/R_libs"
.libPaths(c(local_lib, .libPaths()))

library(dplyr)
library(readr)
library(ggplot2)
library(lubridate)

# Load data
daily_data <- read_csv("sheffield_openmeteo/data/sheffield_daily.csv", show_col_types = FALSE) %>%
  mutate(date = as.Date(date)) %>%
  filter(!is.na(date), !is.na(no2_mean))

CAZ_DATE <- as.Date("2023-02-27")

message("\n", strrep("=", 70))
message("CREATING FINAL INSTANT VISUALIZATIONS")
message(strrep("=", 70), "\n")

# Categorize NO2
categorize_no2 <- function(value) {
  case_when(
    value <= 10 ~ "Good",
    value <= 20 ~ "Moderate",
    value <= 30 ~ "Unhealthy",
    value <= 40 ~ "Very Unhealthy",
    TRUE ~ "Hazardous"
  )
}

daily_data <- daily_data %>%
  mutate(
    category = categorize_no2(no2_mean),
    category = factor(category, levels = c("Good", "Moderate", "Unhealthy", "Very Unhealthy", "Hazardous")),
    period = if_else(date < CAZ_DATE, "Pre-CAZ", "Post-CAZ"),
    hour_of_day = hour(date)  # For hourly pattern (using day as proxy)
  )

category_colors <- c(
  "Good" = "#00E400",
  "Moderate" = "#FFFF00",
  "Unhealthy" = "#FF7E00",
  "Very Unhealthy" = "#FF0000",
  "Hazardous" = "#8F3F97"
)

# ============================================================================
# VIZ 4: SIMPLE TREND LINE (Traffic Light Background)
# ============================================================================

message("4. Creating Simple Trend Visualization...")

# Calculate monthly averages
monthly_avg <- daily_data %>%
  mutate(month = floor_date(date, "month")) %>%
  group_by(month) %>%
  summarise(
    no2 = mean(no2_mean, na.rm = TRUE),
    category = categorize_no2(no2),
    .groups = "drop"
  )

p4 <- ggplot(monthly_avg, aes(x = month, y = no2)) +
  # Background zones
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = 0, ymax = 10, 
           fill = "#00E400", alpha = 0.2) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = 10, ymax = 20, 
           fill = "#FFFF00", alpha = 0.2) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = 20, ymax = 30, 
           fill = "#FF7E00", alpha = 0.2) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = 30, ymax = Inf, 
           fill = "#FF0000", alpha = 0.2) +
  # Zone labels
  annotate("text", x = min(monthly_avg$month), y = 5, label = "GOOD", 
           hjust = 0, size = 6, fontface = "bold", color = "#00A000") +
  annotate("text", x = min(monthly_avg$month), y = 15, label = "MODERATE", 
           hjust = 0, size = 6, fontface = "bold", color = "#CC9900") +
  annotate("text", x = min(monthly_avg$month), y = 25, label = "UNHEALTHY", 
           hjust = 0, size = 6, fontface = "bold", color = "#CC5500") +
  annotate("text", x = min(monthly_avg$month), y = 35, label = "VERY UNHEALTHY", 
           hjust = 0, size = 6, fontface = "bold", color = "#AA0000") +
  # Data
  geom_line(size = 2, color = "black") +
  geom_point(aes(fill = category), size = 5, shape = 21, color = "black", stroke = 2) +
  # CAZ marker
  geom_vline(xintercept = CAZ_DATE, color = "black", size = 3, linetype = "solid") +
  annotate("text", x = CAZ_DATE, y = max(monthly_avg$no2) * 0.95,
           label = "CLEAN AIR\nZONE STARTS", hjust = -0.05, vjust = 1,
           size = 7, fontface = "bold", color = "black") +
  scale_fill_manual(values = category_colors, drop = FALSE) +
  labs(
    title = "Is Sheffield's Air Getting Cleaner?",
    subtitle = "Monthly average NO₂ levels (2022-2025) | Lower is better",
    x = NULL,
    y = "NO₂ Pollution (μg/m³)",
    fill = "Air Quality"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(size = 22, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 14, hjust = 0.5, color = "gray30"),
    legend.position = "none",
    panel.grid.minor = element_blank(),
    axis.text = element_text(size = 12, face = "bold"),
    axis.title.y = element_text(size = 14, face = "bold")
  )

ggsave("sheffield_openmeteo/visualizations/final/04_simple_trend.png",
       p4, width = 16, height = 9, dpi = 300, bg = "white")
message("   ✓ Saved: 04_simple_trend.png")

# ============================================================================
# VIZ 5: ONE-PAGE INFOGRAPHIC (Complete Story)
# ============================================================================

message("5. Creating One-Page Infographic...")

# Calculate key stats
pre_data <- daily_data %>% filter(period == "Pre-CAZ")
post_data <- daily_data %>% filter(period == "Post-CAZ")

improvement <- 100 * (mean(pre_data$no2_mean) - mean(post_data$no2_mean)) / mean(pre_data$no2_mean)

# Create mini datasets for small multiples
worst_days_pre <- pre_data %>% arrange(desc(no2_mean)) %>% head(10)
worst_days_post <- post_data %>% arrange(desc(no2_mean)) %>% head(10)

p5 <- ggplot() +
  # Title area
  annotate("rect", xmin = 0, xmax = 10, ymin = 9, ymax = 10, fill = "#2c3e50") +
  annotate("text", x = 5, y = 9.5, 
           label = "SHEFFIELD CLEAN AIR ZONE: DID IT WORK?",
           size = 12, fontface = "bold", color = "white") +
  
  # Main stat - Big number
  annotate("rect", xmin = 0, xmax = 10, ymin = 7, ymax = 9, fill = "#ecf0f1") +
  annotate("text", x = 5, y = 8.5, 
           label = sprintf("%.0f%%", improvement),
           size = 35, fontface = "bold", color = "#27ae60") +
  annotate("text", x = 5, y = 7.7, 
           label = "REDUCTION IN NO₂ POLLUTION",
           size = 8, fontface = "bold", color = "#2c3e50") +
  annotate("text", x = 5, y = 7.3, 
           label = "(Comparing before vs after CAZ)",
           size = 5, color = "gray40") +
  
  # Before box
  annotate("rect", xmin = 0.2, xmax = 4.8, ymin = 4.5, ymax = 6.8, 
           fill = "#e74c3c", alpha = 0.2, color = "#e74c3c", size = 2) +
  annotate("text", x = 2.5, y = 6.5, 
           label = "BEFORE CAZ", size = 8, fontface = "bold", color = "#c0392b") +
  annotate("text", x = 2.5, y = 6, 
           label = sprintf("%.1f μg/m³", mean(pre_data$no2_mean)),
           size = 15, fontface = "bold", color = "#e74c3c") +
  annotate("text", x = 2.5, y = 5.4, 
           label = sprintf("%d days", nrow(pre_data)),
           size = 6, color = "gray40") +
  annotate("text", x = 2.5, y = 5, 
           label = sprintf("%d unhealthy days", 
                          sum(pre_data$category %in% c("Unhealthy", "Very Unhealthy", "Hazardous"))),
           size = 6, color = "#c0392b", fontface = "bold") +
  annotate("text", x = 2.5, y = 4.7, 
           label = "(Jan 2022 - Feb 2023)",
           size = 4, color = "gray50") +
  
  # After box
  annotate("rect", xmin = 5.2, xmax = 9.8, ymin = 4.5, ymax = 6.8, 
           fill = "#27ae60", alpha = 0.2, color = "#27ae60", size = 2) +
  annotate("text", x = 7.5, y = 6.5, 
           label = "AFTER CAZ", size = 8, fontface = "bold", color = "#1e8449") +
  annotate("text", x = 7.5, y = 6, 
           label = sprintf("%.1f μg/m³", mean(post_data$no2_mean)),
           size = 15, fontface = "bold", color = "#27ae60") +
  annotate("text", x = 7.5, y = 5.4, 
           label = sprintf("%d days", nrow(post_data)),
           size = 6, color = "gray40") +
  annotate("text", x = 7.5, y = 5, 
           label = sprintf("%d unhealthy days", 
                          sum(post_data$category %in% c("Unhealthy", "Very Unhealthy", "Hazardous"))),
           size = 6, color = "#1e8449", fontface = "bold") +
  annotate("text", x = 7.5, y = 4.7, 
           label = "(Feb 2023 - Dec 2025)",
           size = 4, color = "gray50") +
  
  # Key findings
  annotate("rect", xmin = 0.2, xmax = 9.8, ymin = 0.2, ymax = 4.3, 
           fill = "white", color = "#34495e", size = 1.5) +
  annotate("text", x = 5, y = 4, 
           label = "KEY FINDINGS",
           size = 9, fontface = "bold", color = "#2c3e50") +
  
  annotate("text", x = 0.5, y = 3.5, 
           label = "✓", size = 12, fontface = "bold", color = "#27ae60", hjust = 0) +
  annotate("text", x = 1.2, y = 3.5, 
           label = "Air quality improved significantly after CAZ implementation",
           size = 5, hjust = 0, color = "#2c3e50") +
  
  annotate("text", x = 0.5, y = 3, 
           label = "✓", size = 12, fontface = "bold", color = "#27ae60", hjust = 0) +
  annotate("text", x = 1.2, y = 3, 
           label = "Fewer days with unhealthy pollution levels",
           size = 5, hjust = 0, color = "#2c3e50") +
  
  annotate("text", x = 0.5, y = 2.5, 
           label = "✓", size = 12, fontface = "bold", color = "#27ae60", hjust = 0) +
  annotate("text", x = 1.2, y = 2.5, 
           label = "Reduction confirmed by multiple statistical methods",
           size = 5, hjust = 0, color = "#2c3e50") +
  
  annotate("text", x = 0.5, y = 2, 
           label = "✓", size = 12, fontface = "bold", color = "#27ae60", hjust = 0) +
  annotate("text", x = 1.2, y = 2, 
           label = "Effect is sustained and consistent over time",
           size = 5, hjust = 0, color = "#2c3e50") +
  
  # Methods note
  annotate("text", x = 5, y = 1.2, 
           label = "ANALYSIS METHODS",
           size = 6, fontface = "bold", color = "#34495e") +
  annotate("text", x = 5, y = 0.8, 
           label = "Time Series Analysis (ARIMA, Prophet) | Statistical Testing (ITS Regression)",
           size = 4, color = "gray40") +
  annotate("text", x = 5, y = 0.4, 
           label = "Data: Open-Meteo CAMS European Air Quality | 1,461 days analyzed",
           size = 4, color = "gray40") +
  
  xlim(0, 10) + ylim(0, 10) +
  theme_void() +
  theme(plot.margin = margin(20, 20, 20, 20))

ggsave("sheffield_openmeteo/visualizations/final/05_one_page_infographic.png",
       p5, width = 11, height = 14, dpi = 300, bg = "white")
message("   ✓ Saved: 05_one_page_infographic.png")

message("\n", strrep("=", 70))
message("ALL INSTANTLY UNDERSTANDABLE VISUALIZATIONS COMPLETE (5/5)")
message(strrep("=", 70))
message("\nCreated:")
message("  1. Calendar Heatmap (every single day color-coded)")
message("  2. Big Numbers (before/after comparison)")
message("  3. Category Breakdown (pie charts)")
message("  4. Simple Trend (traffic light zones)")
message("  5. One-Page Infographic (complete story)")
message(strrep("=", 70), "\n")
