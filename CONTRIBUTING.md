# Contributing to Sheffield CAZ Analysis

Thank you for your interest in contributing to this project! This document provides guidelines for contributing.

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors, regardless of background or identity.

### Our Standards

- ✅ Be respectful and constructive
- ✅ Welcome newcomers and help them learn
- ✅ Focus on what is best for the community
- ❌ No harassment, trolling, or discriminatory language

## How to Contribute

### Reporting Bugs

**Before submitting a bug report:**
1. Check existing issues to avoid duplicates
2. Verify the bug with the latest code version
3. Collect relevant information (R version, package versions, error messages)

**Bug Report Template:**
```markdown
**Description**: Clear description of the bug

**To Reproduce**:
1. Step 1
2. Step 2
3. ...

**Expected Behavior**: What should happen

**Actual Behavior**: What actually happens

**Environment**:
- R Version: 
- OS: 
- Package Versions:

**Additional Context**: Screenshots, error messages, etc.
```

### Suggesting Enhancements

**Enhancement suggestions are welcome for:**
- New analytical methods
- Additional visualizations
- Performance improvements
- Documentation improvements
- New features

**Enhancement Template:**
```markdown
**Feature Description**: Clear description of the proposed feature

**Motivation**: Why is this feature valuable?

**Proposed Implementation**: How might this work?

**Alternatives Considered**: Other approaches you've thought about
```

### Pull Requests

**Process:**

1. **Fork the repository**
   ```bash
   git clone https://github.com/yourusername/sheffield-caz-analysis.git
   cd sheffield-caz-analysis
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Write clear, commented code
   - Follow existing code style
   - Add tests if applicable
   - Update documentation

4. **Test your changes**
   ```r
   # Run all scripts to ensure nothing breaks
   source("scripts/01_extract_openmeteo.R")
   source("scripts/02_validate_data.R")
   # ... etc
   ```

5. **Commit with clear messages**
   ```bash
   git commit -m "Add feature: brief description"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Open a Pull Request**
   - Provide clear description of changes
   - Reference any related issues
   - Include screenshots for visual changes

### Code Style Guidelines

**R Code:**
- Use `snake_case` for variable and function names
- Indent with 2 spaces (no tabs)
- Maximum line length: 80 characters
- Comment complex logic
- Use meaningful variable names

**Example:**
```r
# Good
calculate_daily_mean <- function(hourly_data, pollutant) {
  daily_data <- hourly_data %>%
    group_by(date) %>%
    summarise(mean_value = mean(!!sym(pollutant), na.rm = TRUE))
  
  return(daily_data)
}

# Avoid
calc <- function(d, p) {
  x <- d %>% group_by(date) %>% summarise(m = mean(!!sym(p), na.rm = TRUE))
  return(x)
}
```

**Documentation:**
- Use Markdown for documentation files
- Keep lines under 100 characters
- Use clear headings and formatting
- Include code examples where helpful

### Commit Message Guidelines

**Format:**
```
<type>: <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat: Add LSTM neural network forecasting method

Implements LSTM model as alternative to ARIMA/Prophet.
Includes hyperparameter tuning and cross-validation.

Closes #42
```

```
fix: Correct daylight saving time gap handling

Fixes issue where DST transitions caused NA values
in time series. Now properly handles 23/25 hour days.

Fixes #38
```

## Development Setup

### Prerequisites

- R (>= 4.5.2)
- RStudio (recommended)
- Git

### Installation

```r
# Install all required packages
install.packages(c(
  "httr", "jsonlite", "dplyr", "readr", "lubridate",
  "forecast", "prophet", "tseries", "ggplot2", 
  "patchwork", "broom", "scales", "zoo"
))
```

### Running Tests

```r
# Validate data quality
source("scripts/02_validate_data.R")

# Check model outputs
source("scripts/05_arima_models.R")
source("scripts/08_prophet_forecast.R")

# Verify visualizations generate without errors
source("scripts/09_create_composite_visualizations.R")
```

## Project Structure

```
sheffield_openmeteo/
├── data/              # Data files (not committed to git)
├── scripts/           # Analysis scripts
├── visualizations/    # Generated plots
├── reports/           # Analysis outputs
├── README.md          # Main documentation
├── TECHNICAL_REPORT.md  # Detailed technical docs
└── CONTRIBUTING.md    # This file
```

## Questions?

If you have questions about contributing:
1. Check existing documentation
2. Search closed issues
3. Open a new issue with the `question` label
4. Contact the maintainer

## Recognition

Contributors will be recognized in:
- README.md acknowledgments section
- Project documentation
- Release notes

Thank you for contributing! 🎉

---

**Last Updated**: January 10, 2026
