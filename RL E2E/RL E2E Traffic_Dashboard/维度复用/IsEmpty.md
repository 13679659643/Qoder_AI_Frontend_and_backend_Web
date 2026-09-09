# RL E2E Traffic_Dashboard

## New Acquisition

### KPIs_Measure_solution

TM 引力魔方-->JD 触点 ISBLANK =
    IF(
        ISBLANK([Cost 引力魔方 Value]) &&
        ISBLANK([Cost% 引力魔方 Value]) &&
        ISBLANK([ROI 引力魔方 Value]) ,
        0,
        1
    )

TM 直通车-->JD 快车 ISBLANK =
    IF(
        ISBLANK([Cost 直通车 Value]) &&
        ISBLANK([Cost% 直通车 Value]) &&
        ISBLANK([ROI 直通车 Value]) ,
        0,
        1
    )
