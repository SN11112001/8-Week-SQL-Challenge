CREATE SCHEMA cs1_dannys_diner;

USE cs1_dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales VALUES
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
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

-- Q No 1 = What is the total amount each customer spent at the restaurant?

SELECT 
  s.customer_id, 
  SUM(price) AS total_spent 
FROM 
  sales AS s 
	INNER JOIN menu AS u
		ON s.product_id = u.product_id 
GROUP BY 
  s.customer_id;

-- Q No 2 = How many days has each customer visited the restaurant?

SELECT 
  customer_id, 
  COUNT(
    DISTINCT(order_date)
  ) AS number_of_days_visited 
FROM 
  sales 
GROUP BY 
  customer_id;

-- Q No 3 = What was the first item from the menu purchased by each customer?

SELECT
	DISTINCT(customer_id),
    FIRST_VALUE(product_name) OVER(PARTITION BY customer_id ORDER BY order_date) AS First_ordered_item
FROM
	sales
		INNER JOIN menu
			ON sales.product_id = menu.product_id;

-- Q No 4 = What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT
	menu.product_name,
    COUNT(sales.product_id) AS number_of_times_ordered
FROM
	sales
		INNER JOIN menu
			ON sales.product_id = menu.product_id
GROUP BY
	menu.product_name
ORDER BY
	number_of_times_ordered DESC
LIMIT 1;

-- Q No 5 = Which item was the most popular for each customer?

WITH cte1 AS
(
SELECT
	customer_id,
    product_name,
    COUNT(*) AS number_of_times_item_ordered
FROM
	sales
		INNER JOIN menu
			ON sales.product_id = menu.product_id
GROUP BY
	customer_id,
    product_name
ORDER BY
	customer_id
),

cte2 AS

(
SELECT
    *,
    MAX(number_of_times_item_ordered) OVER(PARTITION BY customer_id) AS maxx
FROM
	cte1
)

SELECT
	customer_id,
    GROUP_CONCAT(product_name SEPARATOR ", " ) AS most_ordered_item_by_customer
FROM
	cte2
WHERE 
	number_of_times_item_ordered = maxx
GROUP BY
	customer_id
;

-- Q No 6 = Which item was purchased first by the customer after they became a member?

WITH cte AS
(
SELECT
	s.customer_id AS s_customer_id,
    s.order_date,
    s.product_id AS s_product_id,
    mem.customer_id AS mem_customer_id,
    join_date,
    m.product_id AS m_product_id,
    product_name,
    price,
    MIN(s.order_date) OVER(PARTITION BY s.customer_id) AS minimum_date
FROM
	sales AS s
		INNER JOIN
			members AS mem
				ON s.customer_id = mem.customer_id
		INNER JOIN
			menu AS m
				ON s.product_id = m.product_id
WHERE
	s.order_date >= mem.join_date
ORDER BY
	s.order_date
)
SELECT
	s_customer_id AS customer_id,
    product_name AS the_products_customer_purchased_after_becoming_the_member
FROM
	cte
WHERE order_date = minimum_date
;

-- Q No 7 = Which item was purchased just before the customer became a member?

WITH cte AS
(
SELECT
	s.customer_id AS s_customer_id,
    s.order_date,
    s.product_id AS s_product_id,
    mem.customer_id AS mem_customer_id,
    join_date,
    m.product_id AS m_product_id,
    product_name,
    price,
    MAX(s.order_date) OVER(PARTITION BY s.customer_id) AS maximum_date
FROM
	sales AS s
		INNER JOIN
			members AS mem
				ON s.customer_id = mem.customer_id
		INNER JOIN
			menu AS m
				ON s.product_id = m.product_id
WHERE
	s.order_date < mem.join_date
ORDER BY
	s.order_date DESC
),
cte2 AS
(
SELECT
	s_customer_id AS customer_id,
    product_name
FROM
	cte
WHERE order_date = maximum_date
)
SELECT
	customer_id,
    GROUP_CONCAT(product_name SEPARATOR ", ") AS the_products_customer_purchased_before_becoming_the_member
FROM
	cte2
GROUP BY
	customer_id
;

-- Q No 8 = What is the total items and amount spent for each member before they became a member?

WITH cte AS
(
SELECT
	s.customer_id AS s_customer_id,
    s.order_date,
    s.product_id AS s_product_id,
    mem.customer_id AS mem_customer_id,
    join_date,
    m.product_id AS m_product_id,
    product_name,
    price
FROM
	sales AS s
		INNER JOIN
			members AS mem
				ON s.customer_id = mem.customer_id
		INNER JOIN
			menu AS m
				ON s.product_id = m.product_id
WHERE
	s.order_date < mem.join_date
)
SELECT
	s_customer_id AS customer_id,
    COUNT(*) AS items_purchased_before_becoming_member,
    SUM(price) AS amount_spent_before_becoming_member
FROM
	cte
GROUP BY
	s_customer_id;

-- Q No 9 = If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH cte1 AS
(
SELECT
	customer_id AS customer_id_1,
    COUNT(*) AS total_orders,
    COUNT(*) * 10 AS points
FROM
	sales
GROUP BY
	customer_id
),
cte2 AS
(
SELECT
	customer_id AS customer_id_2,
    COUNT(*) AS total_sushi_orders,
    COUNT(*) * 2 AS multiplication
FROM
	sales
		INNER JOIN menu
			ON sales.product_id = menu.product_id
WHERE
	product_name = "sushi"
GROUP BY
	customer_id
)
SELECT
	customer_id_1 AS customer_id,
    points * IFNULL(multiplication,0) AS total_points
FROM
	cte1
		LEFT JOIN
			cte2
				ON cte1.customer_id_1 = cte2.customer_id_2;

-- Q No 10 = In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH cte AS
(
SELECT
	sales.customer_id AS sales_customer_id,
    order_date,
    sales.product_id AS sales_product_id,
    members.customer_id AS members_customer_id,
    join_date,
    menu.product_id AS menu_product_id,
    product_name,
    price,
    CASE
		WHEN
			DATEDIFF(order_date,join_date) BETWEEN 0 AND 7 THEN 2
		ELSE
			1
	END * price AS points
FROM
	sales
		INNER JOIN members
			ON sales.customer_id = members.customer_id
		INNER JOIN menu
			ON sales.product_id = menu.product_id
WHERE EXTRACT(MONTH FROM order_date) = 1
)
SELECT
	sales_customer_id AS customer_id,
    SUM(points) AS total_points_earned
FROM
	cte
GROUP BY
	sales_customer_id
ORDER BY
	sales_customer_id;