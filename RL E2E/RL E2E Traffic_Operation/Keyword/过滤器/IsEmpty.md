# IsKeywordX_Visible

IsKeywordX_Visible = 
// 柱形或趋势图中用于过滤多余的X轴维度（Keyword行）
// 当9个度量值同时为空时返回0（隐藏），否则返回1（显示）
IF(
    ISBLANK([Keyword X Add to Cart]) &&
    ISBLANK([Keyword X Click]) &&
    ISBLANK([Keyword X Cost]) &&
    ISBLANK([Keyword X Cost%]) &&
    ISBLANK([Keyword X CPATC]) &&
    ISBLANK([Keyword X CPC]) &&
    ISBLANK([Keyword X CTR]) &&
    ISBLANK([Keyword X CVR]) &&
    ISBLANK([Keyword X ROI]),
    0,  // 全部为空 → 隐藏
    1   // 至少有一个有值 → 显示
)


# IsKeyword_Visible

IsKeyword_Visible = 
// 柱形或趋势图中用于过滤多余的X轴维度（Keyword行）
// 当9个度量值同时为空时返回0（隐藏），否则返回1（显示）
IF(
    ISBLANK([Keyword X Add to Cart]) &&
    ISBLANK([Keyword X Click]) &&
    ISBLANK([Keyword X Cost]) &&
    ISBLANK([Keyword Cost%]) &&
    ISBLANK([Keyword X CPATC]) &&
    ISBLANK([Keyword X CPC]) &&
    ISBLANK([Keyword X CTR]) &&
    ISBLANK([Keyword X CVR]) &&
    ISBLANK([Keyword X ROI]),
    0,  // 全部为空 → 隐藏
    1   // 至少有一个有值 → 显示
)
