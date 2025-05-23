/* Here I imported the data file as a flat file*/

---Inspecting Data
SELECT * FROM [dbo].[sales_data_sample]

--CHecking unique values
SELECT DISTINCT STATUS FROM [dbo].[sales_data_sample] --Nice one to plot
SELECT DISTINCT year_id  FROM [dbo].[sales_data_sample]
SELECT DISTINCT PRODUCTLINE  FROM [dbo].[sales_data_sample] ---Nice to plot
SELECT DISTINCT COUNTRY  FROM [dbo].[sales_data_sample] ---Nice to plot
SELECT DISTINCT DEALSIZE  FROM [dbo].[sales_data_sample] ---Nice to plot
SELECT DISTINCT TERRITORY  FROM [dbo].[sales_data_sample] ---Nice to plot

SELECT DISTINCT MONTH_ID  FROM [dbo].[sales_data_sample]
where year_id = 2003

---ANALYSIS
----Let's start by grouping sales by productline
SELECT PRODUCTLINE, sum(sales) Revenue
FROM [dbo].[sales_data_sample]
GROUP BY  PRODUCTLINE
ORDER BY 2 DESC


select YEAR_ID, sum(sales) Revenue
FROM [dbo].[sales_data_sample]
group by YEAR_ID
order by 2 desc


SELECT 
    DEALSIZE,  
    SUM(sales) AS Revenue
FROM 
    sales_data_sample
GROUP BY 
    DEALSIZE
ORDER BY 
    Revenue DESC;


----What was the best month for sales in a specific year? How much was earned that month? 
select  MONTH_ID, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from .sales_data_sample
where YEAR_ID = 2004 --change year to see the rest
group by  MONTH_ID
order by 2 desc


--November seems to be the month, what product do they sell in November, Classic I believe
select  MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER)
from sales_data_sample
where YEAR_ID = 2004 and MONTH_ID = 11 --change year to see the rest
group by  MONTH_ID, PRODUCTLINE
order by 3 desc


----Who is our best customer (this could be best answered with RFM)


DROP TABLE IF EXISTS #rfm
;with rfm as 
(
	select 
		CUSTOMERNAME, 
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from [dbo].[sales_data_sample]) max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data_sample])) Recency
	from sales_data_sample
	group by CUSTOMERNAME
),
rfm_calc as
(

	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)
select 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar)rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven�t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm



--What products are most often sold together? 
--select * from [dbo].[sales_data_sample] where ORDERNUMBER =  10411

select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from [dbo].[sales_data_sample] p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM sales_data_sample
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes

from [dbo].[sales_data_sample] s
order by 2 desc


---EXTRAs----
--What city has the highest number of sales in a specific country
select city, sum (sales) Revenue
from sales_data_sample
where country = 'UK'
group by city
order by 2 desc



---What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from sales_data_sample
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc



/* monthly revenue and order volume*/

SELECT
    YEAR(ORDERDATE) AS Year,
    MONTH(ORDERDATE) AS Month,
    SUM(SALES) AS Total_Revenue,
    COUNT(DISTINCT ORDERNUMBER) AS Total_Orders
FROM
    sales_data_sample
GROUP BY
    YEAR(ORDERDATE),
    MONTH(ORDERDATE)
ORDER BY
    Year,
    Month;


/* Sales Trend by Product Line*/
SELECT 
    YEAR_ID AS Year,
    MONTH_ID AS Month,
    SUM(SALES) AS TotalSales
FROM sales_data_sample
GROUP BY YEAR_ID, MONTH_ID
ORDER BY Year, Month;

	/* Sales by country*/

SELECT 
    COUNTRY,
    SUM(SALES) AS TotalSales,
    COUNT(ORDERNUMBER) AS NumberOfOrders
FROM sales_data_sample
GROUP BY COUNTRY
ORDER BY TotalSales DESC;

	/* Sales by deal size*/
SELECT 
    DEALSIZE,
    SUM(SALES) AS TotalSales,
    COUNT(ORDERNUMBER) AS NumberOfOrders,
    AVG(SALES) AS AverageOrderValue
FROM sales_data_sample
GROUP BY DEALSIZE
ORDER BY 
    TotalSales DESC;


	/* top selling product*/
SELECT 
    PRODUCTCODE,
    PRODUCTLINE,
    SUM(QUANTITYORDERED) AS TotalQuantity,
    SUM(SALES) AS TotalSales
FROM sales_data_sample
GROUP BY PRODUCTCODE, PRODUCTLINE
ORDER BY TotalSales DESC


	/* Sales by country*/
SELECT 
    STATUS,
    COUNT(ORDERNUMBER) AS NumberOfOrders,
    SUM(SALES) AS TotalSales
FROM sales_data_sample
GROUP BY  STATUS;


/* Customer Analysis*/
SELECT 
    CUSTOMERNAME,
    SUM(SALES) AS TotalSales ,
    COUNT(ORDERNUMBER) AS NumberOfOrders,
    AVG(SALES) AS AverageOrderValue
FROM 
    sales_data_sample
GROUP BY CUSTOMERNAME
ORDER BY TotalSales DESC  ;
/* Sales Growth Rate*/
WITH yearly_sales AS (
    SELECT 
        YEAR_ID,
        SUM(SALES) AS TotalSales
    FROM 
        sales_data_sample
    GROUP BY 
        YEAR_ID
)
SELECT 
    a.YEAR_ID,
    a.TotalSales,
    ((a.TotalSales - b.TotalSales) / b.TotalSales) * 100 AS GrowthRate
FROM 
    yearly_sales a
JOIN 
    yearly_sales b ON a.YEAR_ID = b.YEAR_ID + 1
ORDER BY 
    a.YEAR_ID;
