# 第一轮提示词：
参考RL E2E\RL E2E BOSS Dashboard\口径文档\Overview.md的格式，根据文件D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\参考文件\取数逻辑for PBI.xlsx中的Tab为Performance By Location和Performance By Merchandise部分，分别输出这两部分的口径文档，在RL E2E\RL E2E BOSS Dashboard\口径文档目录下。execl文件中附属指标列，也需要列为子指标项，Overview.md中有类似情况，按照该文件的格式输出，记得检查计算指标是否一致，这是口径很重要很严格，不能出错，不懂就问。

# 第二轮提示词:
参考这个文件，D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E BOSS Dashboard\Overview\Sales\Overview_Sales_ms.md
根据所选timeframe聚合，如果是Month，则聚合在月粒度，展示所选时间范围每月的聚合值；如果是Year，则聚合在年粒度，展示所选时间范围每年的聚合值。
柱形图 + 趋势图，无需矩阵 SWITCH 路由分发，每个指标独立编写 Value / Display 度量
一切口径以指标口径文档，不懂就问，输出方案文件在RL E2E\RL E2E BOSS Dashboard\Overview\Fulfillment分组目录下，
单独输出Value和Display度量

# 第二轮提示词（实际生效）:
口径确认结论：
1、Overview.md 文件仅作为结构参考，数据内容以当前 Excel 为准；Fulfillment% Trend（行25）的 calc_type = fulfillment 是当前指标的固定筛选。
2、行23 Shipped Order Qty 数据底表 a02_e1e_boss_performance_summary_d 为笔误，统一为 a02_e2e_boss_performance_summary_d。
3、行44-53 的 e3e/e4e/e5e/.../e12e 全部为笔误，统一为 a02_e2e_boss_performance_summary_d。
4、行27 ads_e2e_boss_fulfillment_fail_reason_d 笔误，应为 a02_e2e_boss_fulfillment_fail_reason_d；e3e 等全部为笔误，只有 e2e。
5、YOY 同比口径统一为：今年 / 去年 − 1。
6、行24 Shipped Order Amt 的附属指标应为 "LY Fulfilled Order Amt"（原 Excel 写成 "LY Fulfilled Order Qty" 为笔误）。
7、行75 Product Volume 无 K 列附属指标，不输出 LY/vs LY。
8、行26 Unfulfilled Order by Region 无 LY，不输出 LY/vs LY。
9、行27 Failed Request by Reason 不输出 LY/vs LY。
10、K 列有附属指标就输出 LY/vs LY，没有就不输出。

# 第三轮提示词：


# 第四轮提示：



# 第五轮提示：


# 第六轮提示:


# 第七轮提示：

# 第八轮提示：

