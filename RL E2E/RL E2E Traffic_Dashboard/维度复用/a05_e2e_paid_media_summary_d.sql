let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "select 
*,
'Total' AS Total
FROM `indep_rl_ads`.a05_e2e_paid_media_summary_d
WHERE platform IN ('JD', 'TM', 'RLE', 'DY');")
in
    源



select 
*,
'Total' AS Total
FROM `indep_rl_ads`.a05_e2e_paid_media_summary_d
WHERE platform IN ('JD', 'TM', 'RLE', 'DY');