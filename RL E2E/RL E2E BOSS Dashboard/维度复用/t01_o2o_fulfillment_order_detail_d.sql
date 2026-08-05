let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
select * from `indep_rl_dw`.`t01_o2o_fulfillment_order_detail_d`
   "),
    更改的类型 = Table.TransformColumnTypes(源,{{"dt", type date}})
in
    更改的类型