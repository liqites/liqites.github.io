---
layout: post
title: Elasticsearch Reference Function Score Query
author: Tesla Lee
date: 2018-05-14 18:37:35 +0800
categories: [elasticsearch2]
---

`function_score` 允许你修改文档 `score` 的计算方式。

<!--more-->

为了使用 `function_score` ，用户需要定义一个 `query` 以及一个或多个 `function`.

使用单个 `function`

```json
"function_score": {
    "query": {},
    "boost": "boost for the whole query",
    "FUNCTION": {},
    "boost_mode":"(multiply|replace|...)"
}
```

使用多个 `function`
```json
"function_score": {
    "query": {},
    "boost": "boost for the whole query",
    "functions": [
        {
            "filter": {},
            "FUNCTION": {},
            "weight": number
        },
        {
            "FUNCTION": {}
        },
        {
            "filter": {},
            "weight": number
        }
    ],
    "max_boost": number,
    "score_mode": "(multiply|max|...)",
    "boost_mode": "(multiply|replace|...)",
    "min_score" : number
}
```

如果没有给出 `query` ，等同于使用 `match_all query`
