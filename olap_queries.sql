SELECT 
    dt.year,
    dt.month,
    COUNT(fs.order_id) AS total_orders
FROM Fact_Sales fs
JOIN Dim_Time dt ON fs.time_key = dt.time_key
WHERE dt.date >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year'
GROUP BY dt.year, dt.month
ORDER BY dt.year, dt.month;
