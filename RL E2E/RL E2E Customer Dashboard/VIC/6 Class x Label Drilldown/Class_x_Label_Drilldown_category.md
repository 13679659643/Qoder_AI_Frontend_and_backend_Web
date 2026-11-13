# Power BI 解决方案 — Class x Label Drilldown（category 维度，仅度量实现）

> status: ready
> created: 2026-11-12
> type: 度量值开发（category 维度变体）
> 派生自: 本目录 Class_x_Label_Drilldown_list.md（category_summary 维度方案）
> 口径来源: 口径文档/VIC/Class x Label Drilldown.md（4 个 VIC No. 指标）
> 分组维度: `t05_customer_order_data_d[category]`（category，String）替代原方案的 `t05_customer_order_data_d[category_summary]`（品类归纳）
> 本文件仅包含度量实现部分；需求理解 / 方案设计 / 视觉配置 / 验证方法见原方案文件
> 度量命名红线: 原方案既有度量值一律不改名、不重建（Power BI 页面配置绑定度量值名称）；category 维度仅新增 3 个 MAXX 辅助度量

---

## 4. 度量值实现

### 4.1 对外 Value 层 — 4 个独立度量值（完全复用，无需新建、无需修改）

原方案 4 个 Value 度量的 DAX 中**不包含任何 `category_summary` 引用**：分组维度由视觉对象（条形图轴 / 表格行）直接拉取 `t05_customer_order_data_d[category]` 字段自动传递筛选，DAX 无需显式处理分组。因此轴从 `category_summary` 换成 `category` 时，Value 度量计算逻辑完全一致，直接复用。

| 序号 | 度量值名称                            | Display Folder | 状态 |
| ---- | ------------------------------------- | -------------- | ---- |
| 1    | VIC No. (Net_Retention VIC) Value    | Cell Values    | 复用（DAX 与原方案 §4.1.1 逐字一致） |
| 2    | VIC No. (Net_T4-5 Upgrade) Value     | Cell Values    | 复用（DAX 与原方案 §4.1.2 逐字一致） |
| 3    | VIC No. (Net_Direct VIC) Value       | Cell Values    | 复用（DAX 与原方案 §4.1.3 逐字一致） |
| 4    | VIC No. (Net_New VIC) Value          | Cell Values    | 复用（DAX 与原方案 §4.1.4 逐字一致） |

> - 模型中已创建 → 直接拉取既有度量值
> - 模型中尚未创建 → 按原方案 Class_x_Label_Drilldown_list.md §4.1.1–4.1.4 的 DAX 逐字创建（两步法：Step1 a03 end period + VIC 标识框定 user_id；Step2 t05 全局时间范围 + TREATAS 传递 + DISTINCTCOUNT）
> - 不要在 category 视觉上新建同名或变体 Value 度量

### 4.2 对外 Display 层 — 4 个独立度量值（完全复用，无需新建、无需修改）

与 Value 层同理，Display 度量仅做 `#,##0` 格式化，不含分组维度引用。

| 序号 | 度量值名称                            | Display Folder | 状态 |
| ---- | ------------------------------------- | -------------- | ---- |
| 1    | VIC No. (Net_Retention VIC) Display  | Formatting      | 复用（DAX 与原方案 §4.2.1 逐字一致） |
| 2    | VIC No. (Net_T4-5 Upgrade) Display   | Formatting      | 复用（DAX 与原方案 §4.2.2 逐字一致） |
| 3    | VIC No. (Net_Direct VIC) Display     | Formatting      | 复用（DAX 与原方案 §4.2.3 逐字一致） |
| 4    | VIC No. (Net_New VIC) Display        | Formatting      | 复用（DAX 与原方案 §4.2.4 逐字一致） |

### 4.3 辅助度量值 — 3 个新度量值（category 维度专用，需新建）

原方案 §4.3 的 MAXX 辅助度量（用于条形图条件格式 / 数据条上限计算）显式迭代 `ALL(t05_customer_order_data_d[category_summary])`。category 维度条形图需要按 `ALL(t05_customer_order_data_d[category])` 取全轴最大值，原度量不可复用、不可改名，必须新建 3 个对应度量（名称追加 "(Category)" 后缀，与原度量并存）。

#### 4.3.1 MAXX Retention VIC (Category)

```dax
MAXX Retention VIC (Category) = 
// ========================================
// 度量值: MAXX Retention VIC (Category)
// 用途: 留存VIC数量在 category 全轴上的最大值（category 维度条形图条件格式基准）
// 依赖: [VIC No. (Net_Retention VIC) Value], t05_customer_order_data_d[category]
// 对应原方案度量: MAXX Retention VIC（category_summary 维度，保持不变）
// ========================================
MAXX(ALL(t05_customer_order_data_d[category]),[VIC No. (Net_Retention VIC) Value])
```

#### 4.3.2 MAXX T4-5 Upgrade VIC (Category)

```dax
MAXX T4-5 Upgrade VIC (Category) = 
// ========================================
// 度量值: MAXX T4-5 Upgrade VIC (Category)
// 用途: T4-5升级VIC数量在 category 全轴上的最大值（category 维度条形图条件格式基准）
// 依赖: [VIC No. (Net_T4-5 Upgrade) Value], t05_customer_order_data_d[category]
// 对应原方案度量: MAXX T4-5 Upgrade VIC（category_summary 维度，保持不变）
// ========================================
MAXX(ALL(t05_customer_order_data_d[category]),[VIC No. (Net_T4-5 Upgrade) Value])
```

#### 4.3.3 MAXX Direct VIC (Category)

```dax
MAXX Direct VIC (Category) = 
// ========================================
// 度量值: MAXX Direct VIC (Category)
// 用途: 直接买成VIC数量在 category 全轴上的最大值（category 维度条形图条件格式基准）
// 依赖: [VIC No. (Net_Direct VIC) Value], t05_customer_order_data_d[category]
// 对应原方案度量: MAXX Direct VIC（category_summary 维度，保持不变）
// ========================================
MAXX(ALL(t05_customer_order_data_d[category]),[VIC No. (Net_Direct VIC) Value])
```

> 原方案 §4.3 仅含 3 个 MAXX 度量（无 Net_New VIC 版本），本方案按原结构镜像，同为 3 个。

### 4.4 度量值清单与 Display Folder

| 序号 | 度量值名称                              | Display Folder | 用途                                             | 新建/复用 |
| ---- | --------------------------------------- | --------------- | ------------------------------------------------ | ---------- |
| 1    | VIC No. (Net_Retention VIC) Value      | Cell Values     | 留存VIC数量（对外值，两步法）                    | 复用       |
| 2    | VIC No. (Net_T4-5 Upgrade) Value       | Cell Values     | T4-5升级VIC数量（对外值，两步法）                | 复用       |
| 3    | VIC No. (Net_Direct VIC) Value         | Cell Values     | 直接买成VIC数量（对外值，两步法）                | 复用       |
| 4    | VIC No. (Net_New VIC) Value            | Cell Values     | 新VIC数量（对外值，两步法）                      | 复用       |
| 5    | VIC No. (Net_Retention VIC) Display   | Formatting       | 留存VIC数量格式化显示（#,##0）                   | 复用       |
| 6    | VIC No. (Net_T4-5 Upgrade) Display    | Formatting       | T4-5升级VIC数量格式化显示（#,##0）               | 复用       |
| 7    | VIC No. (Net_Direct VIC) Display      | Formatting       | 直接买成VIC数量格式化显示（#,##0）               | 复用       |
| 8    | VIC No. (Net_New VIC) Display         | Formatting       | 新VIC数量格式化显示（#,##0）                     | 复用       |
| 9    | MAXX Retention VIC (Category)         | （同原 MAXX 度量摆放位置） | category 全轴留存VIC最大值（条件格式基准） | 新建       |
| 10   | MAXX T4-5 Upgrade VIC (Category)       | （同原 MAXX 度量摆放位置） | category 全轴T4-5升级VIC最大值（条件格式基准） | 新建 |
| 11   | MAXX Direct VIC (Category)             | （同原 MAXX 度量摆放位置） | category 全轴直接买成VIC最大值（条件格式基准） | 新建   |

### 4.5 与原方案（category_summary 维度）度量实现差异

| 差异点 | 原方案（category_summary）                        | 本方案（category）                                          | 是否需要改动 |
| ------ | ------------------------------------------------- | ------------------------------------------------------------ | ------------ |
| 4 个 Value 度量 | DAX 无 category_summary 引用，分组由视觉轴自动传递 | 计算逻辑不变，轴字段换成 t05[category] 后自动按新维度分组    | 否（复用）   |
| 4 个 Display 度量 | 仅 #,##0 格式化                                   | 不变                                                         | 否（复用）   |
| 3 个 MAXX 辅助度量 | `MAXX(ALL(t05[category_summary]), [Value])`      | `MAXX(ALL(t05[category]), [Value])`，新建度量名追加 "(Category)" | 是（新建 3 个） |
| 条形图轴 / 表格行 | t05[category_summary]                             | t05[category]                                                 | 是（视觉配置，非度量 DAX） |
| 其余筛选逻辑（end period / 全局时间范围 / TREATAS / is_member / is_employee / register_date 哨兵模式） | — | 全部不变                                                     | 否           |

> 注意：原 3 个 MAXX 度量（`MAXX Retention VIC` 等）服务于 category_summary 条形图，保持原样不动；category 条形图的条件格式改拉取本方案新增的 "(Category)" 后缀度量。若两图同页共存，各用各的 MAXX 基准，互不影响。
