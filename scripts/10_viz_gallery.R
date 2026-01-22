# 11_create_instantly_understandable_viz.R
# Create visualizations that are instantly understandable by anyone
# Inspired by AQI.in design principles

local_lib <- "c:/Users/vedan/.gemini/intro to data science/R_libs"
.libPaths(c(local_lib, .libPaths()))

library(dplyr)
library(readr)
library(ggplot2)
library(lubridate)
library(scales)

# Load data
daily_data <- read_csv("sheffield_openmeteo/data/sheffield_daily.csv", show_col_types = FALSE) %>%
  mutate(date = as.Date(date)) %>%
  filter(!is.na(date), !is.na(no2_mean))

CAZ_DATE <- as.Date("2023-02-27")

# Create output directory
dir.create("sheffield_openmeteo/visualizations/final", recursive = TRUE, showWarnings = FALSE)

message("\n", strrep("=", 70))
message("CREATING INSTANTLY UNDERSTANDABLE VISUALIZATIONS")
message(strrep("=", 70), "\n")

# Define WHO/EPA-style categories for NO2
categorize_no2 <- function(value) {
  case_when(
    value <= 10 ~ "Good",
    value <= 20 ~ "Moderate",
    value <= 30 ~ "Unhealthy",
    value <= 40 ~ "Very Unhealthy",
    TRUE ~ "Hazardous"
  )
}

# Add categories
daily_data <- daily_data %>%
  mutate(
    category = categorize_no2(no2_mean),
    category = factor(category, levels = c("Good", "Moderate", "Unhealthy", "Very Unhealthy", "Hazardous")),
    period = if_else(date < CAZ_DATE, "Pre-CAZ", "Post-CAZ")
  )

# Color palette (traffic light system)
category_colors <- c(
  "Good" = "#00E400",           # Green
  "Moderate" = "#FFFF00",       # Yellow
  "Unhealthy" = "#FF7E00",      # Orange
  "Very Unhealthy" = "#FF0000", # Red
  "Hazardous" = "#8F3F97"       # Purple
)

# ============================================================================
# VIZ 1: CALENDAR HEATMAP (Like AQI.in)
# ============================================================================

message("1. Creating Calendar Heatmap...")

calendar_data <- daily_data %>%
  mutate(
    year = year(date),
    month = month(date, label = TRUE, abbr = TRUE),
    day = day(date),
    week = week(date)
  )

p1 <- ggplot(calendar_data, aes(x = week, y = factor(wday(date, label = TRUE)), fill = category)) +
  geom_tile(color = "white", size = 0.5) +
  geom_vline(xintercept = week(CAZ_DATE), color = "black", size = 2, linetype = "solid") +
  scale_fill_manual(values = category_colors, drop = FALSE) +
  facet_wrap(~year, ncol = 1, scales = "free_x") +
  labs(
    title = "Sheffield Air Quality: Every Single Day (2022-2025)",
    subtitle = "Black line = Clean Air Zone implemented (Feb 27, 2023)",
    x = "Week of Year",
    y = NULL,
    fill = "Air Quality"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(size = 20, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 14, hjust = 0.5, color = "gray30"),
    legend.position = "bottom",
    legend.title = element_text(face = "bold", size = 12),
    legend.text = element_text(size = 11),
    panel.grid = element_blank(),
    strip.text = element_text(size = 14, face = "bold")
  ) +
  guides(fill = guide_legend(nrow = 1, override.aes = list(size = 8)))

ggsave("sheffield_openmeteo/visualizations/final/01_calendar_heatmap.png",
       p1, width = 16, height = 10, dpi = 300, bg = "white")
message("   ✓ Saved: 01_calendar_heatmap.png")

# ============================================================================
# VIZ 2: BIG NUMBERS - BEFORE/AFTER COMPARISON
# ============================================================================

message("2. Creating Big Numbers Comparison...")

# Calculate statistics
pre_stats <- daily_data %>% filter(period == "Pre-CAZ") %>%
  summarise(
    days = n(),
    mean_no2 = mean(no2_mean, na.rm = TRUE),
    good_days = sum(category == "Good"),
    bad_days = sum(category %in% c("Unhealthy", "Very Unhealthy", "Hazardous"))
  )

post_stats <- daily_data %>% filter(period == "Post-CAZ") %>%
  summarise(
    days = n(),
    mean_no2 = mean(no2_mean, na.rm = TRUE),
    good_days = sum(category == "Good"),
    bad_days = sum(category %in% c("Unhealthy", "Very Unhealthy", "Hazardous"))
  )

# Create big number visualization
p2 <- ggplot() +
  # Pre-CAZ box
  annotate("rect", xmin = 0, xmax = 0.45, ymin = 0, ymax = 1, 
           fill = "#3498db", alpha = 0.2, color = "#3498db", size = 3) +
  annotate("text", x = 0.225, y = 0.85, label = "BEFORE CAZ", 
           size = 12, fontface = "bold", color = "#3498db") +
  annotate("text", x = 0.225, y = 0.65, label = sprintf("%.1f", pre_stats$mean_no2), 
           size = 30, fontface = "bold", color = "#3498db") +
  annotate("text", x = 0.225, y = 0.5, label = "μg/m³ NO₂", 
           size = 8, color = "#3498db") +
  annotate("text", x = 0.225, y = 0.3, label = sprintf("%d unhealthy days", pre_stats$bad_days), 
           size = 7, color = "#e74c3c") +
  annotate("text", x = 0.225, y = 0.15, label = sprintf("out of %d total days", pre_stats$days), 
           size = 6, color = "gray40") +
  
  # Post-CAZ box
  annotate("rect", xmin = 0.55, xmax = 1, ymin = 0, ymax = 1, 
           fill = "#2ecc71", alpha = 0.2, color = "#2ecc71", size = 3) +
  annotate("text", x = 0.775, y = 0.85, label = "AFTER CAZ", 
           size = 12, fontface = "bold", color = "#2ecc71") +
  annotate("text", x = 0.775, y = 0.65, label = sprintf("%.1f", post_stats$mean_no2), 
           size = 30, fontface = "bold", color = "#2ecc71") +
  annotate("text", x = 0.775, y = 0.5, label = "μg/m³ NO₂", 
           size = 8, color = "#2ecc71") +
  annotate("text", x = 0.775, y = 0.3, label = sprintf("%d unhealthy days", post_stats$bad_days), 
           size = 7, color = "#27ae60") +
  annotate("text", x = 0.775, y = 0.15, label = sprintf("out of %d total days", post_stats$days), 
           size = 6, color = "gray40") +
  
  # Improvement arrow
  annotate("segment", x = 0.45, xend = 0.55, y = 0.65, yend = 0.65,
           arrow = arrow(length = unit(0.5, "cm"), type = "closed"),
           color = "#27ae60", size = 3) +
  annotate("text", x = 0.5, y = 0.75, 
           label = sprintf("%.0f%% REDUCTION", 
                          100 * (pre_stats$mean_no2 - post_stats$mean_no2) / pre_stats$mean_no2),
           size = 10, fontface = "bold", color = "#27ae60") +
  
  xlim(0, 1) + ylim(0, 1) +
  labs(title = "Clean Air Zone Impact: The Numbers That Matter",
       subtitle = "Average NO₂ pollution levels before and after CAZ implementation") +
  theme_void() +
  theme(
    plot.title = element_text(size = 22, face = "bold", hjust = 0.5, margin = margin(b = 10)),
    plot.subtitle = element_text(size = 14, hjust = 0.5, color = "gray30", margin = margin(b = 20)),
    plot.margin = margin(30, 30, 30, 30)
  )

ggsave("sheffield_openmeteo/visualizations/final/02_big_numbers.png",
       p2, width = 14, height = 8, dpi = 300, bg = "white")
message("   ✓ Saved: 02_big_numbers.png")

# ============================================================================
# VIZ 3: CATEGORY BREAKDOWN (Pie/Donut charts)
# ============================================================================

message("3. Creating Category Breakdown...")

# Count days by category and period
category_counts <- daily_data %>%
  group_by(period, category) %>%
  summarise(days = n(), .groups = "drop") %>%
  group_by(period) %>%
  mutate(
    total = sum(days),
    percentage = 100 * days / total,
    label = sprintf("%s\n%d days\n(%.0f%%)", category, days, percentage)
  )

p3 <- ggplot(category_counts, aes(x = "", y = days, fill = category)) +
  geom_col(width = 1, color = "white", size = 2) +
  coord_polar(theta = "y") +
  facet_wrap(~period, ncol = 2) +
  scale_fill_manual(values = category_colors, drop = FALSE) +
  geom_text(aes(label = sprintf("%.0f%%", percentage)), 
            position = position_stack(vjust = 0.5), 
            size = 6, fontface = "bold", color = "white") +
  labs(
    title = "How Many Days Were Safe to Breathe?",
    subtitle = "Distribution of air quality categories before and after Clean Air Zone",
    fill = "Air Quality"
  ) +
  theme_void(base_size = 14) +
  theme(
    plot.title = element_text(size = 20, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 13, hjust = 0.5, color = "gray30", margin = margin(b = 20)),
    legend.position = "bottom",
    legend.title = element_text(face = "bold", size = 12),
    legend.text = element_text(size = 11),
    strip.text = element_text(size = 16, face = "bold", margin = margin(b = 10))
  ) +
  guides(fill = guide_legend(nrow = 1, override.aes = list(size = 8)))

ggsave("sheffield_openmeteo/visualizations/final/03_category_breakdown.png",
       p3, width = 14, height = 8, dpi = 300, bg = "white")
message("   ✓ Saved: 03_category_breakdown.png")

message("\n", strrep("=", 70))
message("INSTANTLY UNDERSTANDABLE VISUALIZATIONS COMPLETE (3/5)")
message(strrep("=", 70), "\n")
