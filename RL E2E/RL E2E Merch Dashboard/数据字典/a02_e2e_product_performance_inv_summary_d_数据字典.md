# a02_e2e_product_performance_inv_summary_d 数据字典

## 表基本信息

| 属性 | 值 |
|------|-----|
| 表名 | a02_e2e_product_performance_inv_summary_d |
| 表注释 | 产品库存汇总表 |
| 是否分区表 | 是 |
| 备注 | 字段、字段类型及主键信息以 ClickHouse 建表语句为准 |

## 字段明细

| 字段名 | 字段类型 | 字段注释 | 是否主键 | 字段说明 | 值示例 | 备注 |
|--------|----------|----------|----------|----------|--------|------|
| etl_time | Nullable(String) | 数据创建时间 |  | 数据记录创建时间 |  |  |
| data_date | Nullable(Date) | 数据日期 | 是 | 数据所属日期 | 2024-03-15 |  |
| data_week | Nullable(String) | 财务周 |  | 数据所属财务周 |  |  |
| data_week_name | Nullable(String) | 财务周 |  | 数据所属财务周名称 |  |  |
| data_month | Nullable(String) | 财务月 |  | 数据所属财务月 |  |  |
| data_month_name | Nullable(String) | 财务月 |  | 数据所属财务月名称 |  |  |
| data_quarter | Nullable(String) | 财务季度 |  | 数据所属财务季度 |  |  |
| data_quarter_name | Nullable(String) | 财务季度 |  | 数据所属财务季度名称 |  |  |
| data_year | Nullable(String) | 财务年 |  | 数据所属财务年 |  |  |
| data_year_name | Nullable(String) | 财务年 |  | 数据所属财务年名称 |  |  |
| division | Nullable(String) | division | 是 | 事业部/性别维度 |  |  |
| product_type | Nullable(String) | product_type | 是 | 产品类型 |  |  |
| framework | Nullable(String) | framework | 是 | 产品框架 |  |  |
| category | Nullable(String) | category | 是 | 品类 |  |  |
| ax_class | Nullable(String) | ax_class | 是 | AX分类 |  |  |
| category_summary | Nullable(String) | 品类归纳 | 是 | 品类汇总/归纳层级 |  |  |
| predictive_buy | Nullable(Int32) | 是否 predictive buy | 是 | 是否 predictive buy：1 表示是，0 表示否 | 1 |  |
| special_supply | Nullable(String) | 待确认 | 是 | 特供标识，具体业务含义待确认 |  |  |
| label | Nullable(String) | label | 是 | 品牌标签 |  |  |
| super_season | Nullable(String) | 待确认 | 是 | 超级季节/大季维度，具体业务含义待确认 |  |  |
| md_type | Nullable(String) | 折扣类型 | 是 | 折扣类型 |  |  |
| computed_product_tag | Nullable(String) | 商品分层标签 | 是 | 商品分层标签，例如：hero model、slow mover、normal | hero model |  |
| currency | Nullable(String) | 币种 |  | 金额字段对应币种 | CNY |  |
| msrp_inv_amt | Nullable(Decimal(19, 5)) | 库存吊牌价金额 |  | 当前库存按吊牌价计算的金额 |  |  |
| md_inv_amt | Nullable(Decimal(19, 5)) | 库存折扣价金额 |  | 当前库存按折扣价计算的金额 |  |  |
| inv_qty | Nullable(Int64) | 库存数量 |  | 当前库存数量 |  |  |
| msrp_in_trans_inv_amt | Nullable(Decimal(19, 5)) | 在途库存吊牌价金额 |  | 在途库存按吊牌价计算的金额 |  |  |
| md_in_trans_inv_amt | Nullable(Decimal(19, 5)) | 在途库存折扣价金额 |  | 在途库存按折扣价计算的金额 |  |  |
| in_trans_inv_qty | Nullable(Int64) | 在途库存数量 |  | 在途库存数量 |  |  |
| msrp_o2o_inv_amt | Nullable(Decimal(19, 5)) | O2O库存吊牌价金额 |  | O2O库存按吊牌价计算的金额 |  |  |
| md_o2o_inv_amt | Nullable(Decimal(19, 5)) | O2O库存折扣价金额 |  | O2O库存按折扣价计算的金额 |  |  |
| o2o_inv_qty | Nullable(Int64) | O2O库存数量 |  | O2O库存数量 |  |  |

## 主键信息

主键字段及排序字段均按以下顺序定义：

`data_date, division, product_type, framework, category, ax_class, category_summary, predictive_buy, special_supply, label, super_season, md_type, computed_product_tag`
