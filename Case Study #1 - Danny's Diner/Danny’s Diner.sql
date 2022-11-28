--------------------------------
--CASE STUDY #1: DANNY'S DINER--
--------------------------------

--Author: Iyanu Elijah
--Date: 13/10/2022 (updated 14/10/2022)
--Tool used: PostgreSQL

CREATE SCHEMA dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

SELECT *
FROM dbo.members;

SELECT *
FROM dbo.menu;

SELECT *
FROM dbo.sales;

------------------------
--CASE STUDY QUESTIONS--
------------------------

--1. What is the total amount each customer spent at the restaurant?

SELECT
    customer_id, 
    SUM(price) total_amount
FROM dannys_diner.menu m
JOIN dannys_diner.sales s
ON m.product_id = s.product_id
GROUP BY customer_id
ORDER BY total_amount DESC;


--2. How many days has each customer visited the restaurant?

SELECT 
    customer_id, 
    COUNT(DISTINCT(order_date)) num_of_days
FROM dannys_diner.sales s
GROUP BY customer_id
ORDER BY num_of_days DESC;

--3. What was the first item from the menu purchased by each customer?

WITH ordered_sales_cte AS
(
 SELECT 
    customer_id,
    order_date, 
    product_name,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
FROM dannys_diner.menu m
JOIN dannys_diner.sales s
ON s.product_id = m.product_id
)
SELECT customer_id, product_name
FROM ordered_sales_cte
WHERE rank = 1
GROUP BY customer_id, product_name;

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
    product_name, 
    COUNT(product_name) most_purchased
FROM dannys_diner.menu m
JOIN dannys_diner.sales s
ON s.product_id = m.product_id
GROUP BY product_name
ORDER BY most_purchased DESC
LIMIT 1;

--5. Which item was the most popular for each customer?

WITH fav_item_cte AS
(
SELECT 
    s.customer_id, m.product_name, 
    COUNT(m.product_id) AS order_count,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.customer_id) DESC) AS rank
FROM dannys_diner.menu AS m
JOIN dannys_diner.sales AS s
ON m.product_id = s.product_id
GROUP BY s.customer_id, m.product_name
)
SELECT 
    customer_id, 
    product_name,
    order_count
FROM fav_item_cte 
WHERE rank = 1;

--6. Which item was purchased first by the customer after they became a member?

WITH member_sales_cte AS 
(
SELECT
    s.customer_id,
    m.join_date,
    s.order_date,
    s.product_id,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
FROM dannys_diner.sales s
JOIN dannys_diner.members m
ON s.customer_id = m.customer_id
WHERE s.order_date >= m.join_date
)
SELECT 
    s.customer_id,
    s.order_date,
    me.product_name 
FROM member_sales_cte s
JOIN dannys_diner.menu me
ON s.product_id = me.product_id
WHERE rank = 1;

--7. Which item was purchased just before the customer became a member?

WITH member_sales_cte AS 
(
SELECT
    s.customer_id,
    m.join_date,
    s.order_date,
    s.product_id,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rank
FROM dannys_diner.sales s
JOIN dannys_diner.members m
ON s.customer_id = m.customer_id
WHERE s.order_date < m.join_date
)
SELECT 
    s.customer_id, 
    s.order_date, 
    me.product_name 
FROM member_sales_cte s
JOIN dannys_diner.menu me
ON s.product_id = me.product_id
WHERE rank = 1;


--8. What is the total items and amount spent for each member before they became a member?

SELECT 
    s.customer_id,
    COUNT(DISTINCT(product_name)), 
    SUM(price)
FROM dannys_diner.sales s
JOIN dannys_diner.menu m
ON s.product_id = m.product_id
JOIN dannys_diner.members mm
ON mm.customer_id = s.customer_id                          
WHERE s.order_date < mm.join_date
GROUP BY s.customer_id;

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH point_table AS
(
SELECT *, 
    CASE
        WHEN product_id = 1 THEN price * 20
        ELSE price * 10
        END AS points
FROM dannys_diner.menu
)
SELECT
    customer_id, 
    SUM(points)
FROM point_table
JOIN dannys_diner.sales s
ON s.product_id = point_table.product_id
GROUP BY customer_id;

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi
--- how many points do customer A and B have at the end of January?

WITH customer_point AS
(
WITH dates_cte AS 
(
SELECT *, 
  (join_date + INTERVAL '6 DAY')::DATE AS valid_date, 
  (date_trunc('MONTH', ('202101'||'01')::date) + INTERVAL '1 MONTH - 1 day')::DATE last_date
FROM dannys_diner.members AS m
)
SELECT 
    d.customer_id,
    s.order_date,
    d.join_date, 
    d.valid_date,
    d.last_date,
    m.product_name,
    m.price,
    SUM
    (
        CASE
            WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
            WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN 2 * 10 * m.price
            ELSE 10 * m.price
            END
    ) AS points
FROM dates_cte AS d
JOIN dannys_diner.sales AS s
ON d.customer_id = s.customer_id
JOIN dannys_diner.menu AS m
ON s.product_id = m.product_id
WHERE s.order_date < d.last_date
GROUP BY d.customer_id, s.order_date, d.join_date, d.valid_date, d.last_date, m.product_name, m.price
)
SELECT customer_id, SUM(points)
FROM customer_point
GROUP BY customer_id;



