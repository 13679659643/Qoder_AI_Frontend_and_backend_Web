let
    源 = Odbc.Query("dsn=bytehouse_rl", "#(lf)SELECT DISTINCT#(lf)    Season AS `Super Season`,#(lf)    Category  AS `Category`,#(lf)    brand  AS `Label`#(lf)FROM `indep_rl_ads`.a05_e2e_paid_media_crowed_data_d#(lf)WHERE platform IN ('JD', 'TM')#(lf)ORDER BY `Super Season`, `Category`, `Label`#(lf)")
in
    源