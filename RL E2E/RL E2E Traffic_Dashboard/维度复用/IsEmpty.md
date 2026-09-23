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

# Traffic_Operation

## Category Growth ISBLANK = 
    IF(
        ISBLANK([Category Growth EOH(OMS)%]) &&
        ISBLANK([Category Growth Active IDs]) &&
        ISBLANK([Category Growth Active IDs VS LP]) &&
        ISBLANK([Category Growth Net Sales%]) &&
        ISBLANK([Category Growth SLS% VS LP]) &&
        ISBLANK([Category Growth Cost]) &&
        ISBLANK([Category Growth Cost VS LP]) &&
        ISBLANK([Category Growth Cost%]) &&
        ISBLANK([Category Growth Cost% VS LP]) &&
        ISBLANK([Category Growth ROI]) &&
        ISBLANK([Category Growth ROI VS LP])
        ,
        0,
        1
    )

## Keyword X  Ads format ISBLANK
Keyword X  Ads format ISBLANK = 
    IF(
        ISBLANK([Keyword X Cost]) &&
        ISBLANK([Keyword X Cost%]) &&
        ISBLANK([Keyword X ROI]) &&
        ISBLANK([Keyword X Click]) &&
        ISBLANK([Keyword X CPC]) &&
        ISBLANK([Keyword X CTR]) &&
        ISBLANK([Keyword X CVR]) &&
        ISBLANK([Keyword X Add to Cart]) &&
        ISBLANK([Keyword X CPATC]),
        0,
        1
    )

## Keyword ISBLANK
Keyword ISBLANK = 
    IF(
        ISBLANK([Keyword X Cost]) &&
        ISBLANK([Keyword Cost%]) &&
        ISBLANK([Keyword X ROI]) &&
        ISBLANK([Keyword X Click]) &&
        ISBLANK([Keyword X CPC]) &&
        ISBLANK([Keyword X CTR]) &&
        ISBLANK([Keyword X CVR]) &&
        ISBLANK([Keyword X Add to Cart]) &&
        ISBLANK([Keyword X CPATC]),
        0,
        1
    )

## Crowd TA X Channel ISBLANK
Crowd TA X Channel ISBLANK = 
    IF(
        ISBLANK([Crowd Cost]) &&
        ISBLANK([Crowd Cost%]) &&
        ISBLANK([Crowd ROI]) &&
        ISBLANK([Crowd Click]) &&
        ISBLANK([Crowd CPC]) &&
        ISBLANK([Crowd CTR]) &&
        ISBLANK([Crowd CVR]) &&
        ISBLANK([Crowd Add to Cart]) &&
        ISBLANK([Crowd CPATC]),
        0,
        1
    )

## Crowd TA ISBLANK
Crowd TA ISBLANK = 
    IF(
        ISBLANK([Crowd Cost]) &&
        ISBLANK([Crowd TA Cost%]) &&
        ISBLANK([Crowd ROI]) &&
        ISBLANK([Crowd Click]) &&
        ISBLANK([Crowd CPC]) &&
        ISBLANK([Crowd CTR]) &&
        ISBLANK([Crowd CVR]) &&
        ISBLANK([Crowd Add to Cart]) &&
        ISBLANK([Crowd CPATC]),
        0,
        1
    )