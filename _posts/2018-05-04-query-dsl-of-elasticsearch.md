---
layout: post
title: Query DSL of Elasticsearch
author: Tesla Lee
date: 2018-05-04 00:00:00 +0800
categories: [elasticsearch]
---

Elasticsearch 查询 DSL 基础知识

<!--more-->

## Query DSL

* Leaf query clauses（子查询）：在一个特定的 `Field` 查询特定的 `Value`，例如 `match`, `term` 或 `range` 查询。
* Compound query clauses（组合查询）：将子查询或组合查询再组合起来，例如，使用逻辑（`bool` 或 `dis_max`)，或者改变查询的行为（`not` 或 `constant_score`）

> Query clauses behave differently depending on whether they are used in query context or filter context.

## Query and filter context

The behaviour of a query clause depends on whether it is used in query context or in filter context:

### Query context
A query clause used in query context answers the question “**How well does this document match this query clause?**”.The query clause also calculates a _score representing how well the document matches, relative to other documents.

### Filter Context
In filter context, a query clause answers the question “**Does this document match this query clause?**”

Frequently used filters will be cached automatically by Elasticsearch, to speed up performance.

Filter context is in effect whenever a query clause is passed to a filter parameter, such as the `filter` or `must_not` parameters in the `bool` query, the filter parameter in the `constant_score` query, or the `filter` aggregation.


```json
GET _search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "title":   "Search"        }},
        { "match": { "content": "Elasticsearch" }}
      ],
      "filter": [
        { "term":  { "status": "published" }},
        { "range": { "publish_date": { "gte": "2015-01-01" }}}
      ]
    }
  }
}
```

* `query` 指 `query context`
* `bool` 和两个 `match` 是在 `query context` 使用，来评价每个 `document` 的评分
* `filter` 表示 `filter context`
* `term` 和 `range` 语句是在 `filter context` 中使用，他们用来筛选 `document`

> 问题：`Filter context` 是在计算 score 前执行还是在计算 score 后执行？

## Match all query

```json
{"match_all": {}}
```

匹配所有的 `document`，并且给它们一个默认分数 `1.0`

## Full text queries
The high-level full text queries are usually used for running full text queries on full text fields like the body of an email.They understand how the field being queried is analyzed and will apply each field’s analyzer (or search_analyzer) to the query string before executing.

* `match` query: 单个基础全文搜索，包括模糊、短语或近似查询
* `multi_match` query: 多个字段的 `match` 查询
* `common_terms` query: 更特殊的查询，用于处理一些不常用的词
* `query_string` query: Supports the compact Lucene query string syntax, allowing you to specify AND|OR|NOT conditions and multi-field search within a single query string. For expert users only.
* `simple_query_string`: A simpler, more robust version of the query_string syntax suitable for exposing directly to users.

### Match Query

#### boolean

默认的 `match` 查询是 `boolean`
