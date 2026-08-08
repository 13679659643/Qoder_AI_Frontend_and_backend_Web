let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
SELECT * FROM `indep_rl_ads`.a02_e2e_boss_fulfillment_request_data_d
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2026/7/15' AS dt, 'day' AS data_type, '2026-07-15' AS data_date, '29' AS data_week, 'FW202629' AS data_week_name, '07_Oct' AS data_month, '2026财年7月' AS data_month_name, '3' AS data_quarter, '2026财年第三季度' AS data_quarter_name, '2026' AS data_year, '2026财年' AS data_year_name, 'TM' AS framework, 'MN' AS gender, 'POLO' AS brand, 'APPAREL' AS product_type, 'TOPS' AS category_summary, 'SHIRT' AS category, 'payment' AS calc_type, 'Exclude orders cancelled in pay date' AS fulfillment_calc_type, 'RMB' AS currency, 12 AS o2o_fulfillment_request_failed_times, 150 AS o2o_fulfillment_request_times, 125.50 AS o2o_fulfillment_request_duration, 88 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2026/7/15' AS dt, 'day' AS data_type, '2026-07-15' AS data_date, '29' AS data_week, 'FW202629' AS data_week_name, '07_Oct' AS data_month, '2026财年7月' AS data_month_name, '3' AS data_quarter, '2026财年第三季度' AS data_quarter_name, '2026' AS data_year, '2026财年' AS data_year_name, 'JD' AS framework, 'CW' AS gender, 'RALPH' AS brand, 'ACCESSORIES' AS product_type, 'BOTTOMS' AS category_summary, 'PANT' AS category, 'payment' AS calc_type, 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled' AS fulfillment_calc_type, 'RMB' AS currency, 15 AS o2o_fulfillment_request_failed_times, 185 AS o2o_fulfillment_request_times, 148.30 AS o2o_fulfillment_request_duration, 102 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2026/7/20' AS dt, 'day' AS data_type, '2026-07-20' AS data_date, '30' AS data_week, 'FW202630' AS data_week_name, '07_Oct' AS data_month, '2026财年7月' AS data_month_name, '3' AS data_quarter, '2026财年第三季度' AS data_quarter_name, '2026' AS data_year, '2026财年' AS data_year_name, 'RLE' AS framework, 'WM' AS gender, 'LAUREN' AS brand, 'FOOTWEAR' AS product_type, 'OUTERWEAR' AS category_summary, 'JACKET' AS category, 'fulfillment' AS calc_type, 'Exclude orders cancelled in pay date' AS fulfillment_calc_type, 'RMB' AS currency, 18 AS o2o_fulfillment_request_failed_times, 210 AS o2o_fulfillment_request_times, 172.60 AS o2o_fulfillment_request_duration, 118 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2026/7/20' AS dt, 'day' AS data_type, '2026-07-20' AS data_date, '30' AS data_week, 'FW202630' AS data_week_name, '07_Oct' AS data_month, '2026财年7月' AS data_month_name, '3' AS data_quarter, '2026财年第三季度' AS data_quarter_name, '2026' AS data_year, '2026财年' AS data_year_name, 'JD' AS framework, 'WM' AS gender, 'POLO' AS brand, 'APPAREL' AS product_type, 'TOPS' AS category_summary, 'DRESS' AS category, 'fulfillment' AS calc_type, 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled' AS fulfillment_calc_type, 'RMB' AS currency, 20 AS o2o_fulfillment_request_failed_times, 235 AS o2o_fulfillment_request_times, 195.40 AS o2o_fulfillment_request_duration, 132 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2026/7/20' AS dt, 'day' AS data_type, '2026-07-20' AS data_date, '30' AS data_week, 'FW202630' AS data_week_name, '07_Oct' AS data_month, '2026财年7月' AS data_month_name, '3' AS data_quarter, '2026财年第三季度' AS data_quarter_name, '2026' AS data_year, '2026财年' AS data_year_name, 'RLE' AS framework, 'MN' AS gender, 'RALPH' AS brand, 'ACCESSORIES' AS product_type, 'BOTTOMS' AS category_summary, 'COAT' AS category, 'payment' AS calc_type, 'Exclude orders cancelled in pay date' AS fulfillment_calc_type, 'RMB' AS currency, 14 AS o2o_fulfillment_request_failed_times, 175 AS o2o_fulfillment_request_times, 158.20 AS o2o_fulfillment_request_duration, 95 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2026/6/15' AS dt, 'day' AS data_type, '2026-06-15' AS data_date, '25' AS data_week, 'FW202625' AS data_week_name, '06_Sep' AS data_month, '2026财年6月' AS data_month_name, '3' AS data_quarter, '2026财年第三季度' AS data_quarter_name, '2026' AS data_year, '2026财年' AS data_year_name, 'RLE' AS framework, 'WM' AS gender, 'POLO' AS brand, 'APPAREL' AS product_type, 'TOPS' AS category_summary, 'PANT' AS category, 'fulfillment' AS calc_type, 'Exclude orders cancelled in pay date' AS fulfillment_calc_type, 'RMB' AS currency, 22 AS o2o_fulfillment_request_failed_times, 265 AS o2o_fulfillment_request_times, 218.50 AS o2o_fulfillment_request_duration, 155 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2026/6/15' AS dt, 'day' AS data_type, '2026-06-15' AS data_date, '25' AS data_week, 'FW202625' AS data_week_name, '06_Sep' AS data_month, '2026财年6月' AS data_month_name, '3' AS data_quarter, '2026财年第三季度' AS data_quarter_name, '2026' AS data_year, '2026财年' AS data_year_name, 'DY' AS framework, 'WM' AS gender, 'RALPH' AS brand, 'ACCESSORIES' AS product_type, 'BOTTOMS' AS category_summary, 'JACKET' AS category, 'fulfillment' AS calc_type, 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled' AS fulfillment_calc_type, 'RMB' AS currency, 25 AS o2o_fulfillment_request_failed_times, 295 AS o2o_fulfillment_request_times, 238.70 AS o2o_fulfillment_request_duration, 172 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2026/6/15' AS dt, 'day' AS data_type, '2026-06-15' AS data_date, '25' AS data_week, 'FW202625' AS data_week_name, '06_Sep' AS data_month, '2026财年6月' AS data_month_name, '3' AS data_quarter, '2026财年第三季度' AS data_quarter_name, '2026' AS data_year, '2026财年' AS data_year_name, 'DY' AS framework, 'MN' AS gender, 'LAUREN' AS brand, 'FOOTWEAR' AS product_type, 'OUTERWEAR' AS category_summary, 'DRESS' AS category, 'payment' AS calc_type, 'Exclude orders cancelled in pay date' AS fulfillment_calc_type, 'RMB' AS currency, 28 AS o2o_fulfillment_request_failed_times, 325 AS o2o_fulfillment_request_times, 258.90 AS o2o_fulfillment_request_duration, 188 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2026/6/20' AS dt, 'day' AS data_type, '2026-06-20' AS data_date, '25' AS data_week, 'FW202625' AS data_week_name, '06_Sep' AS data_month, '2026财年6月' AS data_month_name, '3' AS data_quarter, '2026财年第三季度' AS data_quarter_name, '2026' AS data_year, '2026财年' AS data_year_name, 'DY' AS framework, 'CW' AS gender, 'POLO' AS brand, 'APPAREL' AS product_type, 'TOPS' AS category_summary, 'COAT' AS category, 'payment' AS calc_type, 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled' AS fulfillment_calc_type, 'RMB' AS currency, 30 AS o2o_fulfillment_request_failed_times, 355 AS o2o_fulfillment_request_times, 278.40 AS o2o_fulfillment_request_duration, 205 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2026/6/20' AS dt, 'day' AS data_type, '2026-06-20' AS data_date, '25' AS data_week, 'FW202625' AS data_week_name, '06_Sep' AS data_month, '2026财年6月' AS data_month_name, '3' AS data_quarter, '2026财年第三季度' AS data_quarter_name, '2026' AS data_year, '2026财年' AS data_year_name, 'DY' AS framework, 'WM' AS gender, 'RALPH' AS brand, 'ACCESSORIES' AS product_type, 'BOTTOMS' AS category_summary, 'SHIRT' AS category, 'fulfillment' AS calc_type, 'Exclude orders cancelled in pay date' AS fulfillment_calc_type, 'RMB' AS currency, 32 AS o2o_fulfillment_request_failed_times, 385 AS o2o_fulfillment_request_times, 298.60 AS o2o_fulfillment_request_duration, 222 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2026/6/20' AS dt, 'day' AS data_type, '2026-06-20' AS data_date, '25' AS data_week, 'FW202625' AS data_week_name, '06_Sep' AS data_month, '2026财年6月' AS data_month_name, '3' AS data_quarter, '2026财年第三季度' AS data_quarter_name, '2026' AS data_year, '2026财年' AS data_year_name, 'DY' AS framework, 'WM' AS gender, 'LAUREN' AS brand, 'FOOTWEAR' AS product_type, 'OUTERWEAR' AS category_summary, 'PANT' AS category, 'fulfillment' AS calc_type, 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled' AS fulfillment_calc_type, 'RMB' AS currency, 35 AS o2o_fulfillment_request_failed_times, 415 AS o2o_fulfillment_request_times, 318.80 AS o2o_fulfillment_request_duration, 238 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2026/6/20' AS dt, 'day' AS data_type, '2026-06-20' AS data_date, '25' AS data_week, 'FW202625' AS data_week_name, '06_Sep' AS data_month, '2026财年6月' AS data_month_name, '3' AS data_quarter, '2026财年第三季度' AS data_quarter_name, '2026' AS data_year, '2026财年' AS data_year_name, 'DY' AS framework, 'MN' AS gender, 'POLO' AS brand, 'APPAREL' AS product_type, 'TOPS' AS category_summary, 'JACKET' AS category, 'payment' AS calc_type, 'Exclude orders cancelled in pay date' AS fulfillment_calc_type, 'RMB' AS currency, 38 AS o2o_fulfillment_request_failed_times, 445 AS o2o_fulfillment_request_times, 338.50 AS o2o_fulfillment_request_duration, 255 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2025/7/15' AS dt, 'day' AS data_type, '2025-07-15' AS data_date, '29' AS data_week, 'FW202529' AS data_week_name, '07_Oct' AS data_month, '2025财年7月' AS data_month_name, '3' AS data_quarter, '2025财年第三季度' AS data_quarter_name, '2025' AS data_year, '2025财年' AS data_year_name, 'DY' AS framework, 'MN' AS gender, 'POLO' AS brand, 'APPAREL' AS product_type, 'TOPS' AS category_summary, 'JACKET' AS category, 'payment' AS calc_type, 'Exclude orders cancelled in pay date' AS fulfillment_calc_type, 'RMB' AS currency, 40 AS o2o_fulfillment_request_failed_times, 475 AS o2o_fulfillment_request_times, 358.20 AS o2o_fulfillment_request_duration, 272 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2025/7/15' AS dt, 'day' AS data_type, '2025-07-15' AS data_date, '29' AS data_week, 'FW202529' AS data_week_name, '07_Oct' AS data_month, '2025财年7月' AS data_month_name, '3' AS data_quarter, '2025财年第三季度' AS data_quarter_name, '2025' AS data_year, '2025财年' AS data_year_name, 'DY' AS framework, 'CW' AS gender, 'RALPH' AS brand, 'ACCESSORIES' AS product_type, 'BOTTOMS' AS category_summary, 'DRESS' AS category, 'payment' AS calc_type, 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled' AS fulfillment_calc_type, 'RMB' AS currency, 42 AS o2o_fulfillment_request_failed_times, 505 AS o2o_fulfillment_request_times, 378.90 AS o2o_fulfillment_request_duration, 288 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2025/7/15' AS dt, 'day' AS data_type, '2025-07-15' AS data_date, '29' AS data_week, 'FW202529' AS data_week_name, '07_Oct' AS data_month, '2025财年7月' AS data_month_name, '3' AS data_quarter, '2025财年第三季度' AS data_quarter_name, '2025' AS data_year, '2025财年' AS data_year_name, 'TM' AS framework, 'WM' AS gender, 'LAUREN' AS brand, 'FOOTWEAR' AS product_type, 'OUTERWEAR' AS category_summary, 'COAT' AS category, 'fulfillment' AS calc_type, 'Exclude orders cancelled in pay date' AS fulfillment_calc_type, 'RMB' AS currency, 45 AS o2o_fulfillment_request_failed_times, 535 AS o2o_fulfillment_request_times, 398.40 AS o2o_fulfillment_request_duration, 305 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2025/7/20' AS dt, 'day' AS data_type, '2025-07-20' AS data_date, '30' AS data_week, 'FW202530' AS data_week_name, '07_Oct' AS data_month, '2025财年7月' AS data_month_name, '3' AS data_quarter, '2025财年第三季度' AS data_quarter_name, '2025' AS data_year, '2025财年' AS data_year_name, 'DY' AS framework, 'WM' AS gender, 'POLO' AS brand, 'APPAREL' AS product_type, 'TOPS' AS category_summary, 'SHIRT' AS category, 'fulfillment' AS calc_type, 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled' AS fulfillment_calc_type, 'RMB' AS currency, 48 AS o2o_fulfillment_request_failed_times, 565 AS o2o_fulfillment_request_times, 418.70 AS o2o_fulfillment_request_duration, 322 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2025/7/20' AS dt, 'day' AS data_type, '2025-07-20' AS data_date, '30' AS data_week, 'FW202530' AS data_week_name, '07_Oct' AS data_month, '2025财年7月' AS data_month_name, '3' AS data_quarter, '2025财年第三季度' AS data_quarter_name, '2025' AS data_year, '2025财年' AS data_year_name, 'TM' AS framework, 'MN' AS gender, 'RALPH' AS brand, 'ACCESSORIES' AS product_type, 'BOTTOMS' AS category_summary, 'PANT' AS category, 'payment' AS calc_type, 'Exclude orders cancelled in pay date' AS fulfillment_calc_type, 'RMB' AS currency, 50 AS o2o_fulfillment_request_failed_times, 595 AS o2o_fulfillment_request_times, 438.50 AS o2o_fulfillment_request_duration, 338 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2025/7/20' AS dt, 'day' AS data_type, '2025-07-20' AS data_date, '30' AS data_week, 'FW202530' AS data_week_name, '07_Oct' AS data_month, '2025财年7月' AS data_month_name, '3' AS data_quarter, '2025财年第三季度' AS data_quarter_name, '2025' AS data_year, '2025财年' AS data_year_name, 'JD' AS framework, 'CW' AS gender, 'LAUREN' AS brand, 'FOOTWEAR' AS product_type, 'OUTERWEAR' AS category_summary, 'JACKET' AS category, 'payment' AS calc_type, 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled' AS fulfillment_calc_type, 'RMB' AS currency, 52 AS o2o_fulfillment_request_failed_times, 625 AS o2o_fulfillment_request_times, 458.30 AS o2o_fulfillment_request_duration, 355 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2025/6/15' AS dt, 'day' AS data_type, '2025-06-15' AS data_date, '25' AS data_week, 'FW202525' AS data_week_name, '06_Sep' AS data_month, '2025财年6月' AS data_month_name, '3' AS data_quarter, '2025财年第三季度' AS data_quarter_name, '2025' AS data_year, '2025财年' AS data_year_name, 'TM' AS framework, 'WM' AS gender, 'POLO' AS brand, 'APPAREL' AS product_type, 'TOPS' AS category_summary, 'DRESS' AS category, 'fulfillment' AS calc_type, 'Exclude orders cancelled in pay date' AS fulfillment_calc_type, 'RMB' AS currency, 55 AS o2o_fulfillment_request_failed_times, 655 AS o2o_fulfillment_request_times, 478.60 AS o2o_fulfillment_request_duration, 372 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2025/6/15' AS dt, 'day' AS data_type, '2025-06-15' AS data_date, '25' AS data_week, 'FW202525' AS data_week_name, '06_Sep' AS data_month, '2025财年6月' AS data_month_name, '3' AS data_quarter, '2025财年第三季度' AS data_quarter_name, '2025' AS data_year, '2025财年' AS data_year_name, 'JD' AS framework, 'WM' AS gender, 'RALPH' AS brand, 'ACCESSORIES' AS product_type, 'BOTTOMS' AS category_summary, 'COAT' AS category, 'fulfillment' AS calc_type, 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled' AS fulfillment_calc_type, 'RMB' AS currency, 58 AS o2o_fulfillment_request_failed_times, 685 AS o2o_fulfillment_request_times, 498.20 AS o2o_fulfillment_request_duration, 388 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2025/6/15' AS dt, 'day' AS data_type, '2025-06-15' AS data_date, '25' AS data_week, 'FW202525' AS data_week_name, '06_Sep' AS data_month, '2025财年6月' AS data_month_name, '3' AS data_quarter, '2025财年第三季度' AS data_quarter_name, '2025' AS data_year, '2025财年' AS data_year_name, 'RLE' AS framework, 'MN' AS gender, 'LAUREN' AS brand, 'FOOTWEAR' AS product_type, 'OUTERWEAR' AS category_summary, 'SHIRT' AS category, 'payment' AS calc_type, 'Exclude orders cancelled in pay date' AS fulfillment_calc_type, 'RMB' AS currency, 60 AS o2o_fulfillment_request_failed_times, 715 AS o2o_fulfillment_request_times, 518.40 AS o2o_fulfillment_request_duration, 405 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2025/6/20' AS dt, 'day' AS data_type, '2025-06-20' AS data_date, '25' AS data_week, 'FW202525' AS data_week_name, '06_Sep' AS data_month, '2025财年6月' AS data_month_name, '3' AS data_quarter, '2025财年第三季度' AS data_quarter_name, '2025' AS data_year, '2025财年' AS data_year_name, 'JD' AS framework, 'CW' AS gender, 'POLO' AS brand, 'APPAREL' AS product_type, 'TOPS' AS category_summary, 'PANT' AS category, 'payment' AS calc_type, 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled' AS fulfillment_calc_type, 'RMB' AS currency, 62 AS o2o_fulfillment_request_failed_times, 745 AS o2o_fulfillment_request_times, 538.70 AS o2o_fulfillment_request_duration, 422 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2025/6/20' AS dt, 'day' AS data_type, '2025-06-20' AS data_date, '25' AS data_week, 'FW202525' AS data_week_name, '06_Sep' AS data_month, '2025财年6月' AS data_month_name, '3' AS data_quarter, '2025财年第三季度' AS data_quarter_name, '2025' AS data_year, '2025财年' AS data_year_name, 'RLE' AS framework, 'WM' AS gender, 'RALPH' AS brand, 'ACCESSORIES' AS product_type, 'BOTTOMS' AS category_summary, 'JACKET' AS category, 'fulfillment' AS calc_type, 'Exclude orders cancelled in pay date' AS fulfillment_calc_type, 'RMB' AS currency, 65 AS o2o_fulfillment_request_failed_times, 775 AS o2o_fulfillment_request_times, 558.90 AS o2o_fulfillment_request_duration, 438 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2025/6/20' AS dt, 'day' AS data_type, '2025-06-20' AS data_date, '25' AS data_week, 'FW202525' AS data_week_name, '06_Sep' AS data_month, '2025财年6月' AS data_month_name, '3' AS data_quarter, '2025财年第三季度' AS data_quarter_name, '2025' AS data_year, '2025财年' AS data_year_name, 'DY' AS framework, 'WM' AS gender, 'LAUREN' AS brand, 'FOOTWEAR' AS product_type, 'OUTERWEAR' AS category_summary, 'DRESS' AS category, 'fulfillment' AS calc_type, 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled' AS fulfillment_calc_type, 'RMB' AS currency, 68 AS o2o_fulfillment_request_failed_times, 805 AS o2o_fulfillment_request_times, 579.30 AS o2o_fulfillment_request_duration, 455 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2025/6/20' AS dt, 'day' AS data_type, '2025-06-20' AS data_date, '25' AS data_week, 'FW202525' AS data_week_name, '06_Sep' AS data_month, '2025财年6月' AS data_month_name, '3' AS data_quarter, '2025财年第三季度' AS data_quarter_name, '2025' AS data_year, '2025财年' AS data_year_name, 'TM' AS framework, 'CW' AS gender, 'POLO' AS brand, 'APPAREL' AS product_type, 'TOPS' AS category_summary, 'COAT' AS category, 'payment' AS calc_type, 'Exclude orders cancelled in pay date' AS fulfillment_calc_type, 'RMB' AS currency, 70 AS o2o_fulfillment_request_failed_times, 835 AS o2o_fulfillment_request_times, 599.50 AS o2o_fulfillment_request_duration, 472 AS o2o_fulfillment_request_sku_qty
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/15', 'day', '2026-06-15', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'CW', 'APPAREL', 'TOPS', 'SHIRT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 43, 486, 14.48, 153
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/16', 'day', '2026-06-16', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'CW', 'ACCESSORIES', 'BOTTOMS', 'PANT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 6, 91, 30.21, 285
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/17', 'day', '2026-06-17', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'CW', 'FOOTWEAR', 'OUTERWEAR', 'JACKET', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 9, 111, 20.25, 245
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/18', 'day', '2026-06-18', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'CW', 'APPAREL', 'TOPS', 'DRESS', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 55, 421, 10.28, 201
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/20', 'day', '2026-06-20', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'CW', 'ACCESSORIES', 'BOTTOMS', 'COAT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 45, 426, 7.29, 163
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/21', 'day', '2026-06-21', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'CW', 'FOOTWEAR', 'OUTERWEAR', 'SHIRT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 25, 266, 42.12, 211
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/15', 'day', '2026-07-15', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'CW', 'APPAREL', 'TOPS', 'PANT', 'fulfillment', 'Exclude orders cancelled in pay date', 'RMB', 32, 226, 20.99, 111
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/16', 'day', '2026-07-16', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'CW', 'ACCESSORIES', 'BOTTOMS', 'JACKET', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 26, 426, 1.51, 29
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/17', 'day', '2026-07-17', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'CW', 'FOOTWEAR', 'OUTERWEAR', 'DRESS', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 5, 79, 33.34, 206
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/18', 'day', '2026-07-18', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'CW', 'APPAREL', 'TOPS', 'COAT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 23, 341, 15.42, 154
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/20', 'day', '2026-07-20', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'CW', 'ACCESSORIES', 'BOTTOMS', 'SHIRT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 14, 252, 43.94, 152
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/21', 'day', '2026-07-21', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'CW', 'FOOTWEAR', 'OUTERWEAR', 'PANT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 11, 86, 20.04, 146
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/15', 'day', '2026-06-15', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'HM', 'APPAREL', 'TOPS', 'SHIRT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 50, 451, 3.73, 55
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/16', 'day', '2026-06-16', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'HM', 'ACCESSORIES', 'BOTTOMS', 'PANT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 25, 270, 45.39, 285
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/17', 'day', '2026-06-17', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'HM', 'FOOTWEAR', 'OUTERWEAR', 'JACKET', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 46, 328, 26.32, 49
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/18', 'day', '2026-06-18', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'HM', 'APPAREL', 'TOPS', 'DRESS', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 52, 378, 4.76, 47
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/20', 'day', '2026-06-20', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'HM', 'ACCESSORIES', 'BOTTOMS', 'COAT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 3, 108, 9.99, 41
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/21', 'day', '2026-06-21', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'HM', 'FOOTWEAR', 'OUTERWEAR', 'SHIRT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 11, 300, 6.24, 145
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/15', 'day', '2026-07-15', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'HM', 'APPAREL', 'TOPS', 'PANT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 7, 297, 31.33, 45
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/16', 'day', '2026-07-16', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'HM', 'ACCESSORIES', 'BOTTOMS', 'JACKET', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 6, 202, 37.51, 273
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/17', 'day', '2026-07-17', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'HM', 'FOOTWEAR', 'OUTERWEAR', 'DRESS', 'fulfillment', 'Exclude orders cancelled in pay date', 'RMB', 4, 63, 38.17, 261
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/18', 'day', '2026-07-18', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'HM', 'APPAREL', 'TOPS', 'COAT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 26, 433, 18.13, 68
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/20', 'day', '2026-07-20', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'HM', 'ACCESSORIES', 'BOTTOMS', 'SHIRT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 16, 460, 9.07, 91
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/21', 'day', '2026-07-21', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'HM', 'FOOTWEAR', 'OUTERWEAR', 'PANT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 38, 340, 28.48, 168
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/15', 'day', '2026-06-15', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'RRL', 'APPAREL', 'TOPS', 'SHIRT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 5, 94, 24.62, 60
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/16', 'day', '2026-06-16', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'RRL', 'ACCESSORIES', 'BOTTOMS', 'PANT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 34, 285, 26.58, 239
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/17', 'day', '2026-06-17', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'RRL', 'FOOTWEAR', 'OUTERWEAR', 'JACKET', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 32, 279, 4.34, 230
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/18', 'day', '2026-06-18', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'RRL', 'APPAREL', 'TOPS', 'DRESS', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 7, 138, 35.5, 191
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/20', 'day', '2026-06-20', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'RRL', 'ACCESSORIES', 'BOTTOMS', 'COAT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 27, 256, 13.97, 87
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/21', 'day', '2026-06-21', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'RRL', 'FOOTWEAR', 'OUTERWEAR', 'SHIRT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 26, 204, 36.66, 129
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/15', 'day', '2026-07-15', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'RRL', 'APPAREL', 'TOPS', 'PANT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 10, 179, 9.78, 75
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/16', 'day', '2026-07-16', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'RRL', 'ACCESSORIES', 'BOTTOMS', 'JACKET', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 28, 414, 7.49, 92
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/17', 'day', '2026-07-17', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'RRL', 'FOOTWEAR', 'OUTERWEAR', 'DRESS', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 9, 437, 13.13, 185
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/18', 'day', '2026-07-18', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'RRL', 'APPAREL', 'TOPS', 'COAT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 32, 336, 46.37, 188
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/20', 'day', '2026-07-20', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'RRL', 'ACCESSORIES', 'BOTTOMS', 'SHIRT', 'fulfillment', 'Exclude orders cancelled in pay date', 'RMB', 46, 410, 23.06, 229
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/21', 'day', '2026-07-21', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'RRL', 'FOOTWEAR', 'OUTERWEAR', 'PANT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 18, 192, 47.07, 289
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/15', 'day', '2026-06-15', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'M Polo', 'APPAREL', 'TOPS', 'SHIRT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 19, 315, 40.11, 68
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/16', 'day', '2026-06-16', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'M Polo', 'ACCESSORIES', 'BOTTOMS', 'PANT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 5, 265, 37.64, 21
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/17', 'day', '2026-06-17', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'M Polo', 'FOOTWEAR', 'OUTERWEAR', 'JACKET', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 22, 370, 32.23, 221
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/18', 'day', '2026-06-18', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'M Polo', 'APPAREL', 'TOPS', 'DRESS', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 5, 190, 40.86, 179
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/20', 'day', '2026-06-20', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'M Polo', 'ACCESSORIES', 'BOTTOMS', 'COAT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 54, 500, 5.79, 86
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/21', 'day', '2026-06-21', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'M Polo', 'FOOTWEAR', 'OUTERWEAR', 'SHIRT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 5, 248, 28.84, 156
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/15', 'day', '2026-07-15', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'M Polo', 'APPAREL', 'TOPS', 'PANT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 42, 353, 46.04, 262
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/16', 'day', '2026-07-16', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'M Polo', 'ACCESSORIES', 'BOTTOMS', 'JACKET', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 17, 135, 18.61, 24
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/17', 'day', '2026-07-17', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'M Polo', 'FOOTWEAR', 'OUTERWEAR', 'DRESS', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 29, 273, 43.1, 277
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/18', 'day', '2026-07-18', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'M Polo', 'APPAREL', 'TOPS', 'COAT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 35, 287, 21.98, 134
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/20', 'day', '2026-07-20', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'M Polo', 'ACCESSORIES', 'BOTTOMS', 'SHIRT', 'fulfillment', 'Exclude orders cancelled in pay date', 'RMB', 12, 313, 16.18, 196
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/21', 'day', '2026-07-21', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'M Polo', 'FOOTWEAR', 'OUTERWEAR', 'PANT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 51, 407, 21.31, 254
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/15', 'day', '2026-06-15', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'PL', 'APPAREL', 'TOPS', 'SHIRT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 27, 362, 21.94, 217
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/16', 'day', '2026-06-16', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'PL', 'ACCESSORIES', 'BOTTOMS', 'PANT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 10, 245, 2.81, 108
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/17', 'day', '2026-06-17', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'PL', 'FOOTWEAR', 'OUTERWEAR', 'JACKET', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 17, 499, 16.7, 230
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/18', 'day', '2026-06-18', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'PL', 'APPAREL', 'TOPS', 'DRESS', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 14, 212, 3.85, 194
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/20', 'day', '2026-06-20', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'PL', 'ACCESSORIES', 'BOTTOMS', 'COAT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 25, 195, 19.62, 259
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/21', 'day', '2026-06-21', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'PL', 'FOOTWEAR', 'OUTERWEAR', 'SHIRT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 19, 482, 15.0, 80
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/15', 'day', '2026-07-15', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'PL', 'APPAREL', 'TOPS', 'PANT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 8, 146, 31.8, 153
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/16', 'day', '2026-07-16', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'PL', 'ACCESSORIES', 'BOTTOMS', 'JACKET', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 66, 461, 35.8, 255
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/17', 'day', '2026-07-17', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'PL', 'FOOTWEAR', 'OUTERWEAR', 'DRESS', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 12, 114, 27.33, 67
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/18', 'day', '2026-07-18', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'PL', 'APPAREL', 'TOPS', 'COAT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 39, 391, 15.51, 77
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/20', 'day', '2026-07-20', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'PL', 'ACCESSORIES', 'BOTTOMS', 'SHIRT', 'fulfillment', 'Exclude orders cancelled in pay date', 'RMB', 20, 145, 13.31, 150
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/21', 'day', '2026-07-21', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'PL', 'FOOTWEAR', 'OUTERWEAR', 'PANT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 37, 277, 6.58, 291
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/15', 'day', '2026-06-15', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'CL', 'APPAREL', 'TOPS', 'SHIRT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 10, 257, 23.11, 107
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/16', 'day', '2026-06-16', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'CL', 'ACCESSORIES', 'BOTTOMS', 'PANT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 9, 130, 41.53, 143
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/17', 'day', '2026-06-17', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'CL', 'FOOTWEAR', 'OUTERWEAR', 'JACKET', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 43, 425, 30.13, 36
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/18', 'day', '2026-06-18', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'CL', 'APPAREL', 'TOPS', 'DRESS', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 11, 285, 17.9, 99
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/20', 'day', '2026-06-20', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'CL', 'ACCESSORIES', 'BOTTOMS', 'COAT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 21, 409, 11.04, 86
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/21', 'day', '2026-06-21', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'CL', 'FOOTWEAR', 'OUTERWEAR', 'SHIRT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 18, 157, 19.45, 136
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/15', 'day', '2026-07-15', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'CL', 'APPAREL', 'TOPS', 'PANT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 16, 337, 41.05, 282
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/16', 'day', '2026-07-16', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'CL', 'ACCESSORIES', 'BOTTOMS', 'JACKET', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 35, 394, 47.94, 62
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/17', 'day', '2026-07-17', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'CL', 'FOOTWEAR', 'OUTERWEAR', 'DRESS', 'fulfillment', 'Exclude orders cancelled in pay date', 'RMB', 4, 133, 41.82, 248
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/18', 'day', '2026-07-18', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'CL', 'APPAREL', 'TOPS', 'COAT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 32, 225, 14.45, 131
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/20', 'day', '2026-07-20', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'CL', 'ACCESSORIES', 'BOTTOMS', 'SHIRT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 26, 232, 35.46, 50
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/21', 'day', '2026-07-21', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'CL', 'FOOTWEAR', 'OUTERWEAR', 'PANT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 16, 480, 41.64, 61
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/15', 'day', '2026-06-15', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'Lauren', 'APPAREL', 'TOPS', 'SHIRT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 8, 361, 47.58, 189
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/16', 'day', '2026-06-16', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'Lauren', 'ACCESSORIES', 'BOTTOMS', 'PANT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 23, 184, 34.09, 185
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/17', 'day', '2026-06-17', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'Lauren', 'FOOTWEAR', 'OUTERWEAR', 'JACKET', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 23, 317, 29.28, 42
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/18', 'day', '2026-06-18', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'Lauren', 'APPAREL', 'TOPS', 'DRESS', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 14, 433, 5.21, 124
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/20', 'day', '2026-06-20', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'Lauren', 'ACCESSORIES', 'BOTTOMS', 'COAT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 27, 298, 33.02, 237
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/21', 'day', '2026-06-21', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'Lauren', 'FOOTWEAR', 'OUTERWEAR', 'SHIRT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 4, 126, 12.11, 70
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/15', 'day', '2026-07-15', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'Lauren', 'APPAREL', 'TOPS', 'PANT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 39, 319, 5.34, 221
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/16', 'day', '2026-07-16', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'Lauren', 'ACCESSORIES', 'BOTTOMS', 'JACKET', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 54, 422, 20.66, 207
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/17', 'day', '2026-07-17', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'Lauren', 'FOOTWEAR', 'OUTERWEAR', 'DRESS', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 38, 412, 38.5, 160
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/18', 'day', '2026-07-18', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'Lauren', 'APPAREL', 'TOPS', 'COAT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 15, 234, 14.18, 79
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/20', 'day', '2026-07-20', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'Lauren', 'ACCESSORIES', 'BOTTOMS', 'SHIRT', 'fulfillment', 'Exclude orders cancelled in pay date', 'RMB', 1, 82, 22.17, 289
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/21', 'day', '2026-07-21', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'Lauren', 'FOOTWEAR', 'OUTERWEAR', 'PANT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 50, 397, 21.62, 296
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/15', 'day', '2026-06-15', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'W Polo', 'APPAREL', 'TOPS', 'SHIRT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 17, 482, 13.67, 231
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/16', 'day', '2026-06-16', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'W Polo', 'ACCESSORIES', 'BOTTOMS', 'PANT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 15, 235, 38.27, 233
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/17', 'day', '2026-06-17', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'W Polo', 'FOOTWEAR', 'OUTERWEAR', 'JACKET', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 68, 492, 27.33, 298
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/18', 'day', '2026-06-18', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'W Polo', 'APPAREL', 'TOPS', 'DRESS', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 22, 254, 43.87, 132
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/20', 'day', '2026-06-20', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'W Polo', 'ACCESSORIES', 'BOTTOMS', 'COAT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 8, 75, 13.14, 93
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/21', 'day', '2026-06-21', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'W Polo', 'FOOTWEAR', 'OUTERWEAR', 'SHIRT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 16, 407, 34.25, 104
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/15', 'day', '2026-07-15', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'W Polo', 'APPAREL', 'TOPS', 'PANT', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 60, 403, 41.38, 110
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/16', 'day', '2026-07-16', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'W Polo', 'ACCESSORIES', 'BOTTOMS', 'JACKET', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 37, 371, 29.75, 37
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/17', 'day', '2026-07-17', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'W Polo', 'FOOTWEAR', 'OUTERWEAR', 'DRESS', 'payment', 'Exclude orders cancelled in pay date', 'RMB', 23, 307, 22.39, 65
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/18', 'day', '2026-07-18', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'POLO', 'MN', 'W Polo', 'APPAREL', 'TOPS', 'COAT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 8, 251, 12.19, 169
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/20', 'day', '2026-07-20', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'RALPH', 'WM', 'W Polo', 'ACCESSORIES', 'BOTTOMS', 'SHIRT', 'fulfillment', 'Exclude orders cancelled in pay date', 'RMB', 27, 452, 25.73, 211
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/21', 'day', '2026-07-21', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'LAUREN', 'CW', 'W Polo', 'FOOTWEAR', 'OUTERWEAR', 'PANT', 'fulfillment', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RMB', 42, 440, 28.78, 281    
    "),
    更改的类型 = Table.TransformColumnTypes(源,{{"data_date", type date}})
in
    更改的类型