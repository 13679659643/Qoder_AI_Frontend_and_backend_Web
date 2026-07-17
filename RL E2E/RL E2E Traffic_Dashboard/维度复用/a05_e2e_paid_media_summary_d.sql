let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "select 
*,
'Total' AS Total,
CASE 
    WHEN is_controllable_channel = 1 THEN 'Controllable%'
    WHEN is_controllable_channel = 0 THEN 'Uncontrollable%'
    ELSE 'Unknown' -- 良好实践，尽管按 is_controllable_channel 过滤后可能不会触发
END AS Un_Controllable_Group,
CASE
    WHEN is_controllable_channel = 0 THEN 'Uncontrollable'
    WHEN platform = 'TM' THEN
        CASE
            WHEN channel IN ('直通车', '引力魔方') THEN channel
            ELSE 'TM_Other_Channel'
        END
    WHEN platform = 'JD' THEN
        CASE
            WHEN channel IN ('快车', '触点') THEN channel
            ELSE 'JD_Other_Channel'
        END
    WHEN platform = 'DY' THEN 'DY_Other_Channel'
    WHEN platform = 'RLE' THEN 'RLE_Other_Channel'
    ELSE 'Unknown' -- 良好实践，尽管按 platform 过滤后可能不会触发
END AS Channel_Group
FROM `indep_rl_ads`.a05_e2e_paid_media_summary_d
WHERE platform IN ('JD', 'TM', 'RLE', 'DY');")
in
    源



select 
*,
'Total' AS Total,
CASE 
    WHEN is_controllable_channel = 1 THEN 'Controllable%'
    WHEN is_controllable_channel = 0 THEN 'Uncontrollable%'
    ELSE 'Unknown' -- 良好实践，尽管按 is_controllable_channel 过滤后可能不会触发
END AS Un_Controllable%_Group,
CASE
    WHEN is_controllable_channel = 0 THEN 'Uncontrollable'
    WHEN platform = 'TM' THEN
        CASE
            WHEN channel IN ('直通车', '引力魔方') THEN channel
            ELSE 'TM_Other_Channel'
        END
    WHEN platform = 'JD' THEN
        CASE
            WHEN channel IN ('快车', '触点') THEN channel
            ELSE 'JD_Other_Channel'
        END
    WHEN platform = 'DY' THEN 'DY_Other_Channel'
    WHEN platform = 'RLE' THEN 'RLE_Other_Channel'
    ELSE 'Unknown' -- 良好实践，尽管按 platform 过滤后可能不会触发
END AS Channel_Group
FROM `indep_rl_ads`.a05_e2e_paid_media_summary_d
WHERE platform IN ('JD', 'TM', 'RLE', 'DY');

let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "select 
*,
'Total' AS Total
FROM `indep_rl_ads`.a05_e2e_paid_media_crowed_data_d
WHERE platform IN ('JD', 'TM', 'RLE', 'DY');")
in
    源


let
    源 = Odbc.Query("dsn=bytehouse_rl", 
    "select 
*,
'Total' AS Total
FROM `indep_rl_ads`.a05_e2e_paid_media_keyword_data_d
WHERE platform IN ('JD', 'TM', 'RLE', 'DY');")
in
    源