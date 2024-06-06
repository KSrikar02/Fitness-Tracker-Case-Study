Fitbit Data Analysis Project
Overview
This project involves analyzing Fitbit data stored in Kaggle. The analysis aims to explore various aspects of the data, including column names and types, timestamp validation, and activity patterns. The project also includes an in-depth look at daily activity, calorie burn, intensity levels, and sleep patterns.

Table of Contents
Introduction
Prerequisites
Project Structure
Dataset Description
Scripts Description
Running the Project
Analysis and Insights
Conclusion
Introduction
The Fitbit Data Analysis Project leverages SQL queries to analyze and validate Fitbit data stored in Google BigQuery. The analysis focuses on identifying common columns across tables, validating timestamp formats, merging data from different tables, and deriving insights related to user activities and sleep patterns.

Prerequisites
Google Cloud Platform (GCP) account with BigQuery enabled.
Basic knowledge of SQL.
Fitbit data loaded into BigQuery.

Dataset Description
The dataset consists of multiple tables containing Fitbit data. Key tables include:

dailyActivity_merged: Contains daily activity data such as steps, distance, and calories burned.
dailyCalories_merged: Contains daily calorie burn data.
dailyIntensities_merged: Contains daily intensity levels data.
dailySteps_merged: Contains daily step count data.
sleepDay_merged: Contains sleep data with start and end times.

Running the Project
Open Google BigQuery in the Google Cloud Console.
Create a new dataset and load your Fitbit data tables.
Copy and paste the SQL scripts from the fitbit_analysis.sql file into the BigQuery console.
Run each section of the script sequentially to validate and analyze the data, or run the entire script at once to execute the full analysis.
Analysis and Insights
The analysis covers various aspects of the Fitbit data, including:

Column and Schema Analysis: Identifies common columns and validates the presence of ID and timestamp columns.
Timestamp Validation: Ensures that the ActivityDate column follows the correct timestamp format.
Data Merging: Joins daily activity, calorie, intensity, step, and sleep data into a comprehensive dataset.
Nap Analysis: Identifies and summarizes nap patterns based on minute-level sleep data.
Intensity Analysis: Analyzes user activity intensity by day of the week and time of day, generating summary statistics and decile distributions.
Conclusion
This project demonstrates how to effectively analyze Fitbit data using SQL in Google BigQuery. By following the provided scripts and guidelines, you can explore and gain insights from your Fitbit dataset, enabling data-driven decisions for health and activity monitoring.
