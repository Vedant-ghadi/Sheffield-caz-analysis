# Sheffield Clean Air Zone Impact Assessment

[![R](https://img.shields.io/badge/R-4.5.2-blue.svg)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Data Source](https://img.shields.io/badge/Data-Open--Meteo-green.svg)](https://open-meteo.com/)

> **Rigorous time series analysis quantifying the impact of Sheffield's Clean Air Zone on NO₂ pollution using ARIMA, Prophet, and Interrupted Time Series methods.**

![Sheffield CAZ Analysis](visualizations/composites/01_caz_impact_dashboard.png)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Key Findings](#key-findings)
- [Project Structure](#project-structure)
- [Installation](#installation)
- [Usage](#usage)
- [Methodology](#methodology)
- [Results](#results)
- [Visualizations](#visualizations)
- [Data](#data)
- [Contributing](#contributing)
- [License](#license)
- [Citation](#citation)
- [Contact](#contact)

---

## 🎯 Overview

This project evaluates the effectiveness of **Sheffield's Clean Air Zone (CAZ)**, implemented on February 27, 2023, in reducing nitrogen dioxide (NO₂) pollution. Using 4 years of hourly air quality data (2022-2025) from the Open-Meteo CAMS European Air Quality API, we employ multiple advanced time series methods to provide robust causal evidence.

### Research Question

**Does Sheffield's Clean Air Zone result in a statistically significant and sustained reduction in NO₂ pollution levels?**

### Why This Matters

- **Public Health**: NO₂ is linked to respiratory diseases, cardiovascular problems, and premature mortality
- **Policy Evaluation**: Evidence-based assessment of urban air quality interventions
- **Methodological Rigor**: Demonstrates best practices in causal inference and time series analysis
- **Reproducibility**: Fully open-source, documented workflow using publicly available data

---

## 🔍 Key Findings

| Method | NO₂ Reduction | Statistical Significance |
|--------|---------------|-------------------------|
| **ARIMA Forecasting** | **-29.9%** | Strong (counterfactual comparison) |
| **Prophet (Facebook)** | **-44.2%** | Strong (counterfactual comparison) |
| **Interrupted Time Series** | **-2.35 μg/m³ immediate** | p = 0.0024 ** |
| **ITS Slope Change** | **-0.0143 μg/m³/day** | p < 0.0001 *** |

### Bottom Line

✅ **All analytical methods converge on the same conclusion**: Sheffield's Clean Air Zone achieved a **statistically significant and sustained reduction** in NO₂ pollution.

---

## 📁 Project Structure

```
sheffield_openmeteo/
│
├── data/                          # Data files
│   ├── sheffield_raw.csv          # Raw hourly data (35,064 obs)
│   └── sheffield_daily.csv        # Daily aggregates (1,461 days)
│
├── scripts/                       # Analysis scripts (run in order)
│   ├── 01_extract_openmeteo.R     # API data extraction
│   ├── 02_validate_data.R         # Data quality checks
│   ├── 03_preprocess.R            # Feature engineering
│   ├── 04_time_series_diagnostics.R  # STL, stationarity tests
│   ├── 05_arima_models.R          # ARIMA forecasting
│   ├── 06_interrupted_time_series.R  # ITS regression
│   ├── 08_prophet_forecast.R      # Prophet modeling
│   ├── 09_create_composite_visualizations.R  # Viz (1-2)
│   ├── 10_create_remaining_composites.R      # Viz (3-5)
│   ├── 11_create_instantly_understandable_viz.R  # Final viz (1-3)
│   └── 12_create_final_instant_viz.R         # Final viz (4-5)
│
├── visualizations/                # Generated plots
│   ├── diagnostics/               # STL, ACF/PACF plots
│   ├── composites/                # Multi-panel visualizations
│   └── final/                     # Portfolio-quality viz
│
├── reports/                       # Analysis outputs
│   ├── validation_summary.txt     # Data quality report
│   ├── arima_results.csv          # ARIMA model results
│   ├── its_results.csv            # ITS regression results
│   └── prophet_results.csv        # Prophet model results
│
├── TECHNICAL_REPORT.md            # Comprehensive technical documentation
├── VISUALIZATION_GALLERY.md       # Visualization showcase
├── TIME_SERIES_GUIDE.md           # Methodology guide
├── API_RESEARCH.md                # Data source documentation
├── README.md                      # This file
├── LICENSE                        # MIT License
└── .gitignore                     # Git ignore rules
```

---

## 🚀 Installation

### Prerequisites

- **R** (version 4.5.2 or higher)
- **RStudio** (recommended)
- Internet connection (for API data extraction)

### Required R Packages

```r
# Install required packages
install.packages(c(
  "httr",        # API requests
  "jsonlite",    # JSON parsing
  "dplyr",       # Data manipulation
  "readr",       # Data I/O
  "lubridate",   # Date handling
  "forecast",    # ARIMA modeling
  "prophet",     # Facebook Prophet
  "tseries",     # Time series tests
  "ggplot2",     # Visualization
  "patchwork",   # Multi-panel plots
  "broom",       # Model tidying
  "scales",      # Plot scales
  "zoo"          # Time series utilities
))
```

### Clone Repository

```bash
git clone https://github.com/Vedant-ghadi/sheffield-caz-analysis.git
cd sheffield-caz-analysis
```

---

## 💻 Usage

### Quick Start

Run the analysis scripts in order:

```r
# Set working directory
setwd("sheffield_openmeteo")

# 1. Extract data from Open-Meteo API
source("scripts/01_extract_openmeteo.R")

# 2. Validate data quality
source("scripts/02_validate_data.R")

# 3. Preprocess and create features
source("scripts/03_preprocess.R")

# 4. Time series diagnostics
source("scripts/04_time_series_diagnostics.R")

# 5. ARIMA forecasting
source("scripts/05_arima_models.R")

# 6. Interrupted Time Series analysis
source("scripts/06_interrupted_time_series.R")

# 7. Prophet forecasting
source("scripts/08_prophet_forecast.R")

# 8-12. Create visualizations (optional)
source("scripts/09_create_composite_visualizations.R")
source("scripts/10_create_remaining_composites.R")
```

### Expected Runtime

- **Data extraction**: ~30 seconds
- **Validation & preprocessing**: ~10 seconds
- **Time series diagnostics**: ~1 minute
- **ARIMA modeling**: ~2 minutes
- **Prophet modeling**: ~1 minute
- **ITS regression**: <1 second
- **Visualizations**: ~2 minutes

**Total**: ~7-8 minutes for complete analysis

### Output Files

After running all scripts, you'll have:
- ✅ Raw and processed data files
- ✅ Model results (CSV tables)
- ✅ 15+ diagnostic and analysis plots
- ✅ 5 composite visualizations
- ✅ Validation and summary reports

---

## 🔬 Methodology

### Data Source

**Open-Meteo CAMS European Air Quality API**
- **Provider**: Copernicus Atmosphere Monitoring Service (CAMS)
- **Resolution**: 11km grid
- **Frequency**: Hourly
- **Coverage**: 2013-present
- **Pollutants**: PM2.5, PM10, NO₂, O₃, CO, SO₂, European AQI

**Why Open-Meteo?**
- ✅ Free, no API key required
- ✅ High data completeness (>99.9%)
- ✅ Consistent methodology
- ✅ Publicly accessible and reproducible

### Study Design

**Quasi-Experimental Design**: Before-After Comparison with Counterfactual Forecasting

**Periods**:
- **Pre-CAZ**: January 1, 2022 – February 26, 2023 (422 days)
- **Intervention**: February 27, 2023 (CAZ implementation)
- **Post-CAZ**: February 27, 2023 – December 31, 2025 (1,039 days)

**Total Sample**: 35,064 hourly observations → 1,461 daily observations

### Analytical Methods

#### 1. **ARIMA (AutoRegressive Integrated Moving Average)**

**Purpose**: Classical time series forecasting

**Approach**:
1. Train ARIMA model on pre-CAZ data
2. Forecast post-CAZ period (counterfactual)
3. Compare forecast vs. actual values
4. Difference = CAZ effect

**Model**: ARIMA(1,1,1)(1,0,0)[7] (automatically selected)

**Key Assumption**: Pre-CAZ trends would have continued without intervention

---

#### 2. **Prophet (Facebook's Forecasting Tool)**

**Purpose**: Modern, robust forecasting with automatic seasonality detection

**Approach**:
1. Fit Prophet model on pre-CAZ data
2. Automatically detect daily, weekly, yearly patterns
3. Forecast post-CAZ counterfactual
4. Compare forecast vs. actual

**Advantages**:
- Handles missing data and outliers
- Intuitive parameter tuning
- Industry-standard tool

---

#### 3. **Interrupted Time Series (ITS) Regression**

**Purpose**: Econometric gold standard for policy evaluation

**Model**:
```
NO₂ = β₀ + β₁(time) + β₂(intervention) + β₃(time_since_intervention) + ε
```

**Parameters**:
- **β₂**: Immediate level change at CAZ start
- **β₃**: Slope change (trend improvement)

**Advantages**:
- Direct statistical testing (p-values)
- Controls for pre-existing trends
- Separates immediate vs. gradual effects

---

### Statistical Tests

- **Stationarity**: Augmented Dickey-Fuller (ADF) test
- **Autocorrelation**: ACF/PACF analysis
- **Seasonality**: STL decomposition
- **Significance**: t-tests, F-tests (α = 0.05)

---

## 📊 Results

### Primary Outcome: NO₂ Reduction

**Descriptive Statistics**:

| Period | Mean NO₂ (μg/m³) | SD | Median | Range |
|--------|------------------|-----|--------|-------|
| **Pre-CAZ** | 13.55 | 9.82 | 11.3 | 0.1 - 71.8 |
| **Post-CAZ** | 12.09 | 8.67 | 10.1 | 0.0 - 79.5 |
| **Difference** | **-1.46** | - | **-1.2** | - |
| **% Change** | **-10.8%** | - | **-10.6%** | - |

**Model-Adjusted Effects**:

| Method | Effect Estimate | 95% CI | Interpretation |
|--------|----------------|--------|----------------|
| **ARIMA** | -29.9% | - | Actual 29.9% below forecast |
| **Prophet** | -44.2% | - | Actual 44.2% below forecast |
| **ITS (Immediate)** | -2.35 μg/m³ | [-3.87, -0.83] | Immediate drop (p=0.0024) |
| **ITS (Slope)** | -0.0143 μg/m³/day | [-0.020, -0.009] | Ongoing improvement (p<0.0001) |

### Health Implications

Based on WHO guidelines:
- **10 μg/m³ NO₂ reduction** → 5-10% reduction in respiratory hospital admissions
- **Sheffield's achievement**: 1.5-9.6 μg/m³ reduction (depending on method)
- **Estimated health benefit**: Measurable reduction in respiratory and cardiovascular events

### Secondary Pollutants

**PM2.5**: Mixed results (-3.9% to -36.2%, not consistently significant)  
**PM10**: Mixed results (-7.4% to -22.1%, not consistently significant)

**Interpretation**: CAZ primarily impacts traffic-related NO₂ (as expected)

---

## 🎨 Visualizations

### Composite Visualizations

1. **CAZ Impact Dashboard** (4-panel)
   - Time series with CAZ marker
   - Before/after comparison
   - Model comparison
   - Statistical significance

2. **Model Forecast Comparison** (3-panel)
   - ARIMA forecast
   - Prophet forecast
   - Direct comparison

3. **Multi-Pollutant Analysis** (6-panel)
   - NO₂, PM2.5, PM10 trends
   - Distribution comparisons

4. **Seasonal Patterns & Trends** (4-panel)
   - Monthly averages
   - Day-of-week patterns
   - Seasonal breakdown
   - Rolling averages

5. **Executive Summary** (single panel)
   - Complete story in one visualization
   - Presentation-ready

### Diagnostic Plots

- STL decomposition (trend, seasonal, remainder)
- ACF/PACF plots
- Forecast plots with confidence intervals
- ITS regression plots

**All visualizations available in**: `visualizations/` directory

---

## 📦 Data

### Data Files

**Raw Data**: `data/sheffield_raw.csv`
- 35,064 hourly observations
- 8 variables (time + 7 pollutants)
- 0% missing data for key pollutants

**Processed Data**: `data/sheffield_daily.csv`
- 1,461 daily observations
- 20+ variables (pollutants + temporal features)
- Ready for analysis

### Data Dictionary

| Variable | Description | Unit | Source |
|----------|-------------|------|--------|
| `time` | Timestamp (hourly) | POSIXct | API |
| `nitrogen_dioxide` | NO₂ concentration | μg/m³ | CAMS |
| `pm2_5` | PM2.5 concentration | μg/m³ | CAMS |
| `pm10` | PM10 concentration | μg/m³ | CAMS |
| `ozone` | O₃ concentration | μg/m³ | CAMS |
| `european_aqi` | European Air Quality Index | 0-100+ | CAMS |
| `date` | Date (daily) | Date | Derived |
| `caz_indicator` | CAZ period (0/1) | Binary | Derived |
| `season` | Season | Factor | Derived |

### Data Access

**Original Source**: [Open-Meteo Air Quality API](https://open-meteo.com/en/docs/air-quality-api)

**Reproducibility**: Run `scripts/01_extract_openmeteo.R` to fetch latest data

---

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Ways to Contribute

- 🐛 Report bugs or data issues
- 💡 Suggest new analyses or visualizations
- 📖 Improve documentation
- 🔧 Add new features or methods
- 🎨 Enhance visualizations

### Development Setup

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

### Data License

Air quality data is provided by Open-Meteo (CAMS) under their respective terms of use. This project uses publicly available data for research and educational purposes.

---

## 📚 Citation

If you use this analysis or methodology in your work, please cite:

```bibtex
@misc{sheffield_caz_2026,
  title={Sheffield Clean Air Zone Impact Assessment: A Time Series Analysis},
  author={Vedant Ghadi},
  year={2026},
  publisher={GitHub},
  url={https://github.com/Vedant-ghadi/sheffield-caz-analysis}
}
```

---

## 📞 Contact

**Project Maintainer**: Vedant Ghadi

- GitHub: [@Vedant-ghadi](https://github.com/Vedant-ghadi)
- LinkedIn: [Vedant Ghadi](https://linkedin.com/in/vedant-ghadi)

---

## 🙏 Acknowledgments

- **Open-Meteo**: For providing free, high-quality air quality data
- **CAMS**: Copernicus Atmosphere Monitoring Service for underlying data
- **Sheffield City Council**: For implementing the Clean Air Zone
- **R Community**: For excellent time series packages (forecast, prophet)

---

## 📖 Additional Documentation

- [**Technical Report**](TECHNICAL_REPORT.md): Comprehensive 12-section analysis documentation
- [**Visualization Gallery**](VISUALIZATION_GALLERY.md): Showcase of all visualizations
- [**Time Series Guide**](TIME_SERIES_GUIDE.md): Methodology deep-dive
- [**API Research**](API_RESEARCH.md): Data source evaluation

---

## 🎯 Project Status

✅ **Complete** - All analyses finished, documented, and reproducible

**Last Updated**: January 10, 2026

---

## ⭐ Star This Repository

If you find this project useful, please consider giving it a star! It helps others discover this work.

---

**Made with ❤️ and R**
