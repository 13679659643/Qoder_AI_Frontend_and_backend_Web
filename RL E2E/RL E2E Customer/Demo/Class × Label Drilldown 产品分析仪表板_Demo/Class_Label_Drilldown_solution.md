# Power BI 报表解决方案 — Class × Label Drilldown 产品分析仪表板

> status: complete
> created: 2026-06-29
> complexity: 中等
> type: 数据建模 + 可视化 + 交互设计

---

## 目录

1. [模拟数据](#1-模拟数据)
2. [数据模型关系图](#2-数据模型关系图)
3. [DAX 度量值（完整带注释）](#3-dax-度量值)
4. [字段参数配置（Trade / Direct 切换）](#4-字段参数配置)
5. [编辑交互设置（中间列表不联动）](#5-编辑交互设置)
6. [报表布局与视觉对象配置](#6-报表布局与视觉对象配置)
7. [完整交互逻辑说明](#7-完整交互逻辑说明)

---

## 1. 模拟数据

### 表1：N Dim_Product（产品维度表，60行）

| ProductID | ProductName | ProductImageURL | Class | Label | Tier |
|-----------|-------------|-----------------|-------|-------|------|
| CWPO2STF8520001 | Oxford Cotton Shirt | https://example.com/img/shirt_01.jpg | Shirt | CLASSIC | A |
| CWPO2STF8520002 | Slim Fit Poplin | https://example.com/img/shirt_02.jpg | Shirt | ESSENTIALS | B |
| CWPO2STF8520003 | Flannel Plaid Shirt | https://example.com/img/shirt_03.jpg | Shirt | SPORT | C |
| CWPO2STF8520004 | Linen Button-Down | https://example.com/img/shirt_04.jpg | Shirt | LUXE | A |
| CWPO2STF8520005 | Denim Casual Shirt | https://example.com/img/shirt_05.jpg | Shirt | ESSENTIALS | B |
| CWPO2STF8520006 | Silk Wrap Dress | https://example.com/img/dress_01.jpg | Dresses | LUXE | A |
| CWPO2STF8520007 | Floral Maxi Dress | https://example.com/img/dress_02.jpg | Dresses | CLASSIC | B |
| CWPO2STF8520008 | Cocktail Mini Dress | https://example.com/img/dress_03.jpg | Dresses | SPORT | C |
| CWPO2STF8520009 | Midi Wrap Dress | https://example.com/img/dress_04.jpg | Dresses | ESSENTIALS | A |
| CWPO2STF8520010 | Evening Gown | https://example.com/img/dress_05.jpg | Dresses | LUXE | B |
| CWPO2STF8520011 | Classic Polo | https://example.com/img/polo_01.jpg | Polo Shirt | POLO | A |
| CWPO2STF8520012 | Striped Polo | https://example.com/img/polo_02.jpg | Polo Shirt | POLO | B |
| CWPO2STF8520013 | Sport Performance Polo | https://example.com/img/polo_03.jpg | Polo Shirt | POLO | A |
| CWPO2STF8520014 | Pique Cotton Polo | https://example.com/img/polo_04.jpg | Polo Shirt | POLO | C |
| CWPO2STF8520015 | Merino Wool Sweater | https://example.com/img/sweater_01.jpg | Sweater | CLASSIC | A |
| CWPO2STF8520016 | Cashmere V-Neck | https://example.com/img/sweater_02.jpg | Sweater | LUXE | A |
| CWPO2STF8520017 | Cable Knit Pullover | https://example.com/img/sweater_03.jpg | Sweater | ESSENTIALS | B |
| CWPO2STF8520018 | Crewneck Wool Sweater | https://example.com/img/sweater_04.jpg | Sweater | CLASSIC | B |
| CWPO2STF8520019 | Hand-Knit Cardigan | https://example.com/img/knit_01.jpg | Knit | CLASSIC | A |
| CWPO2STF8520020 | Mohair Blend Knit | https://example.com/img/knit_02.jpg | Knit | LUXE | B |
| CWPO2STF8520021 | Cropped Knit Top | https://example.com/img/knit_03.jpg | Knit | SPORT | C |
| CWPO2STF8520022 | Leather Tote Bag | https://example.com/img/bag_01.jpg | Handbags | LUXE | A |
| CWPO2STF8520023 | Canvas Crossbody | https://example.com/img/bag_02.jpg | Handbags | ESSENTIALS | B |
| CWPO2STF8520024 | Mini Clutch | https://example.com/img/bag_03.jpg | Handbags | SPORT | C |
| CWPO2STF8520025 | Tailored Wool Trouser | https://example.com/img/pant_01.jpg | Pant | CLASSIC | A |
| CWPO2STF8520026 | Slim Chino Pant | https://example.com/img/pant_02.jpg | Pant | ESSENTIALS | B |
| CWPO2STF8520027 | Cargo Utility Pant | https://example.com/img/pant_03.jpg | Pant | SPORT | C |
| CWPO2STF8520028 | Wool Overcoat | https://example.com/img/outer_01.jpg | Outerwear | LUXE | A |
| CWPO2STF8520029 | Puffer Jacket | https://example.com/img/outer_02.jpg | Outerwear | SPORT | B |
| CWPO2STF8520030 | Pleated Midi Skirt | https://example.com/img/skirt_01.jpg | Skirt | CLASSIC | A |
| CWPO2STF8520031 | Turtleneck Cashmere | https://example.com/img/knit_04.jpg | Knit | LUXE | A |
| CWPO2STF8520032 | Angora Knit Vest | https://example.com/img/knit_05.jpg | Knit | CLASSIC | B |
| CWPO2STF8520033 | Belted Trench Coat | https://example.com/img/outer_03.jpg | Outerwear | LUXE | A |
| CWPO2STF8520034 | Broadcloth Dress Shirt | https://example.com/img/shirt_06.jpg | Shirt | ESSENTIALS | A |
| CWPO2STF8520035 | Wrap Midi Skirt | https://example.com/img/skirt_02.jpg | Skirt | CLASSIC | B |
| CWPO2STF8520036 | Sequin Evening Dress | https://example.com/img/dress_06.jpg | Dresses | LUXE | A |
| CWPO2STF8520037 | Zip-Up Polo | https://example.com/img/polo_05.jpg | Polo Shirt | SPORT | B |
| CWPO2STF8520038 | Alpaca Pullover | https://example.com/img/sweater_05.jpg | Sweater | CLASSIC | B |
| CWPO2STF8520039 | Croc-Emboss Tote | https://example.com/img/bag_04.jpg | Handbags | LUXE | A |
| CWPO2STF8520040 | High-Waist Wide Pant | https://example.com/img/pant_04.jpg | Pant | LUXE | A |
| CWPO2STF8520041 | Down Vest | https://example.com/img/outer_04.jpg | Outerwear | SPORT | B |
| CWPO2STF8520042 | Ribbed Turtleneck | https://example.com/img/knit_06.jpg | Knit | ESSENTIALS | C |
| CWPO2STF8520043 | Satin Camisole Top | https://example.com/img/shirt_07.jpg | Shirt | LUXE | A |
| CWPO2STF8520044 | Tiered Ruffle Dress | https://example.com/img/dress_07.jpg | Dresses | CLASSIC | B |
| CWPO2STF8520045 | Mesh Insert Polo | https://example.com/img/polo_06.jpg | Polo Shirt | POLO | C |
| CWPO2STF8520046 | Cotton Jogger | https://example.com/img/pant_05.jpg | Pant | SPORT | B |
| CWPO2STF8520047 | Chain Strap Clutch | https://example.com/img/bag_05.jpg | Handbags | ESSENTIALS | B |
| CWPO2STF8520048 | Tennis Skirt | https://example.com/img/skirt_03.jpg | Skirt | SPORT | C |
| CWPO2STF8520049 | Quilted Jacket | https://example.com/img/outer_05.jpg | Outerwear | CLASSIC | A |
| CWPO2STF8520050 | Painter Jean | https://example.com/img/pant_06.jpg | Pant | ESSENTIALS | C |
| CWPO2STF8520051 | Cable Knit Beanie | https://example.com/img/knit_07.jpg | Knit | SPORT | C |
| CWPO2STF8520052 | Oversized Blazer Dress | https://example.com/img/dress_08.jpg | Dresses | ESSENTIALS | A |
| CWPO2STF8520053 | Lambswool Cardigan | https://example.com/img/sweater_06.jpg | Sweater | ESSENTIALS | B |
| CWPO2STF8520054 | Monogram Weekender | https://example.com/img/bag_06.jpg | Handbags | LUXE | A |
| CWPO2STF8520055 | Tapered Trouser | https://example.com/img/pant_07.jpg | Pant | CLASSIC | A |
| CWPO2STF8520056 | Windbreaker | https://example.com/img/outer_06.jpg | Outerwear | SPORT | C |
| CWPO2STF8520057 | Intarsia Knit Top | https://example.com/img/knit_08.jpg | Knit | LUXE | A |
| CWPO2STF8520058 | Print Scarf Dress | https://example.com/img/dress_09.jpg | Dresses | SPORT | C |
| CWPO2STF8520059 | Performance Polo | https://example.com/img/polo_07.jpg | Polo Shirt | POLO | A |
| CWPO2STF8520060 | Pencil Skirt | https://example.com/img/skirt_04.jpg | Skirt | LUXE | A |

**Class 分布**：Shirt(7), Dresses(8), Polo Shirt(7), Sweater(6), Knit(8), Handbags(6), Pant(7), Outerwear(6), Skirt(5)

### 表2：N Fact_VIC（VIC事实表，60行）

| ProductID | TotalVIC | TradeVIC | DirectVIC | NewVIC | RetentionVIC |
|-----------|----------|----------|-----------|--------|--------------|
| CWPO2STF8520001 | 1200 | 750 | 450 | 1 | 1 |
| CWPO2STF8520002 | 850 | 500 | 350 | 1 | 0 |
| CWPO2STF8520003 | 620 | 380 | 240 | 0 | 1 |
| CWPO2STF8520004 | 1050 | 680 | 370 | 1 | 1 |
| CWPO2STF8520005 | 430 | 260 | 170 | 0 | 0 |
| CWPO2STF8520006 | 980 | 600 | 380 | 1 | 1 |
| CWPO2STF8520007 | 760 | 450 | 310 | 1 | 0 |
| CWPO2STF8520008 | 520 | 300 | 220 | 0 | 1 |
| CWPO2STF8520009 | 890 | 540 | 350 | 1 | 1 |
| CWPO2STF8520010 | 670 | 410 | 260 | 0 | 0 |
| CWPO2STF8520011 | 1500 | 900 | 600 | 1 | 1 |
| CWPO2STF8520012 | 1100 | 650 | 450 | 1 | 0 |
| CWPO2STF8520013 | 1350 | 800 | 550 | 1 | 1 |
| CWPO2STF8520014 | 480 | 280 | 200 | 0 | 1 |
| CWPO2STF8520015 | 920 | 560 | 360 | 1 | 1 |
| CWPO2STF8520016 | 1150 | 700 | 450 | 1 | 0 |
| CWPO2STF8520017 | 780 | 470 | 310 | 0 | 1 |
| CWPO2STF8520018 | 650 | 390 | 260 | 1 | 1 |
| CWPO2STF8520019 | 880 | 530 | 350 | 1 | 0 |
| CWPO2STF8520020 | 560 | 340 | 220 | 0 | 1 |
| CWPO2STF8520021 | 390 | 230 | 160 | 0 | 0 |
| CWPO2STF8520022 | 1400 | 850 | 550 | 1 | 1 |
| CWPO2STF8520023 | 720 | 430 | 290 | 1 | 0 |
| CWPO2STF8520024 | 310 | 180 | 130 | 0 | 1 |
| CWPO2STF8520025 | 840 | 510 | 330 | 1 | 1 |
| CWPO2STF8520026 | 690 | 420 | 270 | 0 | 0 |
| CWPO2STF8520027 | 450 | 270 | 180 | 1 | 1 |
| CWPO2STF8520028 | 1080 | 660 | 420 | 1 | 1 |
| CWPO2STF8520029 | 750 | 460 | 290 | 0 | 0 |
| CWPO2STF8520030 | 960 | 580 | 380 | 1 | 1 |
| CWPO2STF8520031 | 2850 | 1820 | 1030 | 1 | 1 |
| CWPO2STF8520032 | 680 | 390 | 290 | 0 | 1 |
| CWPO2STF8520033 | 3200 | 2100 | 1100 | 1 | 1 |
| CWPO2STF8520034 | 1580 | 1020 | 560 | 1 | 0 |
| CWPO2STF8520035 | 740 | 430 | 310 | 0 | 1 |
| CWPO2STF8520036 | 1920 | 1250 | 670 | 1 | 1 |
| CWPO2STF8520037 | 1060 | 700 | 360 | 1 | 0 |
| CWPO2STF8520038 | 510 | 300 | 210 | 0 | 1 |
| CWPO2STF8520039 | 2680 | 1750 | 930 | 1 | 1 |
| CWPO2STF8520040 | 1340 | 860 | 480 | 1 | 1 |
| CWPO2STF8520041 | 420 | 250 | 170 | 0 | 0 |
| CWPO2STF8520042 | 590 | 350 | 240 | 1 | 0 |
| CWPO2STF8520043 | 1720 | 1100 | 620 | 1 | 1 |
| CWPO2STF8520044 | 1460 | 950 | 510 | 1 | 0 |
| CWPO2STF8520045 | 380 | 220 | 160 | 0 | 1 |
| CWPO2STF8520046 | 830 | 530 | 300 | 1 | 1 |
| CWPO2STF8520047 | 1150 | 740 | 410 | 0 | 1 |
| CWPO2STF8520048 | 290 | 170 | 120 | 0 | 0 |
| CWPO2STF8520049 | 2100 | 1380 | 720 | 1 | 1 |
| CWPO2STF8520050 | 350 | 200 | 150 | 0 | 1 |
| CWPO2STF8520051 | 470 | 280 | 190 | 0 | 0 |
| CWPO2STF8520052 | 1680 | 1080 | 600 | 1 | 1 |
| CWPO2STF8520053 | 880 | 560 | 320 | 0 | 1 |
| CWPO2STF8520054 | 3500 | 2300 | 1200 | 1 | 1 |
| CWPO2STF8520055 | 1250 | 810 | 440 | 1 | 0 |
| CWPO2STF8520056 | 260 | 150 | 110 | 0 | 0 |
| CWPO2STF8520057 | 950 | 610 | 340 | 1 | 1 |
| CWPO2STF8520058 | 320 | 190 | 130 | 0 | 1 |
| CWPO2STF8520059 | 1800 | 1170 | 630 | 1 | 1 |
| CWPO2STF8520060 | 1100 | 710 | 390 | 0 | 1 |

> CSV 文件已生成至同目录下 `N Dim_Product.csv` 和 `N Fact_VIC.csv`，可直接导入 Power BI。

---

## 2. 数据模型关系图

```
┌─────────────────────────────┐         ┌─────────────────────────────────┐
│       N Dim_Product           │         │          N Fact_VIC               │
│  （产品维度表 - 维度端 1）    │         │   （VIC事实表 - 多端 *）         │
├─────────────────────────────┤         ├─────────────────────────────────┤
│ ProductID  ◄─── PK          │──1 : *──│ ProductID  ──── FK              │
│ ProductName                 │         │ TotalVIC                        │
│ ProductImageURL             │         │ TradeVIC                        │
│ Class                       │         │ DirectVIC                       │
│ Label                       │         │ NewVIC                          │
│ Tier                        │         │ RetentionVIC                    │
└─────────────────────────────┘         └─────────────────────────────────┘

关系配置：
  - 基数：1 对 多（N Dim_Product → N Fact_VIC）
  - 交叉筛选方向：单向（N Dim_Product → N Fact_VIC）
  - 使此关系处于活动状态：是
```

### 导入步骤

1. Power BI Desktop → 获取数据 → 文本/CSV
2. 分别导入 `N Dim_Product.csv` 和 `N Fact_VIC.csv`
3. 点击"转换数据"进入 Power Query Editor
4. 确认 ProductID 列数据类型为 **文本（Text）**
5. 确认后加载到模型

### 建立关系

1. 模型视图 → 拖拽 `N Dim_Product[ProductID]` 到 `N Fact_VIC[ProductID]`
2. 基数选择 **1 对多 (1:*)**
3. 交叉筛选方向：**单向**
4. 勾选"使此关系处于活动状态"

---

## 3. DAX 度量值

以下度量值均创建在 **'N Fact_VIC'** 表（或单独的度量值表中，建议使用 `_Measures` 隐藏表）。

### 3.1 基础度量值

```dax
Total VIC =
// ========================================
// 度量值: Total VIC
// 用途: 所有VIC客户数汇总，用于左侧条形图及各列表排名基数
// 依赖: 'N Fact_VIC'[TotalVIC]
// ========================================
SUM( 'N Fact_VIC'[TotalVIC] )
```

```dax
Trade VIC =
// ========================================
// 度量值: Trade VIC
// 用途: Trade渠道VIC数，供字段参数引用
// 依赖: 'N Fact_VIC'[TradeVIC]
// ========================================
SUM( 'N Fact_VIC'[TradeVIC] )
```

```dax
Direct VIC =
// ========================================
// 度量值: Direct VIC
// 用途: Direct渠道VIC数，供字段参数引用
// 依赖: 'N Fact_VIC'[DirectVIC]
// ========================================
SUM( 'N Fact_VIC'[DirectVIC] )
```

### 3.2 动态 VIC 值（字段参数驱动）

```dax
Total VIC (Dynamic) =
// ========================================
// 度量值: Total VIC (Dynamic)
// 用途: 根据字段参数 VICType 的选择，动态返回对应渠道的VIC值
//       左侧条形图和各排名度量值均引用此度量值
//       使条形图也随 Trade/Direct 切换而变化
// 依赖: Trade VIC, Direct VIC, [Total VIC], Param_VICType（字段参数）
// 备注: 字段参数创建详见第4节
// ========================================
VAR __BaseMeasure =
    SWITCH(
        TRUE(),
        // 通过字段参数 SELECTEDVALUE 获取当前选择的列名
        SELECTEDVALUE( 'Param_VICType'[Param_VICType Fields] ) = NAMEOF( 'N Fact_VIC'[TradeVIC] ),
            [Trade VIC],
        SELECTEDVALUE( 'Param_VICType'[Param_VICType Fields] ) = NAMEOF( 'N Fact_VIC'[DirectVIC] ),
            [Direct VIC],
        // 默认回退到 TotalVIC
        [Total VIC]
    )
RETURN
    __BaseMeasure
```

### 3.3 动态排名（字段参数驱动 + RANKX）

```dax
VIC No. (Dynamic) =
// ========================================
// 度量值: VIC No. (Dynamic)
// 用途: 根据字段参数 VICType 的选择，动态返回排名
//       中间 Top Product List 表格使用此度量值
//       按选中渠道（TradeVIC/DirectVIC）的VIC数值降序排名
// 依赖: Trade VIC, Direct VIC, [Total VIC], Param_VICType（字段参数）
// 备注: ALLSELECTED 包含 ProductName, Label, ProductImageURL 三列，
//       确保表格中多列同时存在时排名不重复
// ========================================
RANKX(
    ALLSELECTED(
        'N Dim_Product'[ProductName],
        'N Dim_Product'[Label],
        'N Dim_Product'[ProductImageURL]
    ),
    SWITCH(
        TRUE(),
        SELECTEDVALUE( 'Param_VICType'[Param_VICType Fields] ) = NAMEOF( 'N Fact_VIC'[TradeVIC] ),
            [Trade VIC],
        SELECTEDVALUE( 'Param_VICType'[Param_VICType Fields] ) = NAMEOF( 'N Fact_VIC'[DirectVIC] ),
            [Direct VIC],
        [Total VIC]
    ),
    ,
    DESC,
    Dense
)
```

### 3.4 New VIC 排名度量值

```dax
New VIC Count =
// ========================================
// 度量值: New VIC Count
// 用途: 仅统计 NewVIC=1 的产品的动态VIC数（作为排名基数）
//       引用 [Total VIC (Dynamic)] 使值随 Trade/Direct 切换而变化
// 依赖: 'N Fact_VIC'[NewVIC], [Total VIC (Dynamic)]
// ========================================
CALCULATE(
    [Total VIC (Dynamic)],
    'N Fact_VIC'[NewVIC] = 1
)
```

```dax
New VIC Rank =
// ========================================
// 度量值: New VIC Rank
// 用途: 在 New VIC Top Product List 表格中显示排名
//       按 NewVIC=1 的产品的动态VIC值降序排名
// 依赖: [New VIC Count]
// 备注: ALLSELECTED 包含 ProductName, Label, ProductImageURL 三列，
//       确保表格中多列同时存在时排名不重复
// ========================================
RANKX(
    ALLSELECTED(
        'N Dim_Product'[ProductName],
        'N Dim_Product'[Label],
        'N Dim_Product'[ProductImageURL]
    ),
    [New VIC Count],
    ,
    DESC,
    Dense
)
```

### 3.5 Retention VIC 排名度量值

```dax
Retention VIC Count =
// ========================================
// 度量值: Retention VIC Count
// 用途: 仅统计 RetentionVIC=1 的产品的动态VIC数（作为排名基数）
//       引用 [Total VIC (Dynamic)] 使值随 Trade/Direct 切换而变化
// 依赖: 'N Fact_VIC'[RetentionVIC], [Total VIC (Dynamic)]
// ========================================
CALCULATE(
    [Total VIC (Dynamic)],
    'N Fact_VIC'[RetentionVIC] = 1
)
```

```dax
Retention VIC Rank =
// ========================================
// 度量值: Retention VIC Rank
// 用途: 在 Retention VIC Top Product List 表格中显示排名
//       按 RetentionVIC=1 的产品的动态VIC值降序排名
// 依赖: [Retention VIC Count]
// 备注: ALLSELECTED 包含 ProductName, Label, ProductImageURL 三列，
//       确保表格中多列同时存在时排名不重复
// ========================================
RANKX(
    ALLSELECTED(
        'N Dim_Product'[ProductName],
        'N Dim_Product'[Label],
        'N Dim_Product'[ProductImageURL]
    ),
    [Retention VIC Count],
    ,
    DESC,
    Dense
)
```

### 3.6 辅助度量值

```dax
New VIC Flag =
// ========================================
// 度量值: New VIC Flag
// 用途: 判断当前产品是否有 NewVIC 标记，用于表格视觉对象级筛选
// 依赖: 'N Fact_VIC'[NewVIC]
// ========================================
SUM( 'N Fact_VIC'[NewVIC] )
```

```dax
Retention VIC Flag =
// ========================================
// 度量值: Retention VIC Flag
// 用途: 判断当前产品是否有 RetentionVIC 标记，用于表格视觉对象级筛选
// 依赖: 'N Fact_VIC'[RetentionVIC]
// ========================================
SUM( 'N Fact_VIC'[RetentionVIC] )
```

---

## 4. 字段参数配置

### 目标

实现所有图表的 **Trade / Direct 按钮切换**，点击不同按钮时条形图和各表格的排名均切换为对应渠道数据。

### 步骤一：创建字段参数

1. 在 Power BI Desktop 菜单栏 → **建模** → **新建参数** → **字段**
2. 参数名称：`Param_VICType`
3. 添加以下字段：

| 显示名称 | 字段 |
|---------|------|
| Trade | `N Fact_VIC[TradeVIC]` |
| Direct | `N Fact_VIC[DirectVIC]` |

4. 勾选 **"将字段添加到画布"**（可选，默认添加切片器）
5. 点击 **创建**

> 创建后会自动生成一张隐藏计算表 `Param_VICType`，包含列 `Param_VICType Fields` 和 `Param_VICType`。

### 步骤二：绑定字段参数到度量值

`Total VIC (Dynamic)`、`VIC No. (Dynamic)` 度量值（见第3.2/3.3节）已通过 `SELECTEDVALUE(Param_VICType[Param_VICType Fields])` 绑定到字段参数。New VIC Rank / Retention VIC Rank 通过依赖链 `[Total VIC (Dynamic)]` 间接绑定。

### 步骤三：创建 Trade / Direct 按钮（使用切片器替代）

由于字段参数默认生成的是切片器，将其样式修改为按钮外观：

1. 将 `Param_VICType` 切片器拖到中间表格上方
2. 切片器设置：
   - **选项** → 样式：**平铺（Tile）** 或 **按钮**
   - **选项** → 方向：**水平**
   - 仅保留 Trade 和 Direct 两个选项
3. 自定义按钮颜色：
   - 选中状态：深蓝色 `#1a2b4c`
   - 未选中状态：浅灰色 `#E0E0E0`

> **替代方案**（书签方式）：如果需要完全自定义的按钮外观，可改用书签 + 按钮方式。创建两个书签分别切换字段参数值，然后在按钮的"操作"中设置书签导航。但字段参数方式更简洁，推荐优先使用。

---

## 5. 编辑交互设置

### 目标

中间 Top Product List 表格 **不受** 左侧条形图的交叉筛选影响，始终显示全部产品排名。

### 详细步骤

1. **选中左侧条形图**（Top Class 条形图）
2. 在菜单栏 → **格式** → **编辑交互**（或在"格式"选项卡中找到"编辑交互"按钮）
3. 此时所有视觉对象周围会出现交互图标
4. **找到中间 Top Product List 表格**
5. 点击该表格上方的 **"禁止"图标**（圆圈加斜线 🚫），关闭交叉筛选
6. 确保右上 New VIC 表格和右下 Retention VIC 表格保持 **"筛选"图标**（漏斗）为激活状态
7. 再次点击 **编辑交互** 按钮退出编辑模式

```
交互配置总结：

                    左侧条形图点击 Class
                    ↓ 交叉筛选方向
    ┌──────────────────────────────────────────────┐
    │                                              │
    │   中间表格        右上表格        右下表格     │
    │   (Top Product)   (New VIC)      (Retention) │
    │                                              │
    │   🚫 禁止          ✅ 筛选        ✅ 筛选     │
    │   不受影响         联动筛选       联动筛选     │
    └──────────────────────────────────────────────┘

    顶部 Class 切片器 → 影响所有三个表格（正常筛选）
```

### 验证方法

- 点击左侧条形图的 "Shirt" 条目
- 中间表格应 **不变**，仍显示全部 60 个产品
- 右上表格应 **只显示** Shirt 类别中 NewVIC=1 的产品
- 右下表格应 **只显示** Shirt 类别中 RetentionVIC=1 的产品

---

## 6. 报表布局与视觉对象配置

### 页面整体布局

```
┌────────────────────────────────────────────────────────────────────┐
│                     Class × Label Drilldown 产品分析仪表板           │
│  ┌──────────┐  ┌────────────────────────┐                         │
│  │ [Class   │  │   Top Product List     │                         │
│  │  切片器]  │  │   [Trade] [Direct]    │                         │
│  └──────────┘  │  ┌──────────────────┐  │                         │
│                │  │ Item|Image|Label |  │                         │
│  ┌──────────┐  │  │ VIC No.          │  │                         │
│  │ Top      │  │  └──────────────────┘  │                         │
│  │ Class    │  └────────────────────────┘                         │
│  │ ████████ │  ┌────────────────────────┐                         │
│  │ ██████   │  │  New VIC Top Product   │                         │
│  │ █████    │  │  ┌──────────────────┐  │                         │
│  │ ███      │  │  │ Item|Image|Label |  │                         │
│  │ ██       │  │  │ VIC No.          │  │                         │
│  │          │  │  └──────────────────┘  │                         │
│  │          │  └────────────────────────┘                         │
│  │          │  ┌────────────────────────┐                         │
│  │          │  │ Retention VIC Top      │                         │
│  │          │  │  ┌──────────────────┐  │                         │
│  │          │  │  │ Item|Image|Label |  │                         │
│  │          │  │  │ VIC No.          │  │                         │
│  │          │  │  └──────────────────┘  │                         │
│  └──────────┘  └────────────────────────┘                         │
└────────────────────────────────────────────────────────────────────┘
```

### 6.1 左侧 — Top Class 条形图

| 配置项 | 设置 |
|--------|------|
| 视觉对象类型 | 条形图（Clustered bar chart） |
| Y轴 | `N Dim_Product[Class]` |
| X轴 | `[Total VIC (Dynamic)]` |
| 排序 | 按 Total VIC (Dynamic) 降序 |
| 柱颜色 | 深蓝 `#1a2b4c`（所有柱子统一色） |
| 数据标签 | 开启，显示数值 |
| 标题 | "Top Class by VIC" |

**配色步骤**：
1. 选中条形图 → 格式 → 列 → 颜色
2. 点击颜色选择器 → 自定义颜色 → 输入 `#1a2b4c`

### 6.2 中间 — Top Product List 表格

| 配置项 | 设置 |
|--------|------|
| 视觉对象类型 | 表格（Table） |
| 列 1 | `N Dim_Product[ProductName]`（标题：Item） |
| 列 2 | `N Dim_Product[ProductImageURL]`（标题：Image，数据类别：Image URL） |
| 列 3 | `N Dim_Product[Label]` |
| 列 4 | `[VIC No. (Dynamic)]`（标题：VIC No.） |
| 排序 | 按 `[VIC No. (Dynamic)]` 降序 |
| 交叉筛选 | **已禁止**（见第5节） |

**图片列设置**：
1. 选中 ProductImageURL 列 → 列工具 → 数据类别 → 选择 **Image URL**
2. 表格中该列会自动显示为缩略图

### 6.3 右上 — New VIC Top Product List

| 配置项 | 设置 |
|--------|------|
| 视觉对象类型 | 表格（Table） |
| 列 1 | `N Dim_Product[ProductName]`（标题：Item） |
| 列 2 | `N Dim_Product[ProductImageURL]`（标题：Image，数据类别：Image URL） |
| 列 3 | `N Dim_Product[Label]` |
| 列 4 | `[New VIC Rank]`（标题：VIC No.） |
| 排序 | 按 `[New VIC Rank]` 升序（排名1在最前） |
| 筛选器 | 添加视觉对象级别筛选：`[New VIC Flag]` > 0 |
| 交叉筛选 | 受左侧条形图联动（默认） |

**筛选器设置**：
1. 选中该表格 → 筛选器面板 → 此视觉对象的筛选器
2. 将 `[New VIC Flag]` 拖入筛选器区域
3. 筛选类型：基本 → 值大于 0（或直接勾选 "is greater than" → 0）

### 6.4 右下 — Retention VIC Top Product List

| 配置项 | 设置 |
|--------|------|
| 视觉对象类型 | 表格（Table） |
| 列 1 | `N Dim_Product[ProductName]`（标题：Item） |
| 列 2 | `N Dim_Product[ProductImageURL]`（标题：Image，数据类别：Image URL） |
| 列 3 | `N Dim_Product[Label]` |
| 列 4 | `[Retention VIC Rank]`（标题：VIC No.） |
| 排序 | 按 `[Retention VIC Rank]` 升序（排名1在最前） |
| 筛选器 | 添加视觉对象级别筛选：`[Retention VIC Flag]` > 0 |
| 交叉筛选 | 受左侧条形图联动（默认） |

### 6.5 顶部 — Class 切片器

| 配置项 | 设置 |
|--------|------|
| 视觉对象类型 | 切片器（Slicer） |
| 字段 | `N Dim_Product[Class]` |
| 样式 | 下拉（Dropdown） |
| 选择模式 | 单选 |
| 标题 | "Class 筛选" |

---

## 7. 完整交互逻辑说明

### 交互矩阵

| 操作 | 左侧条形图 | 中间表格 | 右上表格 | 右下表格 |
|------|-----------|---------|---------|---------|
| 点击条形图某 Class | 高亮选中 | **不变**（编辑交互已禁止） | 仅显示该 Class 下 NewVIC>0 产品 | 仅显示该 Class 下 RetentionVIC>0 产品 |
| 不点击（空白区域） | 无选中 | 显示全部 | 显示全部 NewVIC>0 产品 | 显示全部 RetentionVIC>0 产品 |
| 使用 Class 切片器 | 联动高亮 | 联动筛选 | 联动筛选 + NewVIC过滤 | 联动筛选 + RetentionVIC过滤 |
| 点击 Trade 按钮 | 条形图切换为 TradeVIC 排序 | VIC No. 切换为 TradeVIC 排名 | 排名切换为 TradeVIC 排名 | 排名切换为 TradeVIC 排名 |
| 点击 Direct 按钮 | 条形图切换为 DirectVIC 排序 | VIC No. 切换为 DirectVIC 排名 | 排名切换为 DirectVIC 排名 | 排名切换为 DirectVIC 排名 |

### 交互流程示意

```
用户点击条形图 "Shirt"
    │
    ├─→ 交叉筛选传播到 N Fact_VIC（通过关系）
    │       ↓
    │   N Fact_VIC 被筛选为 Shirt 类的 7 个产品
    │       ↓
    ├─→ 中间表格：🚫 已禁止交叉筛选 → 不受影响
    │       显示全部 60 个产品排名
    │
    ├─→ 右上表格：✅ 正常接收筛选
    │       + 视觉对象筛选器 [New VIC Flag] > 0
    │       → 显示 Shirt 中 NewVIC=1 的产品排名
    │
    └─→ 右下表格：✅ 正常接收筛选
            + 视觉对象筛选器 [Retention VIC Flag] > 0
            → 显示 Shirt 中 RetentionVIC=1 的产品排名

用户点击 Trade/Direct 按钮
    │
    ├─→ 左侧条形图：通过 [Total VIC (Dynamic)] 切换为对应渠道排序
    ├─→ 中间表格：通过 [VIC No. (Dynamic)] 切换为对应渠道排名
    ├─→ 右上表格：通过 [New VIC Rank] → [New VIC Count] → [Total VIC (Dynamic)] 切换排名
    └─→ 右下表格：通过 [Retention VIC Rank] → [Retention VIC Count] → [Total VIC (Dynamic)] 切换排名
```

---

## 附录：快速搭建检查清单

- [ ] 导入 N Dim_Product.csv 和 N Fact_VIC.csv
- [ ] 确认 ProductID 数据类型为文本
- [ ] 建立 N Dim_Product → N Fact_VIC 的 1:* 关系
- [ ] 创建 7 个度量值：Total VIC, Trade VIC, Direct VIC, VIC No. (Dynamic), New VIC Count, Retention VIC Count, New VIC Flag, Retention VIC Flag
- [ ] 创建字段参数 Param_VICType（TradeVIC, DirectVIC）
- [ ] 左侧创建条形图（Class vs Total VIC）
- [ ] 中间创建表格（ProductName, Image, Label, VIC No. Dynamic）
- [ ] 右上创建表格（ProductName, Image, Label, New VIC Count）+ 筛选器
- [ ] 右下创建表格（ProductName, Image, Label, Retention VIC Count）+ 筛选器
- [ ] 顶部创建 Class 下拉切片器
- [ ] **编辑交互**：选中条形图 → 编辑交互 → 中间表格设为"禁止"
- [ ] 中间表格上方放置 Param_VICType 切片器（平铺样式）
- [ ] 验证所有交互逻辑
