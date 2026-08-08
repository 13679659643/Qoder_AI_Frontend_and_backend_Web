let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
SELECT * FROM `indep_rl_ads`.a02_e2e_boss_fulfillment_fail_reason_d
UNION ALL
SELECT '2026-07-28 10:00:00' AS etl_time, '2026/7/15' AS dt, 'day' AS data_type, '2026-07-15' AS data_date, '29' AS data_week, 'FW202629' AS data_week_name, '07_Oct' AS data_month, '2026财年7月' AS data_month_name, '3' AS data_quarter, '2026财年第三季度' AS data_quarter_name, '2026' AS data_year, '2026财年' AS data_year_name, 'Exclude orders cancelled in pay date' AS fulfillment_calc_type, 'TM001' AS store_code, 'FLAGSHIP' AS store_type, 'WEST' AS store_region, '库存不足' AS failure_reason, 'RMB' AS currency, 7377.53 AS sales_amt, 65 AS sales_order_cnt, 195 AS sales_qty, 165 AS request_times
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/16', 'day', '2026-07-16', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'TM001', 'FLAGSHIP', 'EAST', '门店拒单', 'RMB', 8961.19, 75, 75, 60
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/17', 'day', '2026-07-17', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'TM001', 'FLAGSHIP', 'SOUTH', '系统超时', 'RMB', 3377.12, 13, 13, 160
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/20', 'day', '2026-07-20', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'TM001', 'FLAGSHIP', 'NORTH', '用户取消', 'RMB', 10962.96, 29, 29, 105
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/21', 'day', '2026-07-21', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'TM001', 'FLAGSHIP', 'WEST', '地址异常', 'RMB', 11033.58, 36, 72, 109
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/15', 'day', '2026-06-15', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'TM001', 'FLAGSHIP', 'EAST', '物流限制', 'RMB', 2612.7, 22, 44, 192
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/16', 'day', '2026-06-16', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'TM001', 'FLAGSHIP', 'SOUTH', 'SKU缺货', 'RMB', 3628.55, 39, 78, 24
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/17', 'day', '2026-06-17', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'TM001', 'FLAGSHIP', 'NORTH', '支付失败', 'RMB', 14546.21, 61, 183, 129
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/20', 'day', '2026-06-20', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'TM001', 'FLAGSHIP', 'WEST', '其他', 'RMB', 13202.77, 5, 5, 111
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/21', 'day', '2026-06-21', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'TM001', 'FLAGSHIP', 'EAST', '库存不足', 'RMB', 4944.99, 74, 222, 175
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/15', 'day', '2025-07-15', '29', 'FW202529', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'TM001', 'FLAGSHIP', 'SOUTH', '门店拒单', 'RMB', 5569.05, 20, 40, 166
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/16', 'day', '2025-07-16', '29', 'FW202529', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'TM001', 'FLAGSHIP', 'NORTH', '系统超时', 'RMB', 3779.43, 8, 24, 112
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/17', 'day', '2025-07-17', '29', 'FW202529', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'TM001', 'FLAGSHIP', 'WEST', '用户取消', 'RMB', 6513.58, 38, 114, 83
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/20', 'day', '2025-07-20', '30', 'FW202530', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'TM001', 'FLAGSHIP', 'EAST', '地址异常', 'RMB', 3309.85, 66, 66, 177
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/21', 'day', '2025-07-21', '30', 'FW202530', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'TM001', 'FLAGSHIP', 'SOUTH', '物流限制', 'RMB', 6900.17, 18, 18, 62
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/15', 'day', '2025-06-15', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'TM001', 'FLAGSHIP', 'NORTH', 'SKU缺货', 'RMB', 10368.34, 72, 72, 200
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/16', 'day', '2025-06-16', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'TM001', 'FLAGSHIP', 'WEST', '支付失败', 'RMB', 14465.96, 25, 75, 39
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/17', 'day', '2025-06-17', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'TM001', 'FLAGSHIP', 'EAST', '其他', 'RMB', 4848.47, 64, 192, 142
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/18', 'day', '2025-06-18', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'TM001', 'FLAGSHIP', 'SOUTH', '库存不足', 'RMB', 9734.06, 37, 74, 116
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/20', 'day', '2025-06-20', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'TM001', 'FLAGSHIP', 'NORTH', '门店拒单', 'RMB', 4071.77, 77, 77, 17
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/15', 'day', '2026-07-15', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'JD001', 'SELF', 'WEST', '系统超时', 'RMB', 8448.59, 53, 159, 14
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/16', 'day', '2026-07-16', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'JD001', 'SELF', 'EAST', '用户取消', 'RMB', 3274.99, 27, 81, 85
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/17', 'day', '2026-07-17', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'JD001', 'SELF', 'SOUTH', '地址异常', 'RMB', 12587.21, 12, 36, 14
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/20', 'day', '2026-07-20', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'JD001', 'SELF', 'NORTH', '物流限制', 'RMB', 8307.43, 55, 55, 167
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/21', 'day', '2026-07-21', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'JD001', 'SELF', 'WEST', 'SKU缺货', 'RMB', 2760.65, 60, 180, 169
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/15', 'day', '2026-06-15', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'JD001', 'SELF', 'EAST', '支付失败', 'RMB', 2510.66, 49, 147, 199
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/16', 'day', '2026-06-16', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'JD001', 'SELF', 'SOUTH', '其他', 'RMB', 5536.4, 79, 158, 125
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/17', 'day', '2026-06-17', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'JD001', 'SELF', 'NORTH', '库存不足', 'RMB', 11902.32, 35, 35, 170
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/20', 'day', '2026-06-20', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'JD001', 'SELF', 'WEST', '门店拒单', 'RMB', 14854.77, 79, 79, 177
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/21', 'day', '2026-06-21', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'JD001', 'SELF', 'EAST', '系统超时', 'RMB', 12768.87, 43, 86, 111
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/15', 'day', '2025-07-15', '29', 'FW202529', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'JD001', 'SELF', 'SOUTH', '用户取消', 'RMB', 2074.43, 31, 62, 25
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/16', 'day', '2025-07-16', '29', 'FW202529', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'JD001', 'SELF', 'NORTH', '地址异常', 'RMB', 12201.74, 77, 77, 77
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/17', 'day', '2025-07-17', '29', 'FW202529', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'JD001', 'SELF', 'WEST', '物流限制', 'RMB', 13625.54, 11, 22, 13
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/20', 'day', '2025-07-20', '30', 'FW202530', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'JD001', 'SELF', 'EAST', 'SKU缺货', 'RMB', 11450.19, 40, 40, 21
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/21', 'day', '2025-07-21', '30', 'FW202530', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'JD001', 'SELF', 'SOUTH', '支付失败', 'RMB', 5958.01, 32, 96, 117
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/15', 'day', '2025-06-15', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'JD001', 'SELF', 'NORTH', '其他', 'RMB', 7441.56, 22, 22, 55
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/16', 'day', '2025-06-16', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'JD001', 'SELF', 'WEST', '库存不足', 'RMB', 3367.07, 49, 147, 191
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/17', 'day', '2025-06-17', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'JD001', 'SELF', 'EAST', '门店拒单', 'RMB', 6103.18, 48, 48, 122
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/18', 'day', '2025-06-18', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'JD001', 'SELF', 'SOUTH', '系统超时', 'RMB', 648.07, 33, 99, 100
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/20', 'day', '2025-06-20', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'JD001', 'SELF', 'NORTH', '用户取消', 'RMB', 1107.35, 7, 7, 197
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/15', 'day', '2026-07-15', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'RLE001', 'OFFICIAL', 'WEST', '地址异常', 'RMB', 14096.75, 14, 42, 131
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/16', 'day', '2026-07-16', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RLE001', 'OFFICIAL', 'EAST', '物流限制', 'RMB', 3415.94, 57, 171, 133
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/17', 'day', '2026-07-17', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'RLE001', 'OFFICIAL', 'SOUTH', 'SKU缺货', 'RMB', 12249.08, 28, 28, 41
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/20', 'day', '2026-07-20', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RLE001', 'OFFICIAL', 'NORTH', '支付失败', 'RMB', 12101.69, 48, 96, 176
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/21', 'day', '2026-07-21', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'RLE001', 'OFFICIAL', 'WEST', '其他', 'RMB', 7427.95, 12, 36, 179
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/15', 'day', '2026-06-15', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RLE001', 'OFFICIAL', 'EAST', '库存不足', 'RMB', 9233.11, 7, 21, 22
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/16', 'day', '2026-06-16', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'RLE001', 'OFFICIAL', 'SOUTH', '门店拒单', 'RMB', 11326.49, 22, 66, 47
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/17', 'day', '2026-06-17', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RLE001', 'OFFICIAL', 'NORTH', '系统超时', 'RMB', 1706.2, 55, 55, 107
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/20', 'day', '2026-06-20', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'RLE001', 'OFFICIAL', 'WEST', '用户取消', 'RMB', 1272.67, 14, 42, 53
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/21', 'day', '2026-06-21', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RLE001', 'OFFICIAL', 'EAST', '地址异常', 'RMB', 14188.02, 53, 53, 38
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/15', 'day', '2025-07-15', '29', 'FW202529', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'RLE001', 'OFFICIAL', 'SOUTH', '物流限制', 'RMB', 877.66, 19, 19, 74
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/16', 'day', '2025-07-16', '29', 'FW202529', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RLE001', 'OFFICIAL', 'NORTH', 'SKU缺货', 'RMB', 8893.17, 27, 27, 86
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/17', 'day', '2025-07-17', '29', 'FW202529', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'RLE001', 'OFFICIAL', 'WEST', '支付失败', 'RMB', 1851.18, 67, 201, 29
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/20', 'day', '2025-07-20', '30', 'FW202530', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RLE001', 'OFFICIAL', 'EAST', '其他', 'RMB', 9355.49, 13, 13, 46
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/21', 'day', '2025-07-21', '30', 'FW202530', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'RLE001', 'OFFICIAL', 'SOUTH', '库存不足', 'RMB', 3614.9, 60, 120, 24
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/15', 'day', '2025-06-15', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RLE001', 'OFFICIAL', 'NORTH', '门店拒单', 'RMB', 12794.56, 46, 92, 188
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/16', 'day', '2025-06-16', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'RLE001', 'OFFICIAL', 'WEST', '系统超时', 'RMB', 4240.0, 14, 28, 91
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/17', 'day', '2025-06-17', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RLE001', 'OFFICIAL', 'EAST', '用户取消', 'RMB', 2229.4, 38, 114, 59
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/18', 'day', '2025-06-18', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'RLE001', 'OFFICIAL', 'SOUTH', '地址异常', 'RMB', 12714.16, 8, 8, 128
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/20', 'day', '2025-06-20', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'RLE001', 'OFFICIAL', 'NORTH', '物流限制', 'RMB', 6486.81, 7, 14, 14
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/15', 'day', '2026-07-15', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'DYF001', 'LIVE', 'WEST', 'SKU缺货', 'RMB', 6745.88, 29, 29, 162
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/16', 'day', '2026-07-16', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYF001', 'LIVE', 'EAST', '支付失败', 'RMB', 2655.98, 38, 76, 64
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/17', 'day', '2026-07-17', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'DYF001', 'LIVE', 'SOUTH', '其他', 'RMB', 2690.32, 10, 10, 60
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/20', 'day', '2026-07-20', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYF001', 'LIVE', 'NORTH', '库存不足', 'RMB', 10473.99, 5, 10, 157
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/21', 'day', '2026-07-21', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'DYF001', 'LIVE', 'WEST', '门店拒单', 'RMB', 2076.29, 17, 51, 176
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/15', 'day', '2026-06-15', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYF001', 'LIVE', 'EAST', '系统超时', 'RMB', 14274.84, 57, 57, 125
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/16', 'day', '2026-06-16', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'DYF001', 'LIVE', 'SOUTH', '用户取消', 'RMB', 2618.62, 76, 76, 83
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/17', 'day', '2026-06-17', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYF001', 'LIVE', 'NORTH', '地址异常', 'RMB', 3354.44, 60, 120, 94
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/20', 'day', '2026-06-20', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'DYF001', 'LIVE', 'WEST', '物流限制', 'RMB', 8216.63, 38, 76, 165
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/21', 'day', '2026-06-21', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYF001', 'LIVE', 'EAST', 'SKU缺货', 'RMB', 6792.75, 24, 24, 131
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/15', 'day', '2025-07-15', '29', 'FW202529', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'DYF001', 'LIVE', 'SOUTH', '支付失败', 'RMB', 4523.81, 26, 52, 133
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/16', 'day', '2025-07-16', '29', 'FW202529', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYF001', 'LIVE', 'NORTH', '其他', 'RMB', 7296.22, 57, 114, 29
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/17', 'day', '2025-07-17', '29', 'FW202529', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'DYF001', 'LIVE', 'WEST', '库存不足', 'RMB', 5286.46, 13, 26, 42
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/20', 'day', '2025-07-20', '30', 'FW202530', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYF001', 'LIVE', 'EAST', '门店拒单', 'RMB', 7595.92, 48, 144, 106
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/21', 'day', '2025-07-21', '30', 'FW202530', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'DYF001', 'LIVE', 'SOUTH', '系统超时', 'RMB', 12814.48, 46, 46, 96
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/15', 'day', '2025-06-15', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYF001', 'LIVE', 'NORTH', '用户取消', 'RMB', 4685.55, 60, 180, 77
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/16', 'day', '2025-06-16', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'DYF001', 'LIVE', 'WEST', '地址异常', 'RMB', 5426.85, 64, 192, 199
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/17', 'day', '2025-06-17', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYF001', 'LIVE', 'EAST', '物流限制', 'RMB', 7051.53, 51, 153, 34
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/18', 'day', '2025-06-18', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'DYF001', 'LIVE', 'SOUTH', 'SKU缺货', 'RMB', 14954.95, 68, 68, 15
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/20', 'day', '2025-06-20', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYF001', 'LIVE', 'NORTH', '支付失败', 'RMB', 11376.45, 53, 53, 139
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/15', 'day', '2026-07-15', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'DYW001', 'LIVE', 'WEST', '其他', 'RMB', 1117.3, 21, 21, 186
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/16', 'day', '2026-07-16', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYW001', 'LIVE', 'EAST', '库存不足', 'RMB', 3257.9, 74, 222, 18
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/17', 'day', '2026-07-17', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'DYW001', 'LIVE', 'SOUTH', '门店拒单', 'RMB', 1083.55, 56, 168, 112
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/20', 'day', '2026-07-20', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYW001', 'LIVE', 'NORTH', '系统超时', 'RMB', 3968.06, 15, 30, 18
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/21', 'day', '2026-07-21', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'DYW001', 'LIVE', 'WEST', '用户取消', 'RMB', 4708.42, 70, 140, 155
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/15', 'day', '2026-06-15', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYW001', 'LIVE', 'EAST', '地址异常', 'RMB', 2031.4, 44, 88, 89
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/16', 'day', '2026-06-16', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'DYW001', 'LIVE', 'SOUTH', '物流限制', 'RMB', 7343.26, 43, 129, 193
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/17', 'day', '2026-06-17', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYW001', 'LIVE', 'NORTH', 'SKU缺货', 'RMB', 2288.77, 57, 114, 198
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/20', 'day', '2026-06-20', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'DYW001', 'LIVE', 'WEST', '支付失败', 'RMB', 13948.08, 45, 135, 60
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/21', 'day', '2026-06-21', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYW001', 'LIVE', 'EAST', '其他', 'RMB', 8797.32, 18, 18, 88
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/15', 'day', '2025-07-15', '29', 'FW202529', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'DYW001', 'LIVE', 'SOUTH', '库存不足', 'RMB', 10923.03, 43, 129, 65
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/16', 'day', '2025-07-16', '29', 'FW202529', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYW001', 'LIVE', 'NORTH', '门店拒单', 'RMB', 12832.79, 56, 168, 131
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/17', 'day', '2025-07-17', '29', 'FW202529', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'DYW001', 'LIVE', 'WEST', '系统超时', 'RMB', 9638.82, 18, 54, 191
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/20', 'day', '2025-07-20', '30', 'FW202530', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYW001', 'LIVE', 'EAST', '用户取消', 'RMB', 8888.0, 39, 39, 160
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/21', 'day', '2025-07-21', '30', 'FW202530', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'DYW001', 'LIVE', 'SOUTH', '地址异常', 'RMB', 12255.96, 57, 171, 94
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/15', 'day', '2025-06-15', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYW001', 'LIVE', 'NORTH', '物流限制', 'RMB', 9923.63, 65, 130, 114
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/16', 'day', '2025-06-16', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'DYW001', 'LIVE', 'WEST', 'SKU缺货', 'RMB', 14963.2, 44, 132, 107
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/17', 'day', '2025-06-17', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYW001', 'LIVE', 'EAST', '支付失败', 'RMB', 3488.98, 62, 62, 183
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/18', 'day', '2025-06-18', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'DYW001', 'LIVE', 'SOUTH', '其他', 'RMB', 5492.28, 35, 35, 190
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/20', 'day', '2025-06-20', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYW001', 'LIVE', 'NORTH', '库存不足', 'RMB', 3980.12, 24, 48, 129
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/15', 'day', '2026-07-15', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'DYM001', 'LIVE', 'WEST', '门店拒单', 'RMB', 11733.74, 18, 36, 104
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/16', 'day', '2026-07-16', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYM001', 'LIVE', 'EAST', '系统超时', 'RMB', 12056.93, 19, 19, 13
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/17', 'day', '2026-07-17', '29', 'FW202629', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'DYM001', 'LIVE', 'SOUTH', '用户取消', 'RMB', 6364.77, 8, 24, 119
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/20', 'day', '2026-07-20', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYM001', 'LIVE', 'NORTH', '地址异常', 'RMB', 6207.32, 59, 118, 128
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/7/21', 'day', '2026-07-21', '30', 'FW202630', '07_Oct', '2026财年7月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'DYM001', 'LIVE', 'WEST', '物流限制', 'RMB', 816.72, 29, 87, 147
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/15', 'day', '2026-06-15', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYM001', 'LIVE', 'EAST', 'SKU缺货', 'RMB', 9879.46, 48, 144, 198
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/16', 'day', '2026-06-16', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'DYM001', 'LIVE', 'SOUTH', '支付失败', 'RMB', 6994.54, 18, 54, 164
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/17', 'day', '2026-06-17', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYM001', 'LIVE', 'NORTH', '其他', 'RMB', 1566.91, 53, 106, 188
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/20', 'day', '2026-06-20', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in pay date', 'DYM001', 'LIVE', 'WEST', '库存不足', 'RMB', 2967.25, 64, 192, 35
UNION ALL
SELECT '2026-07-28 10:00:00', '2026/6/21', 'day', '2026-06-21', '25', 'FW202625', '06_Sep', '2026财年6月', '3', '2026财年第三季度', '2026', '2026财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYM001', 'LIVE', 'EAST', '门店拒单', 'RMB', 738.54, 66, 132, 19
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/15', 'day', '2025-07-15', '29', 'FW202529', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'DYM001', 'LIVE', 'SOUTH', '系统超时', 'RMB', 2705.77, 79, 79, 148
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/16', 'day', '2025-07-16', '29', 'FW202529', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYM001', 'LIVE', 'NORTH', '用户取消', 'RMB', 8130.96, 74, 148, 57
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/17', 'day', '2025-07-17', '29', 'FW202529', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'DYM001', 'LIVE', 'WEST', '地址异常', 'RMB', 1251.75, 34, 102, 22
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/20', 'day', '2025-07-20', '30', 'FW202530', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYM001', 'LIVE', 'EAST', '物流限制', 'RMB', 8711.73, 39, 78, 11
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/7/21', 'day', '2025-07-21', '30', 'FW202530', '07_Oct', '2025财年7月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'DYM001', 'LIVE', 'SOUTH', 'SKU缺货', 'RMB', 4105.14, 59, 177, 11
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/15', 'day', '2025-06-15', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYM001', 'LIVE', 'NORTH', '支付失败', 'RMB', 1648.31, 31, 62, 92
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/16', 'day', '2025-06-16', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'DYM001', 'LIVE', 'WEST', '其他', 'RMB', 5873.83, 22, 44, 80
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/17', 'day', '2025-06-17', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYM001', 'LIVE', 'EAST', '库存不足', 'RMB', 8065.57, 48, 144, 79
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/18', 'day', '2025-06-18', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in pay date', 'DYM001', 'LIVE', 'SOUTH', '门店拒单', 'RMB', 5918.02, 63, 126, 131
UNION ALL
SELECT '2026-07-28 10:00:00', '2025/6/20', 'day', '2025-06-20', '25', 'FW202525', '06_Sep', '2025财年6月', '3', '2025财年第三季度', '2025', '2025财年', 'Exclude orders cancelled in paydate & EC-fulfilled from O2O unfulfilled', 'DYM001', 'LIVE', 'NORTH', '系统超时', 'RMB', 4972.74, 39, 39, 18
    "),
    更改的类型 = Table.TransformColumnTypes(源,{{"data_date", type date}})
in
    更改的类型