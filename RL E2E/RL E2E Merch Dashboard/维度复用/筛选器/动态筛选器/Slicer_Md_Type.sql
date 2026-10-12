let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select distinct md_type
from indep_rl_ads.a02_e2e_product_performance_sales_summary_d
where md_type is not null
  and md_type <> ''
  and trim(md_type) <> ''
;")
in
    源