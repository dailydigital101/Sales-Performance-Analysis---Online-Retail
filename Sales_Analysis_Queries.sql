CREATE TABLE Orders(
	order_id INT PRIMARY KEY,
	user_id INT,
	product_id INT,
	quantity INT,
	order_date DATE,
	order_dow INT,
	order_hour_of_day INT,
	days_since_prior_order INT,
	order_status VARCHAR(50));
	
SELECT *  FROM Orders;

--created product_stage table - creating unit_cost and unit_price 
-- as TEXT data type because of regoinal decimal conversion
CREATE TABLE Products_stage (
  product_id INT,
  product_name VARCHAR(200),
  aisle_id INT,
  department_id INT,
  unit_cost TEXT,
  unit_price TEXT);
  
--replacing TEXT datatype with NUMERIC
ALTER TABLE Products_stage
ALTER COLUMN unit_price TYPE NUMERIC(10,2)
USING CAST(REPLACE(unit_price,',','.') AS NUMERIC(10,2));

ALTER TABLE Products_stage
ALTER COLUMN unit_cost TYPE NUMERIC(10,2)
USING CAST(REPLACE(unit_cost,',','.') AS NUMERIC(10,2));

--Renamimg product_stage table
ALTER TABLE Products_stage RENAME to Products;
SELECT * FROM Products;

--checking for duplicate values
SELECT product_id, COUNT(*)
FROM Products
GROUP BY product_id
HAVING COUNT(*)>1;

--REmoving duplicates
DELETE FROM Products a
USING (
    SELECT MIN(ctid) AS keep_ctid, product_id
    FROM products
    GROUP BY product_id
) b
WHERE a.product_id = b.product_id
AND a.ctid <> b.keep_ctid;

SELECT * FROM Products
--Creating dept table
CREATE TABLE Departments(
	department_id INT PRIMARY KEY,
	department VARCHAR(100));
	
SELECT *  FROM Departments;

--Creating aisle table
CREATE TABLE Aisles(
	aisle_id INT PRIMARY KEY,
	aisle VARCHAR(100));

SELECT *  FROM Aisles;


-- Q1 What are the top-selling products by revenue, and how much revenue have they generated?
SELECT p.product_name, SUM(p.unit_price*o.quantity) AS revenue
FROM Products p
INNER JOIN Orders o ON o.product_id = p.product_id 
GROUP BY product_name
ORDER BY revenue DESC;

-- Q2 On which day of the week are chocolates mostly sold?
-- Chocolates were sold mostly on Thursdays
SELECT p.product_name, 
		EXTRACT(MONTH FROM o.order_date) AS Mnth,
		TO_CHAR(o.order_date, 'DAY') AS Day_of_week,
		 SUM(o.quantity) AS quantity_sold
FROM Products p
INNER JOIN Orders o ON o.product_id = p.product_id
WHERE p.product_name ILIKE 'chocolates'
GROUP BY product_name, order_date,
		EXTRACT(MONTH FROM o.order_date),
		TO_CHAR(o.order_date, 'DAY')
ORDER BY  quantity_sold,Mnth, Day_of_week DESC;
--OR			
SELECT p.product_name,order_dow,SUM(o.quantity) AS quantity_sold 
FROM Products p
INNER JOIN Orders o ON o.product_id = p.product_id
WHERE p.product_name ILIKE 'chocolates'
GROUP BY product_name, order_dow
ORDER BY  quantity_sold DESC;
			
-- Q3 Do we have any dept where we have made over $15m in revenue and what is the profit?
-- Yes, 7 dept made over $15M in revenue with profits
SELECT d.department, 
		SUM(p.unit_price*o.quantity) AS revenue,
		SUM((p.unit_price-p.unit_cost)*o.quantity) AS profit
FROM Departments d
INNER JOIN Products p ON d.department_id = p.department_id
INNER JOIN Orders o ON p.product_id = o.product_id
GROUP BY department
HAVING SUM(p.unit_price*o.quantity)>15000000
ORDER BY revenue DESC;		 



-- Q4 Is it true that customers buy more alcoholic products on Xmas day 2019?
--It's not TRUE No sales of alcoholic products on Xmas day 2019
SELECT p.product_name,o.order_id, o.order_date 
FROM Products p
INNER JOIN Orders o ON o.product_id = p.product_id 
WHERE product_name ILIKE '%alcohol%'
AND order_date = '2019-12-25';


-- Q5 Which year did Instacart generate the most profit?
-- Instacart made the most sale in 2020 with over $38M in profit
SELECT 
		EXTRACT(YEAR FROM o.order_date) AS Yr,
		SUM((p.unit_price-p.unit_cost)*o.quantity) AS profit
FROM Orders o
INNER JOIN Products p ON o.product_id = p.product_id
GROUP BY Yr
ORDER BY profit DESC;
		

-- Q6 How long has it been since the last cheese order?
-- The last cheese was sold on 2023-04-07
SELECT o.order_id, p.product_name,
		MAX(o.order_date) AS recent_date
FROM Products p
INNER JOIN Orders o ON o.product_id = p.product_id
WHERE product_name ILIKE '%cheese%'
GROUP BY  order_id, product_name
ORDER BY recent_date DESC;

-- Q7 What time of the day do we sell alcohols the most?
SELECT order_id,order_dow,order_hour_of_day
FROM Orders o
INNER JOIN Products p ON p.product_id = o.product_id
Where product_name ILIKE '%alcohol%';


-- Q8 What is the total revenue generated in Qtr. 2 & 3 of 2016 from breads?
SELECT p.product_name,o.order_date,
		SUM(p.unit_price*o.quantity) AS total_revenue
from Products p
INNER JOIN Orders o ON p. product_id = o.product_id
WHERE o.order_date BETWEEN '2016-05-01'AND '2016-12-31'
AND product_name ILIKE '%bread%'
GROUP BY order_date, product_name;

-- Q9 Which 3 products do people buy the most at night(2020 - 2022)?
SELECT p.product_name,
		EXTRACT(YEAR FROM order_date) AS Yr,
		TO_CHAR(o.order_date, 'month') AS mnth,
		TO_CHAR(o.order_date, 'day') AS Dy,
		SUM(o.quantity) as quantity_sold 
FROM Orders o
INNER JOIN Products p ON o.product_id = p.product_id
WHERE order_date BETWEEN '2020-01-01' AND '2022-12-31'
AND order_hour_of_day > 19
GROUP BY product_name, 
		EXTRACT(YEAR FROM order_date),
		TO_CHAR(order_date, 'month'),
		TO_CHAR(order_date, 'day')
ORDER BY quantity_sold,yr,mnth,Dy DESC
LIMIT 3;

	
-- Q10 Is it true that 25% of our revenue is generated from juices?

SELECT p.product_name, SUM(p.unit_price*o.quantity) AS revenue
FROM Products p
INNER JOIN Orders o ON  o.product_id = p.product_id
GROUP BY product_name;

SELECT p.product_name, SUM(p.unit_price*o.quantity) AS revenue
FROM Products p
INNER JOIN Orders o ON  o.product_id = p.product_id
WHERE product_name ILIKE '%juice%'
GROUP BY product_name;

SELECT 
	ROUND(100.0 * SUM(CASE WHEN p.product_name ILIKE '%juice%' THEN p.unit_price*o.quantity ELSE 0 END)
	/SUM(p.unit_price*quantity),0) 
	AS juice_revenue_percentage
FROM Orders o
INNER JOIN Products p ON  o.product_id = p.product_id;

--It's not true.Juices generated only 2% of the total revenue
Select * from Orders;