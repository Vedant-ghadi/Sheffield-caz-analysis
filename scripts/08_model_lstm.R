# Phase 2: HOURLY LSTM Model (35K+ samples)
# Goal: Achieve RMSE < 3.0 using hourly granularity

local_lib <- "c:/Users/vedan/.gemini/intro to data science/R_libs"
.libPaths(c(local_lib, .libPaths()))

suppressPackageStartupMessages({
  library(keras3)
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(lubridate)
  library(httr)
  library(jsonlite)
})

set.seed(42)

base_dir <- "sheffield_openmeteo"
data_dir <- file.path(base_dir, "data")
viz_dir <- file.path(base_dir, "visualizations/phase2")
if (!dir.exists(viz_dir)) dir.create(viz_dir, recursive = TRUE)

message("======================================================================")
message("PHASE 2: HOURLY LSTM (35K+ Samples)")
message("Target: RMSE < 3.0")
message("======================================================================")

# 1. Fetch Hourly Weather Data
message("\n[1/5] Fetching hourly weather data...")

LAT <- 53.3811
LON <- -1.4701
url <- "https://archive-api.open-meteo.com/v1/archive"

params <- list(
  latitude = LAT,
  longitude = LON,
  start_date = "2022-01-01",
  end_date = "2025-12-31",
  hourly = "temperature_2m,precipitation,wind_speed_10m",
  timezone = "Europe/London"
)

response <- GET(url, query = params)
data_json <- fromJSON(content(response, "text", encoding = "UTF-8"))

weather_df <- as.data.frame(data_json$hourly) %>%
  mutate(time = as.POSIXct(time, tz = "Europe/London")) %>%
  select(time, temp = temperature_2m, precip = precipitation, wind_speed = wind_speed_10m)

message(sprintf("Fetched %d hourly weather records", nrow(weather_df)))

# 2. Load & Merge Air Quality Data
message("\n[2/5] Loading hourly air quality data...")

aq_data <- read_csv(file.path(data_dir, "sheffield_processed.csv"), show_col_types = FALSE) %>%
  mutate(time = as.POSIXct(time, tz = "Europe/London"))

data <- aq_data %>%
  left_join(weather_df, by = "time") %>%
  filter(!is.na(nitrogen_dioxide), !is.na(temp)) %>%
  arrange(time)

message(sprintf("Merged dataset: %d hourly samples", nrow(data)))

# 3. Feature Engineering
message("\n[3/5] Engineering features...")

data <- data %>%
  mutate(
    # Lags
    lag_1 = lag(nitrogen_dioxide, 1),
    lag_24 = lag(nitrogen_dioxide, 24),  # Yesterday same hour
    lag_168 = lag(nitrogen_dioxide, 168), # Last week same hour
    
    # Rolling stats (24-hour window)
    roll_mean_24 = zoo::rollmean(nitrogen_dioxide, k=24, fill=NA, align="right"),
    roll_sd_24 = zoo::rollapply(nitrogen_dioxide, width=24, FUN=sd, fill=NA, align="right"),
    
    # Weather interactions
    temp_wind = temp * wind_speed
  ) %>%
  filter(!is.na(lag_168), !is.na(roll_sd_24))

message(sprintf("After feature engineering: %d samples", nrow(data)))

# 4. Prepare for LSTM
message("\n[4/5] Preparing LSTM data...")

feature_cols <- c("nitrogen_dioxide", "temp", "wind_speed", "precip",
                  "hour", "dow", "is_weekend", "is_rush_hour",
                  "lag_1", "lag_24", "lag_168", 
                  "roll_mean_24", "roll_sd_24", "temp_wind")

dataset <- data %>% 
  select(all_of(feature_cols)) %>% 
  mutate(across(everything(), as.numeric)) %>%  # Ensure all numeric
  as.matrix()

# Scale
scale_params <- list(
  mins = apply(dataset, 2, min, na.rm = TRUE),
  maxs = apply(dataset, 2, max, na.rm = TRUE)
)

scaled_data <- sweep(dataset, 2, scale_params$mins, "-")
scaled_data <- sweep(scaled_data, 2, scale_params$maxs - scale_params$mins, "/")

# Create sequences
create_lstm_data <- function(data, look_back = 48) {
  n_samples <- nrow(data) - look_back
  n_features <- ncol(data)
  
  X <- array(0, dim = c(n_samples, look_back, n_features))
  y <- numeric(n_samples)
  
  for (i in 1:n_samples) {
    X[i, , ] <- data[i:(i + look_back - 1), ]
    y[i] <- data[i + look_back, 1]
  }
  
  list(X = X, y = y)
}

LOOK_BACK <- 48  # 48 hours (2 days)
sequences <- create_lstm_data(scaled_data, LOOK_BACK)

# Train/Test split
train_size <- floor(length(sequences$y) * 0.8)
X_train <- sequences$X[1:train_size, , ]
y_train <- sequences$y[1:train_size]
X_test <- sequences$X[(train_size + 1):length(sequences$y), , ]
y_test <- sequences$y[(train_size + 1):length(sequences$y)]

message(sprintf("Training: %d | Test: %d | Features: %d", 
                dim(X_train)[1], dim(X_test)[1], ncol(dataset)))

# 5. Build & Train LSTM
message("\n[5/5] Building LSTM model...")

model <- keras_model_sequential() %>%
  layer_lstm(units = 128, return_sequences = TRUE, 
             input_shape = c(LOOK_BACK, ncol(dataset))) %>%
  layer_dropout(rate = 0.3) %>%
  
  layer_lstm(units = 64, return_sequences = FALSE) %>%
  layer_dropout(rate = 0.2) %>%
  
  layer_dense(units = 32, activation = "relu") %>%
  layer_dropout(rate = 0.2) %>%
  layer_dense(units = 1)

model %>% compile(
  optimizer = optimizer_adam(learning_rate = 0.001),
  loss = "mse",
  metrics = c("mae")
)

summary(model)

message("\nTraining LSTM on hourly data...")

early_stop <- callback_early_stopping(monitor = "val_loss", patience = 20, restore_best_weights = TRUE)
reduce_lr <- callback_reduce_lr_on_plateau(monitor = "val_loss", factor = 0.5, patience = 8, min_lr = 0.00001)

history <- model %>% fit(
  X_train, y_train,
  epochs = 150,
  batch_size = 64,
  validation_split = 0.15,
  callbacks = list(early_stop, reduce_lr),
  verbose = 1
)

# 6. Evaluate
message("\nEvaluating...")

preds_scaled <- model %>% predict(X_test, verbose = 0)
preds_real <- preds_scaled * (scale_params$maxs[1] - scale_params$mins[1]) + scale_params$mins[1]
y_test_real <- y_test * (scale_params$maxs[1] - scale_params$mins[1]) + scale_params$mins[1]

lstm_rmse <- sqrt(mean((y_test_real - preds_real)^2))
lstm_mae <- mean(abs(y_test_real - preds_real))
lstm_r2 <- 1 - sum((y_test_real - preds_real)^2) / sum((y_test_real - mean(y_test_real))^2)

message("\n======================================================================")
message("HOURLY LSTM RESULTS:")
message(sprintf("RMSE: %.3f", lstm_rmse))
message(sprintf("MAE:  %.3f", lstm_mae))
message(sprintf("R²:   %.3f", lstm_r2))
message("======================================================================")

if (lstm_rmse < 3.0) {
  message("✓ TARGET ACHIEVED: RMSE < 3.0!")
} else {
  message(sprintf("Target missed by %.3f", lstm_rmse - 3.0))
}

# 7. Save
results_df <- data.frame(
  Index = 1:length(y_test_real),
  Actual = as.vector(y_test_real),
  Predicted = as.vector(preds_real)
)

p <- ggplot(results_df[1:500, ], aes(x = Index)) +
  geom_line(aes(y = Actual), color = "black", linewidth = 0.5) +
  geom_line(aes(y = Predicted), color = "#E74C3C", linewidth = 0.5, alpha = 0.7) +
  labs(
    title = "Hourly LSTM Performance (First 500 Hours)",
    subtitle = sprintf("RMSE: %.3f | MAE: %.3f | R²: %.3f", lstm_rmse, lstm_mae, lstm_r2),
    y = "NO2 (μg/m³)", x = "Hour"
  ) +
  theme_minimal()

ggsave(file.path(viz_dir, "06_lstm_hourly.png"), p, width = 12, height = 6)
write_csv(results_df, file.path(base_dir, "reports/phase2_lstm_hourly.csv"))

message("\nComplete! Hourly LSTM trained on 35K+ samples.")
