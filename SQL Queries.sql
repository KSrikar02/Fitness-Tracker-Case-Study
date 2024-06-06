DECLARE TIMESTAMP_REGEX STRING DEFAULT r'^\d{4}-\d{1,2}-\d{1,2}[T ]\d{1,2}:\d{1,2}:\d{1,2}(\.\d{1,6})? *(([+-]\d{1,2}(:\d{1,2})?)|Z|UTC)?$';
DECLARE DATE_REGEX STRING DEFAULT r'^\d{4}-(?:[1-9]|0[1-9]|1[012])-(?:[1-9]|0[1-9]|[12][0-9]|3[01])$';
DECLARE TIME_REGEX STRING DEFAULT r'^\d{1,2}:\d{1,2}:\d{1,2}(\.\d{1,6})?$';

DECLARE MORNING_START, MORNING_END, AFTERNOON_END, EVENING_END INT64;
SET MORNING_START = 6;
SET MORNING_END = 12;
SET AFTERNOON_END = 18;
SET EVENING_END = 21;

SELECT column_name, COUNT(table_name)
FROM `casestudyfitnesstracker.bellabeat.INFORMATION_SCHEMA.COLUMNS`
GROUP BY column_name;

SELECT table_name, SUM(CASE WHEN column_name = "Id" THEN 1 ELSE 0 END) AS has_id_column
FROM `casestudyfitnesstracker.bellabeat.INFORMATION_SCHEMA.COLUMNS`
GROUP BY table_name
ORDER BY table_name ASC;

SELECT table_name, SUM(CASE WHEN data_type IN ("TIMESTAMP", "DATETIME", "TIME", "DATE") THEN 1 ELSE 0 END) AS has_time_info
FROM `casestudyfitnesstracker.bellabeat.INFORMATION_SCHEMA.COLUMNS`
WHERE data_type IN ("TIMESTAMP", "DATETIME", "DATE")
GROUP BY table_name
HAVING has_time_info = 0;

SELECT CONCAT(table_catalog,".",table_schema,".",table_name) AS table_path, table_name, column_name
FROM `casestudyfitnesstracker.bellabeat.INFORMATION_SCHEMA.COLUMNS`
WHERE data_type IN ("TIMESTAMP", "DATETIME", "DATE");

SELECT table_name, column_name
FROM `casestudyfitnesstracker.bellabeat.INFORMATION_SCHEMA.COLUMNS`
WHERE REGEXP_CONTAINS(LOWER(column_name), "date|minute|daily|hourly|day|seconds");

SELECT ActivityDate, REGEXP_CONTAINS(STRING(ActivityDate), TIMESTAMP_REGEX) AS is_timestamp
FROM `casestudyfitnesstracker.bellabeat.dailyActivity_merged`
LIMIT 5;

SELECT CASE WHEN MIN(REGEXP_CONTAINS(STRING(ActivityDate), TIMESTAMP_REGEX)) = TRUE THEN "Valid" ELSE "Not Valid" END AS valid_test
FROM `casestudyfitnesstracker.bellabeat.dailyActivity_merged`;


SELECT
  A.Id,
  A.Calories,
  * EXCEPT(Id, Calories, ActivityDay, SleepDay, SedentaryMinutes, LightlyActiveMinutes, FairlyActiveMinutes, VeryActiveMinutes, SedentaryActiveDistance, LightActiveDistance, ModeratelyActiveDistance, VeryActiveDistance),
  I.SedentaryMinutes,
  I.LightlyActiveMinutes,
  I.FairlyActiveMinutes,
  I.VeryActiveMinutes,
  I.SedentaryActiveDistance,
  I.LightActiveDistance,
  I.ModeratelyActiveDistance,
  I.VeryActiveDistance
FROM `casestudyfitnesstracker.bellabeat.dailyActivity_merged` A
LEFT JOIN `casestudyfitnesstracker.bellabeat.dailyCalories_merged` C
  ON A.Id = C.Id AND A.ActivityDate = C.ActivityDay AND A.Calories = C.Calories
LEFT JOIN `casestudyfitnesstracker.bellabeat.dailyIntensities_merged` I
  ON A.Id = I.Id AND A.ActivityDate = I.ActivityDay AND A.FairlyActiveMinutes = I.FairlyActiveMinutes
  AND A.LightActiveDistance = I.LightActiveDistance AND A.LightlyActiveMinutes = I.LightlyActiveMinutes
  AND A.ModeratelyActiveDistance = I.ModeratelyActiveDistance AND A.SedentaryActiveDistance = I.SedentaryActiveDistance
  AND A.SedentaryMinutes = I.SedentaryMinutes AND A.VeryActiveDistance = I.VeryActiveDistance
  AND A.VeryActiveMinutes = I.VeryActiveMinutes
LEFT JOIN `casestudyfitnesstracker.bellabeat.dailySteps_merged` S
  ON A.Id = S.Id AND A.ActivityDate = S.ActivityDay
LEFT JOIN `casestudyfitnesstracker.bellabeat.sleepDay_merged` Sl
  ON A.Id = Sl.Id AND A.ActivityDate = CAST(Sl.SleepDay AS DATE);

SELECT Id, sleep_start AS sleep_date, COUNT(logId) AS number_naps, SUM(EXTRACT(HOUR FROM time_sleeping)) AS total_time_sleeping
FROM (
  SELECT Id, logId, MIN(DATE(date)) AS sleep_start, MAX(DATE(date)) AS sleep_end,
    TIME(TIMESTAMP_DIFF(MAX(date), MIN(date), HOUR), MOD(TIMESTAMP_DIFF(MAX(date), MIN(date), MINUTE), 60), MOD(MOD(TIMESTAMP_DIFF(MAX(date), MIN(date), SECOND), 3600), 60)) AS time_sleeping
  FROM `casestudyfitnesstracker.bellabeat.minuteSleep_merged`
  WHERE value = 1
  GROUP BY Id, logId)
WHERE sleep_start = sleep_end
GROUP BY Id, sleep_date
ORDER BY number_naps DESC;

WITH user_dow_summary AS (
  SELECT
    Id,
    FORMAT_TIMESTAMP("%w", ActivityHour) AS dow_number,
    FORMAT_TIMESTAMP("%A", ActivityHour) AS day_of_week,
    CASE
      WHEN FORMAT_TIMESTAMP("%A", ActivityHour) IN ("Sunday", "Saturday") THEN "Weekend"
      ELSE "Weekday"
    END AS part_of_week,
    CASE
      WHEN TIME(ActivityHour) BETWEEN TIME(MORNING_START, 0, 0) AND TIME(MORNING_END, 0, 0) THEN "Morning"
      WHEN TIME(ActivityHour) BETWEEN TIME(MORNING_END, 0, 0) AND TIME(AFTERNOON_END, 0, 0) THEN "Afternoon"
      WHEN TIME(ActivityHour) BETWEEN TIME(AFTERNOON_END, 0, 0) AND TIME(EVENING_END, 0, 0) THEN "Evening"
      ELSE "Night"
    END AS time_of_day,
    SUM(TotalIntensity) AS total_intensity,
    SUM(AverageIntensity) AS total_average_intensity,
    AVG(AverageIntensity) AS average_intensity,
    MAX(AverageIntensity) AS max_intensity,
    MIN(AverageIntensity) AS min_intensity
  FROM `casestudyfitnesstracker.bellabeat.hourlyIntensities_merged`
  GROUP BY Id, dow_number, day_of_week, part_of_week, time_of_day
),
intensity_deciles AS (
  SELECT
    DISTINCT dow_number,
    part_of_week,
    day_of_week,
    time_of_day,
    ROUND(PERCENTILE_CONT(total_intensity, 0.1) OVER (PARTITION BY dow_number, part_of_week, day_of_week, time_of_day), 4) AS total_intensity_first_decile,
    ROUND(PERCENTILE_CONT(total_intensity, 0.2) OVER (PARTITION BY dow_number, part_of_week, day_of_week, time_of_day), 4) AS total_intensity_second_decile,
    ROUND(PERCENTILE_CONT(total_intensity, 0.3) OVER (PARTITION BY dow_number, part_of_week, day_of_week, time_of_day), 4) AS total_intensity_third_decile,
    ROUND(PERCENTILE_CONT(total_intensity, 0.4) OVER (PARTITION BY dow_number, part_of_week, day_of_week, time_of_day), 4) AS total_intensity_fourth_decile,
    ROUND(PERCENTILE_CONT(total_intensity, 0.6) OVER (PARTITION BY dow_number, part_of_week, day_of_week, time_of_day), 4) AS total_intensity_sixth_decile,
    ROUND(PERCENTILE_CONT(total_intensity, 0.7) OVER (PARTITION BY dow_number, part_of_week, day_of_week, time_of_day), 4) AS total_intensity_seventh_decile,
    ROUND(PERCENTILE_CONT(total_intensity, 0.8) OVER (PARTITION BY dow_number, part_of_week, day_of_week, time_of_day), 4) AS total_intensity_eighth_decile,
    ROUND(PERCENTILE_CONT(total_intensity, 0.9) OVER (PARTITION BY dow_number, part_of_week, day_of_week, time_of_day), 4) AS total_intensity_ninth_decile
  FROM user_dow_summary
),
basic_summary AS (
  SELECT
    part_of_week,
    day_of_week,
    time_of_day,
    SUM(total_intensity) AS total_total_intensity,
    AVG(total_intensity) AS average_total_intensity,
    SUM(total_average_intensity) AS total_total_average_intensity,
    AVG(total_average_intensity) AS average_total_average_intensity,
    SUM(average_intensity) AS total_average_intensity,
    AVG(average_intensity) AS average_average_intensity,
    AVG(max_intensity) AS average_max_intensity,
    AVG(min_intensity) AS average_min_intensity
  FROM user_dow_summary
  GROUP BY part_of_week, dow_number, day_of_week, time_of_day
)
SELECT *
FROM basic_summary
LEFT JOIN intensity_deciles USING (part_of_week, day_of_week, time_of_day)
ORDER BY part_of_week, dow_number, day_of_week,
  CASE
    WHEN time_of_day = "Morning" THEN 0
    WHEN time_of_day = "Afternoon" THEN 1
    WHEN time_of_day = "Evening" THEN 2
    ELSE 3
  END;

