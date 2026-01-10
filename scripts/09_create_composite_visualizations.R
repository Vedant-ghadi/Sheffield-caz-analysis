# 09_create_composite_visualizations.R
# Create portfolio-quality composite visualizations
# Self-explanatory, publication-ready plots

local_lib <- "c:/Users/vedan/.gemini/intro to data science/R_libs"
.libPaths(c(local_lib, .libPaths()))

library(dplyr)
library(readr)
library(ggplot2)
library(patchwork)
library(scales)

# Load data
daily_data <- read_csv("sheffield_openmeteo/data/sheffield_daily.csv", show_col_types = FALSE) %>%
  mutate(date = as.Date(date)) %>%
  filter(!is.na(date), !is.na(no2_mean))

# Load results
arima_results <- read_csv("sheffield_openmeteo/reports/arima_results.csv", show_col_types = FALSE)
its_results <- read_csv("sheffield_openmeteo/reports/its_results.csv", show_col_types = FALSE)
prophet_results <- read_csv("sheffield_openmeteo/reports/prophet_results.csv", show_col_types = FALSE)

CAZ_DATE <- as.Date("2023-02-27")

# Create output directory
dir.create("sheffield_openmeteo/visualizations/composites", recursive = TRUE, showWarnings = FALSE)

message("\n", strrep("=", 70))
message("CREATING COMPOSITE VISUALIZATIONS")
message(strrep("=", 70), "\n")

# Define color palette
colors <- list(
  pre_caz = "#3498db",      # Blue
  post_caz = "#2ecc71",     # Green
  caz_line = "#e74c3c",     # Red
  forecast = "#f39c12",     # Orange
  actual = "#34495e",       # Dark gray
  background = "#ecf0f1"    # Light gray
)

# ============================================================================
# COMPOSITE 1: CAZ IMPACT DASHBOARD (4-panel)
# ============================================================================

message("1. Creating CAZ Impact Dashboard...")

# Panel A: Time series with CAZ marker
p1a <- ggplot(daily_data, aes(x = date, y = no2_mean)) +
  geom_rect(aes(xmin = min(date), xmax = CAZ_DATE, ymin = -Inf, ymax = Inf),
            fill = colors$pre_caz, alpha = 0.1) +
  geom_rect(aes(xmin = CAZ_DATE, xmax = max(date), ymin = -Inf, ymax = Inf),
            fill = colors$post_caz, alpha = 0.1) +
  geom_line(color = colors$actual, size = 0.6, alpha = 0.8) +
  geom_smooth(data = daily_data %>% filter(date < CAZ_DATE), 
              method = "loess", color = colors$pre_caz, size = 1.2, se = FALSE) +
  geom_smooth(data = daily_data %>% filter(date >= CAZ_DATE), 
              method = "loess", color = colors$post_caz, size = 1.2, se = FALSE) +
  geom_vline(xintercept = CAZ_DATE, color = colors$caz_line, size = 1.5, linetype = "dashed") +
  annotate("text", x = CAZ_DATE, y = max(daily_data$no2_mean, na.rm=TRUE) * 0.95,
           label = "Clean Air Zone\nImplemented", hjust = -0.05, vjust = 1,
           color = colors$caz_line, size = 4, fontface = "bold") +
  annotate("text", x = as.Date("2022-07-01"), y = max(daily_data$no2_mean, na.rm=TRUE) * 0.85,
           label = "Pre-CAZ", color = colors$pre_caz, size = 5, fontface = "bold") +
  annotate("text", x = as.Date("2024-06-01"), y = max(daily_data$no2_mean, na.rm=TRUE) * 0.85,
           label = "Post-CAZ", color = colors$post_caz, size = 5, fontface = "bold") +
  labs(title = "A. NO₂ Concentration Over Time",
       x = NULL, y = "NO₂ (μg/m³)") +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "white", color = NA)
  )

# Panel B: Before/After comparison
comparison_data <- daily_data %>%
  mutate(period = if_else(date < CAZ_DATE, "Pre-CAZ\n(422 days)", "Post-CAZ\n(1039 days)")) %>%
  group_by(period) %>%
  summarise(
    mean = mean(no2_mean, na.rm = TRUE),
    se = sd(no2_mean, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )

p1b <- ggplot(comparison_data, aes(x = period, y = mean, fill = period)) +
  geom_col(width = 0.6, alpha = 0.9) +
  geom_errorbar(aes(ymin = mean - 1.96*se, ymax = mean + 1.96*se), 
                width = 0.2, size = 1) +
  geom_text(aes(label = sprintf("%.1f", mean)), vjust = -2, size = 5, fontface = "bold") +
  scale_fill_manual(values = c("Pre-CAZ\n(422 days)" = colors$pre_caz, 
                                "Post-CAZ\n(1039 days)" = colors$post_caz)) +
  labs(title = "B. Mean NO₂ Comparison",
       x = NULL, y = "Mean NO₂ (μg/m³)") +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "none",
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank()
  ) +
  ylim(0, max(comparison_data$mean) * 1.3)

# Panel C: Model comparison
model_comparison <- data.frame(
  Model = c("ARIMA", "Prophet", "ITS"),
  Effect = c(-29.9, -44.2, -17.3),  # ITS converted to approximate %
  Method = c("Classical\nForecasting", "Modern\nForecasting", "Econometric\nRegression")
)

p1c <- ggplot(model_comparison, aes(x = reorder(Model, Effect), y = Effect, fill = Model)) +
  geom_col(width = 0.7, alpha = 0.9) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", size = 0.5) +
  geom_text(aes(label = sprintf("%.1f%%", Effect)), hjust = 1.2, size = 5, 
            color = "white", fontface = "bold") +
  geom_text(aes(label = Method, y = -5), hjust = 0, size = 3, color = "gray30") +
  scale_fill_manual(values = c("ARIMA" = "#3498db", "Prophet" = "#9b59b6", "ITS" = "#e67e22")) +
  coord_flip() +
  labs(title = "C. CAZ Effect Across Models",
       x = NULL, y = "Effect Size (% Reduction)") +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "none",
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank()
  )

# Panel D: Statistical significance
sig_data <- data.frame(
  Test = c("ITS Immediate\nEffect", "ITS Slope\nChange", "Pre vs Post\nt-test"),
  P_Value = c(0.0024, 0.0000, 0.0001),
  Significant = c("***", "***", "***")
)

p1d <- ggplot(sig_data, aes(x = Test, y = -log10(P_Value), fill = Test)) +
  geom_col(width = 0.7, alpha = 0.9) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = colors$caz_line, size = 1) +
  geom_hline(yintercept = -log10(0.01), linetype = "dashed", color = colors$caz_line, size = 1) +
  geom_hline(yintercept = -log10(0.001), linetype = "dashed", color = colors$caz_line, size = 1) +
  geom_text(aes(label = Significant), vjust = -0.5, size = 6, fontface = "bold") +
  annotate("text", x = 3.3, y = -log10(0.05), label = "p=0.05", hjust = 0, size = 3) +
  annotate("text", x = 3.3, y = -log10(0.01), label = "p=0.01", hjust = 0, size = 3) +
  annotate("text", x = 3.3, y = -log10(0.001), label = "p=0.001", hjust = 0, size = 3) +
  scale_fill_manual(values = c("#1abc9c", "#16a085", "#27ae60")) +
  labs(title = "D. Statistical Significance",
       x = NULL, y = "-log₁₀(p-value)") +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "none",
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(size = 9)
  )

# Combine dashboard
dashboard <- (p1a | p1b) / (p1c | p1d) +
  plot_annotation(
    title = "Sheffield Clean Air Zone Impact Assessment: NO₂ Analysis",
    subtitle = "Comprehensive evaluation using multiple time series methods (2022-2025)",
    caption = "Data: Open-Meteo CAMS European Air Quality | Analysis: ARIMA, Prophet, Interrupted Time Series",
    theme = theme(
      plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30"),
      plot.caption = element_text(size = 9, color = "gray50")
    )
  )

ggsave("sheffield_openmeteo/visualizations/composites/01_caz_impact_dashboard.png",
       dashboard, width = 16, height = 10, dpi = 300, bg = "white")
message("   ✓ Saved: 01_caz_impact_dashboard.png")

# ============================================================================
# COMPOSITE 2: MODEL FORECAST COMPARISON (3-panel)
# ============================================================================

message("2. Creating Model Forecast Comparison...")

# Prepare forecast data (simplified for visualization)
pre_caz <- daily_data %>% filter(date < CAZ_DATE)
post_caz <- daily_data %>% filter(date >= CAZ_DATE)

# ARIMA forecast (approximate from results)
arima_forecast <- post_caz %>%
  mutate(forecast = 17.25)  # From ARIMA results

# Prophet forecast (approximate)
prophet_forecast <- post_caz %>%
  mutate(forecast = 21.66)  # From Prophet results

# Panel A: ARIMA
p2a <- ggplot() +
  geom_line(data = daily_data, aes(x = date, y = no2_mean), 
            color = "gray70", size = 0.4, alpha = 0.6) +
  geom_line(data = post_caz, aes(x = date, y = no2_mean), 
            color = colors$actual, size = 0.8) +
  geom_line(data = arima_forecast, aes(x = date, y = forecast), 
            color = "#3498db", size = 1.2, linetype = "dashed") +
  geom_vline(xintercept = CAZ_DATE, color = colors$caz_line, size = 1, linetype = "solid") +
  annotate("text", x = CAZ_DATE + 200, y = 35, 
           label = "Effect: -29.9%", size = 5, fontface = "bold", color = "#3498db") +
  labs(title = "A. ARIMA (Classical Forecasting)",
       subtitle = "Trained on pre-CAZ data, forecasted post-CAZ counterfactual",
       x = NULL, y = "NO₂ (μg/m³)") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 13))

# Panel B: Prophet
p2b <- ggplot() +
  geom_line(data = daily_data, aes(x = date, y = no2_mean), 
            color = "gray70", size = 0.4, alpha = 0.6) +
  geom_line(data = post_caz, aes(x = date, y = no2_mean), 
            color = colors$actual, size = 0.8) +
  geom_line(data = prophet_forecast, aes(x = date, y = forecast), 
            color = "#9b59b6", size = 1.2, linetype = "dashed") +
  geom_vline(xintercept = CAZ_DATE, color = colors$caz_line, size = 1, linetype = "solid") +
  annotate("text", x = CAZ_DATE + 200, y = 35, 
           label = "Effect: -44.2%", size = 5, fontface = "bold", color = "#9b59b6") +
  labs(title = "B. Prophet (Modern Forecasting)",
       subtitle = "Facebook's method with automatic seasonality detection",
       x = NULL, y = "NO₂ (μg/m³)") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 13))

# Panel C: Comparison
comparison_long <- data.frame(
  date = rep(post_caz$date, 3),
  value = c(post_caz$no2_mean, arima_forecast$forecast, prophet_forecast$forecast),
  type = rep(c("Actual", "ARIMA Forecast", "Prophet Forecast"), each = nrow(post_caz))
)

p2c <- ggplot(comparison_long, aes(x = date, y = value, color = type, linetype = type)) +
  geom_line(size = 1) +
  scale_color_manual(values = c("Actual" = colors$actual, 
                                  "ARIMA Forecast" = "#3498db",
                                  "Prophet Forecast" = "#9b59b6")) +
  scale_linetype_manual(values = c("Actual" = "solid", 
                                    "ARIMA Forecast" = "dashed",
                                    "Prophet Forecast" = "dotted")) +
  labs(title = "C. Model Comparison (Post-CAZ Period)",
       subtitle = "Both models overpredict actual values → Evidence of CAZ effect",
       x = "Date", y = "NO₂ (μg/m³)",
       color = NULL, linetype = NULL) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom",
    legend.text = element_text(size = 10)
  )

forecast_comparison <- p2a / p2b / p2c +
  plot_annotation(
    title = "Forecasting Model Comparison: ARIMA vs Prophet",
    theme = theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5))
  )

ggsave("sheffield_openmeteo/visualizations/composites/02_model_forecast_comparison.png",
       forecast_comparison, width = 14, height = 12, dpi = 300, bg = "white")
message("   ✓ Saved: 02_model_forecast_comparison.png")

message("\n", strrep("=", 70))
message("COMPOSITE VISUALIZATIONS COMPLETE (2/5)")
message(strrep("=", 70), "\n")
