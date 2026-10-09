# a02_e2e_product_performance_sales_summary_d 数据字典

## 表基本信息

| 属性 | 值 |
|------|-----|
| 表名 | a02_e2e_product_performance_sales_summary_d |
| 表注释 | 产品销售汇总表 |
| 是否分区表 | 是 |
| 备注 | 字段、字段类型及主键信息以 ClickHouse 建表语句为准 |

## 字段明细

| 字段名 | 字段类型 | 字段注释 | 是否主键 | 字段说明 | 值示例 | 备注 |
|--------|----------|----------|----------|----------|--------|------|
| etl_time | Nullable(String) | 数据生成时间 |  | 数据记录生成时间 |  |  |
| data_date | Nullable(Date) | 数据日期 | 是 | 数据所属日期 | 2024-03-15 |  |
| data_week | Nullable(String) | 财务周 |  | 数据所属财务周 |  |  |
| data_week_name | Nullable(String) | 财务周 |  | 数据所属财务周名称 |  |  |
| data_month | Nullable(String) | 财务月 |  | 数据所属财务月 |  |  |
| data_month_name | Nullable(String) | 财务月 |  | 数据所属财务月名称 |  |  |
| data_quarter | Nullable(String) | 财务季度 |  | 数据所属财务季度 |  |  |
| data_quarter_name | Nullable(String) | 财务季度 |  | 数据所属财务季度名称 |  |  |
| data_year | Nullable(String) | 财务年 |  | 数据所属财务年 |  |  |
| data_year_name | Nullable(String) | 财务年 |  | 数据所属财务年名称 |  |  |
| platform | Nullable(String) | 平台 |  | 销售平台 |  |  |
| shop_info_id | Nullable(String) | 店铺唯一键 | 是 | 店铺唯一标识 |  |  |
| shop_id | Nullable(String) | 店铺ID |  | 平台侧店铺ID |  |  |
| shop_name | Nullable(String) | 店铺名称 |  | 店铺名称 |  |  |
| shop_name_cn | Nullable(String) | 店铺名称_cn |  | 店铺中文名称 |  |  |
| shop_code | Nullable(String) | 店铺code |  | 店铺编码 |  |  |
| division | Nullable(String) | division | 是 | 事业部/性别维度 |  |  |
| product_type | Nullable(String) | product_type | 是 | 产品类型 |  |  |
| framework | Nullable(String) | framework | 是 | 产品框架 |  |  |
| category | Nullable(String) | category | 是 | 品类 |  |  |
| ax_class | Nullable(String) | ax_class | 是 | AX分类 |  |  |
| category_summary | Nullable(String) | category_summary | 是 | 品类汇总/归纳层级 |  |  |
| special_supply | Nullable(String) | special_supply | 是 | 特供标识，具体业务含义待确认 |  |  |
| predictive_buy | Nullable(Int32) | predictive_buy | 是 | 是否 predictive buy：1 表示是，0 表示否 | 1 |  |
| label | Nullable(String) | label | 是 | 品牌标签 |  |  |
| super_season | Nullable(String) | super_season | 是 | 超级季节/大季维度，具体业务含义待确认 |  | season_final |
| md_type | Nullable(String) | md_type | 是 | 折扣类型 |  |  |
| computed_product_tag | Nullable(String) | computed_product_tag | 是 | 商品分层标签，例如：hero model、slow mover、normal | hero model |  |
| currency | Nullable(String) | 币种 |  | 金额字段对应币种 | CNY |  |
| net_sales_qty | Nullable(Int64) | 出库-入库数量 |  | 出库数量减入库数量后的净销售数量 |  |  |
| net_sales_amt | Nullable(Decimal(19, 5)) | 出库-入库金额 |  | 出库金额减入库金额后的净销售金额 |  |  |
| md_net_sales_amt | Nullable(Decimal(19, 5)) | 出库-入库优惠后金额 |  | 按折扣价计算的净销售金额 |  | md price |
| msrp_net_sales_amt | Nullable(Decimal(19, 5)) | 出库-入库吊牌价金额 |  | 按吊牌价计算的净销售金额 |  | msrp price |
| md_inbound_amt | Nullable(Decimal(19, 5)) | 入库折扣价金额 |  | 入库商品按折扣价计算的金额 |  | md price |
| msrp_inbound_amt | Nullable(Decimal(19, 5)) | 入库吊牌价金额 |  | 入库商品按吊牌价计算的金额 |  | msrp price |
| inbound_qty | Nullable(Int32) | 入库数量 |  | 入库商品数量 |  |  |
| md_outbound_amt | Nullable(Decimal(19, 5)) | 出库折扣价金额 |  | 出库商品按折扣价计算的金额 |  | md price |
| msrp_outbound_amt | Nullable(Decimal(19, 5)) | 出库吊牌价金额 |  | 出库商品按吊牌价计算的金额 |  | msrp price |
| outbound_qty | Nullable(Int64) | 出库数量 |  | 出库商品数量 |  |  |

## 主键信息

主键字段及排序字段均按以下顺序定义：

`data_date, shop_info_id, division, product_type, framework, category, ax_class, category_summary, special_supply, predictive_buy, label, super_season, md_type, computed_product_tag`

## 说明

参考信息中的 `up_net_sales_amt` 字段未包含在本次建表语句中，因此未纳入本数据字典。
