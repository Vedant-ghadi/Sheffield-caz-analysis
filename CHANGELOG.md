# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-10

### Added
- Initial release of Sheffield CAZ Impact Assessment
- Complete data extraction pipeline from Open-Meteo API
- Data validation and quality assessment scripts
- Preprocessing and feature engineering pipeline
- Time series diagnostics (STL decomposition, stationarity tests)
- ARIMA forecasting model implementation
- Prophet (Facebook) forecasting model implementation
- Interrupted Time Series (ITS) regression analysis
- Comprehensive visualization suite (15+ plots)
- 5 composite portfolio-quality visualizations
- Detailed technical report (12 sections, 8000+ words)
- Complete GitHub documentation (README, CONTRIBUTING, LICENSE)
- Reproducible workflow with documented decision-making

### Results
- NO₂ reduction: 29.9% (ARIMA), 44.2% (Prophet)
- Statistically significant ITS effects (p < 0.01)
- Robust evidence of CAZ effectiveness

### Documentation
- README.md with comprehensive usage instructions
- TECHNICAL_REPORT.md with detailed methodology
- VISUALIZATION_GALLERY.md showcasing all plots
- TIME_SERIES_GUIDE.md explaining methods
- API_RESEARCH.md documenting data source selection
- CONTRIBUTING.md with contribution guidelines

### Data
- 35,064 hourly observations (2022-2025)
- 1,461 daily aggregates
- 0% missing data for key pollutants
- Full temporal coverage pre/post CAZ

---

## [Unreleased]

### Planned Features
- Interactive Shiny dashboard
- LSTM neural network forecasting
- Spatial analysis (CAZ zone vs non-CAZ)
- Weather-adjusted pollution metrics
- Health outcome analysis
- Economic cost-benefit assessment

---

**Note**: This is version 1.0.0 - the first complete release of the project.
