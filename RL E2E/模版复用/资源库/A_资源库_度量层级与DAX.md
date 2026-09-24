# A_资源库：度量层级与 DAX 原文

## 来源、范围与恢复规则

- 唯一内容依据：[附件 L1–L2464](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1-L2464)；UTF-8，共 2464 行（按编辑器计数，含末尾空行）；表 `A_资源库`。不以既有 Markdown、图片或外部知识补充内容。
- 附件 SHA-256：`d2847fce4a272c564bbc7dbaac6d4e80c5b8b21e829c30c47144fbeb5ba255f6`。
- 仅恢复表内 measure 声明。列、分区及表级 annotation 不混入度量；即使名称含“计算表”，仍按源声明类型收录。
- 文件夹仅取度量直属 displayFolder，以反斜杠分层；DAX 注释中的 Display Folder 不是层级依据。缺失或空值归表根；隐藏度量仍完整收录。
- TMDL 引号名称按成对单引号解析，两个连续单引号解码为一个单引号；正文保留原始名称令牌，DAX 左侧使用实际度量名。
- DAX 仅去掉四个结构性制表符和 TMDL 包裹反引号，并添加实际“度量名 =”；保留表达式内部缩进、首尾空行、行尾空格、注释、字符串和占位公式。文件换行统一 LF。单行公式保留赋值符号右侧原字符。
- 元数据整体保留，仅去掉三个结构性制表符及对象之间的空分隔行；不补写缺失属性，不调整属性顺序。源行号只放在说明中，不写入代码。
- 排序：每层子文件夹按 StringComparer.Ordinal（Unicode/UTF-16 序，非拼音）升序，先子文件夹、后直接度量，深度优先；同一文件夹的直接度量按附件声明顺序。树形索引与正文一致，不按图片截断。
- 本文是原样恢复，不是可执行性保证；未运行 Power BI，未检查依赖的表、列、关系、其他度量或自定义函数，未验证原注释中的技术结论。

## 统计

| 项目 | 数量 |
| --- | ---: |
| 度量总数 | 130 |
| 根文件夹（表的直接子文件夹） | 7 |
| 文件夹层级节点（所有非空路径前缀，不含表和度量） | 20 |
| 叶文件夹路径（无子文件夹） | 17 |
| 实际承载度量的非空完整文件夹路径 | 17 |
| 未归档度量（表根） | 0 |
| 隐藏度量 | 0 |
| 最大文件夹深度（不含表与度量） | 2 |
| 排除的列 / 分区 / 表级 annotation | 1 / 1 / 2 |
| 带 formatString / lineageTag / description 的度量 | 61 / 130 / 0 |
| 度量级 annotation 总数 | 5 |
| 引号包裹名称 / 含单引号转义的名称 | 27 / 0 |

隐藏列的 isHidden 见 [附件 L2446–L2454](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2446-L2454)，它不属于任何度量。源没有 description 属性或声明前说明时，不凭 DAX 注释制造 description。

| 根文件夹 | 含子层级的度量数 |
| --- | ---: |
| `函数` | 13 |
| `分析模型` | 24 |
| `开发复用` | 69 |
| `日期和时间` | 7 |
| `权限设计` | 2 |
| `页面导航` | 10 |
| `页面按钮` | 5 |

## 原样保留的异常与未完成示例

以下只提示可直接追溯的原文特征，不作为完整 DAX 语法审查或执行结论：

- 多个示例被整段块注释包裹，部分有多层块注释，如 [附件 L79–L116](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L79-L116)、[附件 L1142–L1185](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1142-L1185)；没有解除注释或补写有效表达式。
- 购物篮 GE 示例保留数字常量占位，盈亏平衡示例保留文本常量占位，见 [附件 L1982–L2229](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1982-L2229)、[附件 L2231–L2339](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2231-L2339)；未把注释内示例替换为实际公式。
- 表值表达式示例仍按 measure 收录，见 [附件 L1732–L1739](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1732-L1739)；不转换成计算表，也不声称可作为标量度量执行。
- 原排序参数 DESC 与同一行“升序”注释并存，见 [附件 L1875–L1879](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1875-L1879)；保持原样。
- 名称写换行符、表达式却是空格字符串的示例，见 [附件 L2427–L2444](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2427-L2444)；保留空格字符串，不替换成函数调用。
- 含冒号、括号、符号的名称，以及代码中 HTML/SVG、说明文字、引用名称和可能的原始异常，均不重命名、不规范化、不修复。

## 完整树形索引

```text
A_资源库
├── 文件夹：函数
│   ├── 文件夹：HTML
│   │   ├── 度量：HTML Content视觉对象多指标、多维度文本循环滚动 [M074]
│   │   └── 度量：HTML Content 染色文本 [M098]
│   └── 文件夹：SVG
│       ├── 度量：表格矩阵、按钮切片器、新卡片图条件格式图标 [M081]
│       ├── 度量：表格矩阵、按钮切片器实现指定颜色的渐变条形图 [M082]
│       ├── 度量：表格矩阵、按钮切片器、新卡片图展示华夫饼样式的百分比02 [M083]
│       ├── 度量：表格矩阵、按钮切片器、新卡片图展示华夫饼样式的百分比 [M084]
│       ├── 度量：面积折线图_by_day [M086]
│       ├── 度量：面积折线图_等距排列 [M087]
│       ├── 度量：三次贝塞尔曲线_by_day [M088]
│       ├── 度量：三次贝塞尔曲线_等距排列 [M089]
│       ├── 度量：热力矩阵图 颜色自适应 圆角 [M094]
│       ├── 度量：柱形 渐变 动画 [M096]
│       └── 度量：菱形进度条 独立着色 [M099]
├── 文件夹：分析模型
│   ├── 文件夹：基于购物篮数据的GE矩阵
│   │   ├── 度量：1 客户数 [M110]
│   │   ├── 度量：2 同时购买A和B的客户数 [M111]
│   │   ├── 度量：3 关联客户占比 [M112]
│   │   ├── 度量：4 L销售额 [M113]
│   │   ├── 度量：5 关联产品B的销售额 [M114]
│   │   ├── 度量：6 同时购买A和B的客户中，购买产品B的金额 [M115]
│   │   ├── 度量：7 平均_所有产品的关联销售额 [M116]
│   │   ├── 度量：8 平均关联销售额 已选中 [M117]
│   │   ├── 度量：9 平均_所有产品的关联客户占比 [M118]
│   │   ├── 度量：91 运行总和 可视化计算 [M119]
│   │   └── 度量：92 四象限配色 [M120]
│   ├── 文件夹：帕累托
│   │   ├── 度量：帕累托累计占比(ADDCOLUMNS 版本) [M075]
│   │   ├── 度量：帕累托累计占比(SUMMARIZE 版本) [M076]
│   │   ├── 度量：帕累托累计占比(CALCULATE 嵌套版) [M077]
│   │   ├── 度量：占当前筛选上下文总计（受外部筛选器影响） [M078]
│   │   ├── 度量：占总计百分比（不受任何筛选影响） [M079]
│   │   └── 度量：总计 [M080]
│   └── 文件夹：盈亏平衡分析
│       ├── 度量：1：变动成本 [M121]
│       ├── 度量：2：总成本 [M122]
│       ├── 度量：3：收入 [M123]
│       ├── 度量：7：盈亏平衡销售量 [M124]
│       ├── 度量：4：利润 [M125]
│       ├── 度量：5：盈亏平衡点 [M126]
│       └── 度量：6：盈亏平衡收入 [M127]
├── 文件夹：开发复用
│   ├── 文件夹：值格式
│   │   ├── 度量：带正负号的百分比并保留两位小数 [M017]
│   │   ├── 度量：值÷1000，只有-号没有+的K格式化方案 [M018]
│   │   ├── 度量：值×100，带正负bp (基点) [M019]
│   │   ├── 度量：值×100，带正负pts (点) [M020]
│   │   ├── 度量：值的小数位0 [M021]
│   │   ├── 度量：值的小数位2 [M022]
│   │   ├── 度量：只带负号的百分比并保留两位小数 [M023]
│   │   ├── 度量：值的小数位1 [M024]
│   │   ├── 度量：千分位 整数 [M090]
│   │   ├── 度量：千分位 整数 美元符号 [M091]
│   │   └── 度量：只带负号的百分比整数 [M092]
│   ├── 文件夹：图表相关
│   │   ├── 度量：获取筛选值，动态计算指标 [M010]
│   │   ├── 度量：拼接百分比的值 [M011]
│   │   ├── 度量：拼接bp的值 [M012]
│   │   ├── 度量：拼接pts的值 [M013]
│   │   ├── 度量：条件格式里设置颜色 [M014]
│   │   ├── 度量：无关系的情况下，直接获取筛选器的值去计算指标 [M015]
│   │   └── 度量：K M B % 混合格式 [M095]
│   ├── 文件夹：字符拼接
│   │   ├── 度量：字符拼接 [M101]
│   │   ├── 度量：字符拼接_排序 [M104]
│   │   └── 度量：字符拼接_截断 [M105]
│   ├── 文件夹：字符相关
│   │   ├── 度量：图标库显示_↑●↓ [M016]
│   │   ├── 度量：UNICODE正方形 [M093]
│   │   ├── 度量：win+. 输入法符号 [M100]
│   │   └── 度量：换行符UNICHAR(10) [M130]
│   ├── 文件夹：常用函数
│   │   ├── 度量：SELECTCOLUMNS_从事实表中提取平台信息 [M026]
│   │   ├── 度量：DATATABLE_时间周期维度表 [M027]
│   │   ├── 度量：ADDCOLUMNS_创建品牌维度表 [M028]
│   │   ├── 度量：CONCATENATEX [M102]
│   │   ├── 度量：TOPN [M103]
│   │   ├── 度量：CALCULATETABLE [M106]
│   │   ├── 度量：COUNTROWS [M107]
│   │   ├── 度量：USERELATIONSHIP [M108]
│   │   ├── 度量：NATURALINNERJOIN [M109]
│   │   └── 度量：1.CONTAINSSTRING：信息函数 [M128]
│   ├── 文件夹：模型相关
│   │   ├── 度量：计算表 [M003]
│   │   └── 度量：构建指标维度 [M025]
│   ├── 文件夹：筛选相关
│   │   ├── 度量：1、判断当前店铺是否属于选中的平台 [M004]
│   │   ├── 度量：2、判断店铺是否应该出现在店铺切片器中 [M005]
│   │   ├── 度量：获取当前选中的时间周期，筛选器的值 [M006]
│   │   ├── 度量：3、优化_当前店铺平台是否在已选平台中_CONTAINS [M007]
│   │   ├── 度量：判断筛选器是否已选择值 [M008]
│   │   ├── 度量：筛选器影响图表 [M009]
│   │   ├── 度量：筛选控制器 [M085]
│   │   ├── 度量：0%~100% 切片器 [M097]
│   │   └── 度量：判断x轴是否落于全局筛选之中_timeframe（日/周/月/季/年） [M129]
│   └── 文件夹：颜色格式
│       ├── 度量：顶部_深蓝色_#0c2340: [M029]
│       ├── 度量：背景_纯白色_#ffffff: [M030]
│       ├── 度量：书签背景_米白色_#f5f1ea: [M031]
│       ├── 度量：看板背景_浅灰色_#f0f0f0: [M032]
│       ├── 度量：筛选器文字_浅咖色_#be9f71: [M033]
│       ├── 度量：黄_亮黄色_#E1C233: [M034]
│       ├── 度量：红_玫瑰红_#D64550: [M035]
│       ├── 度量：绿_草绿色_#1A9018: [M036]
│       ├── 度量：条形图例1_中灰色_#bcbcbc: [M037]
│       ├── 度量：条形图例2_深灰色_#8c8c8c: [M038]
│       ├── 度量：柱形图例_炭灰色_#808080: [M039]
│       ├── 度量：卡片标题_暗灰色_#595959: [M040]
│       ├── 度量：饼图图例1_灰蓝色_#90a0c2: [M041]
│       ├── 度量：饼图图例2_天蓝色_#6b9ad0: [M042]
│       ├── 度量：饼图图例3_海军蓝_#134885: [M043]
│       ├── 度量：饼图图例4_奶油色_#ffe8c6: [M044]
│       ├── 度量：饼图图例5_石板灰_#4e5762: [M045]
│       ├── 度量：饼图图例6_蜜桃色_#f3c279: [M046]
│       ├── 度量：饼图图例7_银灰色_#c4c4c4 [M047]
│       ├── 度量：表网格背景_象牙白_#f8f8f9: [M048]
│       ├── 度量：树形格子1_雾蓝色_#d8dee5: [M049]
│       ├── 度量：树形格子2_淡蓝色_#95afcf: [M050]
│       └── 度量：环形图嵌套_奶黄色_#ffe4bb [M051]
├── 文件夹：日期和时间
│   ├── 度量：今天日期 [M052]
│   ├── 度量：当前时间 [M053]
│   ├── 度量：UTC时间 [M054]
│   ├── 度量：当年年月 [M055]
│   ├── 度量：获取年、月、日等日期部分 [M056]
│   ├── 度量：动态北京时间 [M057]
│   └── 度量：日期的加减 [M058]
├── 文件夹：权限设计
│   ├── 度量：当前登录用户名 [M001]
│   └── 度量：账号 [M002]
├── 文件夹：页面导航
│   ├── 度量：页面导航按钮5 [M059]
│   ├── 度量：页面导航字体颜色_选中 [M060]
│   ├── 度量：页面导航字体颜色_未选中 [M061]
│   ├── 度量：页面导航填充颜色_选中 [M062]
│   ├── 度量：页面导航填充颜色_未选中 [M063]
│   ├── 度量：页面导航填充悬停颜色 [M064]
│   ├── 度量：页面导航按钮4 [M065]
│   ├── 度量：页面导航按钮3 [M066]
│   ├── 度量：页面导航按钮1 [M067]
│   └── 度量：页面导航按钮2 [M068]
└── 文件夹：页面按钮
    ├── 度量：按钮组1 [M069]
    ├── 度量：按钮组2 [M070]
    ├── 度量：按钮组3 [M071]
    ├── 度量：按钮边框_选中1 [M072]
    └── 度量：按钮边框_未选中1 [M073]
```

## 表：`A_资源库`

### 文件夹：`函数`

文件夹完整路径：`A_资源库\函数`；直接度量 0；含子层级度量 13。

#### 文件夹：`HTML`

文件夹完整路径：`A_资源库\函数\HTML`；直接度量 2；含子层级度量 2。

##### 度量：`HTML Content视觉对象多指标、多维度文本循环滚动`

- 源序号：M074
- 名称：`HTML Content视觉对象多指标、多维度文本循环滚动`
- 原始 TMDL 名称：`'HTML Content视觉对象多指标、多维度文本循环滚动'`
- 完整路径：`A_资源库\函数\HTML\HTML Content视觉对象多指标、多维度文本循环滚动`
- displayFolder：`函数\HTML`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1142–L1185](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1142-L1185)；表达式 L1143–L1181；元数据 L1183–L1185
- DAX SHA-256：`02e94f824ea956c7d47f5082b6c56906fd28b1597758cf2377fddd30cc574576`

**DAX 原文（含度量名称）**

```dax
HTML Content视觉对象多指标、多维度文本循环滚动 =

/*
HTML_Scrolling_Text("销售业绩" & FORMAT([总计],"#,#元") & "，业绩达成率" & FORMAT([占总计百分比（不受任何筛选影响）],"0.00%"))
/*
FUNCTION HTML_Scrolling_Text =
(TextMeasure:string)=>
"<style>
    .scroll-container {
        width: 100%;
        max-width: 1000px;
        overflow: hidden;
    }
        
    .scrolling-text {
        white-space: nowrap;
        display: inline-block;
        padding-left: 100%;
        animation: scroll 25s linear infinite;
        font-size: 1.8rem;
        font-weight: bold;
        text-shadow: 1px 1px 3px rgba(0, 0, 0, 0.5);
        }

        @keyframes scroll {
            0% {
                transform: translateX(0);
            }
            100% {
                transform: translateX(-100%);
            }
        }
    </style>
    <div class='scroll-container'>
        <div class='scrolling-text'>
            " & TextMeasure & "
        </div>
    </div>"
*/
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 函数\HTML
lineageTag: b63beaa8-9bf2-4f61-8721-e8c57c809028
```

##### 度量：`HTML Content 染色文本`

- 源序号：M098
- 名称：`HTML Content 染色文本`
- 原始 TMDL 名称：`'HTML Content 染色文本'`
- 完整路径：`A_资源库\函数\HTML\HTML Content 染色文本`
- displayFolder：`函数\HTML`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1741–L1754](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1741-L1754)；表达式 L1742–L1751；元数据 L1752–L1754
- DAX SHA-256：`f3f77b132ae81870332d6c4627bf3e8a83acb4b7b0798e87f2f42169aabbdd0e`

**DAX 原文（含度量名称）**

```dax
HTML Content 染色文本 =

/*
VAR v_Growth = [完成率 01]
VAR v_Color = IF(v_Growth > 0, "#1A9018", "#D64550")
VAR v_Arrow = IF(v_Growth > 0, "▲", "▼")
RETURN
    "本月增长 <span style='color:" & v_Color & "; font-weight:bold'>"
    & v_Arrow & " " & FORMAT(v_Growth, "+0.0%;-0.0%;0%")
    & "</span>"
    */
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 函数\HTML
lineageTag: 9551fa87-3cfd-4e6f-a0f9-8c8f3a17c7bc
```

#### 文件夹：`SVG`

文件夹完整路径：`A_资源库\函数\SVG`；直接度量 11；含子层级度量 11。

##### 度量：`表格矩阵、按钮切片器、新卡片图条件格式图标`

- 源序号：M081
- 名称：`表格矩阵、按钮切片器、新卡片图条件格式图标`
- 原始 TMDL 名称：`表格矩阵、按钮切片器、新卡片图条件格式图标`
- 完整路径：`A_资源库\函数\SVG\表格矩阵、按钮切片器、新卡片图条件格式图标`
- displayFolder：`函数\SVG`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1394–L1415](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1394-L1415)；表达式 L1395–L1412；元数据 L1413–L1415
- DAX SHA-256：`0db00e1c42e4c8f52912ee45af3ab9cb0e7be945ef79670c326cdac212638344`

**DAX 原文（含度量名称）**

```dax
表格矩阵、按钮切片器、新卡片图条件格式图标 =

/*
// ========================================
// 度量值: SVG_Shape
// 功能: 表格矩阵、按钮切片器、新卡片图条件格式图标
// 参数: 形状编号（1-圆，2-正方形，3-菱形，4-五角星，5-空心圆）、颜色（支持英文颜色名称、RGB）
// ========================================
SVG_Shape(if([占当前筛选上下文总计（受外部筛选器影响）]>=0.5,1,5),if([占当前筛选上下文总计（受外部筛选器影响）]>=0.5,"green","rgb(255,0,0)"))
/*
data:image/svg+xml;utf8,<svg width='400' height='30' xmlns='http://www.w3.org/2000/svg'>
    <foreignObject x='0' y='0' width='400' height='30'>
        <div xmlns='http://www.w3.org/1999/xhtml' style='display: flex; align-items: center; justify-content: left; height: 100%;'>
            <span style='font-size: 20px; color: blue; background-color: lightgrey; padding: 5px 15px; border-radius: 20px;'>SVG_Shape</span>
        </div>
    </foreignObject>
</svg>
*/
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 函数\SVG
lineageTag: 38cf75c9-c00d-4482-9a88-f17095f85cec
```

##### 度量：`表格矩阵、按钮切片器实现指定颜色的渐变条形图`

- 源序号：M082
- 名称：`表格矩阵、按钮切片器实现指定颜色的渐变条形图`
- 原始 TMDL 名称：`表格矩阵、按钮切片器实现指定颜色的渐变条形图`
- 完整路径：`A_资源库\函数\SVG\表格矩阵、按钮切片器实现指定颜色的渐变条形图`
- displayFolder：`函数\SVG`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1417–L1456](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1417-L1456)；表达式 L1418–L1452；元数据 L1454–L1456
- DAX SHA-256：`9b3ad4b3df94de483e09cb309e457fcf99090f5fb01bab47b2e4228366c37e34`

**DAX 原文（含度量名称）**

```dax
表格矩阵、按钮切片器实现指定颜色的渐变条形图 =

/*
// ========================================
// 分类：SVG图表
// 度量值: SVG_Gradient_Bar
// 功能: 表格矩阵、按钮切片器实现指定颜色的渐变条形图
// 参数: 维度表、指标、颜色
// ========================================
SVG_Gradient_Bar('G帕累托分析模板数据',CALCULATE(SUM('G帕累托分析模板数据'[销售额])),"Brown")
/*
FUNCTION SVG_Gradient_Bar = 
(TableForBar:anyref,MeasureForBar:numeric expr,Color:string)=>
VAR numerator =
    MAXX ( TableForBar, MeasureForBar)
VAR MaxValue =
    MAXX ( ALLSELECTED(TableForBar), MeasureForBar)
VAR LinearGradient= "
    <defs>
    <linearGradient id='wujunmin'>
        <stop offset='0%' style='stop-color:white'/>
        <stop offset='100%' style='stop-color:" & Color & "'/>
    </linearGradient>
    </defs>"
VAR SVG =  "
    data:image/svg+xml;utf8,
    <svg xmlns='http://www.w3.org/2000/svg' width='200' height='30' > " & 
        LinearGradient & "
        <rect rx='2' x='0' y='5' width='" & 200 * numerator / MaxValue & "' height='20' 
            fill='url(#wujunmin)'
        />
    </svg>"
RETURN
    SVG
*/
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 函数\SVG
lineageTag: 60cd9868-1078-4428-a9c9-44226d68ecb9
```

##### 度量：`表格矩阵、按钮切片器、新卡片图展示华夫饼样式的百分比02`

- 源序号：M083
- 名称：`表格矩阵、按钮切片器、新卡片图展示华夫饼样式的百分比02`
- 原始 TMDL 名称：`表格矩阵、按钮切片器、新卡片图展示华夫饼样式的百分比02`
- 完整路径：`A_资源库\函数\SVG\表格矩阵、按钮切片器、新卡片图展示华夫饼样式的百分比02`
- displayFolder：`函数\SVG`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1458–L1492](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1458-L1492)；表达式 L1459–L1489；元数据 L1490–L1492
- DAX SHA-256：`632e1d408b8aa734333c443dc9c1df214510ce92cc94aefc8e7bfd64e5d842bb`

**DAX 原文（含度量名称）**

```dax
表格矩阵、按钮切片器、新卡片图展示华夫饼样式的百分比02 =

/*
// ========================================
// 分类：SVG图表
// 度量值: SVG_Waffle
// 功能: 表格矩阵、按钮切片器、新卡片图展示华夫饼样式的百分比
// 参数: 百分比指标、颜色（支持英文颜色名称、RGB）
// ========================================
SVG_Waffle([占总计百分比（不受任何筛选影响）],IF([占总计百分比（不受任何筛选影响）]<0.5,"Brown","green"))

/*
FUNCTION SVG_Waffle =
    (PctMeasure:numeric,Color:string)=>
    VAR t =
        GENERATESERIES ( 1, 10 )
    VAR tPlus =
        GENERATE ( SELECTCOLUMNS ( t, "Value1", [Value] ), t )
    VAR tPlusPlus =
        ADDCOLUMNS ( tPlus, "Index", RANKX ( tPlus, [Value] + [Value1] / 100,, ASC ) )
    VAR tWaffle =
        ADDCOLUMNS (
            tPlusPlus,
            "circle",
                "<circle cx='" & [Value] * 10 -5  & "' cy='" & [Value1] * 10 -5 & "' r='4' fill='"
                    & IF ( [Index] <= ROUND (PctMeasure * 100, 0 ), Color , "LightGrey" ) & "' />")
    RETURN
        "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' id='wujunmin' width='100' height='100'>
            <g transform='rotate(-90,50,50)'>" & CONCATENATEX ( tWaffle, [circle] ) & "</g>
        </svg> "
*/
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 函数\SVG
lineageTag: 620e23ed-ef02-4809-ae19-201f1d46409b
```

##### 度量：`表格矩阵、按钮切片器、新卡片图展示华夫饼样式的百分比`

- 源序号：M084
- 名称：`表格矩阵、按钮切片器、新卡片图展示华夫饼样式的百分比`
- 原始 TMDL 名称：`表格矩阵、按钮切片器、新卡片图展示华夫饼样式的百分比`
- 完整路径：`A_资源库\函数\SVG\表格矩阵、按钮切片器、新卡片图展示华夫饼样式的百分比`
- displayFolder：`函数\SVG`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1494–L1528](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1494-L1528)；表达式 L1495–L1525；元数据 L1526–L1528
- DAX SHA-256：`9139406d7993e23bde12b60c2bb52d3d79308d2c2d31ed1eb1dbfad3bc8fcbe8`

**DAX 原文（含度量名称）**

```dax
表格矩阵、按钮切片器、新卡片图展示华夫饼样式的百分比 =

/*
// ========================================
// 分类：SVG图表
// 度量值: SVG_Waffle
// 功能: 表格矩阵、按钮切片器、新卡片图展示华夫饼样式的百分比
// 参数: 百分比指标、颜色（支持英文颜色名称、RGB）
// ========================================
SVG_Waffle([占当前筛选上下文总计（受外部筛选器影响）],IF([占当前筛选上下文总计（受外部筛选器影响）]<0.5,"Brown","green"))

/*
FUNCTION SVG_Waffle =
    (PctMeasure:numeric,Color:string)=>
    VAR t =
        GENERATESERIES ( 1, 10 )
    VAR tPlus =
        GENERATE ( SELECTCOLUMNS ( t, "Value1", [Value] ), t )
    VAR tPlusPlus =
        ADDCOLUMNS ( tPlus, "Index", RANKX ( tPlus, [Value] + [Value1] / 100,, ASC ) )
    VAR tWaffle =
        ADDCOLUMNS (
            tPlusPlus,
            "circle",
                "<circle cx='" & [Value] * 10 -5  & "' cy='" & [Value1] * 10 -5 & "' r='4' fill='"
                    & IF ( [Index] <= ROUND (PctMeasure * 100, 0 ), Color , "LightGrey" ) & "' />")
    RETURN
        "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' id='wujunmin' width='100' height='100'>
            <g transform='rotate(-90,50,50)'>" & CONCATENATEX ( tWaffle, [circle] ) & "</g>
        </svg> "
*/
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 函数\SVG
lineageTag: b4e713ab-0110-4748-aec8-d9d087d579f6
```

##### 度量：`面积折线图_by_day`

- 源序号：M086
- 名称：`面积折线图_by_day`
- 原始 TMDL 名称：`面积折线图_by_day`
- 完整路径：`A_资源库\函数\SVG\面积折线图_by_day`
- displayFolder：`函数\SVG`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1535–L1549](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1535-L1549)；表达式 L1536–L1546；元数据 L1547–L1549
- DAX SHA-256：`54571259a19902164e902ec8b98a9c8702d9a70b45876d725547311db3da55a9`

**DAX 原文（含度量名称）**

```dax
面积折线图_by_day =

/*
SVG_MiniAreaChart_by_day(
    '订单表',                      -- 表引用
    '日期表'[Date],                -- 日期列
    SUM('订单表'[销售数量]),        -- 聚合表达式（EXPR 参数）
    260,                           -- 宽度
    100,                           -- 高度
    0, 120, 212                    -- RGB 颜色：Power BI 蓝
)
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 函数\SVG
lineageTag: d645a052-2e77-4ef3-b2bc-edac3fbe3cda
```

##### 度量：`面积折线图_等距排列`

- 源序号：M087
- 名称：`面积折线图_等距排列`
- 原始 TMDL 名称：`面积折线图_等距排列`
- 完整路径：`A_资源库\函数\SVG\面积折线图_等距排列`
- displayFolder：`函数\SVG`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1551–L1571](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1551-L1571)；表达式 L1552–L1568；元数据 L1569–L1571
- DAX SHA-256：`5ebf46dcca6085162fb1a823271b194081b5167f298b161d587a523adcc1d4cc`

**DAX 原文（含度量名称）**

```dax
面积折线图_等距排列 =

/*
SVG_MiniAreaChart('日期表'[Date], SUM('订单表'[销售数量]), 260, 100, 0, 120, 212)
/*
// 日粒度
订单趋势_日 = SVG_MiniAreaChart('日期表'[Date], SUM('订单表'[销售数量]), 260, 100, 0, 120, 212)

// 月粒度（传入月份列；日期/整数/文本均可，文本需设置「按列排序」）
订单趋势_月 = SVG_MiniAreaChart('日期表'[YearMonth], SUM('订单表'[销售数量]), 260, 100, 0, 120, 212)

// 年粒度
订单趋势_年 = SVG_MiniAreaChart('日期表'[Year], SUM('订单表'[销售数量]), 260, 100, 0, 120, 212)

// 甚至可以是产品类别、地区等非日期维度
销量趋势_地区 = SVG_MiniAreaChart('地区表'[地区], SUM('订单表'[销售数量]), 200, 80, 40, 167, 69)
*/
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 函数\SVG
lineageTag: a1168730-32cc-43b1-a470-aa8dce3bd0d1
```

##### 度量：`三次贝塞尔曲线_by_day`

- 源序号：M088
- 名称：`三次贝塞尔曲线_by_day`
- 原始 TMDL 名称：`三次贝塞尔曲线_by_day`
- 完整路径：`A_资源库\函数\SVG\三次贝塞尔曲线_by_day`
- displayFolder：`函数\SVG`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1573–L1586](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1573-L1586)；表达式 L1574–L1583；元数据 L1584–L1586
- DAX SHA-256：`e184bc91e04c1390d9d88ce4db91514cdeefc54c85b2e1079894b2f0cee9036a`

**DAX 原文（含度量名称）**

```dax
三次贝塞尔曲线_by_day =

/*
SVG_SmoothArea_by_day(
    '订单表',
    '日期表'[Date],
    SUM('订单表'[销售数量]),
    260, 100,      // 宽 260，高 100
    0, 120, 212    // Power BI 蓝
)
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 函数\SVG
lineageTag: 30b24b5e-f948-4b0f-ab53-79fa0d3ab780
```

##### 度量：`三次贝塞尔曲线_等距排列`

- 源序号：M089
- 名称：`三次贝塞尔曲线_等距排列`
- 原始 TMDL 名称：`三次贝塞尔曲线_等距排列`
- 完整路径：`A_资源库\函数\SVG\三次贝塞尔曲线_等距排列`
- displayFolder：`函数\SVG`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1588–L1602](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1588-L1602)；表达式 L1589–L1598；元数据 L1600–L1602
- DAX SHA-256：`b79b4f6eed02d3817deb547b1f80d267fb445c8aa10502bb182681a0adff0b87`

**DAX 原文（含度量名称）**

```dax
三次贝塞尔曲线_等距排列 =

 /*
SVG_SmoothArea_Universal('日期表'[Date], SUM('订单表'[销售数量]), 260, 100, 0, 120, 212)
// ---------- 版本 2：通用等距（月/年/周/任意分类） ----------
/*
订单趋势_月 = SVG_SmoothArea_Universal('日期表'[YearMonth], SUM('订单表'[销售数量]), 260, 100, 0, 120, 212)
订单趋势_年 = SVG_SmoothArea_Universal('日期表'[Year],     SUM('订单表'[销售数量]), 260, 100, 0, 120, 212)
销量趋势_地区 = SVG_SmoothArea_Universal('地区表'[地区],    SUM('订单表'[销售数量]), 200, 80,  40, 167, 69)
*/
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 函数\SVG
lineageTag: 8eee9e89-b491-4037-81df-a85ba54b89d6
```

##### 度量：`热力矩阵图 颜色自适应 圆角`

- 源序号：M094
- 名称：`热力矩阵图 颜色自适应 圆角`
- 原始 TMDL 名称：`'热力矩阵图 颜色自适应 圆角'`
- 完整路径：`A_资源库\函数\SVG\热力矩阵图 颜色自适应 圆角`
- displayFolder：`函数\SVG`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1636–L1663](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1636-L1663)；表达式 L1637–L1660；元数据 L1661–L1663
- DAX SHA-256：`a91875b586c56961d459d983c436111ae1eb1f71a8e8c3597a1ebe23ff2d0b4f`

**DAX 原文（含度量名称）**

```dax
热力矩阵图 颜色自适应 圆角 =

/*
VAR _MinPct = MIN('Txn% 切片器'[Value])
VAR _MaxPct = MAX('Txn% 切片器'[Value])
RETURN
    SVG_Heatmap_Cell(
        [列100%],
        _MinPct,
        _MaxPct,
        "#,##0%;#,##0%;0%",
        "215,222,228",
        "149,176,206",
        "0,0,0",
        "179,179,179",
        "102,102,102",
        "255,255,255",
        "rgb(215,222,228)",
        "rgb(179,179,179)",
        88,
        33,
        12,
        4
    )
    */
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 函数\SVG
lineageTag: 0fdfe9c8-5308-4afa-92c9-f59e961b68ae
```

##### 度量：`柱形 渐变 动画`

- 源序号：M096
- 名称：`柱形 渐变 动画`
- 原始 TMDL 名称：`'柱形 渐变 动画'`
- 完整路径：`A_资源库\函数\SVG\柱形 渐变 动画`
- displayFolder：`函数\SVG`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1697–L1730](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1697-L1730)；表达式 L1698–L1727；元数据 L1728–L1730
- DAX SHA-256：`e023f1f3691a327651f16f606b119b0562fb70ce43c67cadbf31141b3e0f76fc`

**DAX 原文（含度量名称）**

```dax
柱形 渐变 动画 =

/*
VAR _CurrentValue = CALCULATE ( SUM ( '订单表'[销售数量] ) )
VAR _MaxValue =
    MAXX (
        SUMMARIZE (
            ALLSELECTED ( '日期表' ),
            '日期表'[月份名称],
            "@Sales", CALCULATE ( SUM ( '订单表'[销售数量] ) )
        ),
        [@Sales]
    )
VAR _AxisLabel = SELECTEDVALUE ( '日期表'[月份名称] )
RETURN
    SVG_Gradient_Animation_Bar_Chart(
                _CurrentValue,
                _MaxValue,
                _AxisLabel,
                0,
                50,
                250,
                30,
                "#d5b0aa",
                "#4f2958",
                "#2a114b",
                1,
                0,
                18
    )
    */
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 函数\SVG
lineageTag: b76207d6-95b4-4316-9c2f-fc713aa78a2f
```

##### 度量：`菱形进度条 独立着色`

- 源序号：M099
- 名称：`菱形进度条 独立着色`
- 原始 TMDL 名称：`'菱形进度条 独立着色'`
- 完整路径：`A_资源库\函数\SVG\菱形进度条 独立着色`
- displayFolder：`函数\SVG`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1756–L1791](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1756-L1791)；表达式 L1757–L1788；元数据 L1789–L1791
- DAX SHA-256：`54db7a1c3a6b3c9f9be588d71e9b7795563fb74748f3819aff48285745fb2f6c`

**DAX 原文（含度量名称）**

```dax
菱形进度条 独立着色 =

/*
/// ============================================================
    /// 功能：生成 SVG 菱形进度条（◆◆◇◇），支持逐字独立着色
    /// 背景：原生 REPT 无法对单元格内部分文本染色，必须改用 SVG 逐字着色。
    /// 用法：放入矩阵/表格的「值」区域，将度量值「数据类别」设为「图像 URL」
    /// 特性：
    ///   1. 以 maxRateExpr 为 100% 基准，决定一行共显示多少个菱形
    ///   2. 以 rateExpr 计算实心菱形（◆）数量，剩余显示空心菱形（◇）
    ///   3. 每个菱形为独立 <text> 元素，可分别指定 fill 颜色
    ///   4. 画布宽度自动根据总菱形数 × 字符宽度计算，无多余留白
    /// 参数：
    ///   rateExpr    : EXPR   — 当前完成率（0~1 小数），如 [完成率 01]
    ///   maxRateExpr : EXPR   — 当前上下文最大完成率（作为满格基准），如 [完成率 MAX]
    ///   doneColor   : STRING — 实心菱形颜色，如 "#1A9018"
    ///   undoneColor : STRING — 空心菱形颜色，如 "#D64550"
    ///   fontSize    : INT64  — 菱形符号字号（px），如 40
    ///   charWidth   : INT64  — 每个菱形水平占用像素宽度，如 22
    ///   svgHeight   : INT64  — SVG 画布高度（px），如 26
    ///   baseY       : INT64  — 菱形基线垂直位置（px），如 30
    /// ============================================================
    SVG_DiamondShapedProgressBar(
    [完成率 01],          // rateExpr    : 当前完成率
    [完成率 MAX],         // maxRateExpr : 当前上下文最大完成率（作为满格基准）
    "#1A9018",            // doneColor   : 已完成颜色（绿色）
    "#D64550",            // undoneColor : 未完成颜色（红色）
    40,                   // fontSize    : 菱形字号（px）
    22,                   // charWidth   : 单个菱形水平宽度（px）
    26,                   // svgHeight   : SVG 画布高度（px）
    30                    // baseY       : 菱形基线垂直位置（px）
)
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 函数\SVG
lineageTag: 0bae06c9-8204-48fe-a5e7-a3d01db6451c
```

### 文件夹：`分析模型`

文件夹完整路径：`A_资源库\分析模型`；直接度量 0；含子层级度量 24。

#### 文件夹：`基于购物篮数据的GE矩阵`

文件夹完整路径：`A_资源库\分析模型\基于购物篮数据的GE矩阵`；直接度量 11；含子层级度量 11。

##### 度量：`1 客户数`

- 源序号：M110
- 名称：`1 客户数`
- 原始 TMDL 名称：`'1 客户数'`
- 完整路径：`A_资源库\分析模型\基于购物篮数据的GE矩阵\1 客户数`
- displayFolder：`分析模型\基于购物篮数据的GE矩阵`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1982–L1997](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1982-L1997)；表达式 L1983–L1993；元数据 L1995–L1997
- DAX SHA-256：`20fd0d4f441c57afa429aeecb25ad0ebacabe5f0a8002c8c45a8921606260823`

**DAX 原文（含度量名称）**

```dax
1 客户数 =
1
/*
矩阵分析模型 四象限分析 产品关联分析 简化版的波士顿矩阵/GE矩阵思维
客户数 = 
/*
VALUES('订单表'[客户姓名]) —— 返回当前筛选上下文中，该列不重复且可见的值构成的单列表（会自动排除因关系筛选而不可见的值）。
COUNTROWS(...) —— 计算这个单列表有多少行。
结果：统计当前上下文里有多少个不同的客户姓名。
*/
COUNTROWS(VALUES('订单表'[客户姓名]))
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 分析模型\基于购物篮数据的GE矩阵
lineageTag: 056a012d-cda4-4bb2-9a84-60e4278e9089
```

##### 度量：`2 同时购买A和B的客户数`

- 源序号：M111
- 名称：`2 同时购买A和B的客户数`
- 原始 TMDL 名称：`'2 同时购买A和B的客户数'`
- 完整路径：`A_资源库\分析模型\基于购物篮数据的GE矩阵\2 同时购买A和B的客户数`
- displayFolder：`分析模型\基于购物篮数据的GE矩阵`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1999–L2025](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1999-L2025)；表达式 L2000–L2021；元数据 L2023–L2025
- DAX SHA-256：`b089ea4d812a06df2c1c837a3ee068167865c56467bc037e2524eae227a52b2d`

**DAX 原文（含度量名称）**

```dax
2 同时购买A和B的客户数 =
2
/*
同时购买A和B的客户数 = 
/*
如果 '关联产品表'[产品名称] 切片器同时选中了多个产品（比如 A、B、C），这段 DAX 表达的意思是：
购买过 A、B、C 中任意一个产品的客户数（OR 逻辑），而非「同时购买 A 且 B 且 C」的客户数（AND 逻辑）。

*/
VAR Bcustomer=

    CALCULATETABLE(

        VALUES('订单表'[客户姓名]),

        USERELATIONSHIP('关联产品表'[产品名称],'订单表'[产品名称]),

        ALL('产品表')

    )

RETURN CALCULATE([客户数],Bcustomer)
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 分析模型\基于购物篮数据的GE矩阵
lineageTag: 9e8b3e07-c83e-489a-afce-1cf9bfd6c68e
```

##### 度量：`3 关联客户占比`

- 源序号：M112
- 名称：`3 关联客户占比`
- 原始 TMDL 名称：`'3 关联客户占比'`
- 完整路径：`A_资源库\分析模型\基于购物篮数据的GE矩阵\3 关联客户占比`
- displayFolder：`分析模型\基于购物篮数据的GE矩阵`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L2027–L2034](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2027-L2034)；表达式 L2028–L2031；元数据 L2032–L2034
- DAX SHA-256：`48a58165b11de68c65d0f0a4b576fafa874da137fe7b441a68298e206e3f16a4`

**DAX 原文（含度量名称）**

```dax
3 关联客户占比 =
3
/*
关联客户占比 = DIVIDE([同时购买A和B的客户数],[客户数],BLANK())
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 分析模型\基于购物篮数据的GE矩阵
lineageTag: 447e43f8-5fed-4f61-83f4-886e61dc6ee4
```

##### 度量：`4 L销售额`

- 源序号：M113
- 名称：`4 L销售额`
- 原始 TMDL 名称：`'4 L销售额'`
- 完整路径：`A_资源库\分析模型\基于购物篮数据的GE矩阵\4 L销售额`
- displayFolder：`分析模型\基于购物篮数据的GE矩阵`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L2036–L2043](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2036-L2043)；表达式 L2037–L2040；元数据 L2041–L2043
- DAX SHA-256：`f49ae124a004b380e2eb3517b3df60449ae0fd4ef0741f3cb95e6ff7dfc67c89`

**DAX 原文（含度量名称）**

```dax
4 L销售额 =
4
/*
L销售额 = SUM('订单表'[销售额])
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 分析模型\基于购物篮数据的GE矩阵
lineageTag: b975f6e0-f471-4816-bf52-afb90d7d9a8b
```

##### 度量：`5 关联产品B的销售额`

- 源序号：M114
- 名称：`5 关联产品B的销售额`
- 原始 TMDL 名称：`'5 关联产品B的销售额'`
- 完整路径：`A_资源库\分析模型\基于购物篮数据的GE矩阵\5 关联产品B的销售额`
- displayFolder：`分析模型\基于购物篮数据的GE矩阵`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L2045–L2059](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2045-L2059)；表达式 L2046–L2055；元数据 L2057–L2059
- DAX SHA-256：`ac7287e2398f5ae8b5118050349f5443909c380f78cc745cedcbfc65d1c8dcc2`

**DAX 原文（含度量名称）**

```dax
5 关联产品B的销售额 =
5
/*
关联产品B的销售额 = 
// 仅仅计算购买了产品B的金额有多少？
CALCULATE([L销售额],

    USERELATIONSHIP('关联产品表'[产品名称],'订单表'[产品名称]),

    ALL('产品表') )
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 分析模型\基于购物篮数据的GE矩阵
lineageTag: 239a8903-143b-4949-a401-28430f82fc86
```

##### 度量：`6 同时购买A和B的客户中，购买产品B的金额`

- 源序号：M115
- 名称：`6 同时购买A和B的客户中，购买产品B的金额`
- 原始 TMDL 名称：`'6 同时购买A和B的客户中，购买产品B的金额'`
- 完整路径：`A_资源库\分析模型\基于购物篮数据的GE矩阵\6 同时购买A和B的客户中，购买产品B的金额`
- displayFolder：`分析模型\基于购物篮数据的GE矩阵`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L2061–L2095](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2061-L2095)；表达式 L2062–L2091；元数据 L2093–L2095
- DAX SHA-256：`b0738fd5120c55320c460b3edb9c1488afa3bd9d500280998de3815b2784c1d7`

**DAX 原文（含度量名称）**

```dax
6 同时购买A和B的客户中，购买产品B的金额 =
6
/*
同时购买A和B的客户中，购买产品B的金额 = 
// 先找出产品A和产品B的客户列表，然后通过 NATURALINNERJOIN 函数找出这两个客户列表的交集，也就是同时购买了这两种产品的客户
// 再计算同时购买A和B的客户中，购买产品B的金额。
// 客户重合比例高的两个产品，带来的关联产品的销售额并不一定高，这个跟产品价格、购买数量都有关系。
/*
切片器多选时，这段代码计算的是：买过产品 A、且至少买过一款选中关联产品的客户，他们购买这些关联产品的总金额。
它不是「同时购买 A 和 B」的金额，也不是「购买 B 的金额」——因为 Bcustomer 已经变成并集客户池，且最终度量值 [关联产品B的销售额] 在多选上下文通常也会汇总所有选中产品。
*/
VAR Acustomer=

    CALCULATETABLE(VALUES('订单表'[客户姓名]))

VAR Bcustomer=

    CALCULATETABLE(

        VALUES('订单表'[客户姓名]),

        USERELATIONSHIP('关联产品表'[产品名称],'订单表'[产品名称]),

        ALL('产品表'))

RETURN 
// [关联产品B的销售额]： 计算购买产品A的客户中，购买了产品B的金额有多少？
    CALCULATE([关联产品B的销售额],
// 同时购买产品A和B的客户表集合
        NATURALINNERJOIN(Acustomer,Bcustomer))
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 分析模型\基于购物篮数据的GE矩阵
lineageTag: b8e7b0af-56ec-49c3-8d77-a3253df67b4e
```

##### 度量：`7 平均_所有产品的关联销售额`

- 源序号：M116
- 名称：`7 平均_所有产品的关联销售额`
- 原始 TMDL 名称：`'7 平均_所有产品的关联销售额'`
- 完整路径：`A_资源库\分析模型\基于购物篮数据的GE矩阵\7 平均_所有产品的关联销售额`
- displayFolder：`分析模型\基于购物篮数据的GE矩阵`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L2097–L2125](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2097-L2125)；表达式 L2098–L2121；元数据 L2123–L2125
- DAX SHA-256：`2198ce1e3936edf00dc58ca9118682dd097bc1bbfc0c9a5381a7249ecaf3a5b2`

**DAX 原文（含度量名称）**

```dax
7 平均_所有产品的关联销售额 =
7
/*
平均_所有产品的关联销售额 = 
/*
功能：针对当前关联产品切片器选中的产品（单选或多选），
      遍历「产品表」中的每一个产品作为 A，
      分别计算「同时购买 A 和选中关联产品的客户中，购买选中关联产品的金额」，
      最后对所有产品 A 的结果求算术平均值。
      
用法：放入卡片图，或作为矩阵/表格的总计行度量值。
      若放入矩阵行中，每行显示相同的整体平均值（类似总计效果）。
      
范围选择：
  ALL('产品表')        → 产品表所有产品都参与平均（不受产品表切片器影响）
  ALLSELECTED('产品表')→ 只平均当前可见的产品（受产品表切片器影响）
  VALUES('产品表')     → 只平均当前上下文中有数据的产品（最严格）
每次迭代都是独立、正确的计算，最后 AVERAGEX 对所有结果求平均。
*/

AVERAGEX(
    ALL('产品表'[产品名称]),  -- 遍历产品表所有产品；改为 ALLSELECTED 则只算当前可见产品
    [同时购买A和B的客户中，购买产品B的金额]
)
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 分析模型\基于购物篮数据的GE矩阵
lineageTag: c4c26323-55f7-4ca3-bc24-693b9d4e20d4
```

##### 度量：`8 平均关联销售额 已选中`

- 源序号：M117
- 名称：`8 平均关联销售额 已选中`
- 原始 TMDL 名称：`'8 平均关联销售额 已选中'`
- 完整路径：`A_资源库\分析模型\基于购物篮数据的GE矩阵\8 平均关联销售额 已选中`
- displayFolder：`分析模型\基于购物篮数据的GE矩阵`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L2127–L2174](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2127-L2174)；表达式 L2128–L2170；元数据 L2172–L2174
- DAX SHA-256：`8e2954e26920aad3b1152d61289e4f31f88ad4cf963b7ea0830dd192614a33b9`

**DAX 原文（含度量名称）**

```dax
8 平均关联销售额 已选中 =
8
/*
平均关联销售额 已选中 = 
/*
功能：对于当前行的产品 A，分别计算它与每个选中关联产品（B/C/D...）的交集销售额，
      然后对这些单个结果求平均值。
      
用法：放入矩阵/表格，与 [同时购买A和B的客户中_购买产品B的金额] 配合使用。
*/

// 1. 固定产品 A 的客户池（当前行上下文，不受后续迭代影响）
VAR Acustomer = CALCULATETABLE(VALUES('订单表'[客户姓名]))

// 2. 获取切片器上选中的所有关联产品（B、C、D...）
VAR SelectedProducts = VALUES('关联产品表'[产品名称])

RETURN
    AVERAGEX(
        SelectedProducts,                    // 逐个产品迭代：第一次 B，第二次 C...
        VAR CurrentB = '关联产品表'[产品名称]  // 捕获当前迭代的产品名称

        // 3. 单独计算 CurrentB 的客户池（强制单选，避免多选合并）
        VAR Bcustomer = 
            CALCULATETABLE(
                VALUES('订单表'[客户姓名]),
                USERELATIONSHIP('关联产品表'[产品名称], '订单表'[产品名称]),
                ALL('产品表'),
                '关联产品表'[产品名称] = CurrentB   // 关键：锁定单个产品
            )

        // 4. 产品 A 和 CurrentB 的交集客户
        VAR CommonCustomers = NATURALINNERJOIN(Acustomer, Bcustomer)

        // 5. 计算这些交集客户购买 CurrentB 的金额
        //    此处显式传入 CurrentB 筛选，覆盖外部多选上下文
        RETURN 
            CALCULATE(
                [关联产品B的销售额],
                CommonCustomers,
                '关联产品表'[产品名称] = CurrentB
            )
    )
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 分析模型\基于购物篮数据的GE矩阵
lineageTag: 79db7b75-e9aa-4422-a93f-8bbf2ce872aa
```

##### 度量：`9 平均_所有产品的关联客户占比`

- 源序号：M118
- 名称：`9 平均_所有产品的关联客户占比`
- 原始 TMDL 名称：`'9 平均_所有产品的关联客户占比'`
- 完整路径：`A_资源库\分析模型\基于购物篮数据的GE矩阵\9 平均_所有产品的关联客户占比`
- displayFolder：`分析模型\基于购物篮数据的GE矩阵`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L2176–L2203](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2176-L2203)；表达式 L2177–L2199；元数据 L2201–L2203
- DAX SHA-256：`34d0418cc8918a8e8fe37ad90a390568885d39796d6f550c033e4ba20ce9adae`

**DAX 原文（含度量名称）**

```dax
9 平均_所有产品的关联客户占比 =
9
/*
平均_所有产品的关联客户占比 = 
/*
功能：针对当前关联产品切片器选中的产品（单选或多选），
      遍历「产品表」中的每一个产品作为 A，
      分别计算「同时购买 A 和选中关联产品的客户中，购买选中关联产品的金额」，
      最后对所有产品 A 的结果求算术平均值。
      
用法：放入卡片图，或作为矩阵/表格的总计行度量值。
      若放入矩阵行中，每行显示相同的整体平均值（类似总计效果）。
      
范围选择：
  ALL('产品表')        → 产品表所有产品都参与平均（不受产品表切片器影响）
  ALLSELECTED('产品表')→ 只平均当前可见的产品（受产品表切片器影响）
  VALUES('产品表')     → 只平均当前上下文中有数据的产品（最严格）
*/

AVERAGEX(
    ALL('产品表'[产品名称]),  -- 遍历产品表所有产品；改为 ALLSELECTED 则只算当前可见产品
    [关联客户占比]
)
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 分析模型\基于购物篮数据的GE矩阵
lineageTag: 9c64f934-f981-414b-91d3-f565775f6e5e
```

##### 度量：`91 运行总和 可视化计算`

- 源序号：M119
- 名称：`91 运行总和 可视化计算`
- 原始 TMDL 名称：`'91 运行总和 可视化计算'`
- 完整路径：`A_资源库\分析模型\基于购物篮数据的GE矩阵\91 运行总和 可视化计算`
- displayFolder：`分析模型\基于购物篮数据的GE矩阵`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L2205–L2212](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2205-L2212)；表达式 L2206–L2209；元数据 L2210–L2212
- DAX SHA-256：`b439ed2ac60d4b32374ce051419bc708742b12ce8d6f5487f5497b15fd94ae39`

**DAX 原文（含度量名称）**

```dax
91 运行总和 可视化计算 =
91
/*
运行总和 = RUNNINGSUM([同时购买A和B的客户中，购买产品B的金额])
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 分析模型\基于购物篮数据的GE矩阵
lineageTag: e4cee50e-95cb-4729-9981-33842cb8d092
```

##### 度量：`92 四象限配色`

- 源序号：M120
- 名称：`92 四象限配色`
- 原始 TMDL 名称：`'92 四象限配色'`
- 完整路径：`A_资源库\分析模型\基于购物篮数据的GE矩阵\92 四象限配色`
- displayFolder：`分析模型\基于购物篮数据的GE矩阵`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L2214–L2229](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2214-L2229)；表达式 L2215–L2225；元数据 L2227–L2229
- DAX SHA-256：`b16130591ee07013f8d7e8e49599d2adf3c465ddff55817e38715b1af4f3a916`

**DAX 原文（含度量名称）**

```dax
92 四象限配色 =
92
/*
四象限配色 = 
SWITCH(
    TRUE(),
    AND([同时购买A和B的客户中，购买产品B的金额]>=[平均_所有产品的关联销售额],[关联客户占比]>=[平均_所有产品的关联客户占比]),"#FF6440",
    AND([同时购买A和B的客户中，购买产品B的金额]>=[平均_所有产品的关联销售额],[关联客户占比]<[平均_所有产品的关联客户占比]),"#FFBC00",
    AND([同时购买A和B的客户中，购买产品B的金额]<[平均_所有产品的关联销售额],[关联客户占比]>=[平均_所有产品的关联客户占比]),"#00B74A",
    AND([同时购买A和B的客户中，购买产品B的金额]<[平均_所有产品的关联销售额],[关联客户占比]<[平均_所有产品的关联客户占比]),"#7277D8"
)
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 分析模型\基于购物篮数据的GE矩阵
lineageTag: 65a8c30d-bb52-4736-9c0e-258826a5f88f
```

#### 文件夹：`帕累托`

文件夹完整路径：`A_资源库\分析模型\帕累托`；直接度量 6；含子层级度量 6。

##### 度量：`帕累托累计占比(ADDCOLUMNS 版本)`

- 源序号：M075
- 名称：`帕累托累计占比(ADDCOLUMNS 版本)`
- 原始 TMDL 名称：`'帕累托累计占比(ADDCOLUMNS 版本)'`
- 完整路径：`A_资源库\分析模型\帕累托\帕累托累计占比(ADDCOLUMNS 版本)`
- displayFolder：`分析模型\帕累托`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1187–L1238](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1187-L1238)；表达式 L1188–L1234；元数据 L1236–L1238
- DAX SHA-256：`b605b5602f565f258c8aac657f37a4a0b333a8315a2f3fcd10b0bfdd6a83bb96`

**DAX 原文（含度量名称）**

```dax
帕累托累计占比(ADDCOLUMNS 版本) =

/*
// ========================================
// 度量值: Sales Pareto % (ADDCOLUMNS 版本)
// Display Folder: RATIO
// 用途: 帕累托分析中的累计销售额占比
// 说明: 
//   - 按销售额降序排列后，计算累计占比
//   - 使用 ADDCOLUMNS ALLSELECTED(全表) 预计算虚拟表
//   - 再用 FILTER + 变量比较完成累计筛选，避免上下文干扰
//   - 关键点: 基表使用 ADDCOLUMNS(ALLSELECTED(全表), [子类别])
//     而非 ALLSELECTED([子类别])
// ========================================

    // ── Step 1: 获取当前行（子类别）的销售额 ──
    VAR __CurrentSales = SUM('G帕累托分析模板数据'[销售额])
    
    // ── Step 2: 构建虚拟表 ──
    VAR __AllChannels = 
        ADDCOLUMNS(
                ALLSELECTED('G帕累托分析模板数据'),
            "@Sales", CALCULATE(SUM('G帕累托分析模板数据'[销售额]))
        )
    
    // ── Step 3: 计算累计销售额 ──
    // 筛选出销售额 >= 当前行的所有子类别（即排名在当前行之前或并列的），
    // 对其 @Sales 求和得到累计值
    VAR __CumulativeSales = 
        SUMX(
            FILTER(
                __AllChannels,
                [@Sales] >= __CurrentSales
            ),
            [@Sales]
        )
    
    // ── Step 4: 计算总销售额 ──
    VAR __TotalSales = 
        SUMX(
            __AllChannels,
            [@Sales]
        )
    
    // ── Step 5: 返回累计占比 = 累计值 / 总计 ──
    RETURN
        DIVIDE(__CumulativeSales, __TotalSales, 0)
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 分析模型\帕累托
lineageTag: 72924941-b1ae-4d36-b8fa-72a87d8292ee
```

##### 度量：`帕累托累计占比(SUMMARIZE 版本)`

- 源序号：M076
- 名称：`帕累托累计占比(SUMMARIZE 版本)`
- 原始 TMDL 名称：`'帕累托累计占比(SUMMARIZE 版本)'`
- 完整路径：`A_资源库\分析模型\帕累托\帕累托累计占比(SUMMARIZE 版本)`
- displayFolder：`分析模型\帕累托`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1240–L1275](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1240-L1275)；表达式 L1241–L1271；元数据 L1273–L1275
- DAX SHA-256：`19b0f1fdb2dfef24cf65552289d8b9ce0f32751e60a2864da447b1145be90b7b`

**DAX 原文（含度量名称）**

```dax
帕累托累计占比(SUMMARIZE 版本) =

/*
// ========================================
// 度量值: Sales Pareto % V2
// Display Folder: RATIO
// 用途: 帕累托累计占比（SUMMARIZE 版本）
// ========================================

    VAR __CurrentSales = SUM('G帕累托分析模板数据'[销售额])
    
    VAR __ChannelSales = 
        SUMMARIZE(
            ALLSELECTED('G帕累托分析模板数据'),
            'G帕累托分析模板数据'[子类别],
            "@Sales", CALCULATE(SUM('G帕累托分析模板数据'[销售额]))
        )
    
    VAR __CumulativeSales = 
        SUMX(
            FILTER(
                __ChannelSales,
                [@Sales] >= __CurrentSales
            ),
            [@Sales]
        )
    
    VAR __TotalSales = SUMX(__ChannelSales, [@Sales])
    
    RETURN 
        DIVIDE(__CumulativeSales, __TotalSales, 0)
*/
```

**原始元数据属性**

```tmdl
formatString: 0.00%;-0.00%;0.00%
displayFolder: 分析模型\帕累托
lineageTag: adb5fdfc-5f61-415d-8a44-89b5049db1f1
```

##### 度量：`帕累托累计占比(CALCULATE 嵌套版)`

- 源序号：M077
- 名称：`帕累托累计占比(CALCULATE 嵌套版)`
- 原始 TMDL 名称：`'帕累托累计占比(CALCULATE 嵌套版)'`
- 完整路径：`A_资源库\分析模型\帕累托\帕累托累计占比(CALCULATE 嵌套版)`
- displayFolder：`分析模型\帕累托`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1277–L1324](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1277-L1324)；表达式 L1278–L1320；元数据 L1322–L1324
- DAX SHA-256：`2a7b047b46b700feb5b70464e6fb5827a7872b09a59883173615ad8c31b40119`

**DAX 原文（含度量名称）**

```dax
帕累托累计占比(CALCULATE 嵌套版) =

/*
// ========================================
// 度量值: Sales Pareto % (CALCULATE 嵌套版)
// Display Folder: RATIO
// 用途: 帕累托累计占比（CALCULATE 嵌套版）
// 说明: 
//   - 纯 CALCULATE + FILTER 实现，不借助虚拟表变量
//   - 要求视觉对象按销售额降序排列
//   - 原理: 利用 FILTER + CALCULATE 上下文转换，
//     在 ALLSELECTED 全表的子类别列表中逐行求值并筛选出
//     销售额 >= 当前行的所有子类别，再对筛选结果求和得到累计值
//   - 注意: 此处使用 ALLSELECTED(全表) 而非 ALLSELECTED(单列)，
//     确保 FILTER 迭代时的筛选行为与 SUMMARIZE 版本一致
// ========================================

    // ── Step 1: 获取当前行（子类别）的销售额 ──
    // 在度量值中直接使用 SUM，由视觉对象的筛选上下文决定当前子类别
    VAR __CurrentSales = SUM('G帕累托分析模板数据'[销售额])
    
    // ── Step 2: 计算累计销售额 ──
    // FILTER 遍历 ALLSELECTED(全表) 按子类别分组后的每个值，
    // 对每一行做 CALCULATE(SUM(...)) 获取该子类别的销售额，
    // 仅保留销售额 >= 当前行值的子类别，外层 CALCULATE 对筛选结果求和
    VAR __CumulativeSales = 
        CALCULATE(
            SUM('G帕累托分析模板数据'[销售额]),
            FILTER(
                ALLSELECTED('G帕累托分析模板数据'),
                CALCULATE(SUM('G帕累托分析模板数据'[销售额])) >= __CurrentSales
            )
        )
    
    // ── Step 3: 计算总销售额（所有可见子类别的总和） ──
    VAR __TotalSales = CALCULATE(
        SUM('G帕累托分析模板数据'[销售额]),
        ALLSELECTED('G帕累托分析模板数据')
    )
    
    // ── Step 4: 返回累计占比 = 累计值 / 总计 ──
    RETURN
        DIVIDE(__CumulativeSales, __TotalSales, 0)
*/
```

**原始元数据属性**

```tmdl
formatString: 0.00%;-0.00%;0.00%
displayFolder: 分析模型\帕累托
lineageTag: 58ea6808-9ab9-485b-b24a-f8f8e36372b6
```

##### 度量：`占当前筛选上下文总计（受外部筛选器影响）`

- 源序号：M078
- 名称：`占当前筛选上下文总计（受外部筛选器影响）`
- 原始 TMDL 名称：`占当前筛选上下文总计（受外部筛选器影响）`
- 完整路径：`A_资源库\分析模型\帕累托\占当前筛选上下文总计（受外部筛选器影响）`
- displayFolder：`分析模型\帕累托`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1326–L1348](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1326-L1348)；表达式 L1327–L1344；元数据 L1346–L1348
- DAX SHA-256：`f229d8ef77c3b69a80bfe8f07dc0357d2f60704865d220f354453302c96b00ad`

**DAX 原文（含度量名称）**

```dax
占当前筛选上下文总计（受外部筛选器影响） =

/*
// ========================================
// 度量值: Sales % of Grand Total
// Display Folder: RATIO
// 用途: 当前销售额占当前筛选上下文总计的百分比
// 说明: 保留外部切片器筛选，只清除视觉对象内的行/列筛选
// ========================================

    VAR __CurrentSales = SUM('G帕累托分析模板数据'[销售额])
    VAR __GrandTotal = CALCULATE(
        SUM('G帕累托分析模板数据'[销售额]),
        ALLSELECTED('G帕累托分析模板数据')   // 只清除视觉对象内部筛选
    )
    
    RETURN
        DIVIDE(__CurrentSales, __GrandTotal, 0)
*/
```

**原始元数据属性**

```tmdl
formatString: 0.00%;-0.00%;0.00%
displayFolder: 分析模型\帕累托
lineageTag: 2276eece-8488-445d-97d8-5aaf7d2451b6
```

##### 度量：`占总计百分比（不受任何筛选影响）`

- 源序号：M079
- 名称：`占总计百分比（不受任何筛选影响）`
- 原始 TMDL 名称：`占总计百分比（不受任何筛选影响）`
- 完整路径：`A_资源库\分析模型\帕累托\占总计百分比（不受任何筛选影响）`
- displayFolder：`分析模型\帕累托`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1350–L1372](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1350-L1372)；表达式 L1351–L1368；元数据 L1370–L1372
- DAX SHA-256：`8b750fcdb4e0230b18f938071f1a7af26e690dabff2c026aed7234254790195d`

**DAX 原文（含度量名称）**

```dax
占总计百分比（不受任何筛选影响） =

/*
// ========================================
// 度量值: Sales % of Total
// Display Folder: RATIO
// 用途: 当前销售额占全局总计的百分比
// 说明: 始终基于全部数据计算分母，不受视觉对象行/列筛选影响
// ========================================

    VAR __CurrentSales = SUM('G帕累托分析模板数据'[销售额])
    VAR __TotalSales = CALCULATE(
        SUM('G帕累托分析模板数据'[销售额]),
        REMOVEFILTERS()           // 清除所有筛选器，获取全局总计
    )
    
    RETURN
        DIVIDE(__CurrentSales, __TotalSales, 0)
*/
```

**原始元数据属性**

```tmdl
formatString: 0.00%;-0.00%;0.00%
displayFolder: 分析模型\帕累托
lineageTag: a60c2161-bd6e-44db-b781-3538d1958b79
```

##### 度量：`总计`

- 源序号：M080
- 名称：`总计`
- 原始 TMDL 名称：`总计`
- 完整路径：`A_资源库\分析模型\帕累托\总计`
- displayFolder：`分析模型\帕累托`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1374–L1392](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1374-L1392)；表达式 L1375–L1388；元数据 L1390–L1392
- DAX SHA-256：`af613b7620f3ef8114722a40d499fee01c9f004ac997819a35a4e40052005b26`

**DAX 原文（含度量名称）**

```dax
总计 =

/*
// ========================================
// 度量值: Sales % of Total
// Display Folder: RATIO
// 用途: 当前销售额总计
// 说明: 汇总,受视觉对象行/列筛选影响
// ========================================

    VAR __CurrentSales = SUM('G帕累托分析模板数据'[销售额])
    
    RETURN
        __CurrentSales
*/
```

**原始元数据属性**

```tmdl
formatString: #,0
displayFolder: 分析模型\帕累托
lineageTag: fef62889-745b-4c1c-97a2-87e3844dda57
```

#### 文件夹：`盈亏平衡分析`

文件夹完整路径：`A_资源库\分析模型\盈亏平衡分析`；直接度量 7；含子层级度量 7。

##### 度量：`1：变动成本`

- 源序号：M121
- 名称：`1：变动成本`
- 原始 TMDL 名称：`1：变动成本`
- 完整路径：`A_资源库\分析模型\盈亏平衡分析\1：变动成本`
- displayFolder：`分析模型\盈亏平衡分析`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L2231–L2250](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2231-L2250)；表达式 L2232–L2248；元数据 L2249–L2250
- DAX SHA-256：`2f627f6bd3cd52ea8510d55dd0bdde453a90cc10ab4d35c23a8ae50f8e985099`

**DAX 原文（含度量名称）**

```dax
1：变动成本 =
"1M：变动成本"
/*
/*
盈亏平衡分析是研究固定成本、变动成本、
销售数量、销售价格与利润之间数量关系
的一种方法，也被称为量本利分析，是企
业进行价格制定、销售计划、盈利预测等
经营活动的重要工具；
假设某个产品预测计划中，有单位变动成
本、前期固定投入和销售毛利率三个变量，
在不考虑其他税费的情况下，达到什么销
量才能实现盈利呢？
参数：单位变动成本 = SELECTEDVALUE('参数_单位变动成本'[列：单位变动成本])
参数：销量 = SELECTEDVALUE('参数_销量'[列：销量])
*/
[参数：单位变动成本] * [参数：销量]
*/
```

**原始元数据属性**

```tmdl
displayFolder: 分析模型\盈亏平衡分析
lineageTag: 715035bf-0e34-415f-8e23-dd5176da79bc
```

##### 度量：`2：总成本`

- 源序号：M122
- 名称：`2：总成本`
- 原始 TMDL 名称：`2：总成本`
- 完整路径：`A_资源库\分析模型\盈亏平衡分析\2：总成本`
- displayFolder：`分析模型\盈亏平衡分析`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L2252–L2264](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2252-L2264)；表达式 L2253–L2262；元数据 L2263–L2264
- DAX SHA-256：`1250cba3f47df7aeca4476fd3942333564245370b1b83c6f6823bf8147c32eec`

**DAX 原文（含度量名称）**

```dax
2：总成本 =
"2M：总成本"
/*
/*
参数：单位变动成本 = SELECTEDVALUE('参数_单位变动成本'[列：单位变动成本])
参数：销量 = SELECTEDVALUE('参数_销量'[列：销量])
参数：固定成本 = SELECTEDVALUE('参数_固定成本'[列：固定成本])
参数：毛利率 = SELECTEDVALUE('参数_毛利率'[列：毛利率])
*/
[参数：固定成本] + [1M：变动成本]
*/
```

**原始元数据属性**

```tmdl
displayFolder: 分析模型\盈亏平衡分析
lineageTag: 1ec5cdf8-4775-4531-bdab-6ff974e1ee70
```

##### 度量：`3：收入`

- 源序号：M123
- 名称：`3：收入`
- 原始 TMDL 名称：`3：收入`
- 完整路径：`A_资源库\分析模型\盈亏平衡分析\3：收入`
- displayFolder：`分析模型\盈亏平衡分析`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L2266–L2290](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2266-L2290)；表达式 L2267–L2287；元数据 L2289–L2290
- DAX SHA-256：`f48da65f8b7e5730a7184839dd713695c52f2817339140be4ee7b6f2f82a982c`

**DAX 原文（含度量名称）**

```dax
3：收入 =
"3M：收入"
/*
/*
收入 = 变动成本 + 毛利
     = 变动成本 + (收入 × 毛利率)
     = 变动成本 ÷ (1 - 毛利率)
收入 = 售价 × 销量
变动成本 = 单位变动成本 × 销量
毛利 = 收入 - 变动成本 = 收入 × 毛利率
毛利率 = 毛利 ÷ 收入
公式推导：
    毛利率 = (收入 - 变动成本) ÷ 收入
       = 1 - (变动成本 ÷ 收入)
    (变动成本 ÷ 收入) = 1 - 毛利率
    收入 = 变动成本 - 变动成本 ÷ 毛利率
        = 变动成本 ÷ (1 - 毛利率)
    收入 = 毛利 + 变动成本 = 变动成本 + (收入 × 毛利率)
*/
DIVIDE( [1M：变动成本] , 1-[参数：毛利率] )
*/

```

**原始元数据属性**

```tmdl
displayFolder: 分析模型\盈亏平衡分析
lineageTag: 1ae6158e-d096-470b-ab31-c4d6b2b0b1ca
```

##### 度量：`7：盈亏平衡销售量`

- 源序号：M124
- 名称：`7：盈亏平衡销售量`
- 原始 TMDL 名称：`7：盈亏平衡销售量`
- 完整路径：`A_资源库\分析模型\盈亏平衡分析\7：盈亏平衡销售量`
- displayFolder：`分析模型\盈亏平衡分析`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L2292–L2303](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2292-L2303)；表达式 L2293–L2300；元数据 L2302–L2303
- DAX SHA-256：`407f52063945ac831ad7b2c4c01c5d19f529bc651ad8bbf5f051e954a314716e`

**DAX 原文（含度量名称）**

```dax
7：盈亏平衡销售量 =
"7M：盈亏平衡销售量"
/*
SUMX(
    ALL( '参数_销量' ),
    IF([3M：收入] = [5M：盈亏平衡点]  , [参数：销量])
)
*/

```

**原始元数据属性**

```tmdl
displayFolder: 分析模型\盈亏平衡分析
lineageTag: ea0e60aa-a73e-4e51-bd47-c9b3933973ca
```

##### 度量：`4：利润`

- 源序号：M125
- 名称：`4：利润`
- 原始 TMDL 名称：`4：利润`
- 完整路径：`A_资源库\分析模型\盈亏平衡分析\4：利润`
- displayFolder：`分析模型\盈亏平衡分析`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L2305–L2313](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2305-L2313)；表达式 L2306–L2310；元数据 L2312–L2313
- DAX SHA-256：`5b86c885bbf42c830f9301fc5bdb4fda5497d14d3027c6162206cbdca59ea09d`

**DAX 原文（含度量名称）**

```dax
4：利润 =
"4M：利润"
/*
[3M：收入] - [2M：总成本]
*/

```

**原始元数据属性**

```tmdl
displayFolder: 分析模型\盈亏平衡分析
lineageTag: 4af7e2ef-4eb9-4c3d-904b-2dcd1cc49430
```

##### 度量：`5：盈亏平衡点`

- 源序号：M126
- 名称：`5：盈亏平衡点`
- 原始 TMDL 名称：`5：盈亏平衡点`
- 完整路径：`A_资源库\分析模型\盈亏平衡分析\5：盈亏平衡点`
- displayFolder：`分析模型\盈亏平衡分析`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L2315–L2329](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2315-L2329)；表达式 L2316–L2326；元数据 L2328–L2329
- DAX SHA-256：`59cc998faaf86c83fd7718738d8b643e8d73c1759fa6f7828337684da59d7101`

**DAX 原文（含度量名称）**

```dax
5：盈亏平衡点 =
"5M：盈亏平衡点"
/*
/*
关键是盈亏平衡点的确定，直观的逻辑是收入曲线和成本曲线的交叉点，也就是利润为0对应的点，但在实际情况中，可能并不存在利润正好等于0的点，所以这里将盈亏平衡点的逻辑定义为利润非负的最小值所对应的点。
*/
-- 盈亏平衡点的计算逻辑，迭代每一个销量对应的利润，并返回利润非负的最小值
VAR _bep = MINX( ALL('参数_销量'),IF([4M：利润] > 0 , [4M：利润]))
// 返回盈亏平衡点对应的收入
RETURN IF([4M：利润] = _bep , [3M：收入] ) 
*/

```

**原始元数据属性**

```tmdl
displayFolder: 分析模型\盈亏平衡分析
lineageTag: 527de099-0d00-45e2-820c-b711a94c59a1
```

##### 度量：`6：盈亏平衡收入`

- 源序号：M127
- 名称：`6：盈亏平衡收入`
- 原始 TMDL 名称：`6：盈亏平衡收入`
- 完整路径：`A_资源库\分析模型\盈亏平衡分析\6：盈亏平衡收入`
- displayFolder：`分析模型\盈亏平衡分析`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L2331–L2339](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2331-L2339)；表达式 L2332–L2336；元数据 L2338–L2339
- DAX SHA-256：`6a2b89866024aa0c4297528a0fe1b2ea57c707a25283117252cc898441f40975`

**DAX 原文（含度量名称）**

```dax
6：盈亏平衡收入 =
"6M：盈亏平衡收入"
/*
SUMX( ALL( '参数_销量' ) , [5M：盈亏平衡点] )
*/

```

**原始元数据属性**

```tmdl
displayFolder: 分析模型\盈亏平衡分析
lineageTag: 23a5c15c-1f48-4f26-9410-8af4d1cf4267
```

### 文件夹：`开发复用`

文件夹完整路径：`A_资源库\开发复用`；直接度量 0；含子层级度量 69。

#### 文件夹：`值格式`

文件夹完整路径：`A_资源库\开发复用\值格式`；直接度量 11；含子层级度量 11。

##### 度量：`带正负号的百分比并保留两位小数`

- 源序号：M017
- 名称：`带正负号的百分比并保留两位小数`
- 原始 TMDL 名称：`带正负号的百分比并保留两位小数`
- 完整路径：`A_资源库\开发复用\值格式\带正负号的百分比并保留两位小数`
- displayFolder：`开发复用\值格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L493–L506](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L493-L506)；表达式 L494–L504；元数据 L505–L506
- DAX SHA-256：`987c36f1462417d86704d017115a53c033121162956e76c4e954617f8249e178`

**DAX 原文（含度量名称）**

```dax
带正负号的百分比并保留两位小数 =

"+#,##0.00%;-#,##0.00%;0.00%"
/*
注意事项：
1、如果数值已经乘以100，使用0.00而不是#,##0.00
2、如果需要千分位分隔符，可以简化为+0.00%;-0.00%;0.00%
3、如果零值不显示，可以将第三部分改为""，如：+0.00%;-0.00%;""
关键区别：
1、#,##0.00：有千分位分隔符，适合大数值（如：1,234.56）
2、0.00：无千分位分隔符，适合常规数值（如：1234.56）
*/
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\值格式
lineageTag: ab46e1a6-63f0-4f4a-b5f9-413d5e5d868b
```

##### 度量：`值÷1000，只有-号没有+的K格式化方案`

- 源序号：M018
- 名称：`值÷1000，只有-号没有+的K格式化方案`
- 原始 TMDL 名称：`值÷1000，只有-号没有+的K格式化方案`
- 完整路径：`A_资源库\开发复用\值格式\值÷1000，只有-号没有+的K格式化方案`
- displayFolder：`开发复用\值格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L508–L515](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L508-L515)；表达式 L509–L513；元数据 L514–L515
- DAX SHA-256：`ca05ad295676b7e6552bae08d05a60b0afe99921ace53c0ae9354cf2785efd0c`

**DAX 原文（含度量名称）**

```dax
值÷1000，只有-号没有+的K格式化方案 =

"#,##0'K';-#,##0'K';0'K'"
/*
在 Power BI 的自定义格式字符串中，逗号（,）仅当其位于数字部分格式的末尾时，才起到“缩放”（除以1000）的作用。如果逗号后面紧跟着文本（如 "K"），它将被视为一个普通的千分位分隔符和文本字符，而不会触发除法运算。错误示例："+#,##0.0,'K';-#,##0.0,'K';0.0'K'"
*/
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\值格式
lineageTag: d1631fdc-a8da-47d4-a7cb-ebb579e103c4
```

##### 度量：`值×100，带正负bp (基点)`

- 源序号：M019
- 名称：`值×100，带正负bp (基点)`
- 原始 TMDL 名称：`'值×100，带正负bp (基点)'`
- 完整路径：`A_资源库\开发复用\值格式\值×100，带正负bp (基点)`
- displayFolder：`开发复用\值格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L517–L521](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L517-L521)；表达式 L518–L519；元数据 L520–L521
- DAX SHA-256：`2003767f69725d07b0f7422f38175471b05c2be019acc43a3e0fce2e4d861727`

**DAX 原文（含度量名称）**

```dax
值×100，带正负bp (基点) =

"+#,##0.00'bp';-#,##0.00'bp';0.00'bp'"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\值格式
lineageTag: d130a2b8-c738-4f2b-a058-e73eff34c4a3
```

##### 度量：`值×100，带正负pts (点)`

- 源序号：M020
- 名称：`值×100，带正负pts (点)`
- 原始 TMDL 名称：`'值×100，带正负pts (点)'`
- 完整路径：`A_资源库\开发复用\值格式\值×100，带正负pts (点)`
- displayFolder：`开发复用\值格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L523–L527](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L523-L527)；表达式 L524–L525；元数据 L526–L527
- DAX SHA-256：`6bddd6442b111ae511bfc03862b069ed8920cdb8dd82e8f229c44fe6ba067c20`

**DAX 原文（含度量名称）**

```dax
值×100，带正负pts (点) =

"+#,##0.00'pts';-#,##0.00'pts';0.00'pts'"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\值格式
lineageTag: 5b9726d0-d2e9-4cae-b157-6a684188ef67
```

##### 度量：`值的小数位0`

- 源序号：M021
- 名称：`值的小数位0`
- 原始 TMDL 名称：`值的小数位0`
- 完整路径：`A_资源库\开发复用\值格式\值的小数位0`
- displayFolder：`开发复用\值格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L529–L532](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L529-L532)；表达式 L529–L529；元数据 L530–L532
- DAX SHA-256：`6c021f1bcc91646305086b7bf9e95bc06002301761af20611e49c335411a9a2e`

**DAX 原文（含度量名称）**

```dax
值的小数位0 = 0
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\值格式
lineageTag: 31004732-100a-43f5-ae63-fe8a0d850c99
```

##### 度量：`值的小数位2`

- 源序号：M022
- 名称：`值的小数位2`
- 原始 TMDL 名称：`值的小数位2`
- 完整路径：`A_资源库\开发复用\值格式\值的小数位2`
- displayFolder：`开发复用\值格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L534–L537](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L534-L537)；表达式 L534–L534；元数据 L535–L537
- DAX SHA-256：`16b54b666f248496dde186448d75b500a19bdf8748a79747f2baf72c4112aa2c`

**DAX 原文（含度量名称）**

```dax
值的小数位2 = 2
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\值格式
lineageTag: ab409b4a-be13-48a4-b43d-3b9298d1bd56
```

##### 度量：`只带负号的百分比并保留两位小数`

- 源序号：M023
- 名称：`只带负号的百分比并保留两位小数`
- 原始 TMDL 名称：`只带负号的百分比并保留两位小数`
- 完整路径：`A_资源库\开发复用\值格式\只带负号的百分比并保留两位小数`
- displayFolder：`开发复用\值格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L539–L552](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L539-L552)；表达式 L540–L550；元数据 L551–L552
- DAX SHA-256：`6808673ab7ea919fe5b7146e339479eaec34a14d22c97532e4fdf48e38d63ff5`

**DAX 原文（含度量名称）**

```dax
只带负号的百分比并保留两位小数 =

"#,##0.00%;#,##0.00%;0.00%"
/*
注意事项：
1、如果数值已经乘以100，使用0.00而不是#,##0.00
2、如果需要千分位分隔符，可以简化为+0.00%;-0.00%;0.00%
3、如果零值不显示，可以将第三部分改为""，如：+0.00%;-0.00%;""
关键区别：
1、#,##0.00：有千分位分隔符，适合大数值（如：1,234.56）
2、0.00：无千分位分隔符，适合常规数值（如：1234.56）
*/
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\值格式
lineageTag: edfdb4c8-8343-448a-95fa-912e853aeb0e
```

##### 度量：`值的小数位1`

- 源序号：M024
- 名称：`值的小数位1`
- 原始 TMDL 名称：`值的小数位1`
- 完整路径：`A_资源库\开发复用\值格式\值的小数位1`
- displayFolder：`开发复用\值格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L554–L557](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L554-L557)；表达式 L554–L554；元数据 L555–L557
- DAX SHA-256：`6a289d70ce1a86d5af96c7a206393135d1147ae2e68d3822fcd97b990c64f19d`

**DAX 原文（含度量名称）**

```dax
值的小数位1 = 1
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\值格式
lineageTag: 4ad4b03c-3db3-40b9-a157-250ef739ce21
```

##### 度量：`千分位 整数`

- 源序号：M090
- 名称：`千分位 整数`
- 原始 TMDL 名称：`'千分位 整数'`
- 完整路径：`A_资源库\开发复用\值格式\千分位 整数`
- displayFolder：`开发复用\值格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1604–L1608](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1604-L1608)；表达式 L1605–L1606；元数据 L1607–L1608
- DAX SHA-256：`d8b745516113a91313e6992c3eef33418b3479890e0c61cd9d1e195cd4e6522f`

**DAX 原文（含度量名称）**

```dax
千分位 整数 =

"#,##0"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\值格式
lineageTag: 5f497d0a-a8e4-43d4-b1d4-793195f9284c
```

##### 度量：`千分位 整数 美元符号`

- 源序号：M091
- 名称：`千分位 整数 美元符号`
- 原始 TMDL 名称：`'千分位 整数 美元符号'`
- 完整路径：`A_资源库\开发复用\值格式\千分位 整数 美元符号`
- displayFolder：`开发复用\值格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1610–L1614](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1610-L1614)；表达式 L1611–L1612；元数据 L1613–L1614
- DAX SHA-256：`fc006509c6d5f61122632b8ed73954ed15491991b7f684b399b15ded305e4029`

**DAX 原文（含度量名称）**

```dax
千分位 整数 美元符号 =

"$#,##0"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\值格式
lineageTag: 368a6237-7739-47b3-ad90-07205c2f2f7f
```

##### 度量：`只带负号的百分比整数`

- 源序号：M092
- 名称：`只带负号的百分比整数`
- 原始 TMDL 名称：`只带负号的百分比整数`
- 完整路径：`A_资源库\开发复用\值格式\只带负号的百分比整数`
- displayFolder：`开发复用\值格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1616–L1630](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1616-L1630)；表达式 L1617–L1628；元数据 L1629–L1630
- DAX SHA-256：`3f80bba573e37b4ed9f09fcd49387980312554d02032d3c0deb8298e13268843`

**DAX 原文（含度量名称）**

```dax
只带负号的百分比整数 =

"#,##0%;-#,##0%;0%"
/*
注意事项：
或者使用FORMAT(__Value, "#,##0.0%")，负值指定也会带上负号。
1、如果数值已经乘以100，使用0.00而不是#,##0.00
2、如果需要千分位分隔符，可以简化为+0.00%;-0.00%;0.00%
3、如果零值不显示，可以将第三部分改为""，如：+0.00%;-0.00%;""
关键区别：
1、#,##0.00：有千分位分隔符，适合大数值（如：1,234.56）
2、0.00：无千分位分隔符，适合常规数值（如：1234.56）
*/
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\值格式
lineageTag: 04afeafe-356e-4d32-bafa-5ea03affc05e
```

#### 文件夹：`图表相关`

文件夹完整路径：`A_资源库\开发复用\图表相关`；直接度量 7；含子层级度量 7。

##### 度量：`获取筛选值，动态计算指标`

- 源序号：M010
- 名称：`获取筛选值，动态计算指标`
- 原始 TMDL 名称：`获取筛选值，动态计算指标`
- 完整路径：`A_资源库\开发复用\图表相关\获取筛选值，动态计算指标`
- displayFolder：`开发复用\图表相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L303–L348](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L303-L348)；表达式 L304–L345；元数据 L346–L348
- DAX SHA-256：`8ac47e49a7132f34761f96565834deaa2b358103f0eabbbca29cdfdb8c61e0e1`

**DAX 原文（含度量名称）**

```dax
获取筛选值，动态计算指标 =

/*Dynamic_Metric_Value:
1、依赖D_Metrics_Dim表中的metric_id字段作为指标选择器
2、依赖'D_DCom - Sales & KPIs'表中的平台、店铺、日期字段作为筛选上下文
3、使用REMOVEFILTERS(D_Metrics_Dim)确保指标维度筛选不影响计算结果
4、当前仅支持核心销售指标，需按业务需求扩展SWITCH分支
5、该度量值适合在矩阵、卡片图等可视化元素中使用
*/

/*
// 步骤1：获取用户当前选择的筛选器值
VAR SelectedMetric =
    SELECTEDVALUE ( D_Metrics_Dim[metric_id] ) -- 用户选择的指标ID
VAR SelectedPlatform =
    SELECTEDVALUE ( 'D_DCom - Sales & KPIs'[platform] ) -- 用户选择的电商平台
VAR SelectedStore =
    SELECTEDVALUE ( 'D_DCom - Sales & KPIs'[store] ) -- 用户选择的店铺
VAR SelectedDate =
    SELECTEDVALUE ( 'D_DCom - Sales & KPIs'[start_date] ) -- 用户选择的起始日期
// 步骤2：根据用户选择的指标，使用SWITCH函数返回对应的计算结果
RETURN
    SWITCH (
        TRUE (),
        -- SWITCH(TRUE())模式，按条件顺序匹配
        // 分支1：计算DCom销售额
        SelectedMetric = "SLS_DCom",
            CALCULATE (
                SUM ( 'D_DCom - Sales & KPIs'[SLS DCom] ),
                -- 对DCom销售额字段求和
                REMOVEFILTERS ( D_Metrics_Dim ) -- 移除指标维度筛选，避免循环依赖
            ),
        // 分支2：计算DCom销售额同比目标达成率
        SelectedMetric = "SLS_DCom_vs_LY",
            CALCULATE (
                AVERAGE ( 'D_DCom - Sales & KPIs'[SLS DCom Tar Ach%] ),
                -- 计算目标达成率的平均值
                REMOVEFILTERS ( D_Metrics_Dim ) -- 移除指标维度筛选
            ),
        // 默认分支：当指标ID不匹配任何条件时返回空白
        BLANK ()
    )
    */
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\图表相关
lineageTag: 33b6de11-e45b-4894-96fa-b705745db331
```

##### 度量：`拼接百分比的值`

- 源序号：M011
- 名称：`拼接百分比的值`
- 原始 TMDL 名称：`拼接百分比的值`
- 完整路径：`A_资源库\开发复用\图表相关\拼接百分比的值`
- displayFolder：`开发复用\图表相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L350–L375](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L350-L375)；表达式 L351–L372；元数据 L374–L375
- DAX SHA-256：`86b2865bb17010617aa62f946acbf89b519af4f3b06eb769a21f0918e812e15e`

**DAX 原文（含度量名称）**

```dax
拼接百分比的值 =

VAR MaxValue = MAX('A_Measure'[sort_order])
RETURN
SWITCH(
    TRUE(),
    MaxValue > 0, "+" & FORMAT(MaxValue * 100, "0.00") & "%",
    MaxValue < 0, FORMAT(MaxValue * 100, "0.00") & "%",  // 负数自带负号
    MaxValue = 0, "0%",
    BLANK()
)
// TAR ACH%（SLS Ach%） = 
// VAR MaxValue = MAX('A_Measure'[sort_order])
// RETURN
// IF(
//     MaxValue > 0, 
//     "+" & FORMAT(MaxValue * 100, "0.00") & "%",
//     IF(
//         MaxValue < 0,
//         FORMAT(MaxValue * 100, "0.00") & "%",  // 负数自带负号，不需要加"-"
//         "0%"
//     )
// )
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\图表相关
lineageTag: 188aa906-d2e7-4975-879f-64d60430757d
```

##### 度量：`拼接bp的值`

- 源序号：M012
- 名称：`拼接bp的值`
- 原始 TMDL 名称：`拼接bp的值`
- 完整路径：`A_资源库\开发复用\图表相关\拼接bp的值`
- displayFolder：`开发复用\图表相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L377–L405](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L377-L405)；表达式 L378–L402；元数据 L404–L405
- DAX SHA-256：`ebff4179420bfa9ce80d838210496e3210b04a74a8771de291bed275431a247d`

**DAX 原文（含度量名称）**

```dax
拼接bp的值 =

VAR MaxValue = MAX('A_Measure'[sort_order])
VAR BasePoints = MaxValue * 100
RETURN
SWITCH(
    TRUE(),
    MaxValue > 0, "+" & FORMAT(BasePoints, "0") & "bp",
    MaxValue < 0, FORMAT(BasePoints, "0") & "bp",  // 负数自带负号
    MaxValue = 0, "0bp",
    BLANK()
)

// Cost vs SLS ACH% = 
// VAR MaxValue = MAX('A_Measure'[sort_order])
// VAR BasePoints = MaxValue * 100
// RETURN
// IF(
//     MaxValue > 0, 
//     "+" & FORMAT(BasePoints, "0.00") & "bp",
//     IF(
//         MaxValue < 0,
//         FORMAT(BasePoints, "0.00") & "bp",  // 负数自带负号
//         "0bp"
//     )
// )
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\图表相关
lineageTag: a65763f7-2520-4af0-9b8d-4a6b8734da57
```

##### 度量：`拼接pts的值`

- 源序号：M013
- 名称：`拼接pts的值`
- 原始 TMDL 名称：`拼接pts的值`
- 完整路径：`A_资源库\开发复用\图表相关\拼接pts的值`
- displayFolder：`开发复用\图表相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L407–L420](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L407-L420)；表达式 L408–L418；元数据 L419–L420
- DAX SHA-256：`b61cc742db62daeba2380db9ff98a18c49836f65c97bd20fe84dac1e194e4a54`

**DAX 原文（含度量名称）**

```dax
拼接pts的值 =

VAR MaxValue = MAX('A_Measure'[sort_order])
RETURN
SWITCH(
    TRUE(),
    MaxValue > 0, "+" & FORMAT(MaxValue, "0.00") & "pts",
    // MaxValue > 0, FORMAT(MaxValue, "0.00") & "pts", // 正数没有符号
    MaxValue < 0, FORMAT(MaxValue, "0.00") & "pts",  // 负数自带负号
    MaxValue = 0, "0pts",
    BLANK()
)
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\图表相关
lineageTag: ec20462b-bf76-4fcb-b60a-c8fa44add538
```

##### 度量：`条件格式里设置颜色`

- 源序号：M014
- 名称：`条件格式里设置颜色`
- 原始 TMDL 名称：`条件格式里设置颜色`
- 完整路径：`A_资源库\开发复用\图表相关\条件格式里设置颜色`
- displayFolder：`开发复用\图表相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L422–L443](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L422-L443)；表达式 L423–L440；元数据 L442–L443
- DAX SHA-256：`5cf267db549cc449ddf276077a10fa2ed3ddf430ef8b3245794f692034a27193`

**DAX 原文（含度量名称）**

```dax
条件格式里设置颜色 =

 // 此为视图层，最好直接引用模型的的度量
VAR MaxValue = MAX('A_Measure'[sort_order])
RETURN
if(MaxValue>0,"green",IF(MaxValue<0,"red","yellow"))

/*
ATV vs LY_2_Color = 
VAR _Value = MAX('A_Measure'[sort_order])
RETURN
SWITCH(
    TRUE(),
    _Value = 0, "#E1C233",  -- 等于0：黄色
    _Value > 0, "#1A9018",  -- 大于0：深绿色
    _Value < 0, "#D64550",  -- 小于0：红色
    BLANK()  -- 其他情况
)
*/
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\图表相关
lineageTag: c06563fb-bab6-48ff-bf54-4443137b6bd9
```

##### 度量：`无关系的情况下，直接获取筛选器的值去计算指标`

- 源序号：M015
- 名称：`无关系的情况下，直接获取筛选器的值去计算指标`
- 原始 TMDL 名称：`无关系的情况下，直接获取筛选器的值去计算指标`
- 完整路径：`A_资源库\开发复用\图表相关\无关系的情况下，直接获取筛选器的值去计算指标`
- displayFolder：`开发复用\图表相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L445–L474](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L445-L474)；表达式 L446–L470；元数据 L472–L474
- DAX SHA-256：`711d09deafb51d90262803ba637231fd5dc809cdebd328ddec403649234648c0`

**DAX 原文（含度量名称）**

```dax
无关系的情况下，直接获取筛选器的值去计算指标 =

-- 不建立关联，通过DAX处理筛选
/*
功能：动态销售额度量值
说明：结合平台筛选和动态店铺筛选
特点：不依赖物理关系，通过DAX传递筛选
*/

/*
VAR SelectedPlatforms = VALUES(D_Platform_Dim[platform_id])
VAR SelectedStores = 
    CALCULATETABLE(
        VALUES(D_StoreName_Dim[store_id]),
        ALLSELECTED(D_StoreName_Dim)
    )
RETURN
CALCULATE(
    1,  // 您的销售额度量值
    FILTER(
        'D_DCom - Sales & KPIs',
        'D_DCom - Sales & KPIs'[platform] IN SelectedPlatforms &&
        'D_DCom - Sales & KPIs'[store] IN SelectedStores
    )
)
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\图表相关
lineageTag: 1e005089-a627-4aea-a576-23911f60c789
```

##### 度量：`K M B % 混合格式`

- 源序号：M095
- 名称：`K M B % 混合格式`
- 原始 TMDL 名称：`'K M B % 混合格式'`
- 完整路径：`A_资源库\开发复用\图表相关\K M B % 混合格式`
- displayFolder：`开发复用\图表相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1665–L1695](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1665-L1695)；表达式 L1666–L1693；元数据 L1694–L1695
- DAX SHA-256：`99fd4646be0b643555f20d4bf63e0586149ac846f5433cd56c3179abab8b8732`

**DAX 原文（含度量名称）**

```dax
K M B % 混合格式 =

VAR MeasureValue =
    CALCULATE ( SUM ( 'A_Measure'[sort_order] ) )
VAR vIsRatio =
    IF (
        IFERROR ( FIND ( "%", MeasureValue ), BLANK () ) <> BLANK (),
        TRUE (),
        FALSE ()
    )
// 根据柱形值的大小和是否包含百分比信息，定义了柱形值的格式。
/*
1E3    1 × 10³    1,000    一千
1E6    1 × 10⁶    1,000,000    一百万
1E9    1 × 10⁹    1,000,000,000    十亿
*/
VAR MeasureFormat =
    SWITCH (
        TRUE (),
        vIsRatio, "0.0%",
        MeasureValue < 1E3, "#,##0",
        MeasureValue < 1E6, "#,##0,.0""K""",     // 1个逗号 = ÷1,000，显示 1.5K
        MeasureValue < 1E9, "#,##0,,.0""M""",    // 2个逗号 = ÷1,000,000，显示 1.5M
        "#,##0,,,.0""B"""                        // 3个逗号 = ÷1,000,000,000，显示 1.5B
    )
VAR Label =
    FORMAT ( MeasureValue, MeasureFormat )

RETURN Label
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\图表相关
lineageTag: 922483fd-5c0c-45f2-bbfb-b47807907f72
```

#### 文件夹：`字符拼接`

文件夹完整路径：`A_资源库\开发复用\字符拼接`；直接度量 3；含子层级度量 3。

##### 度量：`字符拼接`

- 源序号：M101
- 名称：`字符拼接`
- 原始 TMDL 名称：`字符拼接`
- 完整路径：`A_资源库\开发复用\字符拼接\字符拼接`
- displayFolder：`开发复用\字符拼接`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1810–L1825](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1810-L1825)；表达式 L1811–L1820；元数据 L1822–L1825
- DAX SHA-256：`c4b48a40f1df58f5d801e408254fd9d3a7180589691813e4b402b75cae09d3fa`

**DAX 原文（含度量名称）**

```dax
字符拼接 =

VAR _SelectedProducts = ALLSELECTED('A_Measure'[sort_order])
VAR _Count = COUNTROWS(_SelectedProducts)
VAR _Result = 
    IF(
        _Count = 1,
        MAX('A_Measure'[sort_order]),           // 单选：返回原始产品值
        CONCATENATEX(_SelectedProducts, 'A_Measure'[sort_order], " & ")  // 多选：用 & 拼接
    )
RETURN _Result
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\字符拼接
lineageTag: dd31f449-5406-4e17-b743-2204f33268e7

annotation PBI_FormatHint = {"isGeneralNumber":true}
```

##### 度量：`字符拼接_排序`

- 源序号：M104
- 名称：`字符拼接_排序`
- 原始 TMDL 名称：`字符拼接_排序`
- 完整路径：`A_资源库\开发复用\字符拼接\字符拼接_排序`
- displayFolder：`开发复用\字符拼接`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1866–L1887](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1866-L1887)；表达式 L1867–L1882；元数据 L1884–L1887
- DAX SHA-256：`e088837ef521b0c9073f36bef0e15fc2b9457ecd26c943127086d3b0177aaa43`

**DAX 原文（含度量名称）**

```dax
字符拼接_排序 =

// 控制拼接顺序
VAR _SelectedProducts = ALLSELECTED('A_Measure'[sort_order])
VAR _Count = COUNTROWS(_SelectedProducts)
VAR _Result = 
    IF(
        _Count = 1,
        MAX('A_Measure'[sort_order]),
        CONCATENATEX(
            _SelectedProducts, 
            'A_Measure'[sort_order], 
            " & ",
            'A_Measure'[sort_order], DESC  // 按产品名称升序排列
        )
    )
RETURN _Result
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\字符拼接
lineageTag: d52a8bf8-fff9-4846-9b6a-ad36edcd5a63

annotation PBI_FormatHint = {"isGeneralNumber":true}
```

##### 度量：`字符拼接_截断`

- 源序号：M105
- 名称：`字符拼接_截断`
- 原始 TMDL 名称：`字符拼接_截断`
- 完整路径：`A_资源库\开发复用\字符拼接\字符拼接_截断`
- displayFolder：`开发复用\字符拼接`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1889–L1925](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1889-L1925)；表达式 L1890–L1920；元数据 L1922–L1925
- DAX SHA-256：`5f64f7e7859896ebbab2ac0f0bd6eac07dcd8d3aaadf87a7442b7c1e2f300e4c`

**DAX 原文（含度量名称）**

```dax
字符拼接_截断 =

/*
限制显示个数（如最多显示3个，超出用"等N项"）
TOPN 是"筛选器"，不是"排序器"。 它返回的表在 DAX 里被视为无序集合。想让拼接结果有序，必须在 CONCATENATEX 中显式声明 ORDER BY。
*/
VAR _SelectedProducts = ALLSELECTED('A_Measure'[sort_order])
VAR _Count = COUNTROWS(_SelectedProducts)
VAR _First3 = TOPN(3, _SelectedProducts, 'A_Measure'[sort_order], ASC)
VAR _Result = 
    IF(
        _Count = 1,
        MAX('A_Measure'[sort_order]),
        IF(
            _Count <= 3,
            // 多选 ≤3 个：直接拼接，显式按产品名升序
            CONCATENATEX(
                _SelectedProducts, 
                'A_Measure'[sort_order], 
                " & ",
                'A_Measure'[sort_order], ASC
            ),
            // 多选 >3 个：先 TOPN 取前3，再显式排序拼接
            CONCATENATEX(
                _First3, 
                'A_Measure'[sort_order], 
                " & ",
                'A_Measure'[sort_order], ASC
            ) & " 等" & _Count & "项"
        )
    )
RETURN _Result
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\字符拼接
lineageTag: cb0c10b3-3564-4c44-9080-6eb64bd825bc

annotation PBI_FormatHint = {"isGeneralNumber":true}
```

#### 文件夹：`字符相关`

文件夹完整路径：`A_资源库\开发复用\字符相关`；直接度量 4；含子层级度量 4。

##### 度量：`图标库显示_↑●↓`

- 源序号：M016
- 名称：`图标库显示_↑●↓`
- 原始 TMDL 名称：`图标库显示_↑●↓`
- 完整路径：`A_资源库\开发复用\字符相关\图标库显示_↑●↓`
- displayFolder：`开发复用\字符相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L476–L491](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L476-L491)；表达式 L477–L489；元数据 L490–L491
- DAX SHA-256：`97538f80e71fe8af623c2763afa0787b767cebd71c71ece4366c527b2ccf96ae`

**DAX 原文（含度量名称）**

```dax
图标库显示_↑●↓ =

VAR a = MAX('A_Measure'[sort_order])*1000
RETURN

SWITCH(
    TRUE(),
    a > 0, "↑ " & FORMAT(ABS(a), "0.0") & "pts",
    a < 0, "↓ " & FORMAT(ABS(a), "0.0") & "pts",
    "● " & FORMAT(a, "0.0") & "pts"
)
// ""▲ "这种常用图像都列举出来。包括不仅..."点击查看元宝的回答
// "▲ 0%;▼ -0%; - " "🡽;🡾; - "
// https://yb.tencent.com/s/SC3o3SOBv7iL
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\字符相关
lineageTag: a127911d-14d3-4070-b20c-a9d525720d08
```

##### 度量：`UNICODE正方形`

- 源序号：M093
- 名称：`UNICODE正方形`
- 原始 TMDL 名称：`UNICODE正方形`
- 完整路径：`A_资源库\开发复用\字符相关\UNICODE正方形`
- displayFolder：`开发复用\字符相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1632–L1634](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1632-L1634)；表达式 L1632–L1632；元数据 L1633–L1634
- DAX SHA-256：`e54175d52be9e2857dbfd7e06b99b14f1f8ad3b1c8a5a20a629f45798430dfaf`

**DAX 原文（含度量名称）**

```dax
UNICODE正方形 = UNICHAR(9632)
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\字符相关
lineageTag: 3052966a-060c-4b1a-a551-2578d5882b61
```

##### 度量：`win+. 输入法符号`

- 源序号：M100
- 名称：`win+. 输入法符号`
- 原始 TMDL 名称：`'win+. 输入法符号'`
- 完整路径：`A_资源库\开发复用\字符相关\win+. 输入法符号`
- displayFolder：`开发复用\字符相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1793–L1808](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1793-L1808)；表达式 L1794–L1805；元数据 L1806–L1808
- DAX SHA-256：`f6d7ee01a1f8ecc8c1de430b6c3209707c9c075a13eeeb61edf97a517cc2e28f`

**DAX 原文（含度量名称）**

```dax
win+. 输入法符号 =

/*
/*
REPT：按给定次数重复文本。 使用 REPT 用文本字符串的多个实例填充单元格。
这样就没法显示具体值了。
◇ ◆ ● ◌ ★ ☆ ◇ ◆  ▷ ▶ ◁ ◀  ♡ ♥ ♢ ♦ ♧ ♣ ★ ☆ 💚💚❤️❤️💔💔💛💛🤍🤍  "▲", "▼"
*/
VAR a=ROUND([完成率 01]*10,0)
VAR b=ROUND([完成率 MAX]*10,0)
RETURN
REPT( "◆", a ) & REPT( "◇", IF(b<=10, 10 - a, b - a ))
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\字符相关
lineageTag: 3f44a436-7036-4da6-b4a1-396c1c088209
```

##### 度量：`换行符UNICHAR(10)`

- 源序号：M130
- 名称：`换行符UNICHAR(10)`
- 原始 TMDL 名称：`换行符UNICHAR(10)`
- 完整路径：`A_资源库\开发复用\字符相关\换行符UNICHAR(10)`
- displayFolder：`开发复用\字符相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L2427–L2444](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2427-L2444)；表达式 L2428–L2441；元数据 L2443–L2444
- DAX SHA-256：`e37840b5f6301cd9cf8a0e4f854522930086b13393cf44e05bcc0f550d468357`

**DAX 原文（含度量名称）**

```dax
换行符UNICHAR(10) =
" "
/*
UNICHAR(32)   普通空格 (Space)                             键盘上打的空格。在 HTML / Power BI 渲染中受"空白折叠"规则限制，多个连续空格会被合并成 1 个。
UNICHAR(160) 不换行空格 (Non-breaking Space, &nbsp;)      专门用来强制保留空格的字符。HTML 不会把它折叠，多个就显示多个，且不会自动换行。是你当前形状 Tooltip 里唯一能用的"空格"。
UNICHAR(10)  换行符 (Line Feed, LF)                       相当于代码里的 \n。在 Power BI 的卡片图、报表页面 Tooltip（开启 Word wrap）中能正常换行；但在形状/按钮的 Action Tooltip 中会被直接剥除。
UNICHAR(13)  回车符 (Carriage Return, CR)                 相当于代码里的 \r。通常和 UNICHAR(10) 搭配写成 UNICHAR(13) & UNICHAR(10)（即 Windows 的 CRLF 换行），但在 Power BI 默认 Tooltip 里同样基本无效。
CHAR(8203) = U+200B 零宽空格，肉眼不可见但占字符位，是数仓里导致 DISTINCT 虚高、JOIN 漏匹配、GROUP BY 多出空壳分组 的头号隐形元凶。
*/
// -- 第一行标题
// "TAR ACH% display rules" & 
// -- 尝试换行 + 用非断行空格撑开一段距离
// UNICHAR(10) & REPT(UNICHAR(160), 86) & 
// -- 正文内容（如果不需要英文引号，把 ""-"" 改回 - 即可）
// "TAR ACH% is shown as ""-"" for Day and Week, for Timeframes not applicable to the metric, or when target data is unavailable for the selected period."
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\字符相关
lineageTag: 1c648c57-ef95-42a9-98cc-be7e43d1f8cd
```

#### 文件夹：`常用函数`

文件夹完整路径：`A_资源库\开发复用\常用函数`；直接度量 10；含子层级度量 10。

##### 度量：`SELECTCOLUMNS_从事实表中提取平台信息`

- 源序号：M026
- 名称：`SELECTCOLUMNS_从事实表中提取平台信息`
- 原始 TMDL 名称：`SELECTCOLUMNS_从事实表中提取平台信息`
- 完整路径：`A_资源库\开发复用\常用函数\SELECTCOLUMNS_从事实表中提取平台信息`
- displayFolder：`开发复用\常用函数`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L629–L664](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L629-L664)；表达式 L630–L660；元数据 L662–L664
- DAX SHA-256：`9a66f471c1558ad4454acfe4abdac29ae643f64dbbd67397dd3462df8b9f143d`

**DAX 原文（含度量名称）**

```dax
SELECTCOLUMNS_从事实表中提取平台信息 =

/*
// 从事实表中提取平台信息
DISTINCT(
    SELECTCOLUMNS(
        'D_DCom - Sales & KPIs',
        "platform_id", 'D_DCom - Sales & KPIs'[platform],
        "platform_name", 
            SWITCH(
                'D_DCom - Sales & KPIs'[platform],
                "TM", "天猫",
                "JD", "京东",
                "DY", "抖音",
                "RLE", "小红书",
                "Total", "总计",
                'D_DCom - Sales & KPIs'[platform]
            ),
        "platform_code", 'D_DCom - Sales & KPIs'[platform],
        "platform_order",
            SWITCH(
                'D_DCom - Sales & KPIs'[platform],
                "Total", 1,
                "TM", 2,
                "JD", 3,
                "DY", 4,
                "RLE", 5,
                99
            )
    )
)
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\常用函数
lineageTag: 918f67af-1c13-4275-ab0d-d415a58b2fb2
```

##### 度量：`DATATABLE_时间周期维度表`

- 源序号：M027
- 名称：`DATATABLE_时间周期维度表`
- 原始 TMDL 名称：`DATATABLE_时间周期维度表`
- 完整路径：`A_资源库\开发复用\常用函数\DATATABLE_时间周期维度表`
- displayFolder：`开发复用\常用函数`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L666–L714](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L666-L714)；表达式 L667–L710；元数据 L712–L714
- DAX SHA-256：`7259d57f723dc6be3c7ce6e7135666c495957537a63ec41090b3bcf3ca0832f0`

**DAX 原文（含度量名称）**

```dax
DATATABLE_时间周期维度表 =

/*
/*
功能：创建一个时间周期维度表，用于报表中的时间周期筛选和分组
用途：用户可以通过此表选择不同的时间分析周期（如日、周、月累计、年累计等）
*/

VAR TimeData = 
    DATATABLE(
        // 定义表的列结构
        "Time_Code", STRING,       // 时间周期代码，用于程序内部标识
        "Time_Name", STRING,       // 时间周期英文名称，用于技术标识
        "Time_Name_Display", STRING, // 时间周期显示名称，用于报表界面显示
        "Time_Type", STRING,       // 时间周期类型：基础周期/累计周期
        "Time_Category", STRING,   // 时间周期类别，用于进一步分类
        "Sort_Order", INTEGER,     // 排序顺序，控制报表中显示的顺序
        "Is_Default", INTEGER,     // 是否默认选中：1-是，0-否
        "Icon", STRING,           // 图标标识，可用于可视化显示
        {
            // 基础周期 - 表示固定的时间单位
            {"DAILY", "Daily", "最近七天", "累计周期", "精确周期", 2, 0, "●"},
            // 解释：DAILY 表示按天统计，是基础的精确时间周期
            
            // 累计周期 - 表示从周期开始到当前日期的累计
            {"MTD", "Month-to-Date", "本月至今", "累计周期", "累计周期", 3, 0, "📈"},
            // 解释：MTD 计算从当月第一天到当前日期的累计值
            
            {"QTD", "Quarter-to-Date", "本季至今", "累计周期", "累计周期", 4, 0, "📊"},
            // 解释：QTD 计算从当季第一天到当前日期的累计值
            
            {"WTD", "Week-to-Date", "本周至今", "累计周期", "累计周期", 6, 1, "📅"},
            // 解释：WTD 计算从本周第一天到当前日期的累计值，设为默认选项
            
            {"YTD", "Year-to-Date", "本年至今", "累计周期", "累计周期", 7, 0, "🎯"},
            // 解释：YTD 计算从当年第一天到当前日期的累计值

            {"DATE", "Date", "自定义日期", "基础周期", "精确周期", 99, 0, "📅"}
            // 解释：DATE 允许用户自定义日期范围，提供最大灵活性
        }
    )

RETURN
TimeData
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\常用函数
lineageTag: 1cdefb75-f9f4-40a8-b7f3-7060f2398619
```

##### 度量：`ADDCOLUMNS_创建品牌维度表`

- 源序号：M028
- 名称：`ADDCOLUMNS_创建品牌维度表`
- 原始 TMDL 名称：`ADDCOLUMNS_创建品牌维度表`
- 完整路径：`A_资源库\开发复用\常用函数\ADDCOLUMNS_创建品牌维度表`
- displayFolder：`开发复用\常用函数`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L716–L795](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L716-L795)；表达式 L717–L791；元数据 L793–L795
- DAX SHA-256：`b42b1bc76033c8d00e5d19e284d1b2a03921846e30f49a1b1ab70ccb328d6f32`

**DAX 原文（含度量名称）**

```dax
ADDCOLUMNS_创建品牌维度表 =

/*
/*
功能：创建品牌维度表
说明：从事实表提取唯一品牌值，建立标准化维度表
注意：品牌包括主品牌、副品牌和产品线
*/
VAR BrandValues = 
    DISTINCT(
        SELECTCOLUMNS(
            'M_Merch-Sales Mix by Label',
            "Brand_Clean", 
            TRIM(SUBSTITUTE('M_Merch-Sales Mix by Label'[Brand], " ", ""))
        )
    )
RETURN
ADDCOLUMNS(
    BrandValues,
    
    // 主键：唯一标识符
    "Brand_Key", RANKX(BrandValues, [Brand_Clean], , ASC, Dense),
    
    // 原始品牌代码
    "Brand_Code", IF(ISBLANK([Brand_Clean]),"Unknown",[Brand_Clean]),
    
    // 品牌显示名称
    "Brand_Name", 
        SWITCH(
            [Brand_Clean],
            "RRL", "RRL",                     // RRL品牌
            "Lauren", "Ralph Lauren",         // Ralph Lauren品牌
            "Polo", "Polo",                   // Polo品牌
            "CL", "Collection",               // Collection系列
            "Overall", "Overall",             // 总计
            BLANK(), "Unknown",
            UPPER([Brand_Clean])                    // 其他品牌转为大写
        ),
    
    // 品牌层级：标识品牌层级（主品牌、副品牌、产品线）
    "Brand_Level",
        SWITCH(
            [Brand_Clean],
            "RRL", "Sub-Brand",      // 副品牌
            "Lauren", "Main-Brand",  // 主品牌
            "Polo", "Main-Brand",    // 主品牌
            "CL", "Collection",      // 系列
            "Overall", "Total",      // 总计
            "Brand"                  // 其他为普通品牌
        ),
    
    // 品牌分组：将品牌归入业务组
    "Brand_Group",
        SWITCH(
            [Brand_Clean],
            "RRL", "Premium",        // 高端系列
            "Lauren", "Premium",     // 高端系列
            "Polo", "Core",          // 核心系列
            "CL", "Collection",      // 精选系列
            "Overall", "Overall",    // 总计
            "Core"                   // 其他为核心品牌
        ),
    
    // 排序顺序
    "Sort_Order",
        SWITCH(
            [Brand_Clean],
            "Overall", 1,            // 总计排第一
            "RRL", 2,                // RRL
            "Lauren", 3,             // Lauren
            "Polo", 4,               // Polo
            "CL", 5,                 // CL
            99                       // 其他排在最后
        )
)
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\常用函数
lineageTag: 9800be72-bc87-42ad-a730-7519b868ca08
```

##### 度量：`CONCATENATEX`

- 源序号：M102
- 名称：`CONCATENATEX`
- 原始 TMDL 名称：`CONCATENATEX`
- 完整路径：`A_资源库\开发复用\常用函数\CONCATENATEX`
- displayFolder：`开发复用\常用函数`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1827–L1840](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1827-L1840)；表达式 L1828–L1837；元数据 L1838–L1840
- DAX SHA-256：`626b61e4e246f3eef21c14287945af1375ce065da4c757cb71f4fd6689eff7f1`

**DAX 原文（含度量名称）**

```dax
CONCATENATEX =
1
/*
CONCATENATEX(
    表,
    表达式,
    分隔符,
    排序表达式, [排序方向],   -- ← 第4、5个参数才是 ORDER BY
    [排序表达式2], [排序方向2]...
)
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\常用函数
lineageTag: 3eb20003-bfeb-49b8-b0ad-028362765214
```

##### 度量：`TOPN`

- 源序号：M103
- 名称：`TOPN`
- 原始 TMDL 名称：`TOPN`
- 完整路径：`A_资源库\开发复用\常用函数\TOPN`
- displayFolder：`开发复用\常用函数`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1842–L1864](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1842-L1864)；表达式 L1843–L1861；元数据 L1862–L1864
- DAX SHA-256：`ed399a476f3f1f313525fbc9eb5384e83aace4584f1b8e74c2a4592b93d9b514`

**DAX 原文（含度量名称）**

```dax
TOPN =
1
/*
TOPN(
    n_value,                    -- 返回的最大行数（但遇并列值时可能超量）
    table,                      -- 源表或表表达式
    orderBy_expression,         -- 第一排序键（决定"谁在前"）
    [order],                    -- 方向：ASC / DESC（默认 DESC）
    [orderBy_expression2],      -- 第二排序键（可选，用于打破平手）
    [order2],                   -- 方向（可选）
    ...
)
一句话总结：TOPN 负责"挑出前 N 个值"，但不负责"排好序交给你"。 它返回的表在 DAX 中视为无序集合，后续必须再次显式 ORDER BY。
要点                    说明
返回类型是表（Table）     TOPN 是表函数，不能单独作为度量值最终结果，必须被 CONCATENATEX、SELECTCOLUMNS、SUMX 等函数消费
返回的表 = 无序集合         虽然内部按 orderBy_expression 筛选出了前 N 行，但交出去的表不保留任何行顺序。后续迭代必须再次显式 ORDER BY
并列（Tie）会超量返回     如果第 n 行与第 n+1 行的排序键值相同，它们会被一起返回。最终行数可能 > n_value
默认排序方向是 DESC         不写 [order] 时，默认按降序取前 N。想取最小的 N 个，必须显式写 ASC
支持多键排序            可以写多组 orderBy_expression + order，实现"先按销售额降序，再按日期升序"
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\常用函数
lineageTag: 9bc917a2-9062-415c-b2ac-3fc398756682
```

##### 度量：`CALCULATETABLE`

- 源序号：M106
- 名称：`CALCULATETABLE`
- 原始 TMDL 名称：`CALCULATETABLE`
- 完整路径：`A_资源库\开发复用\常用函数\CALCULATETABLE`
- displayFolder：`开发复用\常用函数`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1927–L1940](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1927-L1940)；表达式 L1928–L1937；元数据 L1938–L1940
- DAX SHA-256：`33da820a2ad4f8742fa839fbb53965dc59f0f8c141a87c69913f67a66a89106a`

**DAX 原文（含度量名称）**

```dax
CALCULATETABLE =
1
/*
CALCULATETABLE(
    <表表达式>,           // 必填：要返回的表（可以是物理表或表函数，如 FILTER、VALUES 等）
    <筛选器1>,            // 可选：修改筛选上下文的条件
    <筛选器2>,
    ...
)
一句话总结：CALCULATETABLE(表, 筛选1, 筛选2...) 在修改后的筛选上下文中返回一张表；筛选器之间是 AND 交集；需要 OR 时用 FILTER 包一层；与 CALCULATE 语法完全对称，只是返回类型不同。
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\常用函数
lineageTag: 8deb2528-7db6-411f-8099-505e21f2c81e
```

##### 度量：`COUNTROWS`

- 源序号：M107
- 名称：`COUNTROWS`
- 原始 TMDL 名称：`COUNTROWS`
- 完整路径：`A_资源库\开发复用\常用函数\COUNTROWS`
- displayFolder：`开发复用\常用函数`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1942–L1952](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1942-L1952)；表达式 L1943–L1949；元数据 L1950–L1952
- DAX SHA-256：`850a24e56736a871f51aa82f9de4e237e3e07fcd33a7b112de3f2f44ecb5b763`

**DAX 原文（含度量名称）**

```dax
COUNTROWS =
1
/*
COUNTROWS(
<表表达式>            // 必填：任意返回表的表达式（物理表、表变量或表函数结果）
)
一句话总结：COUNTROWS(表) 返回指定表的总行数；对空表返回 0；常用于度量值中统计筛选后的结果行数。
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\常用函数
lineageTag: 55064fd2-6eb0-4721-8da6-c43da8b367fe
```

##### 度量：`USERELATIONSHIP`

- 源序号：M108
- 名称：`USERELATIONSHIP`
- 原始 TMDL 名称：`USERELATIONSHIP`
- 完整路径：`A_资源库\开发复用\常用函数\USERELATIONSHIP`
- displayFolder：`开发复用\常用函数`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1954–L1967](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1954-L1967)；表达式 L1955–L1964；元数据 L1965–L1967
- DAX SHA-256：`78aa22ecf53bb3505c1b881979975a0c0efa56da4b7c2cc84d5fdc81755d09d3`

**DAX 原文（含度量名称）**

```dax
USERELATIONSHIP =
1
/*
USERELATIONSHIP(
<列名1>,              // 必填：关系中的"多"端列（事实表外键）
<列名2>               // 必填：关系中的"一"端列（维度表主键）
)
一句话总结：USERELATIONSHIP(列1, 列2) 在单次计算中临时激活两列之间的非活动关系；必须配合 CALCULATE / CALCULATETABLE 使用，且仅在当前计算内生效。
多选时，这段 DAX 利用的是并集筛选（OR），返回「至少买过其中一款产品」的客户数；
需要改用交集思路，例如用迭代检查每个产品是否都有购买记录，或利用 SUMMARIZE + COUNTROWS 做筛选，而不是直接用 VALUES 取并集。
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\常用函数
lineageTag: df7dd6d6-c4c6-405a-823b-027b30446ed9
```

##### 度量：`NATURALINNERJOIN`

- 源序号：M109
- 名称：`NATURALINNERJOIN`
- 原始 TMDL 名称：`NATURALINNERJOIN`
- 完整路径：`A_资源库\开发复用\常用函数\NATURALINNERJOIN`
- displayFolder：`开发复用\常用函数`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1969–L1980](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1969-L1980)；表达式 L1970–L1977；元数据 L1978–L1980
- DAX SHA-256：`61e2903bbe9adbf33f929c73ad1865dca94714016106b6e216fbd40aaf21898f`

**DAX 原文（含度量名称）**

```dax
NATURALINNERJOIN =
1
/*
NATURALINNERJOIN(
<左表>,               // 必填：左侧表表达式（物理表、变量或表函数）
<右表>                // 必填：右侧表表达式
)
一句话总结：NATURALINNERJOIN(左表, 右表) 基于两表的同名列执行自然内连接，仅返回匹配行，结果包含两表全部列（同名列不重复出现）。
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\常用函数
lineageTag: f62787e2-5d98-49a7-a160-a9d66e7c5758
```

##### 度量：`1.CONTAINSSTRING：信息函数`

- 源序号：M128
- 名称：`1.CONTAINSSTRING：信息函数`
- 原始 TMDL 名称：`'1.CONTAINSSTRING：信息函数'`
- 完整路径：`A_资源库\开发复用\常用函数\1.CONTAINSSTRING：信息函数`
- displayFolder：`开发复用\常用函数`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L2341–L2362](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2341-L2362)；表达式 L2342–L2359；元数据 L2360–L2362
- DAX SHA-256：`3b9b5537ea1e539bfc515e0d8ce572c50e7b75619790ab69c0575a702194cde9`

**DAX 原文（含度量名称）**

```dax
1.CONTAINSSTRING：信息函数 =
1
/*
功能：检查一个字符串是否包含另一个字符串（不区分大小写）。
CONTAINSSTRING(<文本>, <查找的文本>)
✅ 不区分大小写（例如："A" 和 "a" 视为相同）
✅ 支持通配符：?（单个字符）和 *（多个字符）：
// 查找类似 "A-123" 格式的产品代码
CONTAINSSTRING(Products[Code], "A-???")  // 匹配 A-123, A-ABC, A-X1Y
// * 表示任意长度的任意字符
CONTAINSSTRING("apple", "*pp*")   // TRUE - 任何包含 "pp" 的字符串
CONTAINSSTRING("apple", "a*e")     // TRUE - 以 "a" 开头，以 "e" 结尾
CONTAINSSTRING("apple", "*")       // TRUE - 总是返回 TRUE
函数                     区分大小写    通配符支持   功能说明
CONTAINSSTRING          ❌ 否        ✅ 是       检查字符串是否包含子字符串
CONTAINSSTRINGEXACT     ✅ 是       ✅ 是       区分大小写的版本
SEARCH                  ❌ 否       ✅ 是       返回子字符串位置（类似 CONTAINSSTRING，但返回数字）
FIND                    ✅ 是       ❌ 否       区分大小写，返回子字符串位置
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\常用函数
lineageTag: 42f46967-a86f-4a2a-8e55-2ac59506e87c
```

#### 文件夹：`模型相关`

文件夹完整路径：`A_资源库\开发复用\模型相关`；直接度量 2；含子层级度量 2。

##### 度量：`计算表`

- 源序号：M003
- 名称：`计算表`
- 原始 TMDL 名称：`计算表`
- 完整路径：`A_资源库\开发复用\模型相关\计算表`
- displayFolder：`开发复用\模型相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L26–L77](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L26-L77)；表达式 L27–L73；元数据 L75–L77
- DAX SHA-256：`39cd166f3a9d84011f5d2d7047e0ab9b362f8cb7b6b5fdda69dbbc4b8bc7f188`

**DAX 原文（含度量名称）**

```dax
计算表 =

/*D_Dynamic_Store_Filter_Enhanced：计算表
不改变模型的DAX动态计算表方案:使用维度和事实表结合（推荐）：计算表和计算列是静态的，所以没实现*/
/*功能：创建完整的动态店铺筛选表说明：结合维度表和事实表，提供完整信息特点：包含所有维度信息，支持筛选逻辑*/
// VAR SelectedPlatforms = 
//     // 获取当前选中的平台（如果有）
//     CALCULATETABLE(
//         VALUES(D_Platform_Dim[platform_code]),  // 从平台维度获取选中值
//         ALLSELECTED(D_Platform_Dim)              // 保持当前筛选上下文
//     )
// VAR HasPlatformFilter = 
//     // 检查是否有平台筛选
//     ISFILTERED(D_Platform_Dim[platform_code]) || 
//     ISFILTERED(D_Platform_Dim[platform_name])
// RETURN 
1
// ADDCOLUMNS(
//     // 基础数据：店铺维度表的所有记录
//     D_StoreName_Dim,
    
//     // 是否可见的逻辑
//     "Is_Visible",
//     SWITCH(
//         TRUE(),
//         // 情况1：没有平台筛选，显示所有店铺
//         NOT HasPlatformFilter, TRUE(),
        
//         // 情况2：有平台筛选，检查店铺是否属于选中的平台
//         HASONEVALUE(D_StoreName_Dim[platform_code]),
//             CONTAINSROW(SelectedPlatforms, D_StoreName_Dim[platform_code]),
        
//         // 情况3：多个平台被选中
//         COUNTROWS(SelectedPlatforms) > 0,
//             CONTAINSROW(SelectedPlatforms, D_StoreName_Dim[platform_code]),
        
//         // 默认情况
//         TRUE()
//     ),
    
//     // 店铺平台名称（用于显示）
//     "Platform_Name_Display",
//     LOOKUPVALUE(
//         D_Platform_Dim[platform_name],
//         D_Platform_Dim[platform_code],
//         D_StoreName_Dim[platform_code]
//     )
// )
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\模型相关
lineageTag: 9a12d9fe-d033-4a4f-b029-ad55db615c42
```

##### 度量：`构建指标维度`

- 源序号：M025
- 名称：`构建指标维度`
- 原始 TMDL 名称：`构建指标维度`
- 完整路径：`A_资源库\开发复用\模型相关\构建指标维度`
- displayFolder：`开发复用\模型相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L559–L627](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L559-L627)；表达式 L560–L623；元数据 L625–L627
- DAX SHA-256：`831ad9a8919fa92335d1a643ce17c00b51fa6a0edbcbf5877759fc6ba06150b5`

**DAX 原文（含度量名称）**

```dax
构建指标维度 =

/*
VAR BaseMetrics = 
    DATATABLE(
        "metric_id", STRING,
        "metric_name", STRING,
        "metric_name_display", STRING,  // 显示名称
        "metric_group", STRING,
        "metric_subgroup", STRING,      // 子组
        "is_percentage", INTEGER,       // 是否为百分比
        "is_growth", INTEGER,           // 是否为增长指标
        "has_plus_minus", INTEGER,      // 是否需要显示±号
        "format_type", STRING,          // 格式化类型
        "sort_order", INTEGER,
        "is_visible", INTEGER,          // 是否默认显示
        {
            // ============================================
            // 1. 核心销售指标
            // ============================================
            {"SLS_DCom", "SLS DCom", "SLS DCom", "销售业绩", "核心销售额", 0, 0, 0, "Number", 101, 1},
            {"SLS_DCom_vs_LY", "SLS DCom vs LY", "同比", "销售业绩", "增长率", 1, 1, 1, "Percentage", 102, 1},
            {"SLS_DCom_Tar_Ach", "SLS DCom Tar Ach%", "目标达成率", "销售业绩", "目标达成", 1, 0, 0, "Percentage", 103, 1},
            
            // ============================================
            // 2. 需求销售指标
            // ============================================
            {"Demand_Sales", "Demand Sales", "需求销售额", "需求销售", "绝对值", 0, 0, 0, "Number", 201, 1},
            {"Demand_Sales_vs_LY", "Demand Sales vs LY", "同比", "需求销售", "增长率", 1, 1, 1, "Percentage", 202, 1},
            
            // ============================================
            // 3. 取消/退货指标
            // ============================================
            {"Cancel_Percent", "Cancel%", "取消率", "取消退货", "取消", 1, 0, 0, "Percentage", 301, 1},
            {"Cancel_Percent_vs_LY", "Cancel% vs LY", "同比", "取消退货", "取消", 1, 1, 1, "Percentage", 302, 1},
            {"Return_Percent", "Return%", "退货率", "取消退货", "退货", 1, 0, 0, "Percentage", 303, 1},
            {"Return_Percent_vs_LY", "Return% vs LY", "同比", "取消退货", "退货", 1, 1, 1, "Percentage", 304, 1},
            
            // ============================================
            // 4. 客单价相关指标
            // ============================================
            {"ATV", "ATV", "客单价", "客单价", "绝对值", 0, 0, 0, "Number", 401, 1},
            {"ATV_vs_LY", "ATV vs LY", "同比", "客单价", "增长率", 1, 1, 1, "Percentage", 402, 1},
            {"AUR", "AUR", "平均单价", "客单价", "绝对值", 0, 0, 0, "Number", 403, 1},
            {"AUR_vs_LY", "AUR vs LY", "同比", "客单价", "增长率", 1, 1, 1, "Percentage", 404, 1},
            {"UPT", "UPT", "单件数", "客单价", "绝对值", 0, 0, 0, "Number", 405, 1},
            {"UPT_vs_LY", "UPT vs LY", "同比", "客单价", "增长率", 1, 1, 1, "Percentage", 406, 1},
            
            // ============================================
            // 5. 流量指标
            // ============================================
            {"Traffic", "Traffic", "流量", "流量", "绝对值", 0, 0, 0, "Number", 501, 1},
            {"Traffic_vs_LY", "Traffic vs LY", "同比", "流量", "增长率", 1, 1, 1, "Percentage", 502, 1},
            
            // ============================================
            // 6. 转化指标
            // ============================================
            {"Conversion_Percent", "Conversion%", "转化率", "转化", "绝对值", 1, 0, 0, "Percentage", 601, 1},
            {"Conversion_Percent_vs_LY", "Conversion% vs LY", "同比", "转化", "增长率", 1, 1, 1, "Percentage", 602, 1}
        }
    )

RETURN
BaseMetrics
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\模型相关
lineageTag: 96bc2cc0-44f3-40a3-a421-95890d5b22b4
```

#### 文件夹：`筛选相关`

文件夹完整路径：`A_资源库\开发复用\筛选相关`；直接度量 9；含子层级度量 9。

##### 度量：`1、判断当前店铺是否属于选中的平台`

- 源序号：M004
- 名称：`1、判断当前店铺是否属于选中的平台`
- 原始 TMDL 名称：`1、判断当前店铺是否属于选中的平台`
- 完整路径：`A_资源库\开发复用\筛选相关\1、判断当前店铺是否属于选中的平台`
- displayFolder：`开发复用\筛选相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L79–L116](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L79-L116)；表达式 L80–L112；元数据 L114–L116
- DAX SHA-256：`e1f1825b44813295c69c69a0ec56935c5e2f58ed43e27946fb96fcda464b16b0`

**DAX 原文（含度量名称）**

```dax
1、判断当前店铺是否属于选中的平台 =

/*
/*
1、IsShopVisible:
基础度量：判断当前店铺是否属于选中的平台
度量名称：IsShopVisible
功能：判断店铺在当前筛选上下文中是否应该显示
返回：1（显示）或0（隐藏）
*/
// 步骤1：获取用户当前选择的平台ID列表
// VALUES函数返回当前筛选上下文中可见的平台ID
VAR SelectedPlatforms = VALUES(Slicer_Platform_Selection[Platform_ID])

// 步骤2：获取当前行的店铺所属平台ID
// SELECTEDVALUE函数返回当前行上下文中的店铺PlatformID
// 注意：这个度量值通常在店铺维度表的行上下文中被计算
VAR CurrentShopPlatform = SELECTEDVALUE(Slicer_Store_Name[Platform_ID])

// 步骤3：计算是否可见的逻辑
// 如果用户通过平台切片器进行了筛选
VAR IsVisible = 
    IF(
        ISFILTERED(Slicer_Platform_Selection[Platform_ID]),  // 检查平台ID字段是否被筛选
        // 如果筛选了，检查当前店铺的平台是否在已选平台中
        CurrentShopPlatform IN SelectedPlatforms,  // 使用IN操作符检查成员关系
        TRUE  // 如果没有筛选，则显示所有店铺
    )

// 步骤4：返回结果
// 将布尔值转换为1/0，便于后续筛选
RETURN
    IF(ISVisible, 1, 0)
    */
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\筛选相关
lineageTag: 530428ae-2f9f-4dc1-ad00-aee17470a710
```

##### 度量：`2、判断店铺是否应该出现在店铺切片器中`

- 源序号：M005
- 名称：`2、判断店铺是否应该出现在店铺切片器中`
- 原始 TMDL 名称：`2、判断店铺是否应该出现在店铺切片器中`
- 完整路径：`A_资源库\开发复用\筛选相关\2、判断店铺是否应该出现在店铺切片器中`
- displayFolder：`开发复用\筛选相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L118–L159](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L118-L159)；表达式 L119–L156；元数据 L157–L159
- DAX SHA-256：`5f1467264631dcc8d4993a73c51924ab73023dd667056c27fd22184568282a30`

**DAX 原文（含度量名称）**

```dax
2、判断店铺是否应该出现在店铺切片器中 =

/*
/*
2、ShowInShopSlicer:
度量名称：ShowInShopSlicer
功能：判断店铺是否应该出现在店铺切片器中
与IsShopVisible功能类似，但更具体地用于切片器筛选
返回：1（应该显示在切片器）或0（不应该显示）
*/
// 步骤1：获取用户当前选择的平台ID列表
// VALUES返回当前筛选上下文中的平台ID
VAR SelectedPlatforms = VALUES(Slicer_Platform_Selection[Platform_ID])

// 步骤2：获取当前评估的店铺所属的平台ID
// 当在店铺切片器的上下文中，这个度量值会为每个店铺行进行计算
VAR CurrentShopPlatform = SELECTEDVALUE(Slicer_Store_Name[Platform_ID])

// 步骤3：返回筛选逻辑
RETURN
    IF(
        // 条件A：检查用户是否选择了平台
        ISFILTERED(Slicer_Platform_Selection[Platform_ID]),  // 平台ID字段是否被筛选？
        // 如果选择了平台（条件A为真）：
        IF(
            // 条件B：当前店铺的平台是否在用户选择的平台中
            CurrentShopPlatform IN SelectedPlatforms,
            1,  // 是：店铺应该出现在切片器中
            0   // 否：店铺不应该出现在切片器中
        ),
        // 如果没有选择平台（条件A为假）：
        1  // 显示所有店铺
    )

// 这个度量的逻辑流程：
// 1. 用户是否选择了平台？ → 是 → 当前店铺的平台是否在已选平台中？ → 是 → 返回1
// 2. 用户是否选择了平台？ → 是 → 当前店铺的平台是否在已选平台中？ → 否 → 返回0
// 3. 用户是否选择了平台？ → 否 → 直接返回1
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\筛选相关
lineageTag: c61e4f5f-d6bb-4d0d-b5fe-9f00627ed0d3
```

##### 度量：`获取当前选中的时间周期，筛选器的值`

- 源序号：M006
- 名称：`获取当前选中的时间周期，筛选器的值`
- 原始 TMDL 名称：`获取当前选中的时间周期，筛选器的值`
- 完整路径：`A_资源库\开发复用\筛选相关\获取当前选中的时间周期，筛选器的值`
- displayFolder：`开发复用\筛选相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L161–L188](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L161-L188)；表达式 L162–L184；元数据 L186–L188
- DAX SHA-256：`7bb2f4d561a4bf1c3f7c961d4669ffd8f2420d8cc92eb4602429be7a6bfb3b89`

**DAX 原文（含度量名称）**

```dax
获取当前选中的时间周期，筛选器的值 =

/*
/*Selected_Time_Period： 
示例：获取当前选中的时间周期，筛选器的值
*/
/*
功能：获取用户当前选择的时间周期代码
用途：在动态计算度量值中判断使用哪个时间周期逻辑
*/
VAR SelectedCode = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
/*
SELECTEDVALUE 函数：返回指定列在当前筛选上下文中唯一的值
- 如果当前筛选上下文中 Time_Code 列有且只有一个值，返回该值
- 如果有多个值或没有值，返回空白
- 第二个参数可设置默认值，这里省略，因为 Time_Dim 表中已有默认选项
*/
RETURN
IF(
    ISBLANK(SelectedCode),
    "WTD",  // 如果没有选择，使用默认值
    SelectedCode
)
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\筛选相关
lineageTag: 95a7ec7b-5d11-45ab-b2f7-e41e6d1f5a07
```

##### 度量：`3、优化_当前店铺平台是否在已选平台中_CONTAINS`

- 源序号：M007
- 名称：`3、优化_当前店铺平台是否在已选平台中_CONTAINS`
- 原始 TMDL 名称：`3、优化_当前店铺平台是否在已选平台中_CONTAINS`
- 完整路径：`A_资源库\开发复用\筛选相关\3、优化_当前店铺平台是否在已选平台中_CONTAINS`
- displayFolder：`开发复用\筛选相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L190–L242](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L190-L242)；表达式 L191–L239；元数据 L240–L242
- DAX SHA-256：`ef512c18a4f1b87b8a96576aad8f3da89990e4a7016a4d613633953bb59f5eaf`

**DAX 原文（含度量名称）**

```dax
3、优化_当前店铺平台是否在已选平台中_CONTAINS =

/*
VAR SelectedPlatforms = VALUES(Slicer_Platform_Selection[Platform_ID])
/*
3、IsShopVisible_Optimized:
度量名称：IsShopVisible_Optimized
功能：IsShopVisible的优化版本，减少计算量
返回：1（显示）或0（隐藏）
步骤1：获取当前筛选上下文中的平台ID
这是一个平台ID的列表（可能包含0个、1个或多个值）
*/
// 步骤2：判断并返回
RETURN
    IF(
        // 条件A：检查平台是否被筛选
        ISFILTERED(Slicer_Platform_Selection[Platform_ID]),
        // 如果筛选了平台：
        IF(
            // 条件B：使用CONTAINS函数检查当前店铺平台是否在已选平台中
            // CONTAINS(表, 表[列], 值) → 检查表中是否包含指定的值
            // SELECTEDVALUE(Slicer_Store_Name[Platform_ID])返回当前店铺的平台ID
            CONTAINS(
                SelectedPlatforms,      // 要搜索的表
                [Platform_ID],            // 表中的列（平台ID列）
                SELECTEDVALUE(Slicer_Store_Name[Platform_ID])  // 要查找的值
            ),
            1,  // 找到了：店铺应该显示
            0   // 没找到：店铺不应该显示
        ),
        // 如果没筛选平台：
        1  // 显示所有店铺
    )

// 为什么这是优化版本？
// 1. 使用CONTAINS代替IN操作符：
//    - IN操作符会生成一个OR条件的列表，当已选平台很多时效率低
//    - CONTAINS是专门的查找函数，在处理大数据集时更高效
// 2. 减少了中间变量：
//    - 不创建CurrentShopPlatform变量
//    - 直接在CONTAINS中使用SELECTEDVALUE
// 3. 逻辑更简洁：
//    - 去掉了IsVisible中间变量
//    - 直接返回IF结果

// 性能对比：
// 原始版本：需要先获取CurrentShopPlatform，然后用IN比较
// 优化版本：直接使用CONTAINS在表中查找
// 在大数据集中，优化版本通常执行更快
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\筛选相关
lineageTag: f23416d1-8a3a-47d5-96a0-b2933faf0621
```

##### 度量：`判断筛选器是否已选择值`

- 源序号：M008
- 名称：`判断筛选器是否已选择值`
- 原始 TMDL 名称：`判断筛选器是否已选择值`
- 完整路径：`A_资源库\开发复用\筛选相关\判断筛选器是否已选择值`
- displayFolder：`开发复用\筛选相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L244–L264](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L244-L264)；表达式 L245–L260；元数据 L262–L264
- DAX SHA-256：`74e3f821970760ec9bfff789eddb34dba494f6814d19a408d0beadade3e21b38`

**DAX 原文（含度量名称）**

```dax
判断筛选器是否已选择值 =

/*
/*Dynamic_Store_Filter_Enhanced：判断筛选器是否已选择值*/
/*功能：创建完整的动态店铺筛选表说明：结合维度表和事实表，提供完整信息特点：包含所有维度信息，支持筛选逻辑*/
VAR SelectedPlatforms = 
    // 获取当前选中的平台（如果有）
    CALCULATETABLE(
        VALUES(Slicer_Platform_Selection[Platform_ID]),  // 从平台维度获取选中值
        ALLSELECTED(Slicer_Platform_Selection)              // 保持当前筛选上下文
    )
VAR HasPlatformFilter = 
    // 检查是否有平台筛选
    ISFILTERED(Slicer_Platform_Selection[Platform_ID]) || 
    ISFILTERED(Slicer_Platform_Selection[Platform_Label]) 
    RETURN HasPlatformFilter
    */
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\筛选相关
lineageTag: 6e62807a-4bc2-4c7f-bb97-18e6387e861b
```

##### 度量：`筛选器影响图表`

- 源序号：M009
- 名称：`筛选器影响图表`
- 原始 TMDL 名称：`筛选器影响图表`
- 完整路径：`A_资源库\开发复用\筛选相关\筛选器影响图表`
- displayFolder：`开发复用\筛选相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L266–L301](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L266-L301)；表达式 L267–L297；元数据 L299–L301
- DAX SHA-256：`b44764b37ea0d8cca8e0376f3e029f4b708416a626c533973706dfc6950baed0`

**DAX 原文（含度量名称）**

```dax
筛选器影响图表 =

/*
/*Dynamic_Store_List:筛选器影响图表
不改变模型的DAX动态计算表方案:使用DAX创建动态筛选逻辑（度量值方式）*/
/*
功能：动态店铺筛选度量值
说明：根据平台选择动态筛选店铺
返回：店铺名称列表，可用于切片器
*/
VAR SelectedPlatforms = 
    // 获取选中的平台代码
    CALCULATETABLE(
        VALUES(Slicer_Platform_Selection[Platform_ID]),
        ALLSELECTED(Slicer_Platform_Selection)
    )
RETURN
IF(
    // 如果没有平台被选中，返回所有店铺
    ISEMPTY(SelectedPlatforms),
    VALUES(Slicer_Store_Name[Store_ID]),
    
    // 如果有平台被选中，返回对应平台的店铺
    CALCULATETABLE(
        VALUES(Slicer_Store_Name[Store_ID]),
        FILTER(
            Slicer_Store_Name,
            Slicer_Store_Name[Platform_ID] IN SelectedPlatforms
        )
    )
)
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\筛选相关
lineageTag: 14af33e1-112c-4e2a-990a-014d6de14992
```

##### 度量：`筛选控制器`

- 源序号：M085
- 名称：`筛选控制器`
- 原始 TMDL 名称：`筛选控制器`
- 完整路径：`A_资源库\开发复用\筛选相关\筛选控制器`
- displayFolder：`开发复用\筛选相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1530–L1533](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1530-L1533)；表达式 L1530–L1530；元数据 L1531–L1533
- DAX SHA-256：`4abadc9073ec4236152ef0d62069f596d0bf38e9715336bf2c5f060f1d202d20`

**DAX 原文（含度量名称）**

```dax
筛选控制器 = COUNTROWS( 'A_Measure' )
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\筛选相关
lineageTag: 2cdaacec-9ffe-4fcb-8a1e-6a1a7157cb63
```

##### 度量：`0%~100% 切片器`

- 源序号：M097
- 名称：`0%~100% 切片器`
- 原始 TMDL 名称：`'0%~100% 切片器'`
- 完整路径：`A_资源库\开发复用\筛选相关\0%~100% 切片器`
- displayFolder：`开发复用\筛选相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1732–L1739](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1732-L1739)；表达式 L1733–L1735；元数据 L1736–L1739
- DAX SHA-256：`0075f799b1686f818a46d79b632d9de299d9c1958785bba485a2b56d2208e7a2`

**DAX 原文（含度量名称）**

```dax
0%~100% 切片器 =

// 左闭右开
GENERATESERIES(0, 1.01, 0.01)
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\筛选相关
lineageTag: dbf681db-2b86-4d10-bd02-2927b13e05c0

annotation PBI_FormatHint = {"isGeneralNumber":true}
```

##### 度量：`判断x轴是否落于全局筛选之中_timeframe（日/周/月/季/年）`

- 源序号：M129
- 名称：`判断x轴是否落于全局筛选之中_timeframe（日/周/月/季/年）`
- 原始 TMDL 名称：`判断x轴是否落于全局筛选之中_timeframe（日/周/月/季/年）`
- 完整路径：`A_资源库\开发复用\筛选相关\判断x轴是否落于全局筛选之中_timeframe（日/周/月/季/年）`
- displayFolder：`开发复用\筛选相关`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L2364–L2425](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L2364-L2425)；表达式 L2365–L2421；元数据 L2423–L2425
- DAX SHA-256：`35d55d70ae643cb6475dccfc0074f1e7ffb8cf68290e0e6c895fdf329359b907`

**DAX 原文（含度量名称）**

```dax
判断x轴是否落于全局筛选之中_timeframe（日/周/月/季/年） =

/*
// ========================================
// 度量值: IsTimeFrameVisible
// Display Folder: Sales Trend
// 用途: 判断柱形图/趋势图 X 轴当前遍历的 timeframe（日/周/月/季/年）
//       是否落在起止切片器选定的范围内（同粒度 + Key 在 [MinKey, MaxKey] 区间）
// 返回: 1（显示）或 0（隐藏）
// 依赖: Slicer_Time_Frame[TimeFrame_ID, TimeFrame_Key],
//       Slicer_Time_Frame_Min[TimeFrame_ID, TimeFrame_Key, TimeFrame_Value],
//       Slicer_Time_Frame_Max[TimeFrame_ID, TimeFrame_Key, TimeFrame_Value]
// 使用方式: 作为柱形图/趋势图 X 轴（Slicer_Time_Frame）的视觉对象级别筛选器
//           筛选条件: IsTimeFrameVisible = 1
// 设计说明:
//   1. 粒度一致性校验：X 轴当前行粒度必须与 Min/Max 切片器选择的粒度一致
//      （Min/Max 切片器应受同一粒度选择器联动，保持同粒度）
//   2. Key 范围校验：同粒度下比较 TimeFrame_Key，确保 X 轴柱子在 [MinKey, MaxKey] 区间
//   3. 若 Min/Max 未选择，默认显示 X 轴主表全部同粒度行（取主表 Min/Max Key）
// ========================================
    // ── 步骤1：获取 X 轴当前行的粒度与 Key ──
    VAR __CurrentTimeFrameID = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_ID])
    VAR __CurrentKey = SELECTEDVALUE(Slicer_Time_Frame[TimeFrame_Key])
    // ── 步骤2：获取起止切片器选定的粒度 ──
    VAR __MinTimeFrameID = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_ID])
    VAR __MaxTimeFrameID = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_ID])
    // ── 步骤3：粒度一致性校验 ──
    // X 轴当前行粒度必须与起止切片器选择的粒度一致，才参与 Key 比较
    VAR __IsSameGranularity =
        NOT ISBLANK(__CurrentTimeFrameID)
        && __CurrentTimeFrameID = __MinTimeFrameID
        && __CurrentTimeFrameID = __MaxTimeFrameID
    // ── 步骤4：获取起止切片器选定的 Key（同粒度下比较）──
    // 若未选择，默认取 X 轴主表的最小/最大 Key，确保全部显示
    VAR __MinKey =
        IF(
            ISFILTERED(Slicer_Time_Frame_Min[TimeFrame_Value]),
            MIN(Slicer_Time_Frame_Min[TimeFrame_Key]),
            MIN(Slicer_Time_Frame[TimeFrame_Key])
        )
    VAR __MaxKey =
        IF(
            ISFILTERED(Slicer_Time_Frame_Max[TimeFrame_Value]),
            MAX(Slicer_Time_Frame_Max[TimeFrame_Key]),
            MAX(Slicer_Time_Frame[TimeFrame_Key])
        )
    // ── 步骤5：判断当前 Key 是否在 [MinKey, MaxKey] 区间内 ──
    RETURN
        IF(
            NOT __IsSameGranularity, 0,
            IF(
                __CurrentKey >= __MinKey && __CurrentKey <= __MaxKey,
                1,  // 在范围内：柱子显示
                0   // 不在范围内：柱子隐藏
            )
        )
*/

```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 开发复用\筛选相关
lineageTag: afaee6b5-5670-4bf5-957c-a949ec2cb7e6
```

#### 文件夹：`颜色格式`

文件夹完整路径：`A_资源库\开发复用\颜色格式`；直接度量 23；含子层级度量 23。

##### 度量：`顶部_深蓝色_#0c2340:`

- 源序号：M029
- 名称：`顶部_深蓝色_#0c2340:`
- 原始 TMDL 名称：`顶部_深蓝色_#0c2340:`
- 完整路径：`A_资源库\开发复用\颜色格式\顶部_深蓝色_#0c2340:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L797–L801](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L797-L801)；表达式 L798–L799；元数据 L800–L801
- DAX SHA-256：`e07c0e7a07813334f3b04ef8db69598d954df73ae3c9040ed4a7c34f41d2a72d`

**DAX 原文（含度量名称）**

```dax
顶部_深蓝色_#0c2340: =

"#0c2340"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: e730281b-a974-4a2c-9e16-19caebacc215
```

##### 度量：`背景_纯白色_#ffffff:`

- 源序号：M030
- 名称：`背景_纯白色_#ffffff:`
- 原始 TMDL 名称：`背景_纯白色_#ffffff:`
- 完整路径：`A_资源库\开发复用\颜色格式\背景_纯白色_#ffffff:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L803–L807](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L803-L807)；表达式 L804–L805；元数据 L806–L807
- DAX SHA-256：`8656f9f8efe24679c2f5a23597e45ced028609c4aa904c730a43b01fa74a5ca8`

**DAX 原文（含度量名称）**

```dax
背景_纯白色_#ffffff: =

"#ffffff"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: 9c4f4f64-465e-4887-b615-17b0182270d6
```

##### 度量：`书签背景_米白色_#f5f1ea:`

- 源序号：M031
- 名称：`书签背景_米白色_#f5f1ea:`
- 原始 TMDL 名称：`书签背景_米白色_#f5f1ea:`
- 完整路径：`A_资源库\开发复用\颜色格式\书签背景_米白色_#f5f1ea:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L809–L813](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L809-L813)；表达式 L810–L811；元数据 L812–L813
- DAX SHA-256：`54f9a1d597e732a45b720204c4abf041936135bd792809031427f477bd8f7bd9`

**DAX 原文（含度量名称）**

```dax
书签背景_米白色_#f5f1ea: =

"#f5f1ea"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: ae976c2b-b275-4408-b00b-28c753442fe7
```

##### 度量：`看板背景_浅灰色_#f0f0f0:`

- 源序号：M032
- 名称：`看板背景_浅灰色_#f0f0f0:`
- 原始 TMDL 名称：`看板背景_浅灰色_#f0f0f0:`
- 完整路径：`A_资源库\开发复用\颜色格式\看板背景_浅灰色_#f0f0f0:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L815–L819](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L815-L819)；表达式 L816–L817；元数据 L818–L819
- DAX SHA-256：`733b3c2ac17ac331148b5702c02b3d052e3b6cb7c1988a2365c21f51ee3d8e49`

**DAX 原文（含度量名称）**

```dax
看板背景_浅灰色_#f0f0f0: =

"#f0f0f0"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: 6ff60e5e-1790-4119-925a-8b599fcb841a
```

##### 度量：`筛选器文字_浅咖色_#be9f71:`

- 源序号：M033
- 名称：`筛选器文字_浅咖色_#be9f71:`
- 原始 TMDL 名称：`筛选器文字_浅咖色_#be9f71:`
- 完整路径：`A_资源库\开发复用\颜色格式\筛选器文字_浅咖色_#be9f71:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L821–L825](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L821-L825)；表达式 L822–L823；元数据 L824–L825
- DAX SHA-256：`e68fb647a34003d8693bb9ff74a5a13266ea6ea7f80ecc816bf044d91bb25b03`

**DAX 原文（含度量名称）**

```dax
筛选器文字_浅咖色_#be9f71: =

"#be9f71"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: fff91dd0-0b30-448e-8d16-869a6e954cc4
```

##### 度量：`黄_亮黄色_#E1C233:`

- 源序号：M034
- 名称：`黄_亮黄色_#E1C233:`
- 原始 TMDL 名称：`黄_亮黄色_#E1C233:`
- 完整路径：`A_资源库\开发复用\颜色格式\黄_亮黄色_#E1C233:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L827–L831](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L827-L831)；表达式 L828–L829；元数据 L830–L831
- DAX SHA-256：`ac4ec0f262591492f7b977e986dec2077f0e8babf3f1daa2c309fe4a4864c495`

**DAX 原文（含度量名称）**

```dax
黄_亮黄色_#E1C233: =

"#E1C233"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: 5f8fdedb-2f54-4aab-a287-465c545cc6ab
```

##### 度量：`红_玫瑰红_#D64550:`

- 源序号：M035
- 名称：`红_玫瑰红_#D64550:`
- 原始 TMDL 名称：`红_玫瑰红_#D64550:`
- 完整路径：`A_资源库\开发复用\颜色格式\红_玫瑰红_#D64550:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L833–L837](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L833-L837)；表达式 L834–L835；元数据 L836–L837
- DAX SHA-256：`85f078cd637f0aaff60b1d7a90bdee8e503adcd726ca94bb699ba0371471a7c3`

**DAX 原文（含度量名称）**

```dax
红_玫瑰红_#D64550: =

"#D64550"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: 24d1e31a-4339-4c74-a122-64bc203ec261
```

##### 度量：`绿_草绿色_#1A9018:`

- 源序号：M036
- 名称：`绿_草绿色_#1A9018:`
- 原始 TMDL 名称：`绿_草绿色_#1A9018:`
- 完整路径：`A_资源库\开发复用\颜色格式\绿_草绿色_#1A9018:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L839–L843](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L839-L843)；表达式 L840–L841；元数据 L842–L843
- DAX SHA-256：`43db4032b6b6bfc928810c50f8f9dfaafa26de7e6cc3d05f3398c6dc379e5f00`

**DAX 原文（含度量名称）**

```dax
绿_草绿色_#1A9018: =

"#1A9018"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: 11fb0ae0-7f04-4416-bc4b-4f2ea278b95a
```

##### 度量：`条形图例1_中灰色_#bcbcbc:`

- 源序号：M037
- 名称：`条形图例1_中灰色_#bcbcbc:`
- 原始 TMDL 名称：`条形图例1_中灰色_#bcbcbc:`
- 完整路径：`A_资源库\开发复用\颜色格式\条形图例1_中灰色_#bcbcbc:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L845–L849](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L845-L849)；表达式 L846–L847；元数据 L848–L849
- DAX SHA-256：`152cb726ec75c00e70772fd4d4f31c7cbfe6f65853f4f2c85f81c17f5ba6bfd5`

**DAX 原文（含度量名称）**

```dax
条形图例1_中灰色_#bcbcbc: =

"#bcbcbc"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: 72089f60-ef6a-4675-8f43-48fb6fbfd9f3
```

##### 度量：`条形图例2_深灰色_#8c8c8c:`

- 源序号：M038
- 名称：`条形图例2_深灰色_#8c8c8c:`
- 原始 TMDL 名称：`条形图例2_深灰色_#8c8c8c:`
- 完整路径：`A_资源库\开发复用\颜色格式\条形图例2_深灰色_#8c8c8c:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L851–L855](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L851-L855)；表达式 L852–L853；元数据 L854–L855
- DAX SHA-256：`2248ca356ecfe0d87d38fa8484c8de73fdb99070a8ae35261294f4db39a24682`

**DAX 原文（含度量名称）**

```dax
条形图例2_深灰色_#8c8c8c: =

"#8c8c8c"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: 722db89c-6007-4e5d-ac9f-a8c0aa243efc
```

##### 度量：`柱形图例_炭灰色_#808080:`

- 源序号：M039
- 名称：`柱形图例_炭灰色_#808080:`
- 原始 TMDL 名称：`柱形图例_炭灰色_#808080:`
- 完整路径：`A_资源库\开发复用\颜色格式\柱形图例_炭灰色_#808080:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L857–L861](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L857-L861)；表达式 L858–L859；元数据 L860–L861
- DAX SHA-256：`04e7691a569f050c767e339cc7a79d470e17a03055865b4d1a5801a34879c6f5`

**DAX 原文（含度量名称）**

```dax
柱形图例_炭灰色_#808080: =

"#808080"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: 3b7055d1-758e-4977-8e83-7720cd28197b
```

##### 度量：`卡片标题_暗灰色_#595959:`

- 源序号：M040
- 名称：`卡片标题_暗灰色_#595959:`
- 原始 TMDL 名称：`卡片标题_暗灰色_#595959:`
- 完整路径：`A_资源库\开发复用\颜色格式\卡片标题_暗灰色_#595959:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L863–L867](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L863-L867)；表达式 L864–L865；元数据 L866–L867
- DAX SHA-256：`9bf105969ed40d292850db6d54beaff584c498f081d63fdf0fa4c740946c6cd6`

**DAX 原文（含度量名称）**

```dax
卡片标题_暗灰色_#595959: =

"#595959"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: 72ee8cbb-24bf-4074-abc8-6784f9960651
```

##### 度量：`饼图图例1_灰蓝色_#90a0c2:`

- 源序号：M041
- 名称：`饼图图例1_灰蓝色_#90a0c2:`
- 原始 TMDL 名称：`饼图图例1_灰蓝色_#90a0c2:`
- 完整路径：`A_资源库\开发复用\颜色格式\饼图图例1_灰蓝色_#90a0c2:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L869–L873](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L869-L873)；表达式 L870–L871；元数据 L872–L873
- DAX SHA-256：`910b3ee1a111c4bf186bd3d2b21563e234c329bd0136d8be478758e4fa2679cd`

**DAX 原文（含度量名称）**

```dax
饼图图例1_灰蓝色_#90a0c2: =

"#90a0c2"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: 3443b9b2-70bd-4f6f-988c-701fa4cc001b
```

##### 度量：`饼图图例2_天蓝色_#6b9ad0:`

- 源序号：M042
- 名称：`饼图图例2_天蓝色_#6b9ad0:`
- 原始 TMDL 名称：`饼图图例2_天蓝色_#6b9ad0:`
- 完整路径：`A_资源库\开发复用\颜色格式\饼图图例2_天蓝色_#6b9ad0:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L875–L879](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L875-L879)；表达式 L876–L877；元数据 L878–L879
- DAX SHA-256：`1cf8072d650a58db20c62923d0add596de0ddd645675949fe88fbc57e6934947`

**DAX 原文（含度量名称）**

```dax
饼图图例2_天蓝色_#6b9ad0: =

"#6b9ad0"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: 5299d1c3-febb-4b5f-8290-e4e9f418e79b
```

##### 度量：`饼图图例3_海军蓝_#134885:`

- 源序号：M043
- 名称：`饼图图例3_海军蓝_#134885:`
- 原始 TMDL 名称：`饼图图例3_海军蓝_#134885:`
- 完整路径：`A_资源库\开发复用\颜色格式\饼图图例3_海军蓝_#134885:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L881–L885](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L881-L885)；表达式 L882–L883；元数据 L884–L885
- DAX SHA-256：`b6e9a8c3f28354cfa81148ee39d53489ece65b2ff29f325362039de24decccbc`

**DAX 原文（含度量名称）**

```dax
饼图图例3_海军蓝_#134885: =

"#134885"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: 2a29a52f-fe3f-40a2-893f-2abd8c30318a
```

##### 度量：`饼图图例4_奶油色_#ffe8c6:`

- 源序号：M044
- 名称：`饼图图例4_奶油色_#ffe8c6:`
- 原始 TMDL 名称：`饼图图例4_奶油色_#ffe8c6:`
- 完整路径：`A_资源库\开发复用\颜色格式\饼图图例4_奶油色_#ffe8c6:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L887–L891](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L887-L891)；表达式 L888–L889；元数据 L890–L891
- DAX SHA-256：`6c985014b40d38a4ce6869cab62d44cbe95b6cc5181cf42844b5aceaefca893d`

**DAX 原文（含度量名称）**

```dax
饼图图例4_奶油色_#ffe8c6: =

"#ffe8c6"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: a9891e0d-f5e4-46da-b763-82c089b78a04
```

##### 度量：`饼图图例5_石板灰_#4e5762:`

- 源序号：M045
- 名称：`饼图图例5_石板灰_#4e5762:`
- 原始 TMDL 名称：`饼图图例5_石板灰_#4e5762:`
- 完整路径：`A_资源库\开发复用\颜色格式\饼图图例5_石板灰_#4e5762:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L893–L897](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L893-L897)；表达式 L894–L895；元数据 L896–L897
- DAX SHA-256：`4e9cf9af1fd2f2383cba3ee83e59f4246563affb603506bfd5e25c5f38d6bf32`

**DAX 原文（含度量名称）**

```dax
饼图图例5_石板灰_#4e5762: =

"#4e5762"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: 8226a3d0-98d3-4de7-bfaf-30ddf3fd44eb
```

##### 度量：`饼图图例6_蜜桃色_#f3c279:`

- 源序号：M046
- 名称：`饼图图例6_蜜桃色_#f3c279:`
- 原始 TMDL 名称：`饼图图例6_蜜桃色_#f3c279:`
- 完整路径：`A_资源库\开发复用\颜色格式\饼图图例6_蜜桃色_#f3c279:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L899–L903](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L899-L903)；表达式 L900–L901；元数据 L902–L903
- DAX SHA-256：`8b1c6a1ebd2aa39c913708b651829074c93a6e9f5cd31ee19bebace565196e9a`

**DAX 原文（含度量名称）**

```dax
饼图图例6_蜜桃色_#f3c279: =

"#f3c279"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: 8a35f1ab-6a0b-4c67-acf9-875e3d0e0cc1
```

##### 度量：`饼图图例7_银灰色_#c4c4c4`

- 源序号：M047
- 名称：`饼图图例7_银灰色_#c4c4c4`
- 原始 TMDL 名称：`饼图图例7_银灰色_#c4c4c4`
- 完整路径：`A_资源库\开发复用\颜色格式\饼图图例7_银灰色_#c4c4c4`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L905–L909](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L905-L909)；表达式 L906–L907；元数据 L908–L909
- DAX SHA-256：`5b1bf0dcb6df15771a4e53b1e878b8b80b8fd5e10535aec88156bb4409dc1e79`

**DAX 原文（含度量名称）**

```dax
饼图图例7_银灰色_#c4c4c4 =

"#c4c4c4"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: 6b63ea9c-da35-45a7-8b06-a62add5c27c8
```

##### 度量：`表网格背景_象牙白_#f8f8f9:`

- 源序号：M048
- 名称：`表网格背景_象牙白_#f8f8f9:`
- 原始 TMDL 名称：`表网格背景_象牙白_#f8f8f9:`
- 完整路径：`A_资源库\开发复用\颜色格式\表网格背景_象牙白_#f8f8f9:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L911–L915](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L911-L915)；表达式 L912–L913；元数据 L914–L915
- DAX SHA-256：`14f60747e8e887c81976bfc9471e6cd8b78dd1a6e5b89d9c14be7a3fc5a06d10`

**DAX 原文（含度量名称）**

```dax
表网格背景_象牙白_#f8f8f9: =

"#f8f8f9"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: ebf03531-7e4b-4275-a64e-39f11a3c5aa7
```

##### 度量：`树形格子1_雾蓝色_#d8dee5:`

- 源序号：M049
- 名称：`树形格子1_雾蓝色_#d8dee5:`
- 原始 TMDL 名称：`树形格子1_雾蓝色_#d8dee5:`
- 完整路径：`A_资源库\开发复用\颜色格式\树形格子1_雾蓝色_#d8dee5:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L917–L921](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L917-L921)；表达式 L918–L919；元数据 L920–L921
- DAX SHA-256：`6274d9258e42bfeb8adaccdada2352ed30b0ca6c4e62d2f5fa7736b6f4d722e1`

**DAX 原文（含度量名称）**

```dax
树形格子1_雾蓝色_#d8dee5: =

"#d8dee5"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: 3a136699-b894-471f-a902-29394f3bc9be
```

##### 度量：`树形格子2_淡蓝色_#95afcf:`

- 源序号：M050
- 名称：`树形格子2_淡蓝色_#95afcf:`
- 原始 TMDL 名称：`树形格子2_淡蓝色_#95afcf:`
- 完整路径：`A_资源库\开发复用\颜色格式\树形格子2_淡蓝色_#95afcf:`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L923–L927](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L923-L927)；表达式 L924–L925；元数据 L926–L927
- DAX SHA-256：`c57a6423ca4eff5b708796d7fe768d7e327c7dfe4fdb8474af567dbb71a0d372`

**DAX 原文（含度量名称）**

```dax
树形格子2_淡蓝色_#95afcf: =

"#95afcf"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: 6f237b6b-fc36-4cee-a6d0-f36aeb92f608
```

##### 度量：`环形图嵌套_奶黄色_#ffe4bb`

- 源序号：M051
- 名称：`环形图嵌套_奶黄色_#ffe4bb`
- 原始 TMDL 名称：`环形图嵌套_奶黄色_#ffe4bb`
- 完整路径：`A_资源库\开发复用\颜色格式\环形图嵌套_奶黄色_#ffe4bb`
- displayFolder：`开发复用\颜色格式`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L929–L931](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L929-L931)；表达式 L929–L929；元数据 L930–L931
- DAX SHA-256：`4b172e0c764367d167ce1792cf9488b8e9aa0f54e00786ee00af27fa05e36fe5`

**DAX 原文（含度量名称）**

```dax
环形图嵌套_奶黄色_#ffe4bb = "#ffe4bb"
```

**原始元数据属性**

```tmdl
displayFolder: 开发复用\颜色格式
lineageTag: 3c2f8377-30aa-409b-b3b0-d7fe9d094ef2
```

### 文件夹：`日期和时间`

文件夹完整路径：`A_资源库\日期和时间`；直接度量 7；含子层级度量 7。

#### 度量：`今天日期`

- 源序号：M052
- 名称：`今天日期`
- 原始 TMDL 名称：`今天日期`
- 完整路径：`A_资源库\日期和时间\今天日期`
- displayFolder：`日期和时间`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L933–L958](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L933-L958)；表达式 L934–L952；元数据 L954–L958
- DAX SHA-256：`682afc0ece5885e538f62870fd283ce95bb2f2dd02ee37bc999df77a9e0b5c25`

**DAX 原文（含度量名称）**

```dax
今天日期 =
TODAY()
/*
-- 1、TODAY() 返回的是包含时间部分的日期时间类型
今天日期 = TODAY()  -- 实际值：2024-01-15 00:00:00
-- 在字段格式中可用的自定义格式

2、今天日期_文本 = FORMAT(TODAY(), "yyyy-MM-dd")
-- 结果："2024-01-15"（文本）
yyyy-MM-dd     -- 2024-01-15
yyyy/MM/dd     -- 2024/01/15
yyyy年M月d日   -- 2024年1月15日
ddd, MMM d     -- Thu, Apr 16

3、今天日期_纯日期 = 
VAR a = TODAY()
RETURN
    DATE(YEAR(a), MONTH(a), DAY(a))
-- 结果：2024-01-15（日期类型）
*/
```

**原始元数据属性**

```tmdl
formatString: yyyy-mm-dd
displayFolder: 日期和时间
lineageTag: bdc72f97-8b97-4a95-9a36-fb1e1b8cd88b

annotation PBI_FormatHint = {"isDateTimeCustom":true}
```

#### 度量：`当前时间`

- 源序号：M053
- 名称：`当前时间`
- 原始 TMDL 名称：`当前时间`
- 完整路径：`A_资源库\日期和时间\当前时间`
- displayFolder：`日期和时间`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L960–L965](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L960-L965)；表达式 L961–L962；元数据 L963–L965
- DAX SHA-256：`a3e8c15eaf5cec0f1baadeb5bedc436b3639866eb682056f3d5a78d2398ef153`

**DAX 原文（含度量名称）**

```dax
当前时间 =
NOW()
-- 获取当前日期和时间
```

**原始元数据属性**

```tmdl
formatString: General Date
displayFolder: 日期和时间
lineageTag: 308ec99b-5f02-484b-adb1-c8cebb3eaf88
```

#### 度量：`UTC时间`

- 源序号：M054
- 名称：`UTC时间`
- 原始 TMDL 名称：`UTC时间`
- 完整路径：`A_资源库\日期和时间\UTC时间`
- displayFolder：`日期和时间`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L967–L987](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L967-L987)；表达式 L968–L984；元数据 L985–L987
- DAX SHA-256：`3989153fc375b3b4002883f1a4d14e89f7c52ac3daff96e5354503c119767669`

**DAX 原文（含度量名称）**

```dax
UTC时间 =
UTCNOW()
-- 获取UTC时间（推荐用于跨时区）
/*
UTC时间（协调世界时）是全球统一的标准时间，不受时区或夏令时影响，以原子钟为基础精确计时

-- 基于你的电脑系统时间
本地日期 = TODAY()  -- 返回你电脑设置的日期
本地时间 = NOW()    -- 返回你电脑设置的时间

-- 基于Power BI服务所在数据中心的时钟
服务日期 = TODAY()  -- 返回UTC时间（或数据中心本地时间）
服务时间 = NOW()    -- 返回UTC时间（或数据中心本地时间）

你的电脑（成都） → Power BI Desktop → 显示本地时间
      ↓
Power BI 服务（可能在美国、欧洲、亚洲数据中心） → 显示数据中心时间
*/
```

**原始元数据属性**

```tmdl
formatString: General Date
displayFolder: 日期和时间
lineageTag: 56ba98e8-2bef-42a5-bacb-ec760f28c143
```

#### 度量：`当年年月`

- 源序号：M055
- 名称：`当年年月`
- 原始 TMDL 名称：`当年年月`
- 完整路径：`A_资源库\日期和时间\当年年月`
- displayFolder：`日期和时间`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L989–L991](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L989-L991)；表达式 L989–L989；元数据 L990–L991
- DAX SHA-256：`a537ca9ea0261947678274595e103c66c6f7196be26eca65b985ff27dd9d52da`

**DAX 原文（含度量名称）**

```dax
当年年月 = FORMAT(TODAY(), "yyyy-MM")
```

**原始元数据属性**

```tmdl
displayFolder: 日期和时间
lineageTag: 5d5f9762-a9d0-4969-8f84-ca327932c36a
```

#### 度量：`获取年、月、日等日期部分`

- 源序号：M056
- 名称：`获取年、月、日等日期部分`
- 原始 TMDL 名称：`获取年、月、日等日期部分`
- 完整路径：`A_资源库\日期和时间\获取年、月、日等日期部分`
- displayFolder：`日期和时间`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L993–L1049](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L993-L1049)；表达式 L994–L1045；元数据 L1047–L1049
- DAX SHA-256：`659908ea31e676c65cd9bd456e1dfe6b1bb63a0a43bed1502471a7298b6f22cc`

**DAX 原文（含度量名称）**

```dax
获取年、月、日等日期部分 =
1
/*
1、基本日期函数
-- 从日期中提取各部分
年 = YEAR([日期])           -- 2024
月 = MONTH([日期])          -- 4（数字）
月名 = FORMAT([日期], "MMMM") -- "April"（英文）
季度 = QUARTER([日期])      -- 2（第二季度）
日 = DAY([日期])            -- 16
星期几 = WEEKDAY([日期], 2) -- 2（周一=1，周日=7）
周数 = WEEKNUM([日期], 2)   -- 16（一年中的第几周）

2、日期计算函数
-- 日期加减
昨天 = [日期] - 1
明天 = [日期] + 1
下个月 = EDATE([日期], 1)    -- 加1个月
上个月 = EDATE([日期], -1)   -- 减1个月
明年 = EDATE([日期], 12)     -- 加12个月

-- 日期区间
月初 = STARTOFMONTH([日期])   -- 当月1号
月末 = ENDOFMONTH([日期])     -- 当月最后一天
季初 = STARTOFQUARTER([日期]) -- 季度第一天
季末 = ENDOFQUARTER([日期])   -- 季度最后一天
年初 = STARTOFYEAR([日期])    -- 当年1月1日
年末 = ENDOFYEAR([日期])      -- 当年12月31日

3、日期比较函数
-- 日期差
天数差 = DATEDIFF([开始日期], [结束日期], DAY)
月数差 = DATEDIFF([开始日期], [结束日期], MONTH)
年数差 = DATEDIFF([开始日期], [结束日期], YEAR)

-- 是否在范围内
是否本月 = 
IF(
    [日期] >= STARTOFMONTH(TODAY()) &&
    [日期] <= ENDOFMONTH(TODAY()),
    "是",
    "否"
)

-- 相对日期
是否过去7天 = 
IF(
    [日期] >= TODAY() - 7 &&
    [日期] <= TODAY(),
    "是",
    "否"
)
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 日期和时间
lineageTag: 5677bc32-8249-4761-9a9d-33c92948165e
```

#### 度量：`动态北京时间`

- 源序号：M057
- 名称：`动态北京时间`
- 原始 TMDL 名称：`动态北京时间`
- 完整路径：`A_资源库\日期和时间\动态北京时间`
- displayFolder：`日期和时间`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1051–L1067](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1051-L1067)；表达式 L1052–L1065；元数据 L1066–L1067
- DAX SHA-256：`d52da0beacbe1eb3778b6fb6abd44f7f19ec7e9b95182b29c6617ede5f9fe5f1`

**DAX 原文（含度量名称）**

```dax
动态北京时间 =

/*
动态北京时间
功能：实时显示当前北京时间
返回：格式化时间文本
创建日期：2024-01-15
注意：此度量值每秒自动刷新
*/
VAR UTCNOW = UTCNOW()  // 获取UTC时间
VAR BEIJING_TIME = UTCNOW + TIME(8, 0, 0)  // 转换为UTC+8
RETURN
"北京时间：" & FORMAT(BEIJING_TIME, "yyyy-MM-dd HH:mm:ss")
// -- 建议在导出前明确标注时区
// "北京时间：" & FORMAT(UTCNOW() + TIME(8, 0, 0), "yyyy-MM-dd HH:mm:ss")
```

**原始元数据属性**

```tmdl
displayFolder: 日期和时间
lineageTag: 6a8ddbb4-1c62-49e4-a126-61e2d301adfb
```

#### 度量：`日期的加减`

- 源序号：M058
- 名称：`日期的加减`
- 原始 TMDL 名称：`日期的加减`
- 完整路径：`A_资源库\日期和时间\日期的加减`
- displayFolder：`日期和时间`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1069–L1080](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1069-L1080)；表达式 L1070–L1077；元数据 L1078–L1080
- DAX SHA-256：`c25c7521b5c5ffd4bbab86ac6290d6f01d474b08cf41436b64bd9ec687c79f83`

**DAX 原文（含度量名称）**

```dax
日期的加减 =
1
/*
-- 方法1：简单加法
北京时间 = UTCNOW() + TIME(8, 0, 0)

-- 方法2：使用 DATEADD
北京时间 = DATEADD(UTCNOW(), 8, HOUR)
*/
```

**原始元数据属性**

```tmdl
formatString: 0
displayFolder: 日期和时间
lineageTag: cd758712-990f-4fc8-897f-10e70ddb6878
```

### 文件夹：`权限设计`

文件夹完整路径：`A_资源库\权限设计`；直接度量 2；含子层级度量 2。

#### 度量：`当前登录用户名`

- 源序号：M001
- 名称：`当前登录用户名`
- 原始 TMDL 名称：`当前登录用户名`
- 完整路径：`A_资源库\权限设计\当前登录用户名`
- displayFolder：`权限设计`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L6–L20](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L6-L20)；表达式 L7–L17；元数据 L19–L20
- DAX SHA-256：`7d1816adefbcaf8a10e886bdfda5eda1bdcb187e44d4611cb1f93c22ce1be1f4`

**DAX 原文（含度量名称）**

```dax
当前登录用户名 =

// &""作用: 将结果显式转换为文本类型,否则没有返回值的时候，函数返回空白。
VAR u = CALCULATE(
    MAX('A_页面权限'[用户名]),
    'A_页面权限'[账号]=USERNAME() 
)
VAR e = CALCULATE(
    MAX('A_页面权限'[用户名]),
    'A_页面权限'[邮箱]=USERNAME() 
)
RETURN  IF(ISBLANK(u),e,u)
```

**原始元数据属性**

```tmdl
displayFolder: 权限设计
lineageTag: 1c84f391-c1e2-44b6-a1e1-ab836046e959
```

#### 度量：`账号`

- 源序号：M002
- 名称：`账号`
- 原始 TMDL 名称：`账号`
- 完整路径：`A_资源库\权限设计\账号`
- displayFolder：`权限设计`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L22–L24](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L22-L24)；表达式 L22–L22；元数据 L23–L24
- DAX SHA-256：`e2adb6ee0aae1ff7fccc596aa38d4bfc0803e0f5f8004cb172c79de7ad43c3da`

**DAX 原文（含度量名称）**

```dax
账号 = USERNAME()
```

**原始元数据属性**

```tmdl
displayFolder: 权限设计
lineageTag: 98906d1d-e557-4274-91d4-a5ba26073788
```

### 文件夹：`页面导航`

文件夹完整路径：`A_资源库\页面导航`；直接度量 10；含子层级度量 10。

#### 度量：`页面导航按钮5`

- 源序号：M059
- 名称：`页面导航按钮5`
- 原始 TMDL 名称：`页面导航按钮5`
- 完整路径：`A_资源库\页面导航\页面导航按钮5`
- displayFolder：`页面导航`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1082–L1084](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1082-L1084)；表达式 L1082–L1082；元数据 L1083–L1084
- DAX SHA-256：`8a3cd79f5c33c9001ac2e9bf72c918f684238908d4837686836067a0641e4956`

**DAX 原文（含度量名称）**

```dax
页面导航按钮5 = "Crowd"
```

**原始元数据属性**

```tmdl
displayFolder: 页面导航
lineageTag: 0686135d-3316-4901-8c9e-0d4557f3a905
```

#### 度量：`页面导航字体颜色_选中`

- 源序号：M060
- 名称：`页面导航字体颜色_选中`
- 原始 TMDL 名称：`页面导航字体颜色_选中`
- 完整路径：`A_资源库\页面导航\页面导航字体颜色_选中`
- displayFolder：`页面导航`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1086–L1088](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1086-L1088)；表达式 L1086–L1086；元数据 L1087–L1088
- DAX SHA-256：`c322fb833565da68e717e5b9f7fdda8c9b348b18cb1fbc397b38b0b2cfd2d2bd`

**DAX 原文（含度量名称）**

```dax
页面导航字体颜色_选中 = "#0C2340"
```

**原始元数据属性**

```tmdl
displayFolder: 页面导航
lineageTag: 7bbb2d8b-f126-4109-b3c7-56a76442afdd
```

#### 度量：`页面导航字体颜色_未选中`

- 源序号：M061
- 名称：`页面导航字体颜色_未选中`
- 原始 TMDL 名称：`页面导航字体颜色_未选中`
- 完整路径：`A_资源库\页面导航\页面导航字体颜色_未选中`
- displayFolder：`页面导航`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1090–L1092](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1090-L1092)；表达式 L1090–L1090；元数据 L1091–L1092
- DAX SHA-256：`08f70434b354414e22564a44de70472e0d103c4553eb1db3e7198b3cc3074b29`

**DAX 原文（含度量名称）**

```dax
页面导航字体颜色_未选中 = "#595959"
```

**原始元数据属性**

```tmdl
displayFolder: 页面导航
lineageTag: 34b6d009-448d-430c-98e1-f37487a52ac8
```

#### 度量：`页面导航填充颜色_选中`

- 源序号：M062
- 名称：`页面导航填充颜色_选中`
- 原始 TMDL 名称：`页面导航填充颜色_选中`
- 完整路径：`A_资源库\页面导航\页面导航填充颜色_选中`
- displayFolder：`页面导航`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1094–L1096](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1094-L1096)；表达式 L1094–L1094；元数据 L1095–L1096
- DAX SHA-256：`ea9a078de66750d602e08571a3aa4d1ccf0e9df7acfbec65fee17dcff5275970`

**DAX 原文（含度量名称）**

```dax
页面导航填充颜色_选中 = "#EEE7DB"
```

**原始元数据属性**

```tmdl
displayFolder: 页面导航
lineageTag: b20afb32-0501-4fbf-872c-0a333276be60
```

#### 度量：`页面导航填充颜色_未选中`

- 源序号：M063
- 名称：`页面导航填充颜色_未选中`
- 原始 TMDL 名称：`页面导航填充颜色_未选中`
- 完整路径：`A_资源库\页面导航\页面导航填充颜色_未选中`
- displayFolder：`页面导航`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1098–L1100](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1098-L1100)；表达式 L1098–L1098；元数据 L1099–L1100
- DAX SHA-256：`e284f10bab082ec79709fd2f194a8aa49b0b39eabae04115014dcc9974d777c5`

**DAX 原文（含度量名称）**

```dax
页面导航填充颜色_未选中 = "#FFFFFF"
```

**原始元数据属性**

```tmdl
displayFolder: 页面导航
lineageTag: 3c57fda1-1b38-4ab4-9e8c-d75b64344ab3
```

#### 度量：`页面导航填充悬停颜色`

- 源序号：M064
- 名称：`页面导航填充悬停颜色`
- 原始 TMDL 名称：`页面导航填充悬停颜色`
- 完整路径：`A_资源库\页面导航\页面导航填充悬停颜色`
- displayFolder：`页面导航`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1102–L1104](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1102-L1104)；表达式 L1102–L1102；元数据 L1103–L1104
- DAX SHA-256：`11872e01d690362afb8b2ef90c810144184098b826e1806258d670a4f9b5cc27`

**DAX 原文（含度量名称）**

```dax
页面导航填充悬停颜色 = "#FFFFFF"
```

**原始元数据属性**

```tmdl
displayFolder: 页面导航
lineageTag: 6aff4626-3cb7-4359-bed7-f48507693f59
```

#### 度量：`页面导航按钮4`

- 源序号：M065
- 名称：`页面导航按钮4`
- 原始 TMDL 名称：`页面导航按钮4`
- 完整路径：`A_资源库\页面导航\页面导航按钮4`
- displayFolder：`页面导航`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1106–L1108](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1106-L1108)；表达式 L1106–L1106；元数据 L1107–L1108
- DAX SHA-256：`814929a7f1bb6af3b98f61d9e5cd73d44c4cd7db24bf971b8d5f9c4f28907862`

**DAX 原文（含度量名称）**

```dax
页面导航按钮4 = "Keyword"
```

**原始元数据属性**

```tmdl
displayFolder: 页面导航
lineageTag: 685b4be6-e77b-4ffb-adcd-c72fd9c23751
```

#### 度量：`页面导航按钮3`

- 源序号：M066
- 名称：`页面导航按钮3`
- 原始 TMDL 名称：`页面导航按钮3`
- 完整路径：`A_资源库\页面导航\页面导航按钮3`
- displayFolder：`页面导航`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1110–L1112](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1110-L1112)；表达式 L1110–L1110；元数据 L1111–L1112
- DAX SHA-256：`5f76ce08175d8db54e79b473878fbae06718743585c28b1b8703b5a9236b5ec2`

**DAX 原文（含度量名称）**

```dax
页面导航按钮3 = "Category Growth"
```

**原始元数据属性**

```tmdl
displayFolder: 页面导航
lineageTag: ab95197a-3d10-49bd-88d2-9ec8a9c54795
```

#### 度量：`页面导航按钮1`

- 源序号：M067
- 名称：`页面导航按钮1`
- 原始 TMDL 名称：`页面导航按钮1`
- 完整路径：`A_资源库\页面导航\页面导航按钮1`
- displayFolder：`页面导航`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1114–L1116](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1114-L1116)；表达式 L1114–L1114；元数据 L1115–L1116
- DAX SHA-256：`fd26257f549841f8705b4cd4b52bdae6e03dcee0558b717da4a520e87159fe73`

**DAX 原文（含度量名称）**

```dax
页面导航按钮1 = "Overview"
```

**原始元数据属性**

```tmdl
displayFolder: 页面导航
lineageTag: bd2d9170-dfe4-41eb-86a1-2f1abb7bd2ee
```

#### 度量：`页面导航按钮2`

- 源序号：M068
- 名称：`页面导航按钮2`
- 原始 TMDL 名称：`页面导航按钮2`
- 完整路径：`A_资源库\页面导航\页面导航按钮2`
- displayFolder：`页面导航`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1118–L1120](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1118-L1120)；表达式 L1118–L1118；元数据 L1119–L1120
- DAX SHA-256：`2277ffde05f033e62809b77fad011998aa3ee6c8e666100c40c89c02f50782bd`

**DAX 原文（含度量名称）**

```dax
页面导航按钮2 = "Media Mix"
```

**原始元数据属性**

```tmdl
displayFolder: 页面导航
lineageTag: 0044b225-4fe5-4937-a9fe-bf4ec94f1ae9
```

### 文件夹：`页面按钮`

文件夹完整路径：`A_资源库\页面按钮`；直接度量 5；含子层级度量 5。

#### 度量：`按钮组1`

- 源序号：M069
- 名称：`按钮组1`
- 原始 TMDL 名称：`按钮组1`
- 完整路径：`A_资源库\页面按钮\按钮组1`
- displayFolder：`页面按钮`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1122–L1124](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1122-L1124)；表达式 L1122–L1122；元数据 L1123–L1124
- DAX SHA-256：`47d6e5e36ed826bdb09490637dd5150bd47026409922beac5de587f27c6ed517`

**DAX 原文（含度量名称）**

```dax
按钮组1 = "TTL"
```

**原始元数据属性**

```tmdl
displayFolder: 页面按钮
lineageTag: 47b6c97f-9323-4b5d-b1ed-8cd714398863
```

#### 度量：`按钮组2`

- 源序号：M070
- 名称：`按钮组2`
- 原始 TMDL 名称：`按钮组2`
- 完整路径：`A_资源库\页面按钮\按钮组2`
- displayFolder：`页面按钮`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1126–L1128](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1126-L1128)；表达式 L1126–L1126；元数据 L1127–L1128
- DAX SHA-256：`ce7908a3a0ea410ba48bdf344500f680c2f5835412aef23d9a62eb1a4f2bc561`

**DAX 原文（含度量名称）**

```dax
按钮组2 = "TM"
```

**原始元数据属性**

```tmdl
displayFolder: 页面按钮
lineageTag: be6393b8-ec5f-403e-85fb-f4b78c46b072
```

#### 度量：`按钮组3`

- 源序号：M071
- 名称：`按钮组3`
- 原始 TMDL 名称：`按钮组3`
- 完整路径：`A_资源库\页面按钮\按钮组3`
- displayFolder：`页面按钮`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1130–L1132](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1130-L1132)；表达式 L1130–L1130；元数据 L1131–L1132
- DAX SHA-256：`e54f7f8b265336f79c836abff39a0ba6b7db0d366d8947ca940eed76b9d3d2d5`

**DAX 原文（含度量名称）**

```dax
按钮组3 = "JD"
```

**原始元数据属性**

```tmdl
displayFolder: 页面按钮
lineageTag: 6d374008-3afe-4080-9b75-c954647ff807
```

#### 度量：`按钮边框_选中1`

- 源序号：M072
- 名称：`按钮边框_选中1`
- 原始 TMDL 名称：`按钮边框_选中1`
- 完整路径：`A_资源库\页面按钮\按钮边框_选中1`
- displayFolder：`页面按钮`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1134–L1136](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1134-L1136)；表达式 L1134–L1134；元数据 L1135–L1136
- DAX SHA-256：`a0a4f61ffbc091469f2d0258c9ae9e60f213f59a58187002f341e79c86c1e8df`

**DAX 原文（含度量名称）**

```dax
按钮边框_选中1 = "#b8944d"
```

**原始元数据属性**

```tmdl
displayFolder: 页面按钮
lineageTag: 6c76d325-5d01-4467-8493-e78b5b94e8a0
```

#### 度量：`按钮边框_未选中1`

- 源序号：M073
- 名称：`按钮边框_未选中1`
- 原始 TMDL 名称：`按钮边框_未选中1`
- 完整路径：`A_资源库\页面按钮\按钮边框_未选中1`
- displayFolder：`页面按钮`
- 隐藏状态：否（源未声明 isHidden，或显式为 false）
- 源文件范围：[附件 L1138–L1140](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt#L1138-L1140)；表达式 L1138–L1138；元数据 L1139–L1140
- DAX SHA-256：`16b230f036036fb0880a4c79444ed14145ac33ef3215dbad40e3ea46a86faa61`

**DAX 原文（含度量名称）**

```dax
按钮边框_未选中1 = "#e0dcd4"
```

**原始元数据属性**

```tmdl
displayFolder: 页面按钮
lineageTag: 4ce2929a-249f-4d04-9ed4-08b45cd3b23f
```

## 机械校验记录

- 使用逐行结构解析与独立正则切片交叉核对附件声明；再回读 Markdown 的标题、字段、树形索引及代码块。
- 名称、原始名称令牌、完整路径、源序号、隐藏状态和源行号：逐项一致；每个度量在正文出现一次，在索引出现一次；无遗漏、无重复。
- 每份 DAX 和原始元数据：按以上结构性去缩进规则逐字符比较，并逐项核对 DAX SHA-256；不是只比较名称或数量。
- 所有 Markdown 代码围栏按状态机检查开启、关闭和语言类型；正文恰有 130 个 dax 块、130 个 tmdl 块，以及 1 个完整索引 text 块。
- 标题恢复的文件夹节点及树形索引路径与附件一致；排列顺序遵循本文的文件夹排序规则，同级度量保留附件声明顺序。核验通过后保存，并对落盘文件再次执行相同检查。
- 内容汇总 SHA-256：`75378f19f9f75e2e425028b0cc184618780cd8d185bf49682857ea81b8ef538f`。算法：按源序号依次取名称、原名称令牌、文件夹、完整 DAX、元数据；每字段以 UTF-8 字节长度的十进制数、冒号、原文、LF 串接后计算 SHA-256。
- 附件与既有文件在生成前后均计算原始字节 SHA-256，确认未修改。既有文件只用于保护校验，不参与内容恢复。

| 受保护文件 | 原始字节 SHA-256 |
| --- | --- |
| [text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt](file:///C:/Users/jm043195/AppData/Local/Temp/aicoding-text-field/task-31ac4e31348e43af975f.session.execution/text-field-content-813ee23b-7471-4e72-844c-0fffe4fcbad9.txt) | `d2847fce4a272c564bbc7dbaac6d4e80c5b8b21e829c30c47144fbeb5ba255f6` |
| [A_资源库.md](file:///D:/gutao/%E8%BE%9C%E6%B6%9B/Project/Qoder_AI_Frontend_and_backend_Web/RL%20E2E/%E6%A8%A1%E7%89%88%E5%A4%8D%E7%94%A8/%E8%B5%84%E6%BA%90%E5%BA%93/A_%E8%B5%84%E6%BA%90%E5%BA%93.md) | `7f16e9d5f479970af98811ca1b2c4970710027d164b666be3b3f8adbda2c3fcb` |
| [A_页面权限.md](file:///D:/gutao/%E8%BE%9C%E6%B6%9B/Project/Qoder_AI_Frontend_and_backend_Web/RL%20E2E/%E6%A8%A1%E7%89%88%E5%A4%8D%E7%94%A8/%E8%B5%84%E6%BA%90%E5%BA%93/A_%E9%A1%B5%E9%9D%A2%E6%9D%83%E9%99%90.md) | `4279f00a0c9d54e22855274e9796481b14ec807b99a7a060b6907e9638c62cb0` |
