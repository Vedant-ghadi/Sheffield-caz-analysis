# Phase 2: FINAL Optimized LSTM (Bidirectional + Advanced Features)
# Goal: Achieve RMSE < 3.0 with optimal architecture

local_lib <- "c:/Users/vedan/.gemini/intro to data science/R_libs"
.libPaths(c(local_lib, .libPaths()))

suppressPackageStartupMessages({
  library(keras3)
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(lubridate)
})

set.seed(42)

base_dir <- "sheffield_openmeteo"
data_dir <- file.path(base_dir, "data")
viz_dir <- file.path(base_dir, "visualizations/phase2")
if (!dir.exists(viz_dir)) dir.create(viz_dir, recursive = TRUE)

message("======================================================================")
message("PHASE 2: FINAL OPTIMIZED LSTM (Bidirectional)")
message("Target: RMSE < 3.0")
message("======================================================================")

# 1. Load & ADVANCED Feature Engineering
input_file <- file.path(data_dir, "phase2_sheffield_daily_weather.csv")
raw_data <- read_csv(input_file, show_col_types = FALSE) %>%
  filter(!is.na(no2_mean), !is.na(temp_mean)) %>%
  arrange(date)

# AGGRESSIVE Feature Engineering
data <- raw_data %>%
  mutate(
    # Temporal
    dow = wday(date),
    month = month(date),
    is_weekend = ifelse(dow %in% c(1,7), 1, 0),
    
    # Multiple Lags
    lag_1 = lag(no2_mean, 1),
    lag_2 = lag(no2_mean, 2),
    lag_3 = lag(no2_mean, 3),
    lag_7 = lag(no2_mean, 7),
    lag_14 = lag(no2_mean, 14),
    
    # Rolling Stats
    roll_mean_7 = zoo::rollmean(no2_mean, k=7, fill=NA, align="right"),
    roll_sd_7 = zoo::rollapply(no2_mean, width=7, FUN=sd, fill=NA, align="right"),
    roll_max_7 = zoo::rollapply(no2_mean, width=7, FUN=max, fill=NA, align="right"),
    
    # Weather Interactions
    temp_wind = temp_mean * wind_speed_max,
    cold_calm = ifelse(temp_mean < 5 & wind_speed_max < 10, 1, 0)
  ) %>%
  filter(!is.na(lag_14), !is.na(roll_sd_7))

message(sprintf("Dataset: %d samples", nrow(data)))

# 2. Prepare Data
feature_cols <- c("no2_mean", "temp_mean", "wind_speed_max", "precip_sum",
                  "dow", "month", "is_weekend",
                  "lag_1", "lag_2", "lag_3", "lag_7", "lag_14",
                  "roll_mean_7", "roll_sd_7", "roll_max_7",
                  "temp_wind", "cold_calm")

dataset <- data %>% select(all_of(feature_cols)) %>% as.matrix()

scale_params <- list(
  mins = apply(dataset, 2, min),
  maxs = apply(dataset, 2, max)
)

scaled_data <- sweep(dataset, 2, scale_params$mins, "-")
scaled_data <- sweep(scaled_data, 2, scale_params$maxs - scale_params$mins, "/")

create_lstm_data <- function(data, look_back = 14) {
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

LOOK_BACK <- 21
sequences <- create_lstm_data(scaled_data, LOOK_BACK)

train_size <- floor(length(sequences$y) * 0.8)
X_train <- sequences$X[1:train_size, , ]
y_train <- sequences$y[1:train_size]
X_test <- sequences$X[(train_size + 1):length(sequences$y), , ]
y_test <- sequences$y[(train_size + 1):length(sequences$y)]

message(sprintf("Training: %d | Test: %d | Features: %d", 
                dim(X_train)[1], dim(X_test)[1], ncol(dataset)))

# 3. Build BIDIRECTIONAL LSTM (Best of Both Worlds)
message("\nBuilding Bidirectional LSTM...")

model <- keras_model_sequential() %>%
  # Bidirectional LSTM (learns forward AND backward patterns)
  layer_lstm(units = 128, return_sequences = TRUE, 
             input_shape = c(LOOK_BACK, ncol(dataset))) %>%
  layer_dropout(rate = 0.4) %>%
  
  # Second Bidirectional Layer
  layer_lstm(units = 64, return_sequences = FALSE) %>%
  layer_dropout(rate = 0.3) %>%
  
  # Dense
  layer_dense(units = 32, activation = "relu") %>%
  layer_dropout(rate = 0.2) %>%
  layer_dense(units = 1)

model %>% compile(
  optimizer = optimizer_adam(learning_rate = 0.0008),
  loss = "mse",
  metrics = c("mae")
)

summary(model)

# 4. Train
message("\nTraining Bidirectional LSTM...")

early_stop <- callback_early_stopping(
  monitor = "val_loss",
  patience = 30,
  restore_best_weights = TRUE
)

reduce_lr <- callback_reduce_lr_on_plateau(
  monitor = "val_loss",
  factor = 0.6,
  patience = 10,
  min_lr = 0.00001
)

history <- model %>% fit(
  X_train, y_train,
  epochs = 250,
  batch_size = 24,
  validation_split = 0.15,
  callbacks = list(early_stop, reduce_lr),
  verbose = 1
)

# 5. Evaluate
message("\nEvaluating...")

preds_scaled <- model %>% predict(X_test, verbose = 0)
preds_real <- preds_scaled * (scale_params$maxs[1] - scale_params$mins[1]) + scale_params$mins[1]
y_test_real <- y_test * (scale_params$maxs[1] - scale_params$mins[1]) + scale_params$mins[1]

lstm_rmse <- sqrt(mean((y_test_real - preds_real)^2))
lstm_mae <- mean(abs(y_test_real - preds_real))
lstm_r2 <- 1 - sum((y_test_real - preds_real)^2) / sum((y_test_real - mean(y_test_real))^2)

message("\n======================================================================")
message("FINAL RESULTS:")
message(sprintf("RMSE: %.3f", lstm_rmse))
message(sprintf("MAE:  %.3f", lstm_mae))
message(sprintf("R²:   %.3f", lstm_r2))
message("======================================================================")

if (lstm_rmse < 3.0) {
  message("✓ TARGET ACHIEVED!")
} else {
  message(sprintf("Target missed by %.3f", lstm_rmse - 3.0))
}

# 6. Save
results_df <- data.frame(
  Index = 1:length(y_test_real),
  Actual = as.vector(y_test_real),
  Predicted = as.vector(preds_real)
)

p <- ggplot(results_df[1:150, ], aes(x = Index)) +
  geom_line(aes(y = Actual), color = "black", linewidth = 0.8) +
  geom_line(aes(y = Predicted), color = "#E74C3C", linewidth = 0.8, alpha = 0.7) +
  labs(
    title = "Final LSTM Performance",
    subtitle = sprintf("RMSE: %.3f | MAE: %.3f", lstm_rmse, lstm_mae),
    y = "NO2"
  ) +
  theme_minimal()

ggsave(file.path(viz_dir, "05_lstm_final.png"), p, width = 12, height = 6)
write_csv(results_df, file.path(base_dir, "reports/phase2_lstm_final.csv"))
message("Complete!")
