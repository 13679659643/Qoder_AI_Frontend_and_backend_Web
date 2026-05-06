# 门店分析排名SQL完整优化方案

## 一、当前SQL问题概览

| 序号 | 问题类别 | 问题描述 | 影响程度 |
|------|----------|----------|----------|
| 1 | 索引失效 | `t.dt::date` 类型转换导致索引无法使用 | 高 |
| 2 | 子查询低效 | WHERE中嵌套 `SELECT MAX(dt)` 子查询，每次执行重复扫描 | 高 |
| 3 | 模糊匹配 | `lob LIKE '%..%'` 前导通配符导致全表扫描 | 中 |
| 4 | 重复扫描 | `store_data` CTE被 `FILTERED_DATA` 和 `PREV_FILTERED_DATA` 分别扫描 | 高 |
| 5 | 窗口函数冗余 | CASE嵌套8个ROW_NUMBER()窗口函数，全部计算后仅取其一 | 高 |
| 6 | FULL JOIN不必要 | `summary_final_data` 使用FULL JOIN，大部分场景LEFT JOIN即可 | 中 |
| 7 | 聚合重复计算 | `SUM(SUM(...)) OVER()` 嵌套聚合可预先计算 | 低 |
| 8 | CASE转换低效 | `tag_tb` 中 tag_cycle_time 使用CASE转换做等值比较 | 低 |
| 9 | UNION ALL冗余 | `tag_tb` 两段查询可合并为单一查询 | 低 |
| 10 | 列选择冗余 | `store_data` CTE选取了过多未使用的列 | 低 |

---

## 二、索引优化建议

### 2.1 主表索引

针对表 `apple3pp_ads.dashboard_map_reseller_t_reseller_store_product_sales_detail`：

```sql
-- 核心复合索引（覆盖主要筛选条件）
CREATE INDEX idx_store_sales_main ON apple3pp_ads.dashboard_map_reseller_t_reseller_store_product_sales_detail (
    dt,
    reseller_hq_id,
    reduce_time_type,
    sales_channel,
    category_name_3,
    store_type,
    store_code
);

-- 辅助索引（覆盖次要筛选条件）
CREATE INDEX idx_store_sales_filter ON apple3pp_ads.dashboard_map_reseller_t_reseller_store_product_sales_detail (
    dt,
    reseller_hq_id,
    store_scope,
    brand_name,
    specification,
    store_tier,
    purchase_price_level,
    settlement_mode
);

-- dt字段单独索引（用于MAX(dt)快速定位）
CREATE INDEX idx_store_sales_dt ON apple3pp_ads.dashboard_map_reseller_t_reseller_store_product_sales_detail (dt DESC);
```

### 2.2 标签表索引

针对表 `apple3pp_ads.dashboard_map_tag_pos_week`：

```sql
CREATE INDEX idx_tag_pos_main ON apple3pp_ads.dashboard_map_tag_pos_week (
    dealer_hq_id,
    tag_cycle_time,
    tag_cycle_time_value,
    store_cd
);

CREATE INDEX idx_tag_pos_code ON apple3pp_ads.dashboard_map_tag_pos_week (
    dealer_hq_id,
    tag_code,
    tag_value_display
);
```

---

## 三、SQL结构优化

### 3.1 消除 `dt::date` 类型转换

**问题**：`t.dt::date = (SELECT MAX(dt) ...)` 中的 `::date` 类型转换导致索引失效。

**优化方案**：

```sql
-- 优化前
WHERE t.dt::date = (SELECT MAX(dt) FROM apple3pp_ads.dashboard_map_reseller_t_reseller_store_product_sales_detail)

-- 优化后：先物化MAX(dt)，避免类型转换
-- 方式1：如果dt字段本身是date类型，去掉::date
WHERE t.dt = (SELECT MAX(dt) FROM apple3pp_ads.dashboard_map_reseller_t_reseller_store_product_sales_detail)

-- 方式2：如果dt是timestamp类型，使用范围查询
WHERE t.dt >= (SELECT MAX(dt)::date FROM apple3pp_ads.dashboard_map_reseller_t_reseller_store_product_sales_detail)
  AND t.dt < (SELECT MAX(dt)::date + INTERVAL '1 day' FROM apple3pp_ads.dashboard_map_reseller_t_reseller_store_product_sales_detail)
```

### 3.2 将MAX(dt)子查询提升为独立CTE

**优化方案**：

```sql
WITH max_dt AS (
    SELECT MAX(dt) AS max_dt_value
    FROM apple3pp_ads.dashboard_map_reseller_t_reseller_store_product_sales_detail
    WHERE reseller_hq_id = '$val{reseller_hq_id}'  -- 加入主筛选条件缩小范围
),
store_data AS (
    SELECT ...
    FROM apple3pp_ads.dashboard_map_reseller_t_reseller_store_product_sales_detail t
    CROSS JOIN max_dt m
    WHERE t.dt = m.max_dt_value
      AND ...
)
```

### 3.3 消除 `LIKE '%...%'` 模糊匹配

**问题**：`lob LIKE '%$val{lob}%'` 前导通配符使索引失效。

**优化方案**：

```sql
-- 方案A：如果lob是多值字段（如逗号分隔），改用数组或全文检索
-- 使用PostgreSQL数组类型
WHERE '$val{lob}' = ANY(string_to_array(lob, ','))

-- 方案B：如果业务上lob值有限，使用IN列表替代
WHERE lob IN (SELECT unnest FROM unnest(string_to_array('$val{lob}', ',')))

-- 方案C：使用GIN索引+pg_trgm扩展加速LIKE
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_lob_trgm ON apple3pp_ads.dashboard_map_reseller_t_reseller_store_product_sales_detail
    USING gin (lob gin_trgm_ops);
```

### 3.4 合并FILTERED_DATA与PREV_FILTERED_DATA，避免重复扫描

**问题**：`store_data` 被两个CTE分别过滤（一次按当前周期，一次按上期周期），本质上是对同一数据集的两次扫描。

**优化方案**：

```sql
-- 一次聚合，使用条件聚合分离当前/上期数据
combined_data AS (
    SELECT
        category_name_3,
        category_name_4,
        bar_code,
        mpn,
        sku_info,
        specification,
        store_code,
        store_name,
        store_tier,
        -- 当前周期指标
        SUM(CASE WHEN reduce_time_value = '$val{reduce_time_value}' THEN sell_out_qty END) AS sell_out_qty,
        SUM(CASE WHEN reduce_time_value = '$val{reduce_time_value}' THEN sell_out_amount END) AS sell_out_amount,
        SUM(CASE WHEN reduce_time_value = '$val{reduce_time_value}' THEN profit_amount END) AS profit_amount,
        MAX(CASE WHEN reduce_time_value = '$val{reduce_time_value}' THEN offline_traffic END) AS offline_traffic,
        MAX(CASE WHEN reduce_time_value = '$val{reduce_time_value}' THEN inventory END) AS inventory,
        MAX(CASE WHEN reduce_time_value = '$val{reduce_time_value}' THEN available_inventory END) AS available_inventory,
        MAX(CASE WHEN reduce_time_value = '$val{reduce_time_value}' THEN inventory_cost END) AS inventory_cost,
        SUM(CASE WHEN reduce_time_value = '$val{reduce_time_value}' THEN offline_sales_sku_count END) AS offline_sales_sku_count,
        -- 上期指标（使用pre_reduce_time_value匹配上期）
        SUM(CASE WHEN reduce_time_value = pre_reduce_time_value THEN sell_out_qty END) AS prev_sell_out_qty,
        SUM(CASE WHEN reduce_time_value = pre_reduce_time_value THEN sell_out_amount END) AS prev_sell_out_amount,
        SUM(CASE WHEN reduce_time_value = pre_reduce_time_value THEN profit_amount END) AS prev_profit_amount,
        MAX(CASE WHEN reduce_time_value = pre_reduce_time_value THEN offline_traffic END) AS prev_offline_traffic,
        MAX(CASE WHEN reduce_time_value = pre_reduce_time_value THEN available_inventory END) AS prev_available_inventory,
        MAX(CASE WHEN reduce_time_value = pre_reduce_time_value THEN inventory_cost END) AS prev_inventory_cost,
        SUM(CASE WHEN reduce_time_value = pre_reduce_time_value THEN offline_sales_sku_count END) AS prev_offline_sales_sku_count
    FROM store_data
    GROUP BY category_name_3, category_name_4, mpn, bar_code, sku_info, specification,
             store_code, store_name, store_tier
)
```

### 3.5 窗口函数优化——仅计算需要的排名

**问题**：当前使用CASE包裹8个ROW_NUMBER()窗口函数，数据库引擎可能会计算所有窗口函数后取其一。

**优化方案**：使用动态ORDER BY表达式替代多个窗口函数。

```sql
ranked_data AS (
    SELECT fd.*,
           oft.offline_traffic_sum,
           oft.pre_offline_traffic_sum,
           ROW_NUMBER() OVER (
               PARTITION BY fd.store_tier
               ORDER BY
                   CASE '$val{rank_type}'
                       WHEN '销量排行' THEN fd.sell_out_qty
                       WHEN '销售额排行' THEN fd.sell_out_amount
                       WHEN '毛利额排行' THEN fd.profit_amount
                       WHEN '线下转化率排行' THEN fd.offline_conversion_rate
                   END *
                   CASE '$val{rank_type_asc_desc}'
                       WHEN '降序' THEN -1
                       ELSE 1
                   END ASC NULLS LAST,
                   fd.store_name ASC
           ) AS dynamic_rank
    FROM summary_final_data fd
    LEFT JOIN off_traffic oft ON fd.store_tier = oft.store_tier
)
```

> **注意**：上面使用了乘以-1的技巧将降序转为升序比较。若数据库优化器无法利用此技巧，可在应用层根据参数动态拼接SQL。

**备选方案（推荐）**：在应用层动态拼接ORDER BY子句：

```python
# 应用层动态构建
order_field_map = {
    '销量排行': 'fd.sell_out_qty',
    '销售额排行': 'fd.sell_out_amount',
    '毛利额排行': 'fd.profit_amount',
    '线下转化率排行': 'fd.offline_conversion_rate'
}
order_field = order_field_map[rank_type]
order_dir = 'DESC' if rank_type_asc_desc == '降序' else 'ASC'

sql = f"""
ROW_NUMBER() OVER (
    PARTITION BY fd.store_tier 
    ORDER BY {order_field} {order_dir} NULLS LAST, fd.store_name ASC
) AS dynamic_rank
"""
```

### 3.6 FULL JOIN改为LEFT JOIN

**问题**：`summary_final_data` 中使用 FULL JOIN 合并当前和上期数据，但业务上通常以当前周期门店为基准。

**优化方案**：

```sql
-- 如果业务允许（即只展示当前周期有数据的门店）
summary_final_data AS (
    SELECT 
        fd.store_tier,
        fd.store_code,
        fd.store_name,
        fd.*,
        pfd.pre_sell_out_qty,
        ...
    FROM final_data fd
    LEFT JOIN pre_final_data pfd
        ON fd.store_code = pfd.store_code
        AND fd.store_tier = pfd.store_tier
)
```

> 如果确实需要显示"仅上期有数据，当前期无数据"的门店，保留FULL JOIN，但需确认JOIN条件完整。

### 3.7 tag_tb优化——合并UNION ALL

**问题**：`tag_tb` 使用 UNION ALL 拼接两段条件几乎相同的查询，增加了表扫描次数。

**优化方案**：

```sql
tag_tb AS (
    SELECT *
    FROM apple3pp_ads.dashboard_map_tag_pos_week
    WHERE dealer_hq_id = '$val{reseller_hq_id}'
      AND CASE tag_cycle_time
          WHEN '周' THEN 'week'
          WHEN '月' THEN 'month'
          WHEN '季' THEN 'quarter'
          WHEN '年' THEN 'year'
      END = '$val{reduce_time_type}'
      AND tag_cycle_time_value = '$val{reduce_time_value}'
      AND (
          -- 原第一段条件
          (tag_code NOT LIKE '%ClosedDays%'
           AND tag_sales_touchpoint = '$val{tag_sales_touchpoint}'
           AND tag_statistical_index = '$val{tag_statistical_index}'
           AND tag_evaluation_scope = '$val{tag_evaluation_scope}')
          OR
          -- 原第二段条件
          ((tag_code LIKE '%isAbnormal' AND tag_value_display = '待验证门店')
           OR (tag_code LIKE '%Appointed_Window' AND tag_value_display = '预授权门店（系统标记门店）'))
      )
)
```

**进一步优化**：将 `CASE tag_cycle_time` 改为直接比较源值：

```sql
-- 在应用层预先转换
-- 例如：$val{reduce_time_type} = 'week' → tag_cycle_time_cn = '周'
tag_tb AS (
    SELECT *
    FROM apple3pp_ads.dashboard_map_tag_pos_week
    WHERE dealer_hq_id = '$val{reseller_hq_id}'
      AND tag_cycle_time = '$val{tag_cycle_time_cn}'  -- 直接用中文值比较，可命中索引
      AND tag_cycle_time_value = '$val{reduce_time_value}'
      AND (...)
)
```

### 3.8 store_tier排序优化

**问题**：使用冗长的CASE WHEN做T1-T12的排序映射。

**优化方案**：

```sql
-- 方案A：利用字符串截取
CAST(SUBSTRING(store_tier FROM 2) AS INTEGER) AS store_tier_sort

-- 方案B：使用正则
CAST(REGEXP_REPLACE(store_tier, '[^0-9]', '', 'g') AS INTEGER) AS store_tier_sort

-- 方案C（推荐，兼顾非标准值）：
COALESCE(
    CAST(NULLIF(REGEXP_REPLACE(store_tier, '[^0-9]', '', 'g'), '') AS INTEGER),
    99
) AS store_tier_sort
```

---

## 四、CTE物化控制

PostgreSQL 12+支持CTE物化提示，可以控制CTE是否被内联优化：

```sql
-- 对于只使用一次的CTE，允许优化器内联
WITH store_data AS NOT MATERIALIZED (
    SELECT ...
)

-- 对于使用多次的CTE，强制物化避免重复计算
WITH store_data AS MATERIALIZED (
    SELECT ...
)
```

**建议**：
- `store_data`：由于被多个下游CTE引用 → 使用 `MATERIALIZED`
- `FILTERED_DATA`：被 `final_data`、`in_sku_count` 引用 → 使用 `MATERIALIZED`
- `off_traffic`、`in_store_name_sku_count` 等小结果集：保持默认

---

## 五、完整优化后SQL

```sql
-- 优化后的门店分析排名SQL
WITH 
-- 1. 预计算最大dt，避免子查询重复执行
max_dt AS (
    SELECT MAX(dt) AS max_dt_value
    FROM apple3pp_ads.dashboard_map_reseller_t_reseller_store_product_sales_detail
),

-- 2. 主数据CTE：精简列选择，去除dt::date转换
store_data AS MATERIALIZED (
    SELECT 
        t.category_name_3,
        IF(t.category_name_4 IS NULL OR t.category_name_4 = '', t.category_name_3, t.category_name_4) AS category_name_4,
        t.store_code,
        t.store_name,
        t.store_tier,
        t.bar_code,
        t.mpn,
        t.sku_info,
        t.specification,
        t.reduce_time_value,
        t.pre_reduce_time_value,
        t.sell_out_qty,
        t.sell_out_amount,
        t.profit_amount,
        CASE WHEN t.offline_traffic IS NOT NULL THEN t.offline_traffic::integer END AS offline_traffic,
        t.inventory,
        t.available_inventory,
        t.inventory_cost,
        t.offline_sales_sku_count::int,
        t.pre_offline_sales_sku_count::int
    FROM apple3pp_ads.dashboard_map_reseller_t_reseller_store_product_sales_detail t
    CROSS JOIN max_dt m
    WHERE t.dt = m.max_dt_value
      AND t.store_code IS NOT NULL
      AND t.reseller_hq_id = '$val{reseller_hq_id}'
      AND t.reduce_time_type = '$val{reduce_time_type}'
      AND t.category_name_3 = '$val{category_name_3}'
      AND t.sales_channel = '$val{sales_channel}'
      AND t.store_scope = '$val{store_scope}'
      AND t.brand_name = '$val{brand_name}'
      AND t.lob LIKE '%$val{lob}%'
      AND t.specification = '$val{specification}'
      AND t.store_tier = '$val{store_tier}'
      AND t.purchase_price_level = '$val{purchase_price_level}'
      AND t.settlement_mode = '$val{settlement_mode}'
      AND t.store_type = '店'
      AND CASE
              WHEN '$val{category_name_4}' IS NULL OR '$val{category_name_4}' = ' ' THEN TRUE
              ELSE IF(t.category_name_4 IS NULL OR t.category_name_4 = '', t.category_name_3,
                      t.category_name_4) = '$val{category_name_4}'
          END
),

-- 3. 获取上期快照日期
prev_period AS (
    SELECT MAX(pre_reduce_time_value) AS prev_time_value
    FROM store_data
    WHERE reduce_time_value = '$val{reduce_time_value}'
),

-- 4. 当前周期数据
FILTERED_DATA AS MATERIALIZED (
    SELECT 
        category_name_3, category_name_4, bar_code, mpn, sku_info, specification,
        store_code, store_name, store_tier,
        SUM(sell_out_qty) AS sell_out_qty,
        SUM(sell_out_amount) AS sell_out_amount,
        SUM(profit_amount) AS profit_amount,
        MAX(offline_traffic) AS offline_traffic,
        MAX(inventory) AS inventory,
        MAX(available_inventory) AS available_inventory,
        MAX(inventory_cost) AS inventory_cost,
        SUM(offline_sales_sku_count) AS offline_sales_sku_count
    FROM store_data
    WHERE reduce_time_value = '$val{reduce_time_value}'
    GROUP BY category_name_3, category_name_4, mpn, bar_code, sku_info, specification,
             store_code, store_name, store_tier
),

-- 5. 上期数据
PREV_FILTERED_DATA AS (
    SELECT 
        category_name_3, category_name_4, bar_code, mpn, sku_info, specification,
        store_code, store_name, store_tier,
        SUM(sell_out_qty) AS sell_out_qty,
        SUM(sell_out_amount) AS sell_out_amount,
        SUM(profit_amount) AS profit_amount,
        MAX(offline_traffic) AS offline_traffic,
        MAX(inventory) AS inventory,
        MAX(available_inventory) AS available_inventory,
        MAX(inventory_cost) AS inventory_cost,
        SUM(offline_sales_sku_count) AS offline_sales_sku_count
    FROM store_data
    CROSS JOIN prev_period pp
    WHERE reduce_time_value = pp.prev_time_value
    GROUP BY category_name_3, category_name_4, mpn, bar_code, sku_info, specification,
             store_code, store_name, store_tier
),

-- 6. 上期门店维度汇总（合并pre_store_data + in_store_name_sku_count）
pre_store_summary AS (
    SELECT 
        store_code,
        store_name,
        store_tier,
        COUNT(DISTINCT CASE WHEN available_inventory > 0 THEN mpn END) AS pre_inventory_sku_count,
        COUNT(DISTINCT CASE WHEN sell_out_qty > 0 THEN mpn END) AS pre_sales_sku_count
    FROM PREV_FILTERED_DATA
    GROUP BY store_code, store_name, store_tier
),

-- 7. store_tier维度SKU汇总
tier_sku_count AS (
    SELECT 
        sd.store_tier,
        COUNT(DISTINCT CASE WHEN sd.available_inventory > 0 THEN sd.mpn END) AS total_inventory_sku_count,
        MAX(pd.total_pre_inventory_sku_count) AS total_pre_inventory_sku_count
    FROM FILTERED_DATA sd
    LEFT JOIN (
        SELECT store_tier,
               COUNT(DISTINCT CASE WHEN available_inventory > 0 THEN mpn END) AS total_pre_inventory_sku_count
        FROM PREV_FILTERED_DATA
        GROUP BY store_tier
    ) pd ON sd.store_tier = pd.store_tier
    GROUP BY sd.store_tier
),

-- 8. 当前周期门店汇总
final_data AS (
    SELECT 
        sd.store_tier,
        sd.store_code,
        sd.store_name,
        COUNT(DISTINCT CASE WHEN sd.available_inventory > 0 THEN sd.mpn END) AS inventory_sku_count,
        MAX(pss.pre_inventory_sku_count) AS pre_inventory_sku_count,
        MAX(tsc.total_inventory_sku_count) AS total_inventory_sku_count,
        MAX(tsc.total_pre_inventory_sku_count) AS total_pre_inventory_sku_count,
        CASE
            WHEN MAX(pss.pre_inventory_sku_count) = 0 THEN NULL
            WHEN COUNT(DISTINCT CASE WHEN sd.available_inventory > 0 THEN sd.mpn END) = 0 THEN 0
            ELSE 1.0 * COUNT(DISTINCT CASE WHEN sd.available_inventory > 0 THEN sd.mpn END) 
                 / MAX(pss.pre_inventory_sku_count) - 1
        END AS inventory_sku_count_growth_rate,
        SUM(sd.sell_out_qty) AS sell_out_qty,
        SUM(SUM(sd.sell_out_qty)) OVER () AS sell_out_qty_all,
        SUM(sd.sell_out_amount) AS sell_out_amount,
        SUM(SUM(sd.sell_out_amount)) OVER () AS sell_out_amount_all,
        SUM(sd.profit_amount) AS profit_amount,
        SUM(SUM(sd.profit_amount)) OVER () AS profit_amount_all,
        MAX(sd.offline_traffic) AS offline_traffic,
        COUNT(DISTINCT CASE WHEN sd.sell_out_qty > 0 THEN sd.mpn END) AS sales_sku_count,
        MAX(pss.pre_sales_sku_count) AS pre_sales_sku_count,
        SUM(sd.offline_sales_sku_count) AS offline_sales_sku_count,
        ROUND(SUM(sd.offline_sales_sku_count)::NUMERIC / NULLIF(MAX(sd.offline_traffic), 0), 6) AS offline_conversion_rate,
        SUM(sd.inventory) AS inventory,
        SUM(sd.available_inventory) AS available_inventory,
        SUM(SUM(sd.available_inventory)) OVER () AS available_inventory_all,
        SUM(sd.inventory_cost) AS inventory_cost
    FROM FILTERED_DATA sd
    LEFT JOIN pre_store_summary pss
        ON sd.store_code = pss.store_code AND sd.store_tier = pss.store_tier
    LEFT JOIN tier_sku_count tsc
        ON sd.store_tier = tsc.store_tier
    GROUP BY sd.store_tier, sd.store_code, sd.store_name
),

-- 9. 上期门店汇总
pre_final_data AS (
    SELECT 
        pfd.store_tier,
        pfd.store_code,
        pfd.store_name,
        SUM(pfd.sell_out_qty) AS pre_sell_out_qty,
        SUM(pfd.sell_out_amount) AS pre_sell_out_amount,
        SUM(pfd.profit_amount) AS pre_profit_amount,
        MAX(pfd.offline_traffic) AS pre_offline_traffic,
        SUM(pfd.offline_sales_sku_count) AS pre_offline_sales_sku_count,
        ROUND(SUM(pfd.offline_sales_sku_count)::NUMERIC / NULLIF(MAX(pfd.offline_traffic), 0), 6) AS pre_offline_conversion_rate,
        SUM(pfd.inventory) AS pre_inventory,
        SUM(pfd.available_inventory) AS pre_available_inventory,
        SUM(pfd.inventory_cost) AS pre_inventory_cost
    FROM PREV_FILTERED_DATA pfd
    GROUP BY pfd.store_tier, pfd.store_code, pfd.store_name
),

-- 10. 合并当前与上期数据
summary_final_data AS (
    SELECT 
        COALESCE(fd.store_tier, pfd.store_tier) AS store_tier,
        COALESCE(fd.store_code, pfd.store_code) AS store_code,
        COALESCE(fd.store_name, pfd.store_name) AS store_name,
        fd.inventory_sku_count,
        fd.pre_inventory_sku_count,
        fd.total_inventory_sku_count,
        fd.total_pre_inventory_sku_count,
        fd.inventory_sku_count_growth_rate,
        fd.sell_out_qty,
        fd.sell_out_qty_all,
        fd.sell_out_amount,
        fd.sell_out_amount_all,
        fd.profit_amount,
        fd.profit_amount_all,
        fd.offline_traffic,
        fd.sales_sku_count,
        fd.pre_sales_sku_count,
        fd.offline_sales_sku_count,
        fd.offline_conversion_rate,
        fd.inventory,
        fd.available_inventory,
        fd.available_inventory_all,
        fd.inventory_cost,
        pfd.pre_sell_out_qty,
        pfd.pre_sell_out_amount,
        pfd.pre_profit_amount,
        pfd.pre_offline_traffic,
        pfd.pre_offline_sales_sku_count,
        pfd.pre_offline_conversion_rate,
        pfd.pre_inventory,
        pfd.pre_available_inventory,
        pfd.pre_inventory_cost,
        CASE
            WHEN pfd.pre_offline_conversion_rate = 0 THEN NULL
            WHEN fd.offline_conversion_rate = 0 THEN 0
            ELSE 100 * fd.offline_conversion_rate - 100 * pfd.pre_offline_conversion_rate
        END AS offline_conversion_rate_growth_rate
    FROM final_data fd
    FULL JOIN pre_final_data pfd
        ON fd.store_code = pfd.store_code AND fd.store_tier = pfd.store_tier
),

-- 11. 流量汇总（按store_tier）
off_traffic AS (
    SELECT 
        store_tier,
        SUM(offline_traffic) AS offline_traffic_sum,
        SUM(pre_offline_traffic) AS pre_offline_traffic_sum
    FROM summary_final_data
    GROUP BY store_tier
),

-- 12. 动态排名（单个ROW_NUMBER）
ranked_data AS (
    SELECT 
        fd.*,
        oft.offline_traffic_sum,
        oft.pre_offline_traffic_sum,
        ROW_NUMBER() OVER (
            PARTITION BY fd.store_tier
            ORDER BY
                CASE '$val{rank_type}'
                    WHEN '销量排行' THEN fd.sell_out_qty
                    WHEN '销售额排行' THEN fd.sell_out_amount
                    WHEN '毛利额排行' THEN fd.profit_amount
                    WHEN '线下转化率排行' THEN fd.offline_conversion_rate
                END * CASE '$val{rank_type_asc_desc}' WHEN '降序' THEN -1 ELSE 1 END
                ASC NULLS LAST,
                fd.store_name ASC
        ) AS dynamic_rank
    FROM summary_final_data fd
    LEFT JOIN off_traffic oft ON fd.store_tier = oft.store_tier
),

-- 13. 最终排名过滤
pos_detail AS (
    SELECT 
        store_tier,
        COALESCE(CAST(NULLIF(REGEXP_REPLACE(store_tier, '[^0-9]', '', 'g'), '') AS INTEGER), 99) AS store_tier_sort,
        store_code,
        store_name,
        inventory_sku_count,
        pre_inventory_sku_count,
        total_inventory_sku_count,
        total_pre_inventory_sku_count,
        inventory_sku_count_growth_rate,
        sell_out_qty,
        pre_sell_out_qty,
        sell_out_qty_all,
        sell_out_amount,
        pre_sell_out_amount,
        sell_out_amount_all,
        profit_amount,
        pre_profit_amount,
        profit_amount_all,
        offline_traffic,
        pre_offline_traffic,
        sales_sku_count,
        pre_sales_sku_count,
        offline_sales_sku_count,
        pre_offline_sales_sku_count,
        offline_conversion_rate,
        pre_offline_conversion_rate,
        offline_conversion_rate_growth_rate,
        offline_traffic_sum,
        pre_offline_traffic_sum,
        inventory,
        pre_inventory,
        available_inventory,
        pre_available_inventory,
        available_inventory_all,
        inventory_cost,
        pre_inventory_cost,
        dynamic_rank
    FROM ranked_data
    WHERE CASE '$val{top_rank_type}'
              WHEN '全部' THEN TRUE
              WHEN 'top10' THEN dynamic_rank <= 10
              WHEN 'bottom10' THEN dynamic_rank <= 10
          END
    ORDER BY store_tier, dynamic_rank
),

-- 14. 标签数据（合并UNION ALL为单一查询）
tag_tb AS (
    SELECT *
    FROM apple3pp_ads.dashboard_map_tag_pos_week
    WHERE dealer_hq_id = '$val{reseller_hq_id}'
      AND CASE tag_cycle_time
          WHEN '周' THEN 'week'
          WHEN '月' THEN 'month'
          WHEN '季' THEN 'quarter'
          WHEN '年' THEN 'year'
      END = '$val{reduce_time_type}'
      AND tag_cycle_time_value = '$val{reduce_time_value}'
      AND (
          (tag_code NOT LIKE '%ClosedDays%'
           AND tag_sales_touchpoint = '$val{tag_sales_touchpoint}'
           AND tag_statistical_index = '$val{tag_statistical_index}'
           AND tag_evaluation_scope = '$val{tag_evaluation_scope}')
          OR
          (tag_code LIKE '%isAbnormal' AND tag_value_display = '待验证门店')
          OR
          (tag_code LIKE '%Appointed_Window' AND tag_value_display = '预授权门店（系统标记门店）')
      )
)

-- 最终输出
SELECT 
    d.*,
    t.tag_code,
    CASE 
        WHEN t.tag_value_display = '预授权门店（系统标记门店）' THEN '系统标记门店'
        ELSE t.tag_value_display 
    END AS tag_value_display
FROM pos_detail d 
LEFT JOIN tag_tb t ON d.store_code = t.store_cd;
```

---

## 六、执行计划分析建议

在应用优化前后，建议使用以下命令对比执行计划：

```sql
-- 查看详细执行计划（含实际执行时间）
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
WITH store_data AS (...)
SELECT ...;

-- 关注以下指标
-- 1. Seq Scan → 是否出现不必要的全表扫描
-- 2. Sort → 排序是否使用了索引
-- 3. Hash Join vs Nested Loop → JOIN策略是否合理
-- 4. CTE Scan → CTE是否被物化
-- 5. Rows Removed by Filter → 过滤掉的行数是否过多（说明索引未生效）
```

---

## 七、应用层优化建议

| 建议 | 说明 |
|------|------|
| 参数化查询 | 将 `$val{...}` 替换为预编译参数 `$1, $2, ...`，避免SQL注入并利用执行计划缓存 |
| 动态SQL拼接 | 对于 `rank_type`、`rank_type_asc_desc`、`top_rank_type` 等控制逻辑在应用层构建，减少数据库内CASE分支 |
| 条件下推 | `category_name_4` 的可选筛选改为应用层判断是否拼接WHERE条件，而非数据库内CASE |
| 结果缓存 | 对于 `max_dt` 查询结果可在应用层缓存（如Redis），因为每天只变化一次 |
| 分页优化 | 如果前端支持分页，在 `pos_detail` 层加入 `LIMIT/OFFSET` 减少返回数据量 |

---

## 八、数据建模优化建议

### 8.1 预聚合表

对于高频访问的门店排名场景，建议创建物化视图或预聚合表：

```sql
-- 门店维度预聚合表（定时刷新）
CREATE MATERIALIZED VIEW mv_store_sales_summary AS
SELECT 
    dt,
    reseller_hq_id,
    reduce_time_type,
    reduce_time_value,
    category_name_3,
    sales_channel,
    store_scope,
    brand_name,
    specification,
    store_tier,
    store_code,
    store_name,
    SUM(sell_out_qty) AS sell_out_qty,
    SUM(sell_out_amount) AS sell_out_amount,
    SUM(profit_amount) AS profit_amount,
    MAX(offline_traffic::integer) AS offline_traffic,
    SUM(inventory) AS inventory,
    SUM(available_inventory) AS available_inventory,
    SUM(inventory_cost) AS inventory_cost,
    SUM(offline_sales_sku_count::int) AS offline_sales_sku_count,
    COUNT(DISTINCT CASE WHEN available_inventory > 0 THEN mpn END) AS inventory_sku_count,
    COUNT(DISTINCT CASE WHEN sell_out_qty > 0 THEN mpn END) AS sales_sku_count
FROM apple3pp_ads.dashboard_map_reseller_t_reseller_store_product_sales_detail
WHERE store_code IS NOT NULL AND store_type = '店'
GROUP BY dt, reseller_hq_id, reduce_time_type, reduce_time_value,
         category_name_3, sales_channel, store_scope, brand_name,
         specification, store_tier, store_code, store_name;

-- 刷新策略（每日ETL后）
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_store_sales_summary;
```

### 8.2 分区表

如果数据量较大，建议对主表按 `dt` 进行分区：

```sql
-- 按dt进行范围分区
CREATE TABLE apple3pp_ads.dashboard_map_reseller_t_reseller_store_product_sales_detail (
    ...
) PARTITION BY RANGE (dt);

-- 每月/每周创建新分区
CREATE TABLE apple3pp_ads.dashboard_map_reseller_..._202601 
    PARTITION OF apple3pp_ads.dashboard_map_reseller_t_reseller_store_product_sales_detail
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
```

---

## 九、优化效果预估

| 优化项 | 预期提升 | 风险 |
|--------|----------|------|
| 索引优化（2.1-2.2） | 查询响应时间减少 60-80% | 写入性能略有下降，需评估 |
| 消除dt类型转换（3.1-3.2） | 主表扫描时间减少 50%+ | 需确认dt字段类型 |
| 合并FILTERED/PREV扫描（3.4） | CTE执行时间减少 40% | 逻辑复杂度增加 |
| 窗口函数优化（3.5） | 排名计算减少 75% 开销 | 需验证乘-1技巧的排序正确性 |
| tag_tb合并（3.7） | 标签查询减少一次全表扫描 | 无 |
| 物化视图（8.1） | 整体查询从秒级降到毫秒级 | 需要维护刷新机制 |

---

## 十、实施优先级

1. **P0 - 立即实施**：索引创建（2.1-2.2）、消除dt类型转换（3.1-3.2）
2. **P1 - 短期实施**：MAX(dt)提升为CTE（3.2）、窗口函数优化（3.5）、tag_tb合并（3.7）
3. **P2 - 中期实施**：合并FILTERED/PREV重复扫描（3.4）、CTE物化控制（四）
4. **P3 - 长期规划**：预聚合物化视图（8.1）、分区表（8.2）、应用层动态SQL构建（七）

---

## 十一、注意事项

1. **测试验证**：所有优化必须在测试环境验证数据正确性，特别是排名结果的一致性
2. **索引维护**：新增索引会增加写入开销，需监控INSERT/UPDATE性能
3. **FULL JOIN语义**：将FULL JOIN改为LEFT JOIN前必须确认业务需求
4. **乘-1排序技巧**：需验证NULL值处理逻辑是否与原始CASE分支一致
5. **物化视图刷新**：需与ETL流程协调，确保数据时效性
