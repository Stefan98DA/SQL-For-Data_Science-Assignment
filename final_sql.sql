--Reformat the final_assignments_qa to look like the final_assignments table, 
--filling in any missing values with a placeholder of the appropriate data type.

SELECT 
  item_id,
  test_a       AS test_assignment,
  CASE
  WHEN test_a IS NOT NULL THEN 'test_a'
  ELSE NULL
  END          AS test_name,
  CASE 
  WHEN test_a IS NOT NULL THEN CAST('2013-01-05 00:00:00' AS DATE)
  END          AS test_started
FROM 
  dsv1069.final_assignments_qa
UNION
SELECT 
  item_id,
  test_b       AS test_assignment,
  CASE
    WHEN test_b IS NOT NULL THEN 'test_b'
    ELSE NULL
  END          AS test_name,
  CASE 
    WHEN test_b IS NOT NULL THEN CAST('2013-01-05 00:00:00' AS DATE)
    ELSE NULL
  END          AS test_started
FROM 
  dsv1069.final_assignments_qa
UNION
SELECT 
  item_id,
  test_c       AS test_assignment,
  CASE
    WHEN test_c IS NOT NULL THEN 'test_c'
    ELSE NULL
  END          AS test_name,
  CASE 
    WHEN test_c IS NOT NULL THEN CAST('2013-01-05 00:00:00' AS DATE)
    ELSE NULL
  END          AS test_started
FROM 
  dsv1069.final_assignments_qa
UNION
SELECT 
  item_id,
  test_d       AS test_assignment,
  CASE
    WHEN test_d IS NOT NULL THEN 'test_d'
    ELSE NULL
  END          AS test_name,
  CASE 
    WHEN test_a IS NOT NULL THEN CAST('2013-01-05 00:00:00' AS DATE)
    ELSE NULL
  END          AS test_started
FROM 
  dsv1069.final_assignments_qa
UNION
SELECT 
  item_id,
  test_e       AS test_assignment,
  CASE
    WHEN test_e IS NOT NULL THEN 'test_e'
    ELSE NULL
  END          AS test_name,
  CASE 
    WHEN test_e IS NOT NULL THEN CAST('2013-01-05 00:00:00' AS DATE)
    ELSE NULL
  END          AS test_started
FROM 
  dsv1069.final_assignments_qa
UNION
SELECT 
  item_id,
  test_f       AS test_assignment,
  CASE
    WHEN test_f IS NOT NULL THEN 'test_f'
    ELSE NULL
  END          AS test_name,
  CASE 
    WHEN test_f IS NOT NULL THEN CAST('2013-01-05 00:00:00' AS DATE)
    ELSE NULL
  END          AS test_started
FROM 
  dsv1069.final_assignments_qa;


-- Use this table to 
-- compute order_binary for the 30 day window after the test_start_date
-- for the test named item_test_2

SELECT 
  item_id,
  test_assignment,
  test_number,
  MAX(CASE
        WHEN created_at > test_start_date 
        AND (DATE_PART('day', created_at - test_start_date) BETWEEN 1 AND 30) THEN 1
        ELSE 0
      END) AS order_binary
FROM
  (
  SELECT 
   fa.*,
   DATE(o.created_at) AS created_at
  FROM 
    dsv1069.final_assignments fa
  LEFT JOIN
    dsv1069.orders o 
  ON 
   fa.item_id = o.item_id
  WHERE
    test_number = 'item_test_2'
 
  )  test_2
 GROUP BY
    item_id,
    test_assignment,
    test_number;

-- Use this table to 
-- compute view_binary for the 30 day window after the test_start_date
-- for the test named item_test_2

SELECT 
  item_id,
  test_assignment,
  test_number,
  MAX(CASE
    WHEN (DATE_PART('day', viewed_at - test_start_date) BETWEEN 1 AND 30) THEN 1
    ELSE 0
  END) AS view_binary
FROM
  (
  SELECT 
   fa.*,
   DATE(event_time) AS viewed_at
  FROM 
    dsv1069.final_assignments fa
  LEFT JOIN 
    (
      SELECT 
        DATE(event_time)  AS event_time,
        CASE
          WHEN e.parameter_name = 'item_id' THEN CAST(parameter_value AS INT)
          ELSE NULL 
        END               AS viewed_item
      FROM 
        dsv1069.events e
      WHERE 
        event_name = 'view_item'
    ) events
  ON
    fa.item_id = events.viewed_item
  WHERE
    test_number = 'item_test_2'
  ) item_test_2
GROUP BY 
item_id,
  test_assignment,
  test_number;
--Use the https://thumbtack.github.io/abba/demo/abba.html to compute the lifts in metrics and 
--the p-values for the binary metrics ( 30 day order binary
--and 30 day view binary) using a interval 95% confidence. 

-- ORDER BINARY 
SELECT
  test_assignment,
  test_number,
  COUNT(DISTINCT item_id) AS number_items,
  SUM(order_binary)       AS number_orders
FROM
  ( 
  SELECT 
    item_id,
    test_assignment,
    test_number,
    MAX(CASE
          WHEN created_at > test_start_date 
          AND (DATE_PART('day', created_at - test_start_date) BETWEEN 1 AND 30) THEN 1
          ELSE 0
         END) AS order_binary
  FROM
    (
    SELECT 
     fa.*,
     DATE(o.created_at) AS created_at
    FROM 
      dsv1069.final_assignments fa
    LEFT JOIN
      dsv1069.orders o 
    ON 
     fa.item_id = o.item_id
    WHERE
      test_number = 'item_test_2'
   
    )  test_2
   GROUP BY
      item_id,
      test_assignment,
      test_number
  ) final_table
GROUP BY
  test_assignment,
  test_number;

-- VIEW BINARY


SELECT
  test_assignment,
  test_number,
  COUNT(DISTINCT item_id) AS number_items,
  SUM(view_binary)        AS number_views
FROM
  (
  SELECT 
    item_id,
    test_assignment,
    test_number,
    MAX(CASE
      WHEN (DATE_PART('day', viewed_at - test_start_date) BETWEEN 1 AND 30) THEN 1
      ELSE 0
    END) AS view_binary
  FROM
    (
    SELECT 
     fa.*,
     DATE(event_time) AS viewed_at
    FROM 
      dsv1069.final_assignments fa
    LEFT JOIN 
      (
        SELECT 
          DATE(event_time)  AS event_time,
          CASE
            WHEN e.parameter_name = 'item_id' THEN CAST(parameter_value AS INT)
            ELSE NULL 
          END               AS viewed_item
        FROM 
          dsv1069.events e
        WHERE 
          event_name = 'view_item'
      ) events
    ON
      fa.item_id = events.viewed_item
    WHERE
      test_number = 'item_test_2'
    ) item_test_2
  GROUP BY 
    item_id,
    test_assignment,
    test_number
  ) final_view_table
GROUP BY
  test_assignment,
  test_number;
  

  


