# RL E2E Traffic_Operation

## Category Growth

### Framework/Super Season X X Label X Category X Ads format

Category Growth ISBLANK = 
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

## Keyword

###  Keyword X  Ads format Channel
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

### Keyword
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

## Crowd

### Crowd TA X Channel
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

### Crowd TA
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
