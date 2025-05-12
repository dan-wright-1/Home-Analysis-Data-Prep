# 🏡 Home Analysis Data Preparation

## 📦 Introduction

Welcome to my Home Investment Analysis project! In one of my data science courses, we used R to prepare a real estate dataset to assist a fictional stakeholder in identifying mobile home parks that are viable investment opportunities. This case focused on data cleaning and preparation, ensuring that the dataset was formatted and ready for analysis. The data was provided in both wide and long formats, requiring multiple steps of transformation to meet business requirements.

## 📉 Problem Statement

Our objective was to clean and consolidate property data for investment analysis. The goal was to provide a single, structured dataset with one row per property and columns representing relevant features, allowing the stakeholder to effectively assess investment opportunities in mobile home parks.

## 🗂️ Data Overview

* **Data Source:** Scraped data from a real estate investment website.
* **Formats:** One wide dataset and one long dataset.
* **Identifiers:** A unique `id` column links data between the wide and long formats.
* **Key Features:** Property name, location, price, property size, occupancy rate, amenities, and payment methods.
* **Data Issues:** Missing data, inconsistent formats, multiple price listings, and unstructured attribute columns.

## 🛠️ Methodology

1. **Data Preprocessing:**

   * Data Cleaning: Identified and resolved missing data in the wide dataset, ensuring that key columns had no `NA` values.
   * Data Conversion: Transformed price and percentage columns to numeric values and applied unit labels for clarity (e.g., `price_usd`).
   * Pivoting: Consolidated the long dataset by pivoting attribute data to wide format, creating new indicator columns.
   * Joining Data: Merged the cleaned wide and long datasets using the `id` column.

2. **Feature Engineering:**

   * Created new columns for property age and price per lot.
   * Extracted payment methods into binary indicator columns to facilitate analysis.

3. **Data Validation:**

   * Performed visual QA checks using density plots and histograms to validate data consistency.

## 📊 Results and Findings

* Successfully consolidated two datasets into one comprehensive, wide-format dataset with all relevant property features.
* Identified and resolved multiple pricing discrepancies, ensuring that the most recent listing price was retained.
* Generated binary indicator columns for specific property features (e.g., `has_laundromat`) and payment methods.
* Derived new columns (`age_years` and `price_per_lot_usd`) to provide additional business insights.

## 📢 Recommendations

* Utilize the cleaned dataset to develop investment scoring models based on property characteristics and price per lot.
* Implement automated data quality checks to identify and resolve missing or inconsistent data.
* Visualize property age and price distributions to identify outlier properties for further investigation.

## 🚀 Next Steps

* Deploy the cleaned dataset in a centralized database for ongoing analysis and monitoring.
* Develop interactive dashboards to visualize property features and potential investment returns.
* Implement advanced data analytics to identify high-potential investments based on historical pricing trends.

## ✅ Key Takeaways

* Data consolidation and cleaning are critical in transforming raw data into actionable insights for investment analysis.
* Creating binary indicator columns provides a structured approach to handling categorical attributes.
* Visual QA checks are essential in validating data consistency and identifying anomalies.
