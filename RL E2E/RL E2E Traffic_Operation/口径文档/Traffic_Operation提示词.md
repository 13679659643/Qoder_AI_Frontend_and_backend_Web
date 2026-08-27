## 板块二：Growth Overview-Target Achievement第一轮提示词：
口径文档：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Traffic_Operation\口径文档\Overview.md
参考文件：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Traffic_Operation\Overview\目标达成\KPIs Overview_Target_matrix_solution
日期表：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Traffic_Operation\维度复用\Slicer_Time_Frame.sql
平台维度表Slicer_Platform_Selection：D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Traffic_Operation\维度复用\Slicer_Platform_Selection.md

1、Target我新增了日期表Slicer_Time_Frame与事实表断开连接，之前的Dim_Date_Current ── 1:* ──→ a05_e2e_paid_media_summary_d / product_data_d，所以在涉及到a05_e2e_paid_media_summary_d / product_data_d计算时需要移除Dim_Date_Current表的影响，再添加新的日期范围筛选，日期字段为a05_e2e_paid_media_summary_d[data_date]\a05_e2e_paid_media_fcst_data_m[data_date]。日期表Slicer_Time_Frame在页面上本身就是单选状态，所以不需要考虑跨财年或者跨财月的情况，始终为单个财月、财年。
2、Slicer_Platform_Selection和a05_e2e_paid_media_fcst_data_m断开连接，a05_e2e_paid_media_fcst_data_m和其他事实表不同，platform已经算好了ALL的情况，在计算时筛选a05_e2e_paid_media_fcst_data_m[platform] IN {"ALL"}，而不是IN {"TM","JD"}。
3、Target 的指标计算会存在根据Slicer_Time_Frame[TimeFrame_ID]时间粒度的不同，使用不同的字段，比如，Cost Rate — 目标花费占比的口径中，Month：`media_cost_rate`；Year：`MAX(year_media_cost_rate)`（按 data_year），统一使用以下写法，**SUMMARIZE版）**：`SUMMARIZE(platform, year_vic_customer_cnt)` + 直接引用列- 本质：`SUMMARIZE` 引入指标列天然等价于 `DISTINCT`，直接对去重后的值求和。适用场景：标准的“分组去重后汇总”逻辑，不假设数据唯一性。**关键优势**：语义清晰（等价于 SQL `GROUP BY` 三列），性能更优（减少上下文转换），且对 `NULL/BLANK` 分组处理一致；当数据存在多值风险时，能如实反映全量数据，避免逻辑黑洞。本次方案只存在platform维度，所有SUMMARIZE一个维度+对应指标就够了：
// 推荐写法：语义准确，性能更好，先按维度分组，再对指标列做聚合，都参考以下dax实现方式
```dax
VAR __YearVICCustomerSum =
CALCULATE(
    SUMX(
        SUMMARIZE(
            'a05_e2e_paid_media_fcst_data_m',
            'a05_e2e_paid_media_fcst_data_m'[platform],
            'a05_e2e_paid_media_fcst_data_m'[year_vic_customer_cnt]
        ),
        'a05_e2e_paid_media_fcst_data_m'[year_vic_customer_cnt]
    ),
    'a05_e2e_paid_media_fcst_data_m'[data_date] >= __TimeMin,
    'a05_e2e_paid_media_fcst_data_m'[data_date] <= __TimeMax
)
```
4、Slicer_Time_Frame中TimeFrame_ID作为前端展示的时间粒度，TimeFrame_Value为展示值，slicer所选时间区间（data_date ∈ [Slicer_Time_Frame[TimeFrame_Min], Slicer_Time_Frame[TimeFrame_Max]]）为计算指标的时间范围。
5、新客判定 = Step1 + Step2 交集（合并区间简化实现）:
Step 1：在所选时间范围内筛选 `net_pay_amt > 0` 的 `user_id`（`data_date = 所选时间范围`，`is_member = 0`，`net_pay_amt > 0`）；Step 2：缩小顾客范围至 `lp_12m_net_pay_amt = 0`（`data_date = 所选时间范围 start_period`）；相当于取 Step 1 和 Step 2 的交集，最后 count(distinct user_id)
由于 start_period（第一个财月）是 slicer 区间的子集，技术实现上可"合并区间"——用于判断 `lp_12m_net_pay_amt = 0` 的行一定也在 slicer 区间内。因此技术实现直接等价于单一筛选：
```
data_date ∈ start_period AND net_pay_amt > 0 AND is_member = 0 AND lp_12m_net_pay_amt = 0
```
6、
在D:\gutao\辜涛\Project\Qoder_AI_Frontend_and_backend_Web\RL E2E\RL E2E Traffic_Operation\Overview\目标达成目录下，按照最新逻辑重新输出一份KPIs Overview_Target_matrix_solution，文件名为KPIs Overview_Target_ms.md