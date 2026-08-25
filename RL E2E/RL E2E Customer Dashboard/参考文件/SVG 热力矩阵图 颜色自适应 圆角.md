SVG 热力矩阵图 颜色自适应 圆角 = 
/*
viewBox='0 0 176 88'	建立坐标系，让图形可缩放
preserveAspectRatio='none'	强制拉伸填满，不保持正方形比例
stroke='rgb(9,134,69)' 定义线条的颜色。
stroke-dasharray='none' 定义线条的虚实模式。
fill-opacity 控制填充颜色的透明程度
渐变本身已经用了 rgba(..., 0.3) 这类带透明度的颜色， 会让透明度双重叠加（最终效果约 0.3 × 0.48 ≈ 0.14），
面积会变得更淡。因此两者通常二选一，不要同时硬编码叠加。
*/
// ========================================
// 1. 基础值:Txn% 切片器 = GENERATESERIES(0, 1.01, 0.01)
// ========================================
VAR _RawValue = [列100%]
VAR _Value = MIN(MAX(_RawValue, 0), 1)
VAR _Pct = FORMAT(_Value, "#,##0%;#,##0%;0%")

// ========================================
// 2. 读取百分比切片器（无关系表）
// ========================================
VAR _MinPct = MIN('Txn% 切片器'[Value])   // 滑块左端 / 单滑块阈值
VAR _MaxPct = MAX('Txn% 切片器'[Value])   // 滑块右端（单滑块时默认为1）
VAR _IsInRange = _Value >= _MinPct && _Value <= _MaxPct

// ========================================
// 3. 范围外统一色（置灰模式）
// ========================================
VAR _BgColor_Out = "rgb(215,222,228)"     // #D7DEE4 最浅色
VAR _FontColor_Out = "rgb(179,179,179)"   // #B3B3B3 最浅字色

// ========================================
// 4. 范围内：背景颜色三段插值（0%→50%→100%）
// ========================================
VAR _R_L = 215
VAR _G_L = 222
VAR _B_L = 228

VAR _R_M = 149
VAR _G_M = 176
VAR _B_M = 206

VAR _R_H = 0
VAR _G_H = 0
VAR _B_H = 0

VAR _R_BG = IF(_Value <= 0.5, _R_L + (_R_M - _R_L) * _Value * 2, _R_M + (_R_H - _R_M) * (_Value - 0.5) * 2)
VAR _G_BG = IF(_Value <= 0.5, _G_L + (_G_M - _G_L) * _Value * 2, _G_M + (_G_H - _G_M) * (_Value - 0.5) * 2)
VAR _B_BG = IF(_Value <= 0.5, _B_L + (_B_M - _B_L) * _Value * 2, _B_M + (_B_H - _B_M) * (_Value - 0.5) * 2)
VAR _BgColor = "rgb(" & INT(_R_BG) & "," & INT(_G_BG) & "," & INT(_B_BG) & ")"

// ========================================
// 5. 范围内：字体颜色三段插值
// ========================================
VAR _R_FL = 179
VAR _G_FL = 179
VAR _B_FL = 179

VAR _R_FM = 102
VAR _G_FM = 102
VAR _B_FM = 102

VAR _R_FH = 255
VAR _G_FH = 255
VAR _B_FH = 255

VAR _R_Font = IF(_Value <= 0.5, _R_FL + (_R_FM - _R_FL) * _Value * 2, _R_FM + (_R_FH - _R_FM) * (_Value - 0.5) * 2)
VAR _G_Font = IF(_Value <= 0.5, _G_FL + (_G_FM - _G_FL) * _Value * 2, _G_FM + (_G_FH - _G_FM) * (_Value - 0.5) * 2)
VAR _B_Font = IF(_Value <= 0.5, _B_FL + (_B_FM - _B_FL) * _Value * 2, _B_FM + (_B_FH - _B_FM) * (_Value - 0.5) * 2)
VAR _FontColor = "rgb(" & INT(_R_Font) & "," & INT(_G_Font) & "," & INT(_B_Font) & ")"

// ========================================
// 6. 最终颜色选择：范围内正常，范围外置灰
// ========================================
VAR _FinalBg = IF(_IsInRange, _BgColor, _BgColor_Out)
VAR _FinalFont = IF(_IsInRange, _FontColor, _FontColor_Out)

// ========================================
// 7. SVG 输出
// ========================================
VAR _URL = 
"data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='88' height='33' viewBox='0 0 88 33' preserveAspectRatio='none'>
<rect rx='4' ry='4' x='0' y='0' width='88' height='33' fill='" & _FinalBg & "' stroke='none'/>
<text x='44' y='16.5' text-anchor='middle' dominant-baseline='central' font-size='12' font-family='Segoe UI' font-weight='normal' font-style='normal' fill='" & _FinalFont & "'>" & _Pct & "</text>
</svg>"

RETURN _URL