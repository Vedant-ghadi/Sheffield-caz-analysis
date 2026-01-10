# 🌍 Sheffield Clean Air Zone: Using Data to Measure Impact

[![R](https://img.shields.io/badge/Made%20with-R-blue.svg)](https://www.r-project.org/)
[![Status](https://img.shields.io/badge/Status-Complete-success.svg)]()
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **"Did the Clean Air Zone actually work?"** — This project uses advanced time series analysis to answer that question with hard data.

---

## 📸 The Big Picture

If you only look at one thing, look at this. Here is the direct impact of the Clean Air Zone (CAZ) on Nitrogen Dioxide (NO₂) levels in Sheffield.

![Executive Summary](visualizations/composites/05_executive_summary.png)

---

## 👋 Overview

In February 2023, Sheffield introduced a **Clean Air Zone (CAZ)** to tackle pollution. But policy changes are expensive and controversial—so how do we know if they deliver results?

I built this project to move beyond opinions and look at the evidence. Using **4 years of hourly data (2022–2025)** and three different statistical modeling techniques, I quantified exactly how much pollution dropped after the intervention.

**The Verdict:** The data is clear. The CAZ worked.

---

## 📊 Key Findings

I used three independent methods to ensure the results weren't a fluke. They all point to the same conclusion: **a massive, sustained reduction in toxic NO₂.**

| Method | What it tells us | Result |
|--------|------------------|--------|
| **ARIMA** | "How much lower is pollution compared to the old trend?" | **📉 29.9% Lower** |
| **Prophet** | "What if we account for seasonal weather patterns?" | **📉 44.2% Lower** |
| **ITS Regression** | "Is this drop statistically significant?" | **✅ Yes (p < 0.001)** |

> **Impact**: A reduction of ~30-40% in NO₂ is significant enough to measurably improve public health outcomes, reducing risks of respiratory and cardiovascular issues.

---

## 🖼️ Visualizing the Change

### 1. The "Before & After" Dashboard
A clear look at the structural break in pollution levels. Note the weekly heartbeat of the city (higher on weekdays, lower on weekends) and the shift after Feb 2023.

![CAZ Impact Dashboard](visualizations/composites/01_caz_impact_dashboard.png)

### 2. Forecast vs. Reality
The dotted lines show where pollution *would have been* without the CAZ. The solid line is what actually happened. The gap between them is the "clean air dividend."

![Model Comparison](visualizations/composites/02_model_forecast_comparison.png)

---

## 🛠️ How It Works (The Tech Stack)

This isn't just a spreadsheet analysis. It's a robust, reproducible R pipeline.

**The Workflow:**
1.  **Extraction**: Pulls hourly data from [Open-Meteo API](https://open-meteo.com) (CAMS European Air Quality).
2.  **Cleaning**: Handles missing values, DST gaps, and aggregates to daily averages.
3.  **Diagnostics**: Checks for stationarity (ADF test) and seasonality (STL decomposition).
4.  **Modeling**:
    *   `auto.arima()` for classic forecasting.
    *   `Facebook Prophet` for modern, resilient trend detection.
    *   `Interrupted Time Series (ITS)` for formal statistical testing.
5.  **Visualization**: Uses `ggplot2` and `patchwork` to create publication-ready charts.

---

## 📂 Project Structure

Everything is organized so you can run it yourself.

*   `scripts/`: The R code. Numbered `01` to `10`—just run them in order.
*   `data/`: Where the raw and processed CSVs live.
*   `visualizations/`: All the generated charts and diagnostics.

---

## 🚀 Run It Yourself

Want to check my math? You can reproduce the entire analysis in about **5 minutes**.

1.  **Clone the repo:**
    ```bash
    git clone https://github.com/Vedant-ghadi/sheffield-caz-analysis.git
    ```
2.  **Open in RStudio** and install dependencies:
    ```r
    install.packages(c("tidyverse", "forecast", "prophet", "patchwork", "httr", "jsonlite", "zoo"))
    ```
3.  **Run the pipeline:**
    Start with `scripts/01_extract_openmeteo.R` and work your way down.

---

## 📬 Contact

I love discussing data for public good. If you have questions or ideas, reach out!

**Vedant Ghadi**
*   GitHub: [@Vedant-ghadi](https://github.com/Vedant-ghadi)
*   LinkedIn: [Vedant Ghadi](https://linkedin.com/in/vedant-ghadi)

---

*Data provided courtesy of Open-Meteo and Copernicus Atmosphere Monitoring Service (CAMS).*
