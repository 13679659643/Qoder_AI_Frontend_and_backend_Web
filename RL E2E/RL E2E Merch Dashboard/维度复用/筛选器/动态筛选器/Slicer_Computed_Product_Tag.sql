let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select distinct computed_product_tag
from indep_rl_ads.a02_e2e_product_performance_sales_summary_d
where computed_product_tag is not null
  and computed_product_tag <> ''
  and trim(computed_product_tag) <> ''
;")
in
    源