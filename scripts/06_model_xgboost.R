# Phase 2: XGBoost Model
# Goal: Use Gradient Boosting to capture non-linear weather interactions

local_lib <- "c:/Users/vedan/.gemini/intro to data science/R_libs"
.libPaths(c(local_lib, .libPaths()))

if (!require("xgboost")) install.packages("xgboost")
library(xgboost)
library(dplyr)
library(readr)
library(ggplot2)
library(lubridate)
library(tidyr)

# Set up paths
base_dir <- "sheffield_openmeteo"
data_dir <- file.path(base_dir, "data")
viz_dir <- file.path(base_dir, "visualizations/phase2")

message("======================================================================")
message("PHASE 2: XGBOOST MODELING")
message("======================================================================")

# 1. Load Data & Feature Engineering
# ----------------------------------------------------------------
input_file <- file.path(data_dir, "phase2_sheffield_daily_weather.csv")
data <- read_csv(input_file, show_col_types = FALSE) %>%
  filter(!is.na(no2_mean), !is.na(temp_mean)) %>%
  arrange(date)

# Feature Engineering
# We need to turn specific dates into features a tree can understand
model_data <- data %>%
  mutate(
    # Time Features
    dow = wday(date, label = FALSE),
    month = month(date),
    year = year(date),
    day = yday(date),
    
    # Lag Features (Autocorrelation)
    lag_1 = lag(no2_mean, 1),
    lag_7 = lag(no2_mean, 7),
    
    # Rolling Features
    roll_mean_7 = zoo::rollmean(no2_mean, k = 7, fill = NA, align = "right"),
    
    # Interaction (Simple example)
    cold_stagnant = ifelse(temp_mean < 5 & wind_speed_max < 10, 1, 0)
  ) %>%
  filter(!is.na(lag_7), !is.na(roll_mean_7)) # Drop rows created by lags

# 2. Prepare for XGBoost
# ----------------------------------------------------------------
CAZ_DATE <- as.Date("2023-02-27")

train_df <- model_data %>% filter(date < CAZ_DATE)
test_df <- model_data %>% filter(date >= CAZ_DATE)

# Define Features
features <- c("temp_mean", "precip_sum", "wind_speed_max", "wind_dir",
              "dow", "month", "day", 
              "lag_1", "lag_7", "roll_mean_7")

X_train <- as.matrix(train_df[, features])
y_train <- train_df$no2_mean

X_test <- as.matrix(test_df[, features])
y_test <- test_df$no2_mean

# 3. Train Model
# ----------------------------------------------------------------
message("Training XGBoost Regressor...")

dtrain <- xgb.DMatrix(data = X_train, label = y_train)
dtest <- xgb.DMatrix(data = X_test, label = y_test)

params <- list(
  objective = "reg:squarederror",
  eta = 0.05,
  max_depth = 6,
  subsample = 0.8,
  colsample_bytree = 0.8
)

# Train with Early Stopping
model_xgb <- xgb.train(
  params = params,
  data = dtrain,
  nrounds = 1000,
  watchlist = list(train = dtrain, test = dtest),
  early_stopping_rounds = 50,
  print_every_n = 100,
  verbose = 0
)

# 4. Predict & Evaluate
# ----------------------------------------------------------------
# NOTE: For "Counterfactual", strict recursive forecasting is hard with XGBoost
# because it relies on lags of the *actual* data. 
# Here we are testing "One-Step Ahead" accuracy to see if XGBoost understands the system better.

preds <- predict(model_xgb, X_test)

# Calculate RMSE
rmse <- sqrt(mean((y_test - preds)^2))
message(sprintf("XGBoost RMSE (One-Step Ahead): %.2f", rmse))

# Feature Importance
importance <- xgb.importance(feature_names = features, model = model_xgb)
print(xgb.plot.importance(importance_matrix = importance))

# 5. Visualize Importance
# ----------------------------------------------------------------
p_imp <- xgb.ggplot.importance(importance_matrix = importance) +
  theme_minimal() +
  labs(title = "Feature Importance (XGBoost)", subtitle = "What drives pollution levels?")

ggsave(file.path(viz_dir, "04_xgboost_importance.png"), p_imp, width = 8, height = 6)
message(sprintf("Saved importance plot to %s", file.path(viz_dir, "04_xgboost_importance.png")))

# Save Results
results_df <- data.frame(
  date = test_df$date,
  actual = y_test,
  predicted_xgb = preds
)
write_csv(results_df, file.path(base_dir, "reports/phase2_xgboost_results.csv"))
