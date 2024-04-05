-- Data analysis
Select * From public.sales_dataset_rfm_prj_clean
-- Revenue by ProductLine, Year, and DealSize
Select 
	PRODUCTLINE, 
	YEARID, 
	DEALSIZE, 
	sum(sales) Over(partition by PRODUCTLINE, YEARID, DEALSIZE order by YEARID) as REVENUE
From public.sales_dataset_rfm_prj_clean

-- Which month had the highest sales each year?
-- Which month has the highest revenue?
SELECT 
	monthid,
	yearid,
	SUM (sales) AS revenue,
	ordernumber AS order_number
FROM sales_dataset_rfm_prj
GROUP BY monthid, ordernumber,yearid
ORDER BY revenue DESC
 
--Which product line sells the most in November?
SELECT 
	monthid,
	yearid,
	productline,
	SUM (sales) AS revenue,
	ordernumber AS order_number
FROM sales_dataset_rfm_prj
WHERE monthid = 11
GROUP BY monthid, ordernumber,productline,yearid
ORDER BY revenue DESC

--4) What is the top-selling product in the UK each year by revenue?

SELECT 
	yearid,
	productline,
	revenue
FROM (
	SELECT *,
	DENSE_RANK () OVER (PARTITION BY yearid ORDER BY revenue DESC) AS RANK
	FROM (
		SELECT 
			yearid, 
			productline, 
			SUM (sales) AS revenue
		FROM sales_dataset_rfm_prj
		WHERE country = 'UK'
		GROUP BY yearid, productline, country
		 ) as revenue_year
	) as rank_year
WHERE RANK = 1

-- Who are the best customers, RFM analysis

CREATE TABLE segment_score
(
    segment Varchar,
    scores Varchar)
Select * From public.segment_score

Select *
From public.sales_dataset_rfm_prj_clean;

With RFM_CTE as (
Select 
	customername,
	current_date - Max(orderdate) as R,
	count(Distinct ordernumber) as F,
	sum(sales) as M
From public.sales_dataset_rfm_prj_clean
Group by customername)
, RFM_SCORE AS (
Select 
	customername,
	ntile(5) Over(Order by R DESC) AS R_Score,
	ntile(5) Over(Order by F) as F_Score,
	ntile(5) Over(Order by M) as M_Score
From RFM_CTE)
, RFM_FINAL AS (
Select 
	customername,
	cast(R_Score as varchar) || cast(F_Score as varchar) || cast(M_Score as varchar) as RFM
From RFM_SCORE)

Select 
	customername,
	RFM,
	segment
From RFM_FINAL a join public.segment_score b on a.RFM =b.scores;
