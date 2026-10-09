let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select distinct framework
from indep_rl_ads.a02_e2e_product_performance_sales_summary_d
where framework is not null
  and framework <> ''
  and trim(framework) <> ''
;")
in
    源