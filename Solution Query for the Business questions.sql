select * from customers;
select * from sales;
select * from city;
select * from products;




-- 1.  Estimate Coffee Consumers: How many people in each city are estimated to consume coffee if 25% of the population does? Return city_name, 
-- total population, and estimated coffee consumers (25%).

SELECT 
    city_name,
    population,
    (population * 0.25) AS estimated_coffee_consumers
FROM city
order by 2 desc;


-- 2.Total Revenue: What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT 
    SUM(total) AS total_revenue
FROM 
    sales
WHERE 
    sale_date >= '2023-10-01' AND sale_date <= '2023-12-31';

-- 3. Units Sold: How many units of each coffee product have been sold? Return product_name and total_units_sold.

SELECT 
    product_name,
   COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN
sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC;

-- 4. Average Sales Amount: What is the average sales amount per customer in each city? Return city_name and average_sales_per_customer.

SELECT 
    city_name,
    round(AVG(total_sales),2) AS average_sales_per_customer
FROM 
    (SELECT 
        ci.city_name,
        s.customer_id,
        SUM(s.total) AS total_sales
     FROM 
        sales s
     JOIN 
        customers c ON s.customer_id = c.customer_id
     JOIN 
        products p ON s.product_id = p.product_id
	JOIN 
        city ci ON c.city_id = ci.city_id
     GROUP BY 
        ci.city_name, s.customer_id) AS customer_sales
GROUP BY city_name;
    
-- 5. City Population and Coffee Consumers: Provide a list of cities along with their populations and estimated coffee consumers (25%). 
-- Return city_name, total population, and estimated coffee consumers (25%).

SELECT 
    c.city_name,
    c.population,
    round((c.population * 0.25)/100000,4) AS estimated_coffee_consumers
FROM 
    city c;
    

-- 6. Top Selling Products: What are the top 3 selling products in each city based on sales volume? 
-- Return city_name, product_name, and sales_volume.

WITH RankedProducts AS (
    SELECT 
        ci.city_name,
        p.product_name,
        count(s.sale_id) AS sales_volume,
        ROW_NUMBER() OVER (PARTITION BY ci.city_name ORDER BY count(s.sale_id) DESC) AS top_rank
    FROM 
        sales s
    JOIN 
        products p ON s.product_id = p.product_id
    JOIN 
        customers c ON s.customer_id = c.customer_id
	JOIN 
        city ci ON ci.city_id = c.city_id
    GROUP BY 
        ci.city_name, p.product_name
)
SELECT 
    city_name,
    product_name,
    sales_volume
FROM 
    RankedProducts
WHERE 
    top_rank <= 3;
    
-- 7. Unique Customers: How many unique customers are there in each city who have purchased coffee products? Return city_name and total_unique_customers.

SELECT 
    c.city_name,
    COUNT(DISTINCT cu.customer_id) AS total_unique_customers
FROM city c
JOIN customers cu ON c.city_id = cu.city_id
JOIN sales s ON cu.customer_id = s.customer_id
JOIN products p ON s.product_id = p.product_id
GROUP BY c.city_name;


-- 8. Average Sale and Rent: Find each city and their average sale per customer and average rent per customer. 
-- Return city_name, average_sales_per_customer, and average_rent_per_customer.

SELECT 
    city_name,
    round(AVG(sales_per_customer)/1000,4) AS average_sales_per_customer,
    round(AVG(rent_per_customer)/1000,4) AS average_rent_per_customer
FROM (
    SELECT 
        ct.city_name,
        cu.customer_id,
        SUM(s.total) AS sales_per_customer,
        SUM(ct.estimated_rent) AS rent_per_customer
    FROM city ct
    JOIN customers cu ON ct.city_id = cu.city_id
    JOIN sales s ON cu.customer_id = s.customer_id
    JOIN products p ON s.product_id = p.product_id
    GROUP BY ct.city_name, cu.customer_id
) AS subquery
GROUP BY city_name;

-- 9. Sales Growth: Calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city. 
-- Return city_name, month, and percentage_growth.

SELECT 
    city_name,
    month,
    ROUND(((sales_this_month - sales_last_month) / sales_last_month) * 100, 2) AS percentage_growth
FROM (
    SELECT 
        c.city_name,
        DATE_FORMAT(s.sale_date, '%Y-%m') AS month,
        SUM(s.total) AS sales_this_month,
        LAG(SUM(s.total), 1) OVER (PARTITION BY c.city_name ORDER BY DATE_FORMAT(s.sale_date, '%Y-%m')) AS sales_last_month
    FROM city c
    JOIN customers cu ON c.city_id = cu.city_id
    JOIN sales s ON cu.customer_id = s.customer_id
    GROUP BY c.city_name, month
) AS subquery
WHERE sales_last_month IS NOT NULL;



-- 10. Top 3 Cities by Sales: Identify the top 3 cities based on highest sales. Return city_name, total_sales, total_rent, total_customers, 
-- and estimated coffee consumers (25%).

SELECT 
    c.city_name,
    SUM(s.total) AS total_sales,
    SUM(c.estimated_rent) AS total_rent,
    COUNT(DISTINCT cu.customer_id) AS total_customers,
    ROUND(COUNT(DISTINCT cu.customer_id) * 0.25, 0) AS estimated_coffee_consumers
FROM city c
JOIN customers cu ON c.city_id = cu.city_id
JOIN sales s ON cu.customer_id = s.customer_id
JOIN products p ON s.product_id = p.product_id
GROUP BY c.city_name
ORDER BY total_sales DESC
LIMIT 3;



