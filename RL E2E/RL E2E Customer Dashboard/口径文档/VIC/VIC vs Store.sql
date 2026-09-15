其中('202701','202702')表示筛选器的所选范围，'202702'表示end period
 new_vic和retention_vic部分仅is_new_vic = 1和is_retention_vic = 1区别。

new_vic部分：
ACV vs Store：New VIC ACV / 全客ACV - 1
with new_vic_acv as (
    select sum(net_pay_amt) as net_sales,
       count(distinct user_id) as vic_cnt,
       sum(net_pay_amt)/count(distinct user_id) as new_vic_acv
from `indep_rl_ads`.`a03_e2e_customer_data_m`
where data_month in ('202701','202702')
and is_member = 0
and user_id in
(select distinct user_id
from `indep_rl_ads`.`a03_e2e_customer_data_m`
where is_member = 0
and is_new_vic = 1
and data_month  = '202702')
),

ttl_acv as (
select sum(net_pay_amt) as ttl_net_sales,
        count(distinct a.user_id) as ttl_customer_cnt,
        sum(net_pay_amt)/count(distinct a.user_id) as ttl_acv
from `indep_rl_ads`.`a03_e2e_customer_data_m` as a
where data_month in ('202702','202701')
and is_member = 0 and net_pay_amt > 0
)

select new_vic_acv, ttl_acv,
       new_vic_acv/ttl_acv - 1
from new_vic_acv
cross join ttl_acv


UPT vs Store：New VIC UPT / 全客UPT - 1
with new_vic_upt as (
select sum(net_pay_qty) as net_qty,
       sum(net_pay_order_cnt) as net_order_cnt,
       sum(net_pay_qty)/sum(net_pay_order_cnt) as new_vic_upt
from `indep_rl_ads`.`a03_e2e_customer_data_m`
where data_month in ('202701','202702')
and is_member = 0
and user_id in
(select distinct user_id
from `indep_rl_ads`.`a03_e2e_customer_data_m`
where is_member = 0
and is_new_vic = 1
and data_month  = '202702')
),

ttl_upt as (
select sum(net_pay_qty) as net_qty,
       sum(net_pay_order_cnt) as net_order_cnt,
       sum(net_pay_qty)/sum(net_pay_order_cnt) as ttl_upt
from `indep_rl_ads`.`a03_e2e_customer_data_m` as a
where data_month in ('202702','202701')
and is_member = 0 and net_pay_amt > 0
)

select new_vic_upt, ttl_upt,
       new_vic_upt/ttl_upt - 1
from new_vic_upt
cross join ttl_upt


AUR vs Store：New VIC AUR / 全客AUR - 1
with new_vic_aur as (
select sum(net_pay_amt) as net_pay_amt,
       sum(net_pay_qty) as net_qty,
       sum(net_pay_amt)/sum(net_pay_qty) as new_vic_aur
from `indep_rl_ads`.`a03_e2e_customer_data_m`
where data_month in ('202701','202702')
and is_member = 0
and user_id in
(select distinct user_id
from `indep_rl_ads`.`a03_e2e_customer_data_m`
where is_member = 0
and is_new_vic = 1
and data_month  = '202702')
),

ttl_aur as (
select sum(net_pay_amt) as net_pay_amt,
       sum(net_pay_qty) as net_qty,
       sum(net_pay_amt)/sum(net_pay_qty) as ttl_aur
from `indep_rl_ads`.`a03_e2e_customer_data_m` as a
where data_month in ('202702','202701')
and is_member = 0 and net_pay_amt > 0
)

select new_vic_aur, ttl_aur,
       new_vic_aur/ttl_aur - 1
from new_vic_aur
cross join ttl_aur


Freq vs Store：New VIC Freq / 全客Freq - 1
with new_vic_freq as (
select sum(net_pay_order_cnt) as net_order_cnt,
       count(distinct user_id) as vic_cnt,
       sum(net_pay_order_cnt)/count(distinct user_id) as new_vic_freq
from `indep_rl_ads`.`a03_e2e_customer_data_m`
where data_month in ('202701','202702')
and is_member = 0
and user_id in
(select distinct user_id
from `indep_rl_ads`.`a03_e2e_customer_data_m`
where is_member = 0
and is_new_vic = 1
and data_month  = '202702')
),

ttl_freq as (
select sum(net_pay_order_cnt) as net_order_cnt,
       count(distinct user_id) as vic_cnt,
       sum(net_pay_order_cnt)/count(distinct user_id) as ttl_freq
from `indep_rl_ads`.`a03_e2e_customer_data_m` as a
where data_month in ('202702','202701')
and is_member = 0 and net_pay_amt > 0
)

select new_vic_freq, ttl_freq,
       new_vic_freq/ttl_freq - 1
from new_vic_freq
cross join ttl_freq



 retention_vic部分：
ACV vs Store：Retention VIC ACV / 全客ACV - 1
with retention_vic_acv as (
    select sum(net_pay_amt) as net_sales,
       count(distinct user_id) as vic_cnt,
       sum(net_pay_amt)/count(distinct user_id) as retention_vic_acv
from `indep_rl_ads`.`a03_e2e_customer_data_m`
where data_month in ('202701','202702')
and is_member = 0
and user_id in
(select distinct user_id
from `indep_rl_ads`.`a03_e2e_customer_data_m`
where is_member = 0
and is_retention_vic = 1
and data_month  = '202702')
),

ttl_acv as (
select sum(net_pay_amt) as ttl_net_sales,
        count(distinct a.user_id) as ttl_customer_cnt,
        sum(net_pay_amt)/count(distinct a.user_id) as ttl_acv
from `indep_rl_ads`.`a03_e2e_customer_data_m` as a
where data_month in ('202702','202701')
and is_member = 0 and net_pay_amt > 0
)

select retention_vic_acv, ttl_acv,
       retention_vic_acv/ttl_acv - 1
from retention_vic_acv
cross join ttl_acv


UPT vs Store：Retention VIC UPT / 全客UPT - 1
with retention_vic_upt as (
select sum(net_pay_qty) as net_qty,
       sum(net_pay_order_cnt) as net_order_cnt,
       sum(net_pay_qty)/sum(net_pay_order_cnt) as retention_vic_upt
from `indep_rl_ads`.`a03_e2e_customer_data_m`
where data_month in ('202701','202702')
and is_member = 0
and user_id in
(select distinct user_id
from `indep_rl_ads`.`a03_e2e_customer_data_m`
where is_member = 0
and is_retention_vic = 1
and data_month  = '202702')
),

ttl_upt as (
select sum(net_pay_qty) as net_qty,
       sum(net_pay_order_cnt) as net_order_cnt,
       sum(net_pay_qty)/sum(net_pay_order_cnt) as ttl_upt
from `indep_rl_ads`.`a03_e2e_customer_data_m` as a
where data_month in ('202702','202701')
and is_member = 0 and net_pay_amt > 0
)

select retention_vic_upt, ttl_upt,
       retention_vic_upt/ttl_upt - 1
from retention_vic_upt
cross join ttl_upt


AUR vs Store：Retention VIC AUR / 全客AUR - 1
with retention_vic_aur as (
select sum(net_pay_amt) as net_pay_amt,
       sum(net_pay_qty) as net_qty,
       sum(net_pay_amt)/sum(net_pay_qty) as retention_vic_aur
from `indep_rl_ads`.`a03_e2e_customer_data_m`
where data_month in ('202701','202702')
and is_member = 0
and user_id in
(select distinct user_id
from `indep_rl_ads`.`a03_e2e_customer_data_m`
where is_member = 0
and is_retention_vic = 1
and data_month  = '202702')
),

ttl_aur as (
select sum(net_pay_amt) as net_pay_amt,
       sum(net_pay_qty) as net_qty,
       sum(net_pay_amt)/sum(net_pay_qty) as ttl_aur
from `indep_rl_ads`.`a03_e2e_customer_data_m` as a
where data_month in ('202702','202701')
and is_member = 0 and net_pay_amt > 0
)

select retention_vic_aur, ttl_aur,
       retention_vic_aur/ttl_aur - 1
from retention_vic_aur
cross join ttl_aur


Freq vs Store：Retention VIC Freq / 全客Freq - 1
with retention_vic_freq as (
select sum(net_pay_order_cnt) as net_order_cnt,
       count(distinct user_id) as vic_cnt,
       sum(net_pay_order_cnt)/count(distinct user_id) as retention_vic_freq
from `indep_rl_ads`.`a03_e2e_customer_data_m`
where data_month in ('202701','202702')
and is_member = 0
and user_id in
(select distinct user_id
from `indep_rl_ads`.`a03_e2e_customer_data_m`
where is_member = 0
and is_retention_vic = 1
and data_month  = '202702')
),

ttl_freq as (
select sum(net_pay_order_cnt) as net_order_cnt,
       count(distinct user_id) as vic_cnt,
       sum(net_pay_order_cnt)/count(distinct user_id) as ttl_freq
from `indep_rl_ads`.`a03_e2e_customer_data_m` as a
where data_month in ('202702','202701')
and is_member = 0 and net_pay_amt > 0
)

select retention_vic_freq, ttl_freq,
       retention_vic_freq/ttl_freq - 1
from retention_vic_freq
cross join ttl_freq