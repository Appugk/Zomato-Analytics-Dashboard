#Creating Database
CREATE DATABASE zomato_project;


#Working in the Database
USE zomato_project;


# Creating Main Table
CREATE TABLE main_raw (RestaurantID VARCHAR(50), RestaurantName VARCHAR(255), CountryCode VARCHAR(50),
City VARCHAR(100), Address TEXT, Locality VARCHAR(255), LocalityVerbose TEXT, Longitude VARCHAR(50),
Latitude VARCHAR(50), Cuisines TEXT, Currency VARCHAR(50), Has_Table_booking VARCHAR(10),
Has_Online_delivery VARCHAR(10), Is_delivering_now VARCHAR(10), Switch_to_order_menu VARCHAR(10),
Price_range VARCHAR(50), Votes VARCHAR(50), Average_Cost_for_two VARCHAR(50),
Rating VARCHAR(50), Year_Opening VARCHAR(50), Month_Opening VARCHAR(50),Day_Opening VARCHAR(50));


SHOW VARIABLES LIKE 'secure_file_priv';


#Importing Main CSV File
LOAD DATA INFILE 
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Main.csv'
INTO TABLE main_raw
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(RestaurantID, RestaurantName, CountryCode, City, Longitude, Latitude, Cuisines, Currency, Has_Table_booking, Has_Online_delivery,
Is_delivering_now, Switch_to_order_menu, Price_range, Votes, Average_Cost_for_two, Rating, Year_Opening, Month_Opening,Day_Opening);

#Loading all records
SELECT COUNT(*) FROM main_raw;


# Creating Country Table
CREATE TABLE country (CountryID INT, Countryname VARCHAR(100));


#Importing Country CSV File
LOAD DATA INFILE 
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Country.csv'
INTO TABLE country
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


# Creating Currency Table
CREATE TABLE currency (Currency VARCHAR(50), USD_Rate DECIMAL(10,4));


#Importing Currency CSV File
LOAD DATA INFILE 
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Currency.csv'
INTO TABLE currency
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


#Creating Calendar Table
CREATE TABLE calendar (DateKey DATE PRIMARY KEY, Year INT, MonthNo INT, MonthFullName VARCHAR(20),
Quarter VARCHAR(2), YearMonth VARCHAR(10), WeekdayNo INT, WeekdayName VARCHAR(20),
FinancialMonth VARCHAR(5), FinancialQuarter VARCHAR(5));


#Inserting Values in Calendar Table
INSERT INTO calendar
SELECT DISTINCT DateKey_Opening AS DateKey, YEAR(DateKey_Opening) AS Year,
MONTH(DateKey_Opening) AS MonthNo, MONTHNAME(DateKey_Opening) AS MonthFullName,
CONCAT('Q', QUARTER(DateKey_Opening)) AS Quarter, DATE_FORMAT(DateKey_Opening,'%Y-%b') AS YearMonth,
DAYOFWEEK(DateKey_Opening) AS WeekdayNo, DAYNAME(DateKey_Opening) AS WeekdayName,
CONCAT('FM',CASE WHEN MONTH(DateKey_Opening) >= 4 THEN MONTH(DateKey_Opening) - 3
ELSE MONTH(DateKey_Opening) + 9
END) AS FinancialMonth,
CONCAT('FQ', CEILING((CASE WHEN MONTH(DateKey_Opening) >= 4 THEN MONTH(DateKey_Opening) - 3
ELSE MONTH(DateKey_Opening) + 9 END) / 3)) AS FinancialQuarter
FROM main_raw;

SELECT COUNT(*) FROM calendar;


#Restaurants & Their Avg Cost for two in USD
SELECT m.RestaurantName, m.Average_Cost_for_two,
c.USD_Rate, (m.Average_Cost_for_two * c.USD_Rate) AS Cost_in_USD
FROM main_raw m
JOIN currency c 
ON m.Currency = c.Currency;


#Total Restaurants by Country and City
SELECT c.CountryName, m.City,
COUNT(*) AS Total_Restaurants
FROM main_raw m
JOIN country c 
ON m.CountryCode = c.CountryID
GROUP BY c.CountryName, m.City
ORDER BY CountryName,Total_Restaurants DESC;


#Total Restaurants City-wise 
SELECT m.City,
COUNT(*) AS Total_Restaurants
FROM main_raw m
JOIN country c 
ON m.CountryCode = c.CountryID
GROUP BY m.City
ORDER BY Total_Restaurants DESC;


#Total Restaurants Country-wise
SELECT c.CountryName,
COUNT(*) AS Total_Restaurants
FROM main_raw m
JOIN country c 
ON m.CountryCode = c.CountryID
GROUP BY c.CountryName 
ORDER BY Total_Restaurants DESC;


#Yearly Restaurants Opening
SELECT YEAR(DateKey_Opening) AS Year, COUNT(*) AS Total
FROM main_raw
GROUP BY Year
ORDER BY Year;


#Quarterly Restaurants Opening
SELECT CONCAT('Q',QUARTER(DateKey_Opening)) AS Quarter,
COUNT(*) AS Total
FROM main_raw 
GROUP BY Quarter 
ORDER BY Quarter;


#Monthly Restaurants Opening
SELECT  MONTH(DateKey_Opening) AS MonthNo,
MONTHNAME(DateKey_Opening) AS Month,
COUNT(*) AS Total
FROM main_raw
GROUP BY MonthNo, Month
ORDER BY MonthNo;


#Restaurants by Rating
SELECT Rating, COUNT(*) AS Total
FROM main_raw
GROUP BY Rating
ORDER BY Rating;


#Total Restaurants by Cost Bucekts
SELECT CASE WHEN Average_Cost_for_two < 500 THEN 'Low(<500)'
WHEN Average_Cost_for_two BETWEEN 500 AND 1500 THEN 'Medium(500-1500)'
ELSE 'High(>1500)' END AS Price_Bucket,
COUNT(*) AS Total_Restaurants
FROM main_raw
GROUP BY Price_Bucket;


# % Restaurants Having Table Booking
SELECT Has_Table_booking,
COUNT(*) * 100.0 / (SELECT COUNT(*) FROM main_raw) AS Percentage
FROM main_raw
GROUP BY Has_Table_booking;


# % Restaurants Having Online Delivery
SELECT Has_Online_delivery,
COUNT(*) * 100.0 / (SELECT COUNT(*) FROM main_raw) AS Percentage
FROM main_raw
GROUP BY Has_Online_delivery;


#Top 5 Cities and Total Restaurants
SELECT City, COUNT(*) AS Total
FROM main_raw
GROUP BY City
ORDER BY Total DESC
LIMIT 5;


# Top 10 Cuisines and Total Restaurants
SELECT Cuisines,
COUNT(*) AS Total
FROM main_raw
GROUP BY Cuisines
ORDER BY Total DESC
LIMIT 10;


#Cities and Their Average Ratings
SELECT City, AVG(Rating) AS Avg_Rating
FROM main_raw
GROUP BY City
ORDER BY Avg_Rating DESC;


#YOY Growth %
SELECT YEAR(DateKey_Opening) AS Year, COUNT(*) AS Total,
LAG(COUNT(*)) OVER (ORDER BY YEAR(DateKey_Opening)) AS Previous_Year,
CONCAT(ROUND(((COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY YEAR(DateKey_Opening)))/
LAG(COUNT(*)) OVER (ORDER BY YEAR(DateKey_Opening))) * 100,2),'%') AS Growth_Percentage
FROM main_raw
GROUP BY YEAR(DateKey_Opening)
ORDER BY Year;





CREATE VIEW vw_restaurant_details AS
SELECT 
    m.RestaurantID,
    m.RestaurantName,
    c.CountryName,
    m.City,
    m.Cuisines,
    m.Rating,
    m.Votes,
    m.Average_Cost_for_two,
    cur.USD_Rate,
    (m.Average_Cost_for_two * cur.USD_Rate) AS Cost_in_USD
FROM main_raw m
JOIN country c ON m.CountryCode = c.CountryID
JOIN currency cur ON m.Currency = cur.Currency;

SELECT * FROM vw_restaurant_details;



CREATE VIEW vw_city_kpi AS
SELECT 
    City,
    COUNT(*) AS Total_Restaurants,
    AVG(Rating) AS Avg_Rating,
    SUM(Votes) AS Total_Votes
FROM main_raw
GROUP BY City;

SELECT * FROM vw_city_kpi;




#CREATE PROCEDURE sp_Top_Restaurants(IN p_limit INT)
BEGIN
    SELECT RestaurantName,City, Rating
    FROM main_raw
    ORDER BY Rating DESC
    LIMIT p_limit;
#END 

CALL sp_Top_Restaurants(5);







