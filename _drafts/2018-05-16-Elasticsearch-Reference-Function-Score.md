---
layout: post
title: Elasticsearch Reference - Function Score
author: Tesla Lee
date: 2018-05-16 13:07:45 +0800
categories: [elasticsearch-reference]
---

Function Score Query

<!--more-->

The `function_score` allows you to modify the score of documents taht are retrieved by a query.

To use `function_score`, the user has to define a query and one or more functions, that cpmpute a new score for each document returned by the query.

`function_score`:

```json
"function_score": {
    "query": {},
    "boost": "boost for the whole query",
    "FUNCTION": {},
    "boost_mode":"(multiply|replace|...)"
}
```
furthermore, serveral functions can be combined.

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
```

If no query is given with a function this is equivalent to specifiying `"match_all": {}`
