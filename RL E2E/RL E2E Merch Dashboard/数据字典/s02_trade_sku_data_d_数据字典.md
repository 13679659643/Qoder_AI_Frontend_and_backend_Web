# s02_trade_sku_data_d 数据字典

## 表基本信息

| 属性 | 值 |
|------|-----|
| 表名 | s02_trade_sku_data_d |
| 表注释 | sku粒度交易数据轻度聚合表 |
| 是否分区表 | 是 |
| 数据更新方式 | 全量 |
| 存储引擎 | CnchMergeTree |
| 备注 | 字段、字段类型、默认值及唯一键信息以 ClickHouse 建表语句为准；是否分区表及数据更新方式来自原始数据字典 |

## 字段明细

| 字段名 | 字段类型 | 字段注释 | 是否主键 | 字段说明 | 值示例 | 备注 |
|--------|----------|----------|----------|----------|--------|------|
| etl_time | Nullable(String) | etl时间 |  | 数据ETL生成时间 |  | 默认值为 `now()` |
| dt | Nullable(String) | 数据日期（出入库时间） | 是 | 订单出入库日期 | 2002-01-01 | 唯一键字段 |
| order_type | Nullable(String) | 出入库类型名称 | 是 | 订单出入库类型，包括：销售出库、退货入库、换货出库、换货入库 | 销售出库 | 唯一键字段 |
| order_pay_date_tb | Nullable(Date) | 订单付款时间 | 是 | 订单付款日期 |  | 唯一键字段 |
| sku_id | Nullable(String) | sku_id | 是 | SKU唯一标识 |  | 唯一键字段 |
| spu_id | Nullable(String) | spu_id |  | SPU唯一标识 |  |  |
| shop_info_id | Nullable(String) | 店铺唯一键 | 是 | 店铺唯一标识 |  | 唯一键字段 |
| shop_id | Nullable(String) | 店铺ID |  | 平台侧店铺ID |  |  |
| shop_name | Nullable(String) | 店铺名称 |  | 店铺名称 |  |  |
| shop_name_cn | Nullable(String) | 店铺名称cn |  | 店铺中文名称 |  |  |
| shop_code | Nullable(String) | 店铺CODE |  | 店铺编码 |  |  |
| platform | Nullable(String) | 平台名称 |  | 交易平台名称 |  |  |
| brand | Nullable(String) | Label |  | 品牌标签 | CW |  |
| division | Nullable(String) | Division |  | 事业部/性别维度 | Childrens |  |
| framework | Nullable(String) | category framework |  | 品类框架 |  |  |
| category | Nullable(String) | category |  | 品类 |  |  |
| category_summary | Nullable(String) | category_summary |  | 品类汇总/归纳层级 |  |  |
| ax_class | Nullable(String) | ax_class |  | AX分类 |  |  |
| ax_sub_class | Nullable(String) | ax_sub_class |  | AX子分类 |  |  |
| special_supply | Nullable(String) | special_supply |  | 特供标识 |  |  |
| special_series | Nullable(String) | special_series |  | 特别系列 |  |  |
| spu_model | Nullable(String) | spu_model |  | SPU款号/模型 |  |  |
| sku_size | Nullable(String) | sku_size |  | SKU尺码 |  |  |
| sku_size_category | Nullable(String) | sku_size_category |  | SKU尺码分类 |  |  |
| spu_img_url | Nullable(String) | 商品图片 |  | SPU商品图片链接 |  |  |
| us_style | Nullable(String) | us_style |  | US款号/风格标识 |  |  |
| color_code | Nullable(String) | color_code |  | 颜色编码 |  |  |
| color_name | Nullable(String) | 颜色名称 |  | 颜色名称 |  |  |
| season | Nullable(String) | AX Season |  | AX季节 |  |  |
| super_season | Nullable(String) | 跨年季节标签 |  | 跨季节/大季维度 |  | season_final |
| product_type | Nullable(String) | product_type |  | 产品类型 |  |  |
| predictive_buy | Nullable(Int32) | predictive_buy |  | 是否 predictive buy：1 表示是，0 表示否 | 1 |  |
| equity_fund | Nullable(Decimal(19, 4)) | 权益金 |  | 订单权益金金额 |  |  |
| freight_fee | Nullable(Decimal(19, 4)) | 运费 |  | 订单运费金额 |  |  |
| packing_charges | Nullable(Decimal(19, 4)) | 包装费 |  | 订单包装费金额 |  |  |
| affiliated_amount | Nullable(Decimal(19, 4)) | 定制费 |  | 订单定制费金额 |  |  |
| line_expenses_tax | Nullable(Decimal(19, 4)) | 海外税金 |  | 订单海外税金金额 |  |  |
| product_qty | Nullable(Int32) | 商品购买数量 |  | 商品购买数量 |  |  |
| sales_price | Nullable(Decimal(19, 4)) | 销售价格 |  | 商品实际销售价格 |  |  |
| msrp | Nullable(Decimal(19, 4)) | 吊牌价 |  | 商品吊牌价 |  |  |
| md_price | Nullable(Decimal(19, 4)) | MD 折扣价 |  | 商品折扣价 |  |  |
| md_tag_original | Nullable(String) | MDtag |  | 原始MD标签 |  |  |
| md_type_original | Nullable(String) | 原始 MD type |  | 原始折扣类型 |  |  |
| ltd_sales_amt | Nullable(Decimal(19, 4)) | 开店至今总金额 |  | 店铺开店至今累计销售金额 |  |  |
| ltd_sales_qty | Nullable(Int32) | 开店至今总数量 |  | 店铺开店至今累计销售数量 |  |  |

## 唯一键信息

建表语句未显式定义 `PRIMARY KEY`，定义了以下唯一键：

`dt, order_type, order_pay_date_tb, shop_info_id, sku_id`

排序键 `ORDER BY` 同样按以下顺序定义：

`dt, order_type, order_pay_date_tb, shop_info_id, sku_id`

## 说明

1. 字段及类型以建表语句为准；原始字典中的 `order_pay_date_tb`、`shop_info_id` 字段类型及金额字段精度与建表语句不一致，已按建表语句修正。
2. 原始数据字典标注该表为分区表且更新方式为全量；建表语句未展示 `PARTITION BY` 表达式。
