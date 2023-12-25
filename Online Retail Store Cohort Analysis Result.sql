
WITH cte_Cohort_Items AS (							         -- To get retain users and their first engagements with the retail store 
	SELECT DATETRUNC(MONTH, MIN(InvoiceDate)) AS Cohort_First_Month 
	 	 , Customer_ID
		 , Country
	 FROM [AutoSales].[dbo].[OnlineRetailStoreDataset]
    WHERE InvoiceDate IS NOT NULL 
	  AND Country = 'United Kingdom'
    GROUP BY Customer_ID, Country
) 

, cte_Activities AS (								          -- Calculates when users have been sent comms relative to their cohort 
	SELECT a.Customer_ID
		, CASE WHEN DATEDIFF(MONTH,a.InvoiceDate,b.Cohort_First_Month) < 0 THEN -DATEDIFF(MONTH,a.InvoiceDate,b.Cohort_First_Month) ELSE DATEDIFF(MONTH,a.InvoiceDate,b.Cohort_First_Month) END AS Month_Number 
	 FROM [AutoSales].[dbo].[OnlineRetailStoreDataset] a
	 LEFT JOIN cte_Cohort_Items b 
	   ON a.Customer_ID = b.Customer_ID 
    WHERE InvoiceDate IS NOT NULL 
    GROUP BY a.Customer_ID, a.InvoiceDate, b.Cohort_First_Month
)

, cte_Cohort_Size AS (								         -- Counts number of users in each cohort month 
	SELECT Cohort_First_Month              
		, COUNT(Customer_ID) AS num_users     
	 FROM cte_Cohort_Items         
	GROUP BY Cohort_First_Month
)

, cte_Retention_Table AS (							     	 -- Calculates how many users are active in subsequent months  
	SELECT c.Cohort_First_Month              
		, a.month_number             
		, COUNT(DISTINCT a.Customer_ID) AS num_users        
		, c.Country
	FROM cte_Activities a     
	LEFT JOIN cte_Cohort_Items c        
	ON a.Customer_ID = c.Customer_ID    
	GROUP BY c.Cohort_First_Month, a.month_number, c.Country
)

  SELECT  t.cohort_First_month																		-- Cohort month was formed     
		, t.month_number																			-- Number of months after first month    
		, s.num_users AS total_users																-- Total number of users in the cohort   
		, t.num_users AS users_from_first_month														-- Users still getting comms from first month     
		, ROUND((CAST(t.num_users AS float) * 100 / s.num_users),4) AS cohort_pct                   -- Percent of users that are active in subsequent months
		, t.Country

 FROM cte_retention_table t 
 LEFT JOIN cte_Cohort_Size s 
   ON t.cohort_first_month = s.Cohort_First_Month
WHERE t.cohort_First_month IS NOT NULL
ORDER BY t.cohort_First_month, t.month_number, t.Country

