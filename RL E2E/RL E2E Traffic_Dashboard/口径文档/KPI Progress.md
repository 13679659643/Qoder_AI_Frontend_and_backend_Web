# KPI Progress 指标口径提示词

> **Dashboard**: DCom Performance Media Dashboard  
> **Tab**: KPI Progress  
> **数据底表**: `a05_e2e_paid_media_summary_d`  
> **模块说明**: 本板块为 KPI 进度看板，覆盖 KPIs、Performance Indicators、New Acquisition KPI Trend、Category Growth KPI Trend、KPI by Platform 五个子板块，统计媒体花费、销售达成、新客获取、第二品类增长及分平台表现。

---

## 全局逻辑

| 项目 | 内容 |
|---|---|
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **page_type 筛选** | 本板块统一 `page_type="1"` |
| **customer_type 筛选** | 按指标定义区分 `ALL` / `NEW` |
| **分子/分母标记** | Excel 中以 `└ 分子` / `└ 分母` 行标注派生指标的分子分母取数，本文件在各指标中合并展示 |
| **派生指标** | Cost ACH%、Cost vs SLS ACH%、Media Contribution to New Customer Acquisition%、Cost Per New Acquisition、± Acceleration cost MOB% vs. store SLS MOB% 等为派生指标，本身无独立统计字段，依据其分子/分母行取数计算 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |

---

## 子模块一：KPIs

> **无分组维度**: 只受到筛选器影响，没有分组维度，用于制作Powebi卡片图。

### 1. Media Cost Rate — 媒体花费占比

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Cost Rate / 媒体花费占比 |
| **业务定义** | 实际总媒体花费占比退后金额的百分比 |
| **计算公式** | Cost / Net Sales × 1.13 / 1.06 |
| **分子** | `cost_amt（含红包/返佣返货金），字段值本身就含红包、返佣金，所以不需要加额外的计算` |
| **分母** | `net_sales_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 2. Media Cost — 媒体花费

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Cost / 媒体花费 |
| **业务定义** | 实际媒体花费（绝对值） |
| **计算公式** | 同 Cost（实际媒体花费） |
| **统计字段** | `cost_amt（含红包/返佣返货金），字段值本身就含红包、返佣金，所以不需要加额外的计算` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type="1"` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 3. Cost ACH% — 花费进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost ACH% / 花费进度达成 |
| **业务定义** | 目标花费进度达成 |
| **计算公式** | 实际花费 / 计划花费 |
| **统计字段** | `cost_amt / fcst_cost_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 4. Cost vs SLS ACH% — 花费vs销售达成

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost vs SLS ACH% / 花费vs销售达成 |
| **业务定义** | 花费进度达成 vs 销售进度达成差异 |
| **计算公式** | Cost ACH% − SLS ACH% |
| **数据底表** | (3. Cost ACH% — 花费进度达成) 减 (5. SLS ACH% — 目标达成率) |
| **筛选条件** | 派生：Cost ACH% − SLS ACH%，无独立底表取数，根据 Cost ACH% 行和 SLS ACH% 行生成 |
| **数据类型** | delta_bp      → 增减基点整数： → +120bp / -80bp（基点，含正负号，值×100 转 bp）,乘以100的操作可以放在Cell Display度量中实现 |        
| **数据格式** | `+#,##0bp;-#,##0bp;0bp` |

---

### 5. SLS ACH% — 目标达成率

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS ACH% / 目标达成率 |
| **业务定义** | 退后销售额目标达成率 |
| **计算公式** | 实际退后金额 / 计划退后金额（暂时就按fcst_net_sales_amt字段值计算，后续运营也许会直接提供一个百分比的数值再说） |
| **统计字段** | `net_sales_amt / fcst_net_sales_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 6. SLS DCom — 退后销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | SLS DCom / 退后销售额 |
| **业务定义** | 退后销售额 |
| **计算公式** | net_sales_amt 加总 |
| **统计字段** | `net_sales_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type="1"` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 7. Media Contribution to New Customer Acquisition% — 媒体新客贡献率

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Contribution to New Customer Acquisition% / 媒体新客贡献率 |
| **业务定义** | 媒体新客贡献率 |
| **计算公式** | 媒体新客数 / 全店新客数 |
| **统计字段** | `media_member_cnt（new）/ member_cnt（new）` |
| **分子** | `media_member_cnt`（媒体新客数 media_new_customer_no） |
| **分母** | `member_cnt`（全店新客数） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 8. Media Contribution to New Customer Acquisition% vs LY— 媒体新客贡献率（对比去年同期）

| 项目 | 内容 |
|---|---|
| **计算公式** | 和Media Contribution to New Customer Acquisition%逻辑一致，就是 当期值 - 去年同期值 |
| **计算公式** |  当期值 - 去年同期值 |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type="1"` |
| **数据类型** | delta_bp      → 增减基点整数： → +120bp / -80bp（基点，含正负号，值×100 转 bp）,乘以100的操作可以放在Cell Display度量中实现 |        
| **数据格式** | `+#,##0bp;-#,##0bp;0bp` |

---

### 9. Media Contribution to New Customer Acquisition% TRA ACH% — 媒体新客贡献率进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Contribution to New Customer Acquisition% TRA ACH% / 媒体新客贡献率进度达成 |
| **业务定义** | 媒体新客贡献率进度达成 |
| **计算公式** | 媒体新客贡献率/媒体新客目标贡献率 |
| **统计字段** | 媒体新客贡献率：`media_member_cnt（new）/ member_cnt（new）`，媒体新客目标贡献率：2，暂时固定为2 |
| **分子** | 媒体新客贡献率：`media_member_cnt（new）/ member_cnt（new）` |
| **分母** | `2`暂时固定为2，待后续补充口径，再计算实际分母值 |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 10. Media Cost Per New Acquisition — 媒体新客获客成本

| 项目 | 内容 |
|---|---|
| **指标名称** | Cost Per New Acquisition / 媒体新客获客成本 |
| **业务定义** | 总新客花费 / 总媒体新客的数量 |
| **计算公式** | 新客花费 / 媒体新客数 |
| **分子** | `media_cost_amt`（新客花费 media_new_cost） |
| **分母** | `media_member_cnt`（媒体新客数 media_new_customer_no） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type="1"` |
| **数据类型** | currency_decimal_1dp → 货币符号由币种切片器决定，千分位保留一位小数 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） | 

---

### 11. Media Cost Per New Acquisition vs LY — 媒体新客获客成本（对比去年同期）

| 项目 | 内容 |
|---|---|
| **计算公式** | 和Media Cost Per New Acquisition逻辑一致，就是当期值/去年同期值 - 1 |
| **计算公式** | 当期值/去年同期值 - 1 |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 12. Media Cost Per New Acquisition TRA ACH% — 媒体新客获客成本进度达成
| 项目 | 内容 |
|---|---|
| **指标名称** | Media Cost Per New Acquisition TRA ACH% / 媒体新客获客成本进度达成 |
| **业务定义** | 媒体新客获客成本进度达成 |
| **计算公式** | 媒体新客获客成本/媒体新客获客成本目标 |
| **统计字段** | 媒体新客获客成本：`media_cost_amt（new）/ media_member_cnt（new）`，媒体新客获客成本目标：100，暂时固定为100 |
| **分子** | 媒体新客获客成本：`media_cost_amt（new）/ media_member_cnt（new）` |
| **分母** | `100`暂时固定为100，待后续补充口径，再计算实际分母值 |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 13. ± Acceleration cost MOB% vs. store SLS MOB% — 第二品类花费MOB%vs门店销售MOB%

| 项目 | 内容 |
|---|---|
| **指标名称** | ± Acceleration cost MOB% vs. store SLS MOB% / 第二品类花费MOB%vs门店销售MOB% |
| **业务定义** | 第二品类花费占比 vs 门店销售占比 |
| **计算公式** | Acceleration Cost MOB% − Store SLS MOB%（×100 转为 bp） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **Acceleration Cost MOB%计算公式** | `cost_amt（framework='Acceleration'）/ cost_amt（全部 framework）` |
| **Store SLS MOB%计算** | `net_sales_amt（framework='Acceleration'）/ net_sales_amt（全部 framework）` |
| **筛选条件** | `customer_type='ALL' AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 14. ± Acceleration cost MOB% vs. store SLS MOB% vs LY — 第二品类花费MOB%vs门店销售MOB%（对比去年同期）

| 项目 | 内容 |
|---|---|
| **计算公式** | 和± Acceleration cost MOB% vs. store SLS MOB%逻辑一致，就是 当期值 - 去年同期值 |
| **计算公式** | 当期值 - 去年同期值 |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type="1"` |
| **数据类型** | delta_bp      → 增减基点整数： → +120bp / -80bp（基点，含正负号，值×100 转 bp）,乘以100的操作可以放在Cell Display度量中实现 |        
| **数据格式** | `+#,##0bp;-#,##0bp;0bp` |

---

### 15. ± Acceleration SLS MOB% vs. store SLS MOB% TRA ACH% — 第二品类退后销售额MOB%vs门店销售MOB%进度达成
| 项目 | 内容 |
|---|---|
| **指标名称** | ± Acceleration SLS MOB% vs. store SLS MOB% TRA ACH% / 第二品类退后销售额MOB%vs门店销售MOB%进度达成 |
| **业务定义** | 第二品类退后销售额MOB%vs门店销售MOB%进度达成 |
| **计算公式** | 第二品类退后销售额MOB%vs门店销售MOB%/目标 |
| **目标** | 2，暂时固定为2 |
| **统计字段** | 第二品类退后销售额MOB%vs门店销售MOB%：`net_sales_amt（framework='Acceleration'）/ net_sales_amt（全部 framework）` ，目标：2 ，暂时固定为2|
| **分子** | 第二品类退后销售额MOB%vs门店销售MOB%：`net_sales_amt（framework='Acceleration'）/ net_sales_amt（全部 framework）` |   
| **分母** | `2`暂时固定为2，待后续补充口径，再计算实际分母值 |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 子模块二：Performance Indicators

### 16. New Customer No — 新客数量

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer No / 新客数量 |
| **业务定义** | 店铺新客数 |
| **计算公式** | COUNT DISTINCT 买家id（全店新客） |
| **统计字段** | `1`暂时固定为1，待后续补充口径，再计算实际值 |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type="1"` |
| **数据类型** | integer → 整数，千分位整数 |
| **数据格式** | `#,##0` |

---

### 17. New Customer No vs LY — 新客数量（对比去年同期）

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer No vs LY / 新客数量（对比去年同期） |
| **业务定义** | 店铺新客数 |
| **计算公式** | COUNT DISTINCT 买家id（全店新客） |
| **统计字段** | `1`暂时固定为1，待后续补充口径，再计算实际值 |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 18. New Customer No TRA ACH% — 新客数量进度达成

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer No TRA ACH% / 新客数量进度达成 |
| **业务定义** | 新客数量进度达成 |
| **计算公式** | 新客数量/新客数量目标 |
| **统计字段** | 新客数量：`1`，新客数量目标：1，暂时固定为1 |
| **分子** | COUNT DISTINCT 买家id（全店新客），暂时固定为1，待后续补充口径，再计算实际值  |
| **分母** | `1`暂时固定为1，待后续补充口径，再计算实际值 | 
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 19. Acceleration SLS — 第二品类退后销售额

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration SLS / 第二品类退后销售额 |
| **业务定义** | 第二品类退后销售额 |
| **计算公式** | Net Sales（framework='Acceleration'） |
| **统计字段** | `net_sales_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND framework='Acceleration' AND page_type="1"` |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 20. Acceleration SLS vs LY — 第二品类退后销售额（对比去年同期）

| 项目 | 内容 |
|---|---|
| **计算公式** | 和Acceleration SLS逻辑一致，就是当期值/去年同期值 - 1 |
| **计算公式** | 当期值/去年同期值 - 1 |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND framework='Acceleration' AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 21. Acceleration SLS TRA ACH% — 第二品类退后销售额进度达成
| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration SLS TRA ACH% / 第二品类退后销售额进度达成 |
| **业务定义** | 第二品类退后销售额进度达成 |
| **计算公式** | 第二品类退后销售额/第二品类退后销售额目标 |
| **统计字段** | 第二品类退后销售额：`net_sales_amt（framework='Acceleration'）`，第二品类退后销售额目标：10000，暂时固定为10000 |
| **分子** | 第二品类退后销售额：`net_sales_amt（framework='Acceleration'）` |
| **分母** | `10000`暂时固定为10000，待后续补充口径，再计算实际分母值 | 
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND framework='Acceleration' AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 22. Acceleration SLS MOB% — 第二品类退后销售额MOB%

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration SLS MOB% / 第二品类退后销售额MOB% |
| **业务定义** | 第二品类退后销售额占比 |
| **计算公式** | Acceleration SLS / TTL SLS |
| **分子** | `net_sales_amt`（Acceleration 退后销售额） |
| **分母** | `net_sales_amt`（TTL 退后销售额，全部 framework） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='ALL' AND framework='Acceleration' AND page_type="1"`；分母：`customer_type='ALL' AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

### 23. Acceleration SLS MOB% vs LY — 第二品类退后销售额MOB%（对比去年同期）

| 项目 | 内容 |
|---|---|
| **计算公式** | 和Acceleration SLS MOB%逻辑一致，就是当期值/去年同期值 - 1 |
| **计算公式** | 当期值占比 - 去年同期占比 |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子：`customer_type='ALL' AND framework='Acceleration' AND page_type="1"`；分母：`customer_type='ALL' AND page_type="1"` |
| **数据类型** | delta_bp      → 增减基点整数： → +120bp / -80bp（基点，含正负号，值×100 转 bp）,乘以100的操作可以放在Cell Display度量中实现 |        
| **数据格式** | `+#,##0bp;-#,##0bp;0bp` |

---

### 24. Acceleration SLS MOB% TRA ACH% — 第二品类退后销售额MOB%进度达成
| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration SLS MOB% TRA ACH% / 第二品类退后销售额MOB%进度达成 |
| **业务定义** | 第二品类退后销售额MOB%进度达成 |
| **计算公式** | 第二品类退后销售额MOB%/目标 |
| **统计字段** | 第二品类退后销售额MOB%：`net_sales_amt（framework='Acceleration'）/ net_sales_amt（全部 framework）`，目标：2，暂时固定为2 |
| **分子** | 第二品类退后销售额MOB%：`net_sales_amt（framework='Acceleration'）/ net_sales_amt（全部 framework）` |
| **分母** | `2`暂时固定为2，待后续补充口径，再计算实际分母值 |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type="1"` |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |

---

## 子模块三：New Acquisition KPI Trend

### 25. New Customer No. — 新客数量（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer No / 新客数量 |
| **业务定义** | 店铺新客数 |
| **计算公式** | COUNT DISTINCT 买家id（全店新客） |
| **统计字段** | `1`暂时固定为1，待后续补充口径，再计算实际值 |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type="1"` |
| **数据类型** | currency_M_K_Int_0db → 货币符号由币种切片器决定，千分位整数,需要在Cell Display度量中拼接币种符号，需要判断是否带K、M、或者就是千分位整数，如果值小于1000，就直接表示为千分位整数，如果值大于等于1000，就表示为带K、M的格式，1K为一千，1M为一百万，都采用千分位的格式 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 26. New Customer% — 新客占比（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | New Customer% / 新客占比 |
| **业务定义** | 新客占比趋势 |
| **计算公式** | New Customer No / TTL Buyers |
| **分子** | `member_cnt`（new），`1`暂时固定为1，待后续补充口径，再计算实际值 |
| **分母** | `member_cnt`（all），`2`暂时固定为2，待后续补充口径，再计算实际值 |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | 分子 `customer_type='NEW' AND page_type="1"`；分母 `customer_type='ALL' AND page_type="1"` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%;#,##0%;0%` |

---

### 27. Media Contribution to New Customer Acquisition% — 媒体新客贡献率（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Contribution to New Customer Acquisition% / 媒体新客贡献率 |
| **业务定义** | 新客贡献率趋势 |
| **计算公式** | 媒体新客数 / 全店新客数（趋势图） |
| **统计字段** | `media_member_cnt（new）/ member_cnt（new）` |
| **分子** | `media_member_cnt`（new），`1`暂时固定为1，待后续补充口径，再计算实际值 |
| **分母** | `member_cnt`（all），`3`暂时固定为3，待后续补充口径，再计算实际值 |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type="1"` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%;#,##0%;0%` |

---

## 子模块四：Category Growth KPI Trend

### 28. Acceleration SLS — 第二品类退后销售额（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration SLS / 第二品类退后销售额 |
| **业务定义** | 第二品类退后销售额趋势 |
| **计算公式** | Net Sales（framework='Acceleration'，趋势图） |
| **统计字段** | `net_sales_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND framework='Acceleration' AND page_type="1"` |
| **数据类型** | currency_M_K_Int_0db → 货币符号由币种切片器决定，千分位整数,需要在Cell Display度量中拼接币种符号，需要判断是否带K、M、或者就是千分位整数，如果值小于1000，就直接表示为千分位整数，如果值大于等于1000，就表示为带K、M的格式，1K为一千，1M为一百万，都采用千分位的格式 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |

---

### 29. Acceleration SLS MOB% — 第二品类退后销售额MOB%（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration SLS MOB% / 第二品类退后销售额MOB% |
| **业务定义** | 第二品类退后销售额 MOB% 趋势 |
| **计算公式** | Acceleration SLS / TTL SLS（趋势图） |
| **统计字段** | `net_sales_amt（framework='Acceleration'）/ net_sales_amt（全部 framework）` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type="1"` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%;#,##0%;0%` |

---

### 30. Acceleration Cost MOB% — 第二品类花费MOB%（趋势）

| 项目 | 内容 |
|---|---|
| **指标名称** | Acceleration Cost MOB% / 第二品类花费MOB% |
| **业务定义** | 第二品类花费 MOB% 趋势 |
| **计算公式** | Acceleration Cost / TTL Cost（趋势图） |
| **统计字段** | `cost_amt（framework='Acceleration'）/ cost_amt（全部 framework）` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type="1"` |
| **数据类型** | percent_0dp → 百分比整数，不含正号 |
| **数据格式** | `#,##0%;#,##0%;0%` |

---

## 子模块五：KPI by Platform

> **分组维度**: 按 `platform` 分组，Slicer_Platform_Selection 1:* ──→ a05_e2e_paid_media_summary_d[platform]

### 19. Media Cost Rate — 费比（分平台）

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Cost Rate / 费比 |
| **业务定义** | 各平台费比 |
| **计算公式** | Cost / SLS × 1.13 / 1.06|
| **统计字段** | `cost_amt / net_sales_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type="1"`，按 platform 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |
| **相关字段格式** | 去年同期值(Media Cost Rate vs LP)：percent_1dp、同比(YOY%)：percent_1dp |

---

### 20. Media Cost — 媒体花费（分平台）

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Cost / 媒体花费 |
| **业务定义** | 各平台实际媒体花费 |
| **计算公式** | 同 Cost（实际媒体花费），按 platform 分组 |
| **统计字段** | `cost_amt` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='ALL' AND page_type="1"`，按 platform 分组 |
| **数据类型** | currency → 货币符号由币种切片器决定，千分位整数 |
| **数据格式** | `#,##0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0")` 拼接币种符号） |
| **相关字段格式** | 去年同期值(Media Cost vs LP)：currency、(YOY% )：percent_1dp |

---

### 21. ± Acceleration cost MOB% vs. store SLS MOB% — 第二品类花费MOB%vs门店销售MOB%（分平台）

| 项目 | 内容 |
|---|---|
| **指标名称** | ± Acceleration cost MOB% vs. store SLS MOB% / 第二品类花费MOB%vs门店销售MOB% |
| **业务定义** | 各平台第二品类花费 MOB% vs 门店销售 MOB% |
| **计算公式** | Acceleration Cost MOB% − Store SLS MOB%（by platform，bp） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **Acceleration Cost MOB%计算公式** | `cost_amt（framework='Acceleration'）/ cost_amt（全部 framework）` |
| **Store SLS MOB%计算** | `net_sales_amt（framework='Acceleration'）/ net_sales_amt（全部 framework）` |
| **筛选条件** | `customer_type='ALL' AND page_type="1"`，按 platform 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |
| **相关字段格式** | 去年同期值(± Acceleration cost MOB% vs. store SLS MOB% vs LP)：percent_1dp、(YOY%  )：percent_1dp |

---

### 22. Media Contribution to New Customer Acquisition% — 媒体新客贡献率（分平台）

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Contribution to New Customer Acquisition% / 媒体新客贡献率 |
| **业务定义** | 各平台媒体新客贡献率 |
| **计算公式** | 媒体新客数 / 全店新客数（by platform） |
| **统计字段** | `media_member_cnt（new）/ member_cnt（new）` |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type="1"`，按 platform 分组 |
| **数据类型** | percent_1dp → 百分比，保留一位小数，不含正号 |
| **数据格式** | `#,##0.0%;#,##0.0%;0.0%` |
| **相关字段格式** | 去年同期值(Media Contribution to New Customer Acquisition% vs LP)：percent_1dp、(YOY%   )：percent_1dp |

---

### 23. Media Cost Per New Acquisition — 媒体新客获客成本（分平台）

| 项目 | 内容 |
|---|---|
| **指标名称** | Media Cost Per New Acquisition / 媒体新客获客成本 |
| **业务定义** | 各平台媒体新客获客成本 |
| **计算公式** | 新客花费 / 媒体新客数（by platform） |
| **分子** | `media_cost_amt`（新客花费 media_new_cost） |
| **分母** | `media_member_cnt`（媒体新客数 media_new_customer_no） |
| **数据底表** | `a05_e2e_paid_media_summary_d` |
| **筛选条件** | `customer_type='NEW' AND page_type="1"`，按 platform 分组 |
| **数据类型** | currency_decimal_1dp → 货币符号由币种切片器决定，千分位保留一位小数 |
| **数据格式** | `#,##0.0`（在 DAX 中用 `__CurrencySymbol & FORMAT(__Value, "#,##0.0")` 拼接币种符号） | 
| **相关字段格式** | 去年同期值(Media Cost Per New Acquisition vs LP)：currency_decimal_1dp、(YOY%    )：percent_1dp |

| **子模块五：15个指标汇总** | Media Cost Rate、Media Cost Rate vs LP、YOY%、Media Cost、Media Cost vs LP、YOY%、Cost ACH%、Cost ACH% vs LP、YOY%、Cost vs SLS ACH%、Cost vs SLS ACH% vs LP、YOY%、± Acceleration cost MOB% vs. store SLS MOB%、± Acceleration cost MOB% vs. store SLS MOB% vs LP、YOY%、Media Contribution to New Customer Acquisition%、Media Contribution to New Customer Acquisition% vs LP、YOY%、Cost Per New Acquisition、Cost Per New Acquisition vs LP、YOY% |

---

## 通用规则汇总

| 规则项 | 说明 |
|---|---|
| **数据底表** | 全部指标统一使用 `a05_e2e_paid_media_summary_d` |
| **page_type** | 本板块统一 `page_type="1"` |
| **customer_type** | 按指标区分 `ALL`（全客）或 `NEW`（新客） |
| **派生指标** | Cost vs SLS ACH%、± Acceleration cost MOB% vs. store SLS MOB% 为派生差值，无独立底表取数 |
| **分平台维度** | 子模块五 KPI by Platform 按 `platform` 字段分组 |
| **framework 筛选** | 第二品类（Acceleration）相关指标需叠加 `framework='Acceleration'` 筛选 |
| **必须遵守** | 口径文档中定义的所有指标，必须遵守其数据类型和数据格式，如果和解决方案中存在争议的，一切以口径文档为准，必须按照口径文档中的格式进行调整 |
| **DAX 语法规范** | 文本常量必须使用双引号 `" "`，禁止使用单引号；单引号 `' '` 仅用于表名，列名使用方括号 `[ ]`，例如：`[framework] = "Acceleration"` |
