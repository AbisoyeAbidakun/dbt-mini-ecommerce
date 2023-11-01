{{
    config(
        materialized='table'
    )
}}

WITH final AS (SELECT 
   session_id,
   traffic_source,
   DATE_TRUNC(created_at,DAY) day,
   MAX(products_page) AS product_made_it,
   MAX(purchase_page) AS purchase_made_it,
   MAX(cart_page) AS cart_made_it,
   MAX(home_page) AS home_made_it,
   MAX(department_page) AS department_made_it,
   MAX(cancel_page) AS cancel_made_it
FROM(
SELECT
	session_id,
    traffic_source,
    created_at,
	CASE WHEN web_link_source_page='/product' THEN 1 ELSE 0 END AS products_page,
	CASE WHEN web_link_source_page='/cart' THEN 1 ELSE 0 END AS cart_page,
	CASE WHEN web_link_source_page='/purchase' THEN 1 ELSE 0 END AS purchase_page,
    CASE WHEN web_link_source_page='/home' THEN 1 ELSE 0 END AS home_page,
    CASE WHEN web_link_source_page='/department' THEN 1 ELSE 0 END AS department_page,
    CASE WHEN web_link_source_page='/cancel' THEN 1 ELSE 0 END AS cancel_page
FROM `alt-dbt-proj.dbt_prod.web_campaign`
WHERE 
 created_at BETWEEN '2019-01-01' AND '2019-12-31'
ORDER BY session_id,traffic_source, created_at
)GROUP BY 1,2,3)

SELECT 
       traffic_source,
       day,
       COUNT(DISTINCT session_id) AS sessions,
       COUNT(DISTINCT CASE WHEN home_made_it=1 THEN session_id ELSE NULL END) AS to_home,
       COUNT(DISTINCT CASE WHEN home_made_it=1 THEN session_id ELSE NULL END)/NULLIF(COUNT(DISTINCT session_id),0)  AS home_clickedthru_rate, 
       COUNT(DISTINCT CASE WHEN department_made_it=1 THEN session_id ELSE NULL END) AS to_department,
       COUNT(DISTINCT CASE WHEN department_made_it=1 THEN session_id ELSE NULL END)/NULLIF(COUNT(DISTINCT CASE WHEN home_made_it=1 THEN session_id ELSE NULL END),0) AS department_clickedthru_rate,
       COUNT(DISTINCT CASE WHEN product_made_it=1 THEN session_id ELSE NULL END) AS to_product,
       COUNT(DISTINCT CASE WHEN product_made_it=1 THEN session_id ELSE NULL END)/NULLIF(COUNT(DISTINCT CASE WHEN department_made_it=1 THEN session_id ELSE NULL END),0) AS product_clickedthru_rate, 
	   COUNT(DISTINCT CASE WHEN cart_made_it=1 THEN session_id ELSE NULL END) AS to_cart,
       COUNT(DISTINCT CASE WHEN cart_made_it=1 THEN session_id ELSE NULL END)/NULLIF(COUNT(DISTINCT CASE WHEN product_made_it=1 THEN session_id ELSE NULL END),0) AS cart_clickedthru_rate,
       COUNT(DISTINCT CASE WHEN purchase_made_it=1 THEN session_id ELSE NULL END) AS to_purchase,
       COUNT(DISTINCT CASE WHEN purchase_made_it=1 THEN session_id ELSE NULL END)/NULLIF(COUNT(DISTINCT CASE WHEN cart_made_it=1 THEN session_id ELSE NULL END),0)  AS purcahse_clickedthru_rate,
       COUNT(DISTINCT CASE WHEN cancel_made_it=1 THEN session_id ELSE NULL END) AS to_cancel,
       COUNT(DISTINCT CASE WHEN cancel_made_it=1 THEN session_id ELSE NULL END)/NULLIF(COUNT(DISTINCT CASE WHEN purchase_made_it=1 THEN session_id ELSE NULL END),0)   AS cancel_clickedthru_rate,
       (COUNT(DISTINCT CASE WHEN purchase_made_it=1 THEN session_id ELSE NULL END)/NULLIF(COUNT(DISTINCT session_id),0))*100 AS purcahse_rate, 
       (COUNT(DISTINCT CASE WHEN cancel_made_it=1 THEN session_id ELSE NULL END)/NULLIF(COUNT(DISTINCT session_id),0))*100  AS cancel_rate,      
FROM final
GROUP BY 1,2

