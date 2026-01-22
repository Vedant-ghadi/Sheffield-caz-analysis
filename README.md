# 📉 Quantifying Policy Impact: Sheffield Clean Air Zone Analysis

[![R](https://img.shields.io/badge/R-4.5.2-276DC3.svg?logo=r&logoColor=white)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Complete-success.svg)]()

> **A rigorous time series analysis evaluating the causal effectiveness of Sheffield's 2023 Clean Air Zone (CAZ) intervention on Nitrogen Dioxide (NO₂) concentrations.**

---

## 📊 Executive Summary

This study employs **counterfactual inference** and **interrupted time series (ITS) regression** to quantify the impact of the Sheffield Clean Air Zone implemented on February 27, 2023.

By analyzing **35,064 hourly observations** (Jan 2022 – Dec 2025) and controlling for seasonality and exogenous factors, this analysis demonstrates a statistically significant reduction in traffic-related pollution.

**Key Results:**
*   **Significance:** The intervention caused a statistically observable structural break in NO₂ levels (**p < 0.001**).
*   **Magnitude:** Estimated reduction of **30%–44%** compared to the counterfactual baseline.
*   **Trend:** Immediate level drop followed by a sustained downward trajectory.

![Executive Summary](visualizations/composites/05_executive_summary.png)

---

## 🔬 Technical Methodology

To ensure robustness, this analysis utilizes a multi-model approach to isolate the policy effect from natural variation (weather, seasonality, and secular trends).

### 1. Baseline Forecasting (ARIMA & Prophet)
*   **Objective:** Construct a counterfactual "business as usual" baseline based on pre-intervention dynamics.
*   **Specification:** `SARIMA` for linear autocorrelation and `Prophet` for complex multi-seasonal patterns.
*   **Result:** Actual post-intervention NO₂ levels diverged significantly below both forecasts.

### 2. Machine Learning Weather Normalisation (XGBoost)
*   **Objective:** Remove meteorological confounding (wind speed, direction, temperature, precipitation) using non-linear gradient boosting.
*   **Result:** Confirmed that the reduction was driven by emissions changes, not favorable weather.

### 3. Interrupted Time Series (ITS) Regression
*   **Objective:** Formally test for causal structural breaks using segmented regression.
*   **Model:** $Y_t = \beta_0 + \beta_1 T + \beta_2 D + \beta_3 P + \epsilon_t$
    *   $D$ (Intervention): Immediate level change ($\beta_2 = -2.35$, $p=0.002$)
    *   $P$ (Time since intervention): Slope change ($\beta_3 = -0.014$, $p<0.001$)
*   **Conclusion:** The policy resulted in both an immediate drop and an accelerated rate of improvement.

### 4. Deep Learning Forecasting (LSTM)
*   **Objective:** Capture complex non-linear temporal dependencies for high-precision forecasting.

---

## 💻 Reproducible Workflow

This repository contains a fully reproducible R pipeline designed for environmental policy auditing. The analysis flows sequentially from data extraction to final reporting.

### Prerequisites
*   **Language**: R (v4.5.2+)
*   **Key Libraries**: `forecast`, `prophet`, `xgboost`, `keras3`, `tidyverse`, `zoo`, `lmtest`

### Pipeline Structure

**Data Engineering:**
1.  **`scripts/01_extract_air_quality.R`**: Extract hourly air quality data from Open-Meteo API.
2.  **`scripts/02_extract_weather_merge.R`**: Extract hourly weather data and merge with air quality dataset.
3.  **`scripts/03_eda_weather_pollution.R`**: Exploratory data analysis and correlation assessments.

**Modelling:**
4.  **`scripts/04_model_arima_baseline.R`**: Univariate time series baselining.
5.  **`scripts/05_model_prophet.R`**: Seasonality-aware forecasting.
6.  **`scripts/06_model_xgboost.R`**: Weather-normalised machine learning assessment.
7.  **`scripts/07_model_its.R`**: Causal impact segmentation analysis.
8.  **`scripts/08_model_lstm.R`**: Long Short-Term Memory network implementation.

**Reporting:**
9.  **`scripts/09_viz_composites.R`**: Generate high-level composite visualizations.
10. **`scripts/10_viz_gallery.R`**: Create gallery of diagnostic and summary plots.

To replicate the study, clone the repository and execute the scripts in numerical order.

```bash
git clone https://github.com/Vedant-ghadi/sheffield-caz-analysis.git
```

---

## 👤 Author

**Vedant Ghadigaonkar**  
*Data Scientist | Time Series Analysis | Policy Evaluation*

A data science professional focused on leveraging advanced statistical modeling to solve complex real-world problems. Experienced in building reproducible analytical pipelines, causal inference, and translating data into actionable strategic insights.

*   **GitHub**: [@Vedant-ghadi](https://github.com/Vedant-ghadi)
*   **LinkedIn**: [Vedant Ghadigaonkar](https://www.linkedin.com/in/vedant-ghadigaonkar-2bb022231/)

---

*Data provided by the Copernicus Atmosphere Monitoring Service (CAMS) via Open-Meteo API.*
