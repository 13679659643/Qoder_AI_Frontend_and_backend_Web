let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
WITH base AS (
  -- 1) 取值并规范化：去空格 + 统一大写
  SELECT DISTINCT UPPER(TRIM(sku_size)) AS sku_size
  FROM indep_rl_dw.s02_trade_sku_data_d
  WHERE sku_size IS NOT NULL
    AND TRIM(sku_size) <> ''
),

cls AS (
  -- 2) 机器初分：规则从上往下命中即停
  SELECT
    sku_size,
    CASE
      -- 字母+版型/组合码
      WHEN sku_size REGEXP '^(XXS|XS|S|M|L|XL|XXL|3XL)[ /](XS|XL|S|R|M|L)$' THEN 'LETTER_FIT'
      -- 类型码：完全不含数字
      WHEN sku_size NOT REGEXP '[0-9]' THEN 'TYPE_CODE'
      -- 平面尺寸 5X7 / 54X72
      WHEN sku_size REGEXP '^[0-9]+(\\.[0-9]+)?X[0-9]+(\\.[0-9]+)?$' THEN 'DIMENSION'
      -- 腰/裤长：aa/bb 且腰>=24
      WHEN sku_size REGEXP '^[0-9]{2}/[0-9]{2}$'
           AND CAST(SUBSTRING_INDEX(sku_size, '/', 1) AS UNSIGNED) >= 24 THEN 'WAIST_LEN'
      -- 婴儿月龄
      WHEN sku_size REGEXP '^(NB/)?[0-9]+(-[0-9]+)?M$'
        OR (sku_size REGEXP '^[0-9]+/[0-9]+$'
            AND CAST(SUBSTRING_INDEX(sku_size, '/', 1) AS UNSIGNED) <= 12) THEN 'BABY_MONTH'
      -- 童装T码
      WHEN sku_size REGEXP '^[0-9]+/[0-9]+[TX]$' OR sku_size = '6X' THEN 'TODDLER'
      -- 童鞋区间 aa/bb
      WHEN sku_size REGEXP '^[0-9]+/[0-9]+$' THEN 'KIDS_RANGE'
      -- H 区间 17H23
      WHEN sku_size REGEXP '^[0-9]+H[0-9]+$' THEN 'H_RANGE'
      -- 数字+单字母
      WHEN sku_size REGEXP '^[0-9]+(\\.[0-9]+)? ?[A-Z]$' THEN 'NUM_LETTER'
      -- 纯字母码
      WHEN sku_size REGEXP '^[A-Z]+$' THEN 'LETTER'
      -- 纯数字
      WHEN sku_size REGEXP '^[0-9]+(\\.[0-9]+)?$' THEN 'NUMERIC'
      -- 兜底
      ELSE 'MISC'
    END AS size_group
  FROM base
),

keyed AS (
  -- 3) 生成组权重 + 组内排序键
  SELECT
    sku_size,
    size_group,
    CASE size_group
      WHEN 'TYPE_CODE' THEN 1
      WHEN 'BABY_MONTH' THEN 2
      WHEN 'TODDLER'    THEN 3
      WHEN 'KIDS_RANGE' THEN 4
      WHEN 'H_RANGE'    THEN 5
      WHEN 'NUMERIC'    THEN 6
      WHEN 'NUM_LETTER' THEN 7
      WHEN 'LETTER'     THEN 8
      WHEN 'LETTER_FIT' THEN 9
      WHEN 'WAIST_LEN'  THEN 10
      WHEN 'DIMENSION'  THEN 11
      ELSE 99
    END AS group_weight,
    CASE size_group
      WHEN 'TYPE_CODE' THEN 0
      WHEN 'BABY_MONTH' THEN CAST(REGEXP_REPLACE(sku_size, '^.*?([0-9]+)[^0-9]*$', '$1') AS UNSIGNED)
      WHEN 'TODDLER'    THEN CAST(REGEXP_REPLACE(sku_size, '^.*?([0-9]+)[^0-9]*$', '$1') AS UNSIGNED) * 10
      WHEN 'KIDS_RANGE' THEN CAST(REGEXP_REPLACE(sku_size, '^.*?([0-9]+)[^0-9]*$', '$1') AS UNSIGNED)
      WHEN 'H_RANGE'    THEN CAST(REGEXP_REPLACE(sku_size, '^.*H([0-9]+)$', '$1') AS UNSIGNED)
      WHEN 'NUMERIC'    THEN CAST(CAST(sku_size AS DECIMAL(10,2)) * 100 AS UNSIGNED)
      WHEN 'NUM_LETTER' THEN CAST(CAST(REGEXP_REPLACE(sku_size, '^([0-9.]+).*$', '$1') AS DECIMAL(10,2)) * 100 AS UNSIGNED)
                            + INSTR('BDESRMLH', RIGHT(sku_size, 1))
      WHEN 'LETTER' THEN
        CASE sku_size
          WHEN 'XXSXS' THEN 1
          WHEN 'XXS'   THEN 2
          WHEN 'XSMAL' THEN 3   WHEN 'XS' THEN 3
          WHEN 'SMALL' THEN 4   WHEN 'S'  THEN 4
          WHEN 'MEDIU' THEN 5   WHEN 'M'  THEN 5
          WHEN 'LARGE' THEN 6   WHEN 'L'  THEN 6
          WHEN 'XLARG' THEN 7   WHEN 'XL' THEN 7
          WHEN 'XXLAR' THEN 8   WHEN 'XXL' THEN 8
          WHEN '3XL'   THEN 9
          ELSE 999
        END
      WHEN 'LETTER_FIT' THEN
        (CASE REGEXP_REPLACE(sku_size, '^(XXS|XS|S|M|L|XL|XXL|3XL).*$', '$1')
           WHEN 'XXS' THEN 2 WHEN 'XS' THEN 3 WHEN 'S' THEN 4 WHEN 'M' THEN 5
           WHEN 'L'  THEN 6 WHEN 'XL' THEN 7 WHEN 'XXL' THEN 8 WHEN '3XL' THEN 9
           ELSE 999 END) * 10
        + CASE REGEXP_REPLACE(sku_size, '^.*[ /](XS|XL|S|R|M|L)$', '$1')
            WHEN 'XS' THEN 1 WHEN 'S' THEN 2 WHEN 'R' THEN 3
            WHEN 'M' THEN 4 WHEN 'L' THEN 5 WHEN 'XL' THEN 6 ELSE 9 END
      WHEN 'WAIST_LEN'  THEN CAST(SUBSTRING_INDEX(sku_size, '/', 1) AS UNSIGNED) * 1000
                           + CAST(SUBSTRING_INDEX(sku_size, '/', -1) AS UNSIGNED)
      WHEN 'DIMENSION'  THEN CAST(CAST(REGEXP_REPLACE(sku_size, '^([0-9.]+).*$', '$1') AS DECIMAL(10,2)) * 100000 AS UNSIGNED)
                           + CAST(REGEXP_REPLACE(sku_size, '^.*X([0-9.]+)$', '$1') AS DECIMAL(10,2))
      ELSE 99999999
    END AS inner_key
  FROM cls
)

-- 4) 最终排序键
SELECT
  sku_size,
  size_group,
  group_weight * 1000000
    + (ROW_NUMBER() OVER (PARTITION BY size_group ORDER BY inner_key, sku_size)) AS size_sort
FROM keyed
ORDER BY size_sort;
;")
in
    源