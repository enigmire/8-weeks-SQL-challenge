# 🍜 Case Study #1: Danny's Diner

## Solution

View the complete syntax [here](https://github.com/enigmire/8-weeks-SQL-challenge/blob/main/Case%20Study%20%231%20-%20Danny's%20Diner/Danny%E2%80%99s%20Diner.sql).

***

### 1. What is the total amount each customer spent at the restaurant?

````sql
SELECT
    customer_id, 
    SUM(price) total_amount
FROM dannys_diner.menu m
JOIN dannys_diner.sales s
ON m.product_id = s.product_id
GROUP BY customer_id
ORDER BY total_amount DESC;
````

#### Steps:
- Use **SUM** and **GROUP BY** to find out ```total_amount``` contributed by each customer.
- Use **JOIN** to merge ```menu``` and ```sales``` tables as ```customer_id``` and ```price``` are from both tables.


#### Answer:

![image](https://user-images.githubusercontent.com/75146541/195858056-9a7fe71c-0dda-4ec1-a208-90fd9aa0a50b.png)

- Customer A spent $76.
- Customer B spent $74.
- Customer C spent $36.

***

### 2. How many days has each customer visited the restaurant?

````sql
SELECT 
    customer_id, 
    COUNT(DISTINCT(order_date)) num_of_days
FROM dannys_diner.sales s
GROUP BY customer_id
ORDER BY num_of_days DESC;
````

#### Steps:
- Use **DISTINCT** and wrap with **COUNT** to find out the ```num_of_days``` for each customer.
- We used **DISTINCT** to filter out ```order_date``` where Customers might visit twice within a day.

#### Answer:

![1](https://user-images.githubusercontent.com/75146541/195859351-79b96b25-b6b7-44b2-b2a0-523446166962.jpg)

- Customer A visited 4 times.
- Customer B visited 6 times.
- Customer C visited 2 times.

***

### 3. What was the first item from the menu purchased by each customer?

````sql
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
````

#### Steps:
- Create a temp table ```order_sales_cte``` and use **Windows function** with **DENSE_RANK** to create a new column ```rank``` based on ```order_date```.
- Instead of **ROW_NUMBER** or **RANK**, use **DENSE_RANK** as ```order_date``` is not time-stamped hence, there is no sequence as to which item is ordered first if 2 or more items are ordered on the same day.
- Subsequently, **GROUP BY** all columns to show ```rank = 1``` only.

#### Answer:

![1](https://user-images.githubusercontent.com/75146541/195859911-3d16ee8c-6638-4638-bbe0-9c1773785a34.jpg)

- Customer A's first orders are curry and sushi.
- Customer B's first order is curry.
- Customer C's first order is ramen.

***

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

````sql
SELECT 
    product_name, 
    COUNT(product_name) most_purchased
FROM dannys_diner.menu m
JOIN dannys_diner.sales s
ON s.product_id = m.product_id
GROUP BY product_name
ORDER BY most_purchased DESC
LIMIT 1;
````

#### Steps:
- **COUNT** number of ```product_name``` and **ORDER BY** ```most_purchased``` by descending order. 
- Then, use **LIMIT** to filter highest number of purchased item.

#### Answer:

![1](https://user-images.githubusercontent.com/75146541/195863076-3a544ae0-2052-42e9-90f3-4bf77beb834f.jpg)

- Most purchased item on the menu is ramen which is 8 times. Yummy!

***

### 5. Which item was the most popular for each customer?

````sql
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
````

#### Steps:
- Create a ```fav_item_cte``` and use **DENSE_RANK** to ```rank``` the ```order_count``` for each product by descending order for each customer.
- Generate results where product ```rank = 1``` only as the most popular product for each customer.

#### Answer:

![1](https://user-images.githubusercontent.com/75146541/195863663-1ed17020-3985-4000-82df-85a103ed2c58.jpg)

- Customer A and C's favourite item is ramen.
- Customer B enjoys all items on the menu.

***

### 6. Which item was purchased first by the customer after they became a member?

````sql
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
````

#### Steps:
- Create ```member_sales_cte``` by using **windows function** and partitioning ```customer_id``` by ascending ```order_date```. Then, filter ```order_date``` to be on or after ```join_date```.
- Then, filter table by ```rank = 1``` to show 1st item purchased by each customer.

#### Answer:

![1](https://user-images.githubusercontent.com/75146541/195863936-f305e076-f28c-435f-ba59-f89ca850ff04.jpg)

- Customer A's first order as member is curry.
- Customer B's first order as member is sushi.

***

### 7. Which item was purchased just before the customer became a member?

````sql
WITH prior_member_purchased_cte AS 
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
FROM prior_member_purchased_cte s
JOIN dannys_diner.menu me
ON s.product_id = me.product_id
WHERE rank = 1;
````

#### Steps:
- Create a ```prior_member_purchased_cte``` to create new column ```rank``` by using **Windows function** and partitioning ```customer_id``` by descending ```order_date``` to find out the last ```order_date``` before customer becomes a member.
- Filter ```order_date``` before ```join_date```.

#### Answer:

![1](https://user-images.githubusercontent.com/75146541/195864304-5c2d3549-d0f3-4407-8a1d-2fa54602432f.jpg)

- Customer A’s last order before becoming a member is sushi and curry.
- Whereas for Customer B, it has always been sushi. He/She must really love sushi!

***

### 8. What is the total items and amount spent for each member before they became a member?

````sql
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
````

#### Steps:
- Filter ```order_date``` before ```join_date``` and perform a **COUNT** **DISTINCT** on ```product_id``` and **SUM** the ```total spent``` before becoming member.

#### Answer:

![1](https://user-images.githubusercontent.com/75146541/195864668-f621ed19-b364-4d0c-a212-0c2cbdebfe07.jpg)

Before becoming members,
- Customer A spent $ 25 on 2 items.
- Customer B spent $40 on 2 items.

***

### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?

````sql
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
````

#### Steps:
Let’s breakdown the question.
- Each $1 spent = 10 points.
- But, sushi (product_id 1) gets 2x points, meaning each $1 spent = 20 points
So, we use CASE WHEN to create conditional statements
- If product_id = 1, then every $1 price multiply by 20 points
- All other product_id that is not 1, multiply $1 by 10 points
Using ```point_table```, **SUM** the ```points```.

#### Answer:

![1](https://user-images.githubusercontent.com/75146541/195865073-48c3adec-c816-4b62-b7b2-c7ec3d3d3c6f.jpg)

- Total points for Customer A is 860.
- Total points for Customer B is 940.
- Total points for Customer C is 360.

***

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?

````sql
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
````

#### Steps:
- In ```dates_cte```, find out customer’s ```valid_date``` (which is 6 days after ```join_date``` and inclusive of ```join_date```) and ```last_day``` of Jan 2021 (which is ‘2021–01–31’).
- Then query the ```customer_point``` to get the the ```total point``` for each customer

Our assumptions are:
- On Day -X to Day 1 (customer becomes member on Day 1 ```join_date```), each $1 spent is 10 points and for sushi, each $1 spent is 20 points.
- On Day 1 ```join_date``` to Day 7 ```valid_date```, each $1 spent for all items is 20 points.
- On Day 8 to ```last_day``` of Jan 2021, each $1 spent is 10 points and sushi is 2x points.

#### Answer:

![1](https://user-images.githubusercontent.com/75146541/195865589-4b95a8fb-b70b-4535-82fe-df044edb36f1.jpg)

- Total points for Customer A is 1,370.
- Total points for Customer B is 820.

***
