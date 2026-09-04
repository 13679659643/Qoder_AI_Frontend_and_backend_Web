## 1、Category Growth Cost VS LP Color
```dax
Category Growth Cost VS LP Color =
VAR _Value = [Category Growth Cost VS LP]
RETURN
SWITCH(
    TRUE(),
    _Value = 0, "#E1C233",  -- 等于0：黄色
    _Value > 0, "#1A9018",  -- 大于0：深绿色
    _Value < 0, "#D64550",  -- 小于0：红色
    BLANK()  -- 其他情况
)
```

## 2、Category Growth Cost% VS LP Color
```dax
Category Growth Cost% VS LP Color = 
VAR _Value = [Category Growth Cost% VS LP]
RETURN
SWITCH(
    TRUE(),
    _Value = 0, "#E1C233",  -- 等于0：黄色
    _Value > 0, "#1A9018",  -- 大于0：深绿色
    _Value < 0, "#D64550",  -- 小于0：红色
    BLANK()  -- 其他情况
)
```

## 3、Category Growth ROI VS LP Color
```dax
Category Growth ROI VS LP Color =
VAR _Value = [Category Growth ROI VS LP]
RETURN
SWITCH(
    TRUE(),
    _Value = 0, "#E1C233",  -- 等于0：黄色
    _Value > 0, "#1A9018",  -- 大于0：深绿色
    _Value < 0, "#D64550",  -- 小于0：红色
    BLANK()  -- 其他情况
)
```

## 4、Category Growth Diff Cost VS LP Color
```dax
Category Growth Diff Cost VS LP Color =
VAR _Value = [Category Growth Diff Cost VS LP]
RETURN
SWITCH(
    TRUE(),
    _Value = 0, "#E1C233",  -- 等于0：黄色
    _Value > 0, "#1A9018",  -- 大于0：深绿色
    _Value < 0, "#D64550",  -- 小于0：红色
    BLANK()  -- 其他情况
)
```

## 5、Category Growth Diff Cost% VS LP Color
```dax
Category Growth Diff Cost% VS LP Color =
VAR _Value = [Category Growth Diff Cost% VS LP]
RETURN
SWITCH(
    TRUE(),
    _Value = 0, "#E1C233",  -- 等于0：黄色
    _Value > 0, "#1A9018",  -- 大于0：深绿色
    _Value < 0, "#D64550",  -- 小于0：红色
    BLANK()  -- 其他情况
)
```

## 6、Category Growth Diff ROI VS LP Color
```dax
Category Growth Diff ROI VS LP Color =
VAR _Value = [Category Growth Diff ROI VS LP]
RETURN
SWITCH(
    TRUE(),
    _Value = 0, "#E1C233",  -- 等于0：黄色
    _Value > 0, "#1A9018",  -- 大于0：深绿色
    _Value < 0, "#D64550",  -- 小于0：红色
    BLANK()  -- 其他情况
)
```