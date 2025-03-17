-- SQL Analysis for Danny's Diner
-- Author: [Fady Talat]

-- Q1: Total amount each customer spent
SELECT
    customer_id,
    SUM(price) AS total_spent
FROM sales t1
LEFT JOIN menu t2 ON t1.product_id = t2.product_id
GROUP BY customer_id
ORDER BY total_spent DESC;

-- Q2: Number of days each customer visited the restaurant
SELECT
    customer_id,
    COUNT(DISTINCT order_date) AS total_days_visited
FROM sales
GROUP BY customer_id
ORDER BY customer_id;

-- Q3: First item purchased by each customer
SELECT
    customer_id,
    order_date
FROM sales
WHERE order_date = (SELECT MIN(order_date) FROM sales)
GROUP BY customer_id, order_date
ORDER BY customer_id;

-- Q4: Most purchased item and its total count
SELECT
    product_id,
    COUNT(*) AS total_purchases
FROM sales
GROUP BY product_id
ORDER BY total_purchases DESC
LIMIT 1;

-- Q5: Most purchased item for each customer
SELECT
    customer_id,
    product_id,
    COUNT(*) AS total_purchases
FROM sales
GROUP BY customer_id, product_id
ORDER BY total_purchases DESC, customer_id
LIMIT 5;

-- Q6: First item purchased after becoming a member
WITH ranking AS (
    SELECT
        t1.customer_id,
        product_id,
        order_date,
        DENSE_RANK() OVER(PARTITION BY t1.customer_id ORDER BY order_date) AS rnk
    FROM sales t1
    LEFT JOIN members t2 ON t1.customer_id = t2.customer_id
    WHERE order_date >= join_date
)
SELECT * FROM ranking WHERE rnk = 1;

-- Q7: Item purchased just before becoming a member
WITH ranking AS (
    SELECT
        t1.customer_id,
        product_id,
        order_date,
        DENSE_RANK() OVER(PARTITION BY t1.customer_id ORDER BY order_date DESC) AS rnk
    FROM sales t1
    LEFT JOIN members t2 ON t1.customer_id = t2.customer_id
    WHERE order_date < join_date
)
SELECT * FROM ranking WHERE rnk = 1;

-- Q8: Total items and amount spent before becoming a member
SELECT
    t1.customer_id,
    COUNT(t1.product_id) AS total_items,
    SUM(price) AS amount_spent
FROM sales t1
LEFT JOIN members t2 ON t1.customer_id = t2.customer_id
LEFT JOIN menu t3 ON t1.product_id = t3.product_id
WHERE order_date < join_date
GROUP BY t1.customer_id;

-- Q9: Customer points calculation
WITH points AS (
    SELECT
        customer_id,
        product_name,
        SUM(price) AS total_spent,
        CASE
            WHEN product_name = 'sushi' THEN SUM(price) * 20
            ELSE SUM(price) * 10
        END AS points
    FROM sales t1
    LEFT JOIN menu t2 USING(product_id)
    GROUP BY customer_id, product_name
)
SELECT customer_id, SUM(points) AS total_points
FROM points
GROUP BY customer_id
ORDER BY total_points DESC, customer_id;

-- Q10: Customer points with first-week double points
SELECT
    t1.customer_id,
    SUM(
        CASE
            WHEN t1.order_date BETWEEN t3.join_date AND DATE_ADD(t3.join_date, INTERVAL 6 DAY) THEN t2.price * 20
            WHEN t2.product_name = 'sushi' THEN t2.price * 20
            ELSE t2.price * 10
        END
    ) AS points
FROM sales t1
JOIN menu t2 ON t1.product_id = t2.product_id  
LEFT JOIN members t3 ON t1.customer_id = t3.customer_id
WHERE t1.order_date BETWEEN '2021-01-01' AND '2021-01-31'
GROUP BY t1.customer_id
ORDER BY points DESC;

-- Extra Queries:

-- Q11: Join all tables for insights
SELECT 
    customer_id, 
    order_date,
    product_name, 
    price,
    CASE 
        WHEN order_date >= join_date THEN 'Y'
        ELSE 'N'
    END AS member
FROM sales t1
LEFT JOIN menu t2 USING(product_id)
LEFT JOIN members t3 USING(customer_id)
ORDER BY customer_id, order_date, product_name;

-- Q12: Ranking items only for members
WITH ranked_data AS (
    SELECT 
        customer_id, 
        order_date,
        product_name, 
        price,
        CASE 
            WHEN order_date >= join_date THEN 'Y'
            ELSE 'N'
        END AS member
    FROM sales t1
    LEFT JOIN menu t2 USING(product_id)
    LEFT JOIN members t3 USING(customer_id)
    ORDER BY customer_id, order_date, product_name
)
SELECT 
    *,
    CASE
        WHEN member = 'Y' THEN DENSE_RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date) 
        ELSE NULL
    END AS ranking
FROM ranked_data;
