# 🌍 The Sheffield Experiment: Using Data to Measure Clean Air

[![R](https://img.shields.io/badge/Made%20with-R-blue.svg)](https://www.r-project.org/)
[![Status](https://img.shields.io/badge/Status-Complete-success.svg)]()
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **"Did the Clean Air Zone actually work?"** — A data science case study on policy, pollution, and public health.

---

## 📖 The Story

In February 2023, the city of Sheffield made a controversial decision. To combat rising pollution, they introduced a **Clean Air Zone (CAZ)**, charging the most polluting commercial vehicles to enter the city center.

It was a bold policy intervention. But policies are expensive, and public debate is often fueled by opinions rather than facts. **I wanted to know the truth.** 

Did the air actually get cleaner? Or was it just the weather?

This project is my attempt to answer that question using rigorous data science. By analyzing **35,000+ hours of air quality data**, I strip away the noise of seasons and weather to reveal the hidden signal of the policy's true impact.

---

## 📸 Executive Summary

The short answer: **Yes, it worked.** And better than expected.

![Executive Summary](visualizations/composites/05_executive_summary.png)

---

## 🧩 The Challenge: Why This Analysis is Hard

Measuring air pollution isn't as simple as comparing "before" vs. "after." 

Air quality is remarkably noisy:
*   **Weather**: Windy days clear pollution; stagnant winter days trap it.
*   **Seasonality**: Pollution is naturally higher in winter and lower in summer.
*   **Weekly Cycles**: Traffic drops on weekends.

If you just look at raw averages, you might mistake a windy month for a successful policy. To find the *causal* impact of the CAZ, we need to mathematically "control" for all these natural rhythms.

---

## 🔍 How We Solved It (The Methodology)

I tackled this problem using three distinct statistical angles, moving from simple forecasting to complex causal inference.

### 1. The Counterfactual (What *would* have happened?)
Using **ARIMA** and **Facebook Prophet**, I built models that learned the "heartbeat" of Sheffield's air pollution before 2023. I taught them the seasonal patterns, the weekly trends, and the yearly cycles.

Then, I asked them to predict what pollution *should* have looked like in 2024 and 2025 if the CAZ never happened.

**The Result**: The actual pollution levels (solid line) crashed far below the model's predictions (dotted line). The gap between them represents the clean air we gained.

![Model Comparison](visualizations/composites/02_model_forecast_comparison.png)

### 2. The Structural Break (Interrupted Time Series)
Visuals are great, but are they statistically significant? I used **Interrupted Time Series (ITS) Regression** to formally test the data.

This method looks for two things at the moment the policy started (Feb 27, 2023):
*   **Level Change**: Did pollution drop overnight?
*   **Slope Change**: Did the long-term trend start moving downwards?

**The Finding**: We found a statistically significant **immediate drop (-2.35 μg/m³)** followed by a **sustained daily improvement**. This proves the drop wasn't random chance—it was a direct result of the intervention.

---

## 📊 The Numbers

All three methods pointed to the same conclusion: a massive reduction in Nitrogen Dioxide (NO₂), the primary pollutant from diesel engines.

| Method | The Logic | Estimated Reduction |
|--------|-----------|---------------------|
| **ARIMA** | *Classical Forecasting* | **📉 29.9%** |
| **Prophet** | *Modern Bayesian Trend* | **📉 44.2%** |
| **ITS Regression** | *Statistical Causality* | **✅ p < 0.001 (Significant)** |

> **Context**: A 30-40% reduction is huge in environmental science. For context, many cities struggle to achieve even 5-10% reductions with similar policies.

---

## 🖼️ Visual Evidence

### The Shift
Look at the structural break in this dashboard. You can see the weekly rhythm of the city, and then—right at the black line—the "new normal" begins.

![CAZ Impact Dashboard](visualizations/composites/01_caz_impact_dashboard.png)

---

## 🛠️ Reproducibility

I believe science should be open. You can replicate this entire study from scratch using the code in this repository.

*   `scripts/`: Sequential R scripts (01-10) that handle everything from API calls to final plots.
*   `data/`: The processed datasets.
*   **Tech Stack**: R, Tidyverse, Forecast, Prophet, ggplot2.

### Analysis Pipeline
1.  **Extract**: Pull granular hourly data from Open-Meteo API.
2.  **Diagnose**: STL Decomposition to understand seasonality.
3.  **Model**: Train ARIMA/Prophet models on training set (2022-2023).
4.  **Test**: Evaluate causal impact on test set (2023-2025).

---

## 📬 About the Author

**Vedant Ghadi**  
Data Scientist | Environmental Analytics Enthusiast

I specialize in turning messy, real-world data into clear, actionable stories. This project is a demonstration of how data science can audit public policy and verify that our efforts to save the planet are actually working.

*   [GitHub](https://github.com/Vedant-ghadi)
*   [LinkedIn](https://linkedin.com/in/vedant-ghadi)

---
*Data Source: Copernicus Atmosphere Monitoring Service (CAMS) via Open-Meteo API.*
