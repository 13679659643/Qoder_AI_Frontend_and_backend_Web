let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select distinct category
from indep_rl_ads.a02_e2e_product_performance_sales_summary_d
where category is not null
  and category <> ''
  and trim(category) <> ''
;")
in
    源