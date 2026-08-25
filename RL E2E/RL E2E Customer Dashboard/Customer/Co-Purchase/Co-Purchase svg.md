# Co-Purchase SVG 热力矩阵图 颜色自适应 圆角

> **版本**: v1.1
> **模块**: Customer Dashboard - Customer Tab - Co-Purchase
> **关联度量**: `[Co-Purchase Cross-Sell-Class Value]`、`[Co-Purchase Cross-Sell-Label Value]`
> **参考文件**: 参考文件/SVG 热力矩阵图 颜色自适应 圆角.md
> **用途**: 热力矩阵图单元格，背景/字体颜色按值四点三段插值自适应，圆角 4px

---

## 1. 需求理解

### 1.1 设计说明

- **无百分比切片器**：不读取 `Txn% 切片器`，所有值视为范围内，无置灰模式
- **背景颜色四点三段插值**（0%→30%→50%→100%）：

| 节点 | 颜色 | RGB |
| --- | --- | --- |
| 0% | #d8dee5 | rgb(216, 222, 229) |
| 30% | #95afcf | rgb(149, 175, 207) |
| 50% | #0c2340 | rgb(12, 35, 64) |
| 100% | #000000 | rgb(0, 0, 0) |

- **字体颜色四点三段插值**（0%→30%→**35%**→100%，白色提前到 35%）：

| 节点 | 颜色 | RGB |
| --- | --- | --- |
| 0% | #737373 | rgb(115, 115, 115) |
| 30% | #333333 | rgb(51, 51, 51) |
| 35% | #ffffff | rgb(255, 255, 255) |
| 100% | #ffffff | rgb(255, 255, 255) |

> **v1.1 变更**：字体白色节点从 50% 提前到 35%，使 36% 及以上值的字体为白色，与渐深的背景形成清晰对比。背景越深，字体越白。

### 1.2 三段插值公式

**背景插值**（0%→30%→50%→100%）：

| 段 | 区间 | 宽度 | 插值因子 | 公式 |
| - | ---- | ---- | -------- | ---- |
| 段1 | 0% → 30% | 0.3 | `_Value / 0.3` | `C0 + (C30 - C0) * (_Value / 0.3)` |
| 段2 | 30% → 50% | 0.2 | `(_Value - 0.3) / 0.2` | `C30 + (C50 - C30) * ((_Value - 0.3) / 0.2)` |
| 段3 | 50% → 100% | 0.5 | `(_Value - 0.5) / 0.5` | `C50 + (C100 - C50) * ((_Value - 0.5) / 0.5)` |

**字体插值**（0%→30%→**35%**→100%）：

| 段 | 区间 | 宽度 | 插值因子 | 公式 |
| - | ---- | ---- | -------- | ---- |
| 段1 | 0% → 30% | 0.3 | `_Value / 0.3` | `C0 + (C30 - C0) * (_Value / 0.3)` |
| 段2 | 30% → 35% | 0.05 | `(_Value - 0.3) / 0.05` | `C30 + (C35 - C30) * ((_Value - 0.3) / 0.05)` |
| 段3 | 35% → 100% | 0.65 | `(_Value - 0.35) / 0.65` | `C35 + (C100 - C35) * ((_Value - 0.35) / 0.65)` |

### 1.3 对比度验证

| 值 | 背景 RGB | 背景亮度 | 字体 RGB | 对比说明 |
| - | -------- | -------- | -------- | -------- |
| 30% | rgb(149,175,207) | 中亮蓝 | rgb(51,51,51) 深灰 | 深字 on 中亮背景 ✓ |
| 35% | rgb(115,140,171) | 中蓝 | rgb(255,255,255) 白 | 白字 on 中蓝 ✓ |
| 36% | rgb(108,133,164) | 中深蓝 | rgb(255,255,255) 白 | 白字 on 中深蓝 ✓（v1.0 为深灰，对比不足） |
| 50% | rgb(12,35,64) | 深藏蓝 | rgb(255,255,255) 白 | 白字 on 深藏蓝 ✓ |
| 100% | rgb(0,0,0) | 纯黑 | rgb(255,255,255) 白 | 白字 on 纯黑 ✓ |

### 1.4 BLANK 处理

当度量为 BLANK 时（如切片器未选择），显示浅灰背景 + 灰字 "-"：

| 项目 | 颜色 | RGB |
| --- | --- | --- |
| 背景 | #d7dee4 | rgb(215, 222, 228) |
| 字体 | #b3b3b3 | rgb(179, 179, 179) |
| 文本 | - | "-" |

---

## 2. 度量值实现

### 2.1 Co-Purchase Cross-Sell-Class SVG

```dax
Co-Purchase Cross-Sell-Class SVG =
// ========================================
// 度量值: Co-Purchase Cross-Sell-Class SVG
// 用途: 热力矩阵图单元格，背景/字体颜色按值四点三段插值自适应
// 背景插值: 0%→#d8dee5, 30%→#95afcf, 50%→#0c2340, 100%→#000000
// 字体插值: 0%→#737373, 30%→#333333, 35%→#ffffff, 100%→#ffffff（白色提前到35%）
// 无百分比切片器，全部视为范围内
// 基础度量: [Co-Purchase Cross-Sell-Class Value]
// ========================================

// ── 1. 读取基础值 ──
VAR _RawValue = [Co-Purchase Cross-Sell-Class Value]
VAR _IsBlank = ISBLANK(_RawValue)
VAR _Value = MIN(MAX(_RawValue, 0), 1)
VAR _Pct = FORMAT(_Value, "#,##0%;#,##0%;0%")

// ── 2. 背景颜色三段插值（0%→30%→50%→100%）──
// 0%: #d8dee5 = rgb(216,222,229)
// 30%: #95afcf = rgb(149,175,207)
// 50%: #0c2340 = rgb(12,35,64)
// 100%: #000000 = rgb(0,0,0)
VAR _BR0 = 216
VAR _BG0 = 222
VAR _BB0 = 229

VAR _BR30 = 149
VAR _BG30 = 175
VAR _BB30 = 207

VAR _BR50 = 12
VAR _BG50 = 35
VAR _BB50 = 64

VAR _BR100 = 0
VAR _BG100 = 0
VAR _BB100 = 0

VAR _BR = IF(
    _Value <= 0.3,
    _BR0 + (_BR30 - _BR0) * (_Value / 0.3),
    IF(
        _Value <= 0.5,
        _BR30 + (_BR50 - _BR30) * ((_Value - 0.3) / 0.2),
        _BR50 + (_BR100 - _BR50) * ((_Value - 0.5) / 0.5)
    )
)
VAR _BG = IF(
    _Value <= 0.3,
    _BG0 + (_BG30 - _BG0) * (_Value / 0.3),
    IF(
        _Value <= 0.5,
        _BG30 + (_BG50 - _BG30) * ((_Value - 0.3) / 0.2),
        _BG50 + (_BG100 - _BG50) * ((_Value - 0.5) / 0.5)
    )
)
VAR _BB = IF(
    _Value <= 0.3,
    _BB0 + (_BB30 - _BB0) * (_Value / 0.3),
    IF(
        _Value <= 0.5,
        _BB30 + (_BB50 - _BB30) * ((_Value - 0.3) / 0.2),
        _BB50 + (_BB100 - _BB50) * ((_Value - 0.5) / 0.5)
    )
)
VAR _BgColor = "rgb(" & INT(_BR) & "," & INT(_BG) & "," & INT(_BB) & ")"

// ── 3. 字体颜色三段插值（0%→30%→35%→100%，白色提前到35%）──
// 0%: #737373 = rgb(115,115,115)
// 30%: #333333 = rgb(51,51,51)
// 35%: #ffffff = rgb(255,255,255)  ← 白色节点从50%提前到35%
// 100%: #ffffff = rgb(255,255,255)
VAR _FR0 = 115
VAR _FG0 = 115
VAR _FB0 = 115

VAR _FR30 = 51
VAR _FG30 = 51
VAR _FB30 = 51

VAR _FR35 = 255
VAR _FG35 = 255
VAR _FB35 = 255

VAR _FR100 = 255
VAR _FG100 = 255
VAR _FB100 = 255

VAR _FR = IF(
    _Value <= 0.3,
    _FR0 + (_FR30 - _FR0) * (_Value / 0.3),
    IF(
        _Value <= 0.35,
        _FR30 + (_FR35 - _FR30) * ((_Value - 0.3) / 0.05),
        _FR35 + (_FR100 - _FR35) * ((_Value - 0.35) / 0.65)
    )
)
VAR _FG = IF(
    _Value <= 0.3,
    _FG0 + (_FG30 - _FG0) * (_Value / 0.3),
    IF(
        _Value <= 0.35,
        _FG30 + (_FG35 - _FG30) * ((_Value - 0.3) / 0.05),
        _FG35 + (_FG100 - _FG35) * ((_Value - 0.35) / 0.65)
    )
)
VAR _FB = IF(
    _Value <= 0.3,
    _FB0 + (_FB30 - _FB0) * (_Value / 0.3),
    IF(
        _Value <= 0.35,
        _FB30 + (_FB35 - _FB30) * ((_Value - 0.3) / 0.05),
        _FB35 + (_FB100 - _FB35) * ((_Value - 0.35) / 0.65)
    )
)
VAR _FontColor = "rgb(" & INT(_FR) & "," & INT(_FG) & "," & INT(_FB) & ")"

// ── 4. BLANK 处理：置灰显示 "-" ──
VAR _FinalBg = IF(_IsBlank, "rgb(215,222,228)", _BgColor)
VAR _FinalFont = IF(_IsBlank, "rgb(179,179,179)", _FontColor)
VAR _FinalText = IF(_IsBlank, "-", _Pct)

// ── 5. SVG 输出（圆角 4px，88x33 单元格）──
VAR _URL =
"data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='88' height='33' viewBox='0 0 88 33' preserveAspectRatio='none'>
<rect rx='4' ry='4' x='0' y='0' width='88' height='33' fill='" & _FinalBg & "' stroke='none'/>
<text x='44' y='16.5' text-anchor='middle' dominant-baseline='central' font-size='12' font-family='Segoe UI' font-weight='normal' font-style='normal' fill='" & _FinalFont & "'>" & _FinalText & "</text>
</svg>"

RETURN _URL
```

### 2.2 Co-Purchase Cross-Sell-Label SVG

```dax
Co-Purchase Cross-Sell-Label SVG =
// ========================================
// 度量值: Co-Purchase Cross-Sell-Label SVG
// 用途: 热力矩阵图单元格，背景/字体颜色按值四点三段插值自适应
// 背景插值: 0%→#d8dee5, 30%→#95afcf, 50%→#0c2340, 100%→#000000
// 字体插值: 0%→#737373, 30%→#333333, 35%→#ffffff, 100%→#ffffff（白色提前到35%）
// 无百分比切片器，全部视为范围内
// 基础度量: [Co-Purchase Cross-Sell-Label Value]
// ========================================

// ── 1. 读取基础值 ──
VAR _RawValue = [Co-Purchase Cross-Sell-Label Value]
VAR _IsBlank = ISBLANK(_RawValue)
VAR _Value = MIN(MAX(_RawValue, 0), 1)
VAR _Pct = FORMAT(_Value, "#,##0%;#,##0%;0%")

// ── 2. 背景颜色三段插值（0%→30%→50%→100%）──
// 0%: #d8dee5 = rgb(216,222,229)
// 30%: #95afcf = rgb(149,175,207)
// 50%: #0c2340 = rgb(12,35,64)
// 100%: #000000 = rgb(0,0,0)
VAR _BR0 = 216
VAR _BG0 = 222
VAR _BB0 = 229

VAR _BR30 = 149
VAR _BG30 = 175
VAR _BB30 = 207

VAR _BR50 = 12
VAR _BG50 = 35
VAR _BB50 = 64

VAR _BR100 = 0
VAR _BG100 = 0
VAR _BB100 = 0

VAR _BR = IF(
    _Value <= 0.3,
    _BR0 + (_BR30 - _BR0) * (_Value / 0.3),
    IF(
        _Value <= 0.5,
        _BR30 + (_BR50 - _BR30) * ((_Value - 0.3) / 0.2),
        _BR50 + (_BR100 - _BR50) * ((_Value - 0.5) / 0.5)
    )
)
VAR _BG = IF(
    _Value <= 0.3,
    _BG0 + (_BG30 - _BG0) * (_Value / 0.3),
    IF(
        _Value <= 0.5,
        _BG30 + (_BG50 - _BG30) * ((_Value - 0.3) / 0.2),
        _BG50 + (_BG100 - _BG50) * ((_Value - 0.5) / 0.5)
    )
)
VAR _BB = IF(
    _Value <= 0.3,
    _BB0 + (_BB30 - _BB0) * (_Value / 0.3),
    IF(
        _Value <= 0.5,
        _BB30 + (_BB50 - _BB30) * ((_Value - 0.3) / 0.2),
        _BB50 + (_BB100 - _BB50) * ((_Value - 0.5) / 0.5)
    )
)
VAR _BgColor = "rgb(" & INT(_BR) & "," & INT(_BG) & "," & INT(_BB) & ")"

// ── 3. 字体颜色三段插值（0%→30%→35%→100%，白色提前到35%）──
// 0%: #737373 = rgb(115,115,115)
// 30%: #333333 = rgb(51,51,51)
// 35%: #ffffff = rgb(255,255,255)  ← 白色节点从50%提前到35%
// 100%: #ffffff = rgb(255,255,255)
VAR _FR0 = 115
VAR _FG0 = 115
VAR _FB0 = 115

VAR _FR30 = 51
VAR _FG30 = 51
VAR _FB30 = 51

VAR _FR35 = 255
VAR _FG35 = 255
VAR _FB35 = 255

VAR _FR100 = 255
VAR _FG100 = 255
VAR _FB100 = 255

VAR _FR = IF(
    _Value <= 0.3,
    _FR0 + (_FR30 - _FR0) * (_Value / 0.3),
    IF(
        _Value <= 0.35,
        _FR30 + (_FR35 - _FR30) * ((_Value - 0.3) / 0.05),
        _FR35 + (_FR100 - _FR35) * ((_Value - 0.35) / 0.65)
    )
)
VAR _FG = IF(
    _Value <= 0.3,
    _FG0 + (_FG30 - _FG0) * (_Value / 0.3),
    IF(
        _Value <= 0.35,
        _FG30 + (_FG35 - _FG30) * ((_Value - 0.3) / 0.05),
        _FG35 + (_FG100 - _FG35) * ((_Value - 0.35) / 0.65)
    )
)
VAR _FB = IF(
    _Value <= 0.3,
    _FB0 + (_FB30 - _FB0) * (_Value / 0.3),
    IF(
        _Value <= 0.35,
        _FB30 + (_FB35 - _FB30) * ((_Value - 0.3) / 0.05),
        _FB35 + (_FB100 - _FB35) * ((_Value - 0.35) / 0.65)
    )
)
VAR _FontColor = "rgb(" & INT(_FR) & "," & INT(_FG) & "," & INT(_FB) & ")"

// ── 4. BLANK 处理：置灰显示 "-" ──
VAR _FinalBg = IF(_IsBlank, "rgb(215,222,228)", _BgColor)
VAR _FinalFont = IF(_IsBlank, "rgb(179,179,179)", _FontColor)
VAR _FinalText = IF(_IsBlank, "-", _Pct)

// ── 5. SVG 输出（圆角 4px，88x33 单元格）──
VAR _URL =
"data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='88' height='33' viewBox='0 0 88 33' preserveAspectRatio='none'>
<rect rx='4' ry='4' x='0' y='0' width='88' height='33' fill='" & _FinalBg & "' stroke='none'/>
<text x='44' y='16.5' text-anchor='middle' dominant-baseline='central' font-size='12' font-family='Segoe UI' font-weight='normal' font-style='normal' fill='" & _FinalFont & "'>" & _FinalText & "</text>
</svg>"

RETURN _URL
```

---

## 3. 度量值清单

| # | 度量值名称 | 基础度量 | 用途 |
| --- | --- | --- | --- |
| 1 | Co-Purchase Cross-Sell-Class SVG | [Co-Purchase Cross-Sell-Class Value] | Class 图表热力矩阵单元格 |
| 2 | Co-Purchase Cross-Sell-Label SVG | [Co-Purchase Cross-Sell-Label Value] | Label 图表热力矩阵单元格 |

---

## 4. 注意事项

1. **v1.1 变更：字体白色节点提前**：字体颜色白色节点从 50% 提前到 35%，使 36% 及以上值的字体为白色。原因：36% 时背景已过渡到中深蓝 rgb(108,133,164)，原 v1.0 字体仍为中灰 rgb(112,112,112)，亮度接近导致对比不足。

2. **背景与字体插值点不同步**：背景保持 0%→30%→50%→100%，字体调整为 0%→30%→35%→100%。字体比背景更早到达白色，确保背景越深字体越白，对比度始终充足。

3. **无百分比切片器**：不读取 `Txn% 切片器`，所有值视为范围内，无范围外置灰模式。

4. **颜色对比度自适应**：
   - 0%-30%：浅背景 + 深字（#d8dee5→#95afcf 背景，#737373→#333333 字体）
   - 30%-35%：中背景 + 字体快速过渡到白（#95afcf 背景渐深，字体 #333333→#ffffff）
   - 35%-100%：深背景 + 白字（#0c2340→#000000 背景，#ffffff 字体）

5. **BLANK 处理**：当基础度量为 BLANK 时（如切片器未选择或无数据），显示浅灰背景 `#d7dee4` + 灰字 `-`，避免 0% 误导。

6. **值域钳制**：`MIN(MAX(_RawValue, 0), 1)` 确保值在 [0, 1] 范围内，防止插值越界。

7. **SVG 格式**：`width='88' height='33'`，`preserveAspectRatio='none'` 强制拉伸填满单元格；`rx='4' ry='4'` 圆角 4px；文本居中 `text-anchor='middle' dominant-baseline='central'`。

8. **两个度量差异**：仅基础度量不同（Class 用 `[Co-Purchase Cross-Sell-Class Value]`，Label 用 `[Co-Purchase Cross-Sell-Label Value]`），颜色插值逻辑完全相同。
