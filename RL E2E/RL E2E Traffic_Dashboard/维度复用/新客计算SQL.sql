('202701', '202702')是全局筛选，dt ='202701'是开始财月。
// 变量定义区
// ── 时间筛选：去年同期（直接读取日期表内置 LY 字段）──
VAR __LPTimeMin = SELECTEDVALUE(Slicer_Time_Frame_Min[TimeFrame_Min_LY])
VAR __LPTimeMax = SELECTEDVALUE(Slicer_Time_Frame_Max[TimeFrame_Max_LY])
// ── 第一财月区间（去年同期，新客 Step2 的 start_period）──
VAR __LPFirstFiscalMonthMin = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Min_LY])
VAR __LPFirstFiscalMonthMax = SELECTEDVALUE(Slicer_Time_Frame_Min[First_Fiscal_Month_Max_LY])

SELECT  a.platform,a.shop_info_id,a.shop_name,count(DISTINCT a.user_id) u_cnt  -- 分母
FROM 
(
SELECT platform ,shop_info_id ,shop_name ,user_id ,sum(net_pay_amt) net_pay_amt  
FROM indep_rl_ads.a03_e2e_customer_data_m
where 1=1
and dt >='202701' and dt<='202702'
and is_member = 0
and platform ='TM'
group by platform ,shop_info_id ,shop_name ,user_id 
HAVING sum(net_pay_amt)>0
)a
left anti join (
SELECT platform ,shop_info_id ,shop_name ,user_id  ,sum(lp_12m_net_pay_amt) as lp_12m_net_pay_amt
FROM indep_rl_ads.a03_e2e_customer_data_m
where 1=1
and dt ='202701'
and is_member = 0
and platform ='TM'
group by platform ,shop_info_id ,shop_name ,user_id
having sum(lp_12m_net_pay_amt) > 0
)b on a.user_id=b.user_id
group by  a.platform,a.shop_info_id,a.shop_name
;


select count(distinct user_id)
from (select user_id,
       sum(net_pay_amt) as net_pay_amt,
       sum(case when data_month = '202701' then lp_12m_net_pay_amt else 0 end) as lp_12m_net_pay_amt
from `indep_rl_ads`.`a03_e2e_customer_data_m`
where data_month in ('202701','202702')
and is_member = 0
and platform = 'TM'
group by user_id)
where net_pay_amt > 0 and lp_12m_net_pay_amt = 0


select a.shop_name_en, count(distinct a.user_id)
from (select shop_name_en, user_id, 
       sum(net_pay_amt) as net_pay_amt
from `indep_rl_ads`.`a03_e2e_customer_data_m`
where is_member = 0
and data_month in ('202701', '202702')
group by shop_name_en, user_id) as a
left join
(select shop_name_en, user_id, sum(lp_12m_net_pay_amt) as lp_12m_net_pay_amt
from `indep_rl_ads`.`a03_e2e_customer_data_m`
where is_member = 0
and data_month = '202701'
group by shop_name_en, user_id
) as b
on a.shop_name_en = b.shop_name_en
and a.user_id = b.user_id
where (b.lp_12m_net_pay_amt = 0 or b.lp_12m_net_pay_amt IS NULL)
and a.net_pay_amt > 0
group by a.shop_name_en