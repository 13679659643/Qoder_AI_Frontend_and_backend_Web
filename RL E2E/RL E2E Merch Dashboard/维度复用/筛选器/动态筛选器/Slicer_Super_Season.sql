let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select distinct super_season
from indep_rl_ads.a02_e2e_product_performance_sales_summary_d
where super_season is not null
  and super_season <> ''
  and trim(super_season) <> ''
;")
in
    源