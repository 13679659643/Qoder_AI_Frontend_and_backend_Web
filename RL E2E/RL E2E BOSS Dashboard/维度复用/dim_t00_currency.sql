let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
    SELECT *
    FROM `indep_rl_dim`.dim_t00_currency
    WHERE end_year = (
        SELECT MAX(end_year)
        FROM `indep_rl_dim`.dim_t00_currency
      )
    ")
in
    源


	source_currency_code	source_currency_name	target_currency_code	target_currency_name	exchange_rate	start_date	end_date	start_year	end_year	is_valid	create_time	update_time
	USD	美元	CNY	人民币	7.91	2026-03-29	2027-04-03	2026	2027	1	2026-09-10 15:32:10.000	2026-09-10 15:32:10.000