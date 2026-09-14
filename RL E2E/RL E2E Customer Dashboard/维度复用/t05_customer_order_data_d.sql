let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "
SELECT
    `etl_time`,
    `dt`,
    `user_id`                AS `user_id_origin`,
    MD5(`user_id`)           AS `user_id`,
    `user_name`,
    `platform`,
    `shop_info_id`,
    `shop_id`,
    `shop_name`,
    `shop_code`,
    `product_id`,
    `product_name`,
    `product_img_url`,
    `framework`,
    `brand`,
    `gender`,
    `season`,
    `category`,
    `category_summary`,
    `is_member`,
    `register_time`,
    `pay_amt`,
    `pay_order_cnt`,
    `pay_qty`,
    `net_pay_amt`,
    `net_pay_order_cnt`,
    `net_pay_qty`,
    `return_amt`,
    `return_order_cnt`,
    `return_qty`,
    `cancel_amt`,
    `cancel_order_cnt`,
    `cancel_qty`
FROM `indep_rl_dw`.`t05_customer_order_data_d`

    "),
    更改的类型 = Table.TransformColumnTypes(源,{{"dt", type date}})
in
    更改的类型