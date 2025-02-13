SELECT 
    dt.year,
    dt.month,
    COUNT(fs.order_id) AS total_orders
FROM Fact_Sales fs
JOIN Dim_Time dt ON fs.time_key = dt.time_key
WHERE dt.date >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year'
GROUP BY dt.year, dt.month
ORDER BY dt.year, dt.month;

SELECT 
    dp.category AS product_category,
    SUM(fs.total_sales) AS total_revenue
FROM Fact_Sales fs
JOIN Dim_Time dt ON fs.time_key = dt.time_key
JOIN Dim_Product dp ON dp.product_key = ANY(fs.product_ids)
WHERE dt.date >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year'
GROUP BY dp.category
ORDER BY total_revenue DESC;

