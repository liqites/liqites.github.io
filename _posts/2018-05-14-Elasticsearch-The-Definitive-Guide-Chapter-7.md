---
layout: post
title: Elasticsearch The Defenitive Guide - Chapter 7
author: Tesla Lee
date: 2018-05-14 13:07:44 +0800
categories: [elasticsearch]
---

请求提查询（Full Body Search)

> 简易查询可以提供方便的临时查询功能。但是使用搜索体查询，可以充分利用查询的强大功能。

<!--more-->

## 空查询

空查询将返回索引库中所有的文档。

```shell
GET /_search
{}
```

参数
```shell
GET /_search
{
  "from": 30,
  "size": 10
}
```
> #### 带 body 的 GET 请求？
>
> 某些特定语言（特别是 JavaScript）的 HTTP 库是不允许 GET 请求带有请求体的。 事实上，一些使用者对于 GET 请求可以带请求体感到非常的吃惊。
>
> 而事实是这个RFC文档 RFC 7231— 一个专门负责处理 HTTP 语义和内容的文档 — 并没有规定一个带有请求体的 GET 请求应该如何处理！结果是，一些 HTTP 服务器允许这样子，而有一些 — 特别是一些用于缓存和代理的服务器 — 则不允许。
>
> 对于一个查询请求，Elasticsearch 的工程师偏向于使用 GET 方式，因为他们觉得它比 POST 能更好的描述信息检索（retrieving information）的行为。然而，因为带请求体的 GET 请求并不被广泛支持，所以 search API 同时支持 POST 请求：
>
> ```shell
> POST /_search
> {
>   "from": 30,
>   "size": 10
> }
> ```
> 类似的规则可以应用于任何需要带请求体的 GET API。

## 查询表达式

查询表达式(Query DSL)是一种非常灵活又富有表现力的 查询语言。
要使用这种查询表达式，只需将查询语句传递给 query 参数：

```shell
GET /_search
{
    "query": YOUR_QUERY_HERE
}
```

空搜索等价于
```shell
GET /_search
{
    "query": {
        "match_all": {}
    }
}
```

### 查询语句结构
一个查询语句的典型结构：
```json
{
    QUERY_NAME: {
        ARGUMENT: VALUE,
        ARGUMENT: VALUE,
        ...
    }
}
```

如果是针对某个字段
```json
{
    QUERY_NAME: {
        FIELD_NAME: {
            ARGUMENT: VALUE,
            ARGUMENT: VALUE,
            ...
        }
    }
}
```

### 合并查询语句
* 叶子语句：用于将查询字符串和一个字段对比
* 复合语句：合并其他查询语句，同时可以包含不评分的过滤器。

```json
{
    "bool": {
        "must":     { "match": { "tweet": "elasticsearch" }},
        "must_not": { "match": { "name":  "mary" }},
        "should":   { "match": { "tweet": "full text" }},
        "filter":   { "range": { "age" : { "gt" : 30 }} }
    }
}
```

符合语句可以包含其他任何语句，包括复合语句。

## 查询与过滤
Elasticsearch 有一套查询组件，这些组件可以任意组合。同时在 `Filter Context(过滤情况)` 和 `Query Context(查询情况)` 情况下使用。

当使用于 `过滤情况` 时，查询被设置成一个“不评分”或者“过滤”查询。即，这个查询只是简单的问一个问题：“这篇文档是否匹配？”。

当使用于 `查询情况` 时，查询就变成了一个“评分”的查询。

一个评分查询计算每一个文档与此查询的 ***相关程度*** 同时将这个相关程度分配给表示相关性的字段 `_score`，并且按照相关性对匹配到的文档进行排序。

### 性能差异
过滤查询（Filtering queries）只是简单的检查包含或者排除，这就使得计算起来非常快。

评分查询（scoring queries）不仅仅要找出 匹配的文档，还要计算每个匹配文档的相关性，计算相关性使得它们比不评分查询费力的多。同时，查询结果并不缓存。

过滤（filtering）的目标是减少那些需要通过评分查询（scoring queries）进行检查的文档。

### 如何选择查询与过滤
通常的规则是，使用 查询（query）语句来进行 全文 搜索或者其它任何需要影响 相关性得分 的搜索。除此以外的情况都使用过滤（filters)。

## 最重要的几个查询

### `match_all` 查询
match_all 查询简单的 匹配所有文档。在没有指定查询方式时，它是默认的查询：

```json
{ "match_all": {}}
```
### `match` 查询

如果你在一个全文字段上使用 match 查询，在执行查询前，它将用正确的分析器去分析查询字符串：
```json
{ "match": { "tweet": "About Search" }}
```
如果在一个精确值的字段上使用它， 例如数字、日期、布尔或者一个 not_analyzed 字符串字段，那么它将会精确匹配给定的值：
```json
{ "match": { "age":    26           }}
{ "match": { "date":   "2014-09-01" }}
{ "match": { "public": true         }}
{ "match": { "tag":    "full_text"  }}
```
> 对于精确值的查询，你可能需要使用 filter 语句来取代 query，因为 filter 将会被缓存。

### `multi_match` 查询
`multi_match` 查询可以在多个字段上执行相同的 `match` 查询：
```
{
    "multi_match": {
        "query":    "full text search",
        "fields":   [ "title", "body" ]
    }
}
```

### `range` 查询
range 查询找出那些落在指定区间内的数字或者时间。

* `gt` 大于
* `gte` 大于等于
* `lt` 小于
* `lte` 小于等于

### `term` 查询

term 查询被用于精确值 匹配，这些精确值可能是数字、时间、布尔或者那些 not_analyzed 的字符串。

### `terms` 查询

terms 查询和 term 查询一样，但它允许你指定多值进行匹配。

### `exists` 查询和 `missing` 查询

exists 查询和 missing 查询被用于查找那些指定字段中有值 (exists) 或无值 (missing) 的文档。这与SQL中的 IS_NULL (missing) 和 NOT IS_NULL (exists) 在本质上具有共性.

## 组合多查询

`bool` 查询可以将查询组合起来，它接收以下参数：

* `must` 文档 必须 匹配这些条件才能被包含进来。
* `must_not` 文档 必须不 匹配这些条件才能被包含进来。
* `should` 如果满足这些语句中的任意语句，将增加 _score ，否则，无任何影响。它们主要用于修正每个文档的相关性得分。
* `filter` 必须 匹配，但它以不评分、过滤模式来进行。这些语句对评分没有贡献，只是根据过滤标准来排除或包含文档。

> 如果没有 `must` 语句，那么至少需要能够匹配其中的一条 `should` 语句。但，如果存在至少一条 `must` 语句，则对 `should` 语句的匹配没有要求。

### 增加带过滤器 (filtering) 的查询

```json
{
    "bool": {
        "must":     { "match": { "title": "how to make millions" }},
        "must_not": { "match": { "tag":   "spam" }},
        "should": [
            { "match": { "tag": "starred" }}
        ],
        "filter": {
          "range": { "date": { "gte": "2014-01-01" }}
        }
    }
}
```
通过将 `range` 查询移到 `filter` 语句中，我们将它转化成不评分的查询，将不再影响文档的相关性排名。

`bool` 查询本身也可以被用做不评分的查询。

### `constant_score` 查询
它将一个不变的常量评分应用于所有匹配的文档。它被经常用于你只需要执行一个 filter 而没有其它查询。
```json
{
    "constant_score":   {
        "filter": {
            "term": { "category": "ebooks" }
        }
    }
}
```

## 验证查询

使用 `validate-query` API 验证查询是否合法。
```shell
curl -X GET "localhost:9200/gb/tweet/_validate/query"
-H 'Content-Type: application/json' -d'
{
   "query": {
      "tweet" : {
         "match" : "really powerful"
      }
   }
}
'
```

### 理解错误信息
可以将 explain 参数 加到查询字符串中来显示错误信息。

### 理解查询语句
对于合法查询，使用 explain 参数将返回可读的描述。
