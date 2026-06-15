-- ============================================
-- Superstore 销售数据分析 - 完整 SQL
-- 作者：李诗甜 | 上海对外经贸大学 | 数据科学与大数据技术
-- ============================================

-- ============================================
-- 1. 整体销售概览
-- ============================================

-- 1.1 总销售额、总利润、利润率
SELECT 
    ROUND(SUM(Sales), 2)    AS 总销售额,
    ROUND(SUM(Profit), 2)   AS 总利润,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS 利润率_百分比
FROM orders;

-- 1.2 按年份销售趋势
SELECT 
    YEAR(Order_Date) AS 年份,
    ROUND(SUM(Sales), 2) AS 销售额,
    ROUND(SUM(Profit), 2) AS 利润,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS 利润率,
    COUNT(DISTINCT Order_ID) AS 订单数
FROM orders
GROUP BY YEAR(Order_Date)
ORDER BY 年份;


-- ============================================
-- 2. 产品维度分析
-- ============================================

-- 2.1 按 Category 分析
SELECT 
    Category AS 品类,
    ROUND(SUM(Sales), 2)      AS 销售额,
    ROUND(SUM(Profit), 2)     AS 利润,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS 利润率_百分比,
    COUNT(DISTINCT Order_ID)  AS 订单数
FROM orders
GROUP BY Category
ORDER BY 利润 DESC;

-- 2.2 按 Sub-Category 分析
SELECT 
    Sub_Category AS 子品类,
    Category    AS 所属品类,
    ROUND(SUM(Sales), 2)      AS 销售额,
    ROUND(SUM(Profit), 2)     AS 利润,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS 利润率_百分比,
    SUM(Quantity) AS 总销量
FROM orders
GROUP BY Sub_Category, Category
ORDER BY 利润 DESC;

-- 2.3 亏损产品 Top 10
SELECT 
    Product_Name  AS 产品名称,
    Sub_Category  AS 所属子品类,
    ROUND(SUM(Sales), 2)   AS 销售额,
    ROUND(SUM(Profit), 2)  AS 利润,
    SUM(Quantity) AS 总销量
FROM orders
GROUP BY Product_Name, Sub_Category
HAVING SUM(Profit) < 0
ORDER BY 利润 ASC
LIMIT 10;

-- 2.4 折扣区间分析
SELECT 
    CASE 
        WHEN Discount = 0 THEN '无折扣'
        WHEN Discount <= 0.2 THEN '低折扣(0-20%)'
        WHEN Discount <= 0.5 THEN '中折扣(20-50%)'
        ELSE '高折扣(>50%)'
    END AS 折扣区间,
    COUNT(*) AS 订单明细数,
    ROUND(SUM(Sales), 2)      AS 销售额,
    ROUND(SUM(Profit), 2)     AS 利润,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS 利润率
FROM orders
GROUP BY 折扣区间
ORDER BY 利润率;



-- ============================================
-- 3. 地区维度分析
-- ============================================

-- 3.1 按 Region 分析
SELECT 
    Region AS 地区,
    ROUND(SUM(Sales), 2)      AS 销售额,
    ROUND(SUM(Profit), 2)     AS 利润,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS 利润率_百分比,
    COUNT(DISTINCT Order_ID)  AS 订单数,
    COUNT(DISTINCT Customer_ID) AS 客户数,
    ROUND(SUM(Sales) / COUNT(DISTINCT Customer_ID), 2) AS 客均消费
FROM orders
GROUP BY Region
ORDER BY 销售额 DESC;
-- 3.2 利润 Top 10 州
SELECT 
    State AS 州,
    Region AS 地区,
    ROUND(SUM(Sales), 2)      AS 销售额,
    ROUND(SUM(Profit), 2)     AS 利润,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS 利润率_百分比,
    COUNT(DISTINCT Customer_ID) AS 客户数
FROM orders
GROUP BY State, Region
ORDER BY 利润 DESC
LIMIT 10;

-- 3.3 利润 Bottom 10 州
SELECT 
    State AS 州,
    Region AS 地区,
    ROUND(SUM(Sales), 2)      AS 销售额,
    ROUND(SUM(Profit), 2)     AS 利润,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS 利润率_百分比,
    COUNT(DISTINCT Customer_ID) AS 客户数
FROM orders
GROUP BY State, Region
ORDER BY 利润 ASC
LIMIT 10;

-- 3.4 低利润率城市
SELECT 
    City AS 城市,
    State AS 州,
    ROUND(SUM(Sales), 2)       AS 销售额,
    ROUND(SUM(Profit), 2)      AS 利润,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS 利润率
FROM orders
GROUP BY City, State
HAVING COUNT(DISTINCT Order_ID) >= 10   -- 过滤掉订单太少的城市，避免偶然因素
ORDER BY 利润率 ASC
LIMIT 10;

-- 3.5 地区 × 品类交叉分析
SELECT 
    Region AS 地区,
    Category AS 品类,
    ROUND(SUM(Sales), 2)      AS 销售额,
    ROUND(SUM(Profit), 2)     AS 利润,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS 利润率
FROM orders
GROUP BY Region, Category
ORDER BY 地区, 利润 DESC;

-- ============================================
-- 4. RFM 用户分层分析
-- ============================================

-- 4.1 计算 R/F/M
SELECT 
    Customer_ID,
    Customer_Name,
    DATEDIFF('2018-01-01', MAX(Order_Date))  AS Recency,   -- 距数据集末日的天数，越小越好
    COUNT(DISTINCT Order_ID)                  AS Frequency,  -- 购买次数，越大越好
    ROUND(SUM(Sales), 2)                      AS Monetary    -- 累计消费，越大越好
FROM orders
GROUP BY Customer_ID, Customer_Name
ORDER BY Monetary DESC;


-- 4.2 NTILE(4) 打分
WITH rfm_base AS (
    SELECT 
        Customer_ID,
        Customer_Name,
        DATEDIFF('2018-01-01', MAX(Order_Date))  AS Recency,
        COUNT(DISTINCT Order_ID)                  AS Frequency,
        ROUND(SUM(Sales), 2)                      AS Monetary
    FROM orders
    GROUP BY Customer_ID, Customer_Name
),
rfm_score AS (
    SELECT 
        Customer_ID,
        Customer_Name,
        Recency,
        Frequency,
        Monetary,
        NTILE(4) OVER (ORDER BY Recency DESC)  AS R_score,  -- Recency 值大的（最久不来）→ 4分，越近分数越低
        NTILE(4) OVER (ORDER BY Frequency ASC)  AS F_score,  -- 频率低 → 1分
        NTILE(4) OVER (ORDER BY Monetary ASC)   AS M_score
    FROM rfm_base
)
SELECT *
FROM rfm_score
ORDER BY Monetary DESC;

-- 4.3 客户分层
WITH rfm_base AS (
    SELECT 
        Customer_ID,
        Customer_Name,
        DATEDIFF('2018-01-01', MAX(Order_Date))  AS Recency,
        COUNT(DISTINCT Order_ID)                  AS Frequency,
        ROUND(SUM(Sales), 2)                      AS Monetary
    FROM orders
    GROUP BY Customer_ID, Customer_Name
),
rfm_score AS (
    SELECT 
        Customer_ID,
        Customer_Name,
        Recency,
        Frequency,
        Monetary,
        NTILE(4) OVER (ORDER BY Recency DESC)  AS R_score,
        NTILE(4) OVER (ORDER BY Frequency ASC)  AS F_score,
        NTILE(4) OVER (ORDER BY Monetary ASC)   AS M_score
    FROM rfm_base
)
SELECT 
    Customer_ID,
    Customer_Name,
    Recency,
    Frequency,
    Monetary,
    R_score, F_score, M_score,
    CASE 
        WHEN R_score >= 3 AND F_score >= 3 AND M_score >= 3 THEN '高价值客户'
        WHEN R_score >= 3 AND F_score < 3                    THEN '重点发展客户'
        WHEN R_score <= 2 AND F_score >= 3 AND M_score >= 3 THEN '流失风险客户'
        ELSE '低价值客户'
    END AS 客户分层
FROM rfm_score
ORDER BY Monetary DESC;

-- 
WITH rfm_base AS (
    SELECT 
        Customer_ID,
        Customer_Name,
        DATEDIFF('2018-01-01', MAX(Order_Date))  AS Recency,
        COUNT(DISTINCT Order_ID)                  AS Frequency,
        ROUND(SUM(Sales), 2)                      AS Monetary
    FROM orders
    GROUP BY Customer_ID, Customer_Name
),
rfm_score AS (
    SELECT 
        Customer_ID,
        Customer_Name,
        Recency,
        Frequency,
        Monetary,
        NTILE(4) OVER (ORDER BY Recency DESC)  AS R_score,
        NTILE(4) OVER (ORDER BY Frequency ASC)  AS F_score,
        NTILE(4) OVER (ORDER BY Monetary ASC)   AS M_score
    FROM rfm_base
),
rfm_segment AS (
    SELECT 
        Customer_ID,
        Customer_Name,
        Monetary,
        CASE 
            WHEN R_score >= 3 AND F_score >= 3 AND M_score >= 3 THEN '高价值客户'
            WHEN R_score >= 3 AND F_score < 3                    THEN '重点发展客户'
            WHEN R_score <= 2 AND F_score >= 3 AND M_score >= 3 THEN '流失风险客户'
            ELSE '低价值客户'
        END AS 客户分层
    FROM rfm_score
)
SELECT 
    客户分层,
    COUNT(*) AS 客户数,
    CONCAT(ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100, 1), '%') AS 客户占比,
    ROUND(SUM(Monetary), 2) AS 贡献销售额,
    CONCAT(ROUND(SUM(Monetary) / SUM(SUM(Monetary)) OVER() * 100, 1), '%') AS 销售额占比,
    ROUND(AVG(Monetary), 2) AS 人均消费
FROM rfm_segment
GROUP BY 客户分层
ORDER BY 贡献销售额 DESC;


-- ============================================
-- 5. 时间趋势分析
-- ============================================

-- 5.1 按月统计
SELECT 
    DATE_FORMAT(Order_Date, '%Y-%m') AS 月份,
    ROUND(SUM(Sales), 2)              AS 销售额,
    ROUND(SUM(Profit), 2)             AS 利润,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS 利润率,
    COUNT(DISTINCT Order_ID)          AS 订单数
FROM orders
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
ORDER BY 月份;

-- 5.2 按季度统计
SELECT 
    YEAR(Order_Date) AS 年份,
    QUARTER(Order_Date) AS 季度,
    ROUND(SUM(Sales), 2)      AS 销售额,
    ROUND(SUM(Profit), 2)     AS 利润,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS 利润率,
    COUNT(DISTINCT Order_ID)  AS 订单数
FROM orders
GROUP BY YEAR(Order_Date), QUARTER(Order_Date)
ORDER BY 年份, 季度;

-- 5.3 每月新客数
SELECT 
    DATE_FORMAT(First_Order, '%Y-%m') AS 月份,
    COUNT(*) AS 新增客户数
FROM (
    SELECT 
        Customer_ID,
        MIN(Order_Date) AS First_Order
    FROM orders
    GROUP BY Customer_ID
) AS t
GROUP BY DATE_FORMAT(First_Order, '%Y-%m')
ORDER BY 月份;

-- 5.4 环比增长率
WITH monthly AS (
    SELECT 
        DATE_FORMAT(Order_Date, '%Y-%m') AS 月份,
        ROUND(SUM(Sales), 2)              AS 销售额
    FROM orders
    GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
)
SELECT 
    月份,
    销售额,
    LAG(销售额) OVER (ORDER BY 月份) AS 上月销售额,
    ROUND(
        (销售额 - LAG(销售额) OVER (ORDER BY 月份)) 
        / LAG(销售额) OVER (ORDER BY 月份) * 100, 1
    ) AS 环比增长率_百分比
FROM monthly
ORDER BY 月份;

-- 5.5 各月份 × 品类交叉趋势（横向对比）
SELECT 
    DATE_FORMAT(Order_Date, '%Y-%m') AS 月份,
    Category AS 品类,
    ROUND(SUM(Sales), 2)              AS 销售额
FROM orders
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m'), Category
ORDER BY 月份, 品类;

