SELECT 
    c.name AS customer_name,
    COUNT(o.id) AS total_orders
FROM Customers c
JOIN Orders o ON c.id = o.customer_id
WHERE o.created_at >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
GROUP BY c.name
ORDER BY total_orders DESC;

SELECT 
    p.name AS product_name,
    COUNT(od.id) AS times_ordered
FROM Products p
JOIN Order_Details od ON p.id = od.product_id
GROUP BY p.name
ORDER BY times_ordered DESC
LIMIT 5;
