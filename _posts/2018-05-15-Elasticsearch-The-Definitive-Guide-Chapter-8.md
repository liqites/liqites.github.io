---
layout: post
title: Elasticsearch The Definitive Guide - Chapter 8
author: Tesla Lee
date: 2018-05-15 16:38:54 +0800
categories: [elasticsearch]
---

排序与相关性

<!--more-->

## 排序

为了按照相关性来排序，需要将相关性表示为一个数值。*相关性得分* 由一个浮点数表示，并在结果中以 `_score` 参数返回。默认是 `_score` 降序。

### 按照字段的值排序

```json
GET /_search
{
    "query" : {
        "bool" : {
            "filter" : { "term" : { "user_id" : 1 }}
        }
    },
    "sort": { "date": { "order": "desc" }}
}
```

> 一个简便方法是, 你可以 指定一个字段用来排序：
>
> ```json
>    "sort": "number_of_children"
> ```
> 字段将会默认升序排序 ，而按照 _score 的值进行降序排序。

### 多级排序
```json
GET /_search
{
    "query" : {
        "bool" : {
            "must":   { "match": { "tweet": "manage text search" }},
            "filter" : { "term" : { "user_id" : 2 }}
        }
    },
    "sort": [
        { "date":   { "order": "desc" }},
        { "_score": { "order": "desc" }}
    ]
}
```
结果首先按第一个条件排序，仅当结果集的第一个 sort 值完全相同时才会按照第二个条件进行排序，以此类推。

### 多值字段排序

对于数字或日期，你可以将多值字段减为单值，这可以通过使用 min 、 max 、 avg 或是 sum 排序模式 。
```json
"sort": {
    "dates": {
        "order": "asc",
        "mode":  "min"
    }
}
```

## 字符串排序与多字段
> 被解析的字符串字段也是多值字段。
>
> 但是很少会按照你想要的方式进行排序。如果你想分析一个字符串，如 fine old art ， 这包含 3 项。我们很可能想要按第一项的字母排序，然后按第二项的字母排序，诸如此类，但是 Elasticsearch 在排序过程中没有这样的信息。

为了以字符串字段进行排序，这个字段应仅包含一项： 整个 not_analyzed 字符串。

一个简单的方法是用两种方式对同一个字符串进行索引，这将在文档中包括两个字段： analyzed 用于搜索， not_analyzed 用于排序。

所有的 _core_field 类型 (strings, numbers, Booleans, dates) 接收一个 fields 参数。该参数允许你转化一个简单的映射如：
```json
"tweet": {
    "type":     "string",
    "analyzer": "english"
}
```

```json
"tweet": {
    "type":     "string",
    "analyzer": "english",
    "fields": {
        "raw": {
            "type":  "string",
            "index": "not_analyzed"
        }
    }
}
```

这样可以来使用 `tweet` 来搜索，`tweet.raw` 来排序
```shell
GET /_search
{
    "query": {
        "match": {
            "tweet": "elasticsearch"
        }
    },
    "sort": "tweet.raw"
}
```

## 什么是相关性？

查询语句会为每个文档生成一个 _score 字段。评分的计算方式取决于查询类型 不同的查询语句用于不同的目的： fuzzy 查询会计算与关键词的拼写相似程度，terms 查询会计算 找到的内容与关键词组成部分匹配的百分比，但是通常我们说的 relevance 是我们用来计算全文本字段的值相对于全文本检索词相似程度的算法。

Elasticsearch 的相似度算法 被定义为检索词频率/反向文档频率， TF/IDF ，包括以下内容：

* 检索词频率：检索词在该字段出现的频率？出现频率越高，相关性也越高。 字段中出现过 5 次要比只出现过 1 次的相关性高。
* 反向文档频率：每个检索词在索引中出现的频率？频率越高，相关性越低。检索词出现在多数文档中会比出现在少数文档中的权重更低。
* 字段长度准则：字段的长度是多少？长度越长，相关性越低。 检索词出现在一个短的 title 要比同样的词出现在一个长的 content 字段权重更大。

如果多条查询子句被合并为一条复合查询语句 ，比如 bool 查询，则每个查询子句计算得出的评分会被合并到总的相关性评分中。

### 理解评分标准

Elasticsearch 在 每个查询语句中都有一个 explain 参数，将 explain 设为 true 就可以得到更详细的信息。
```shell
GET /_search?explain
{
   "query"   : { "match" : { "tweet" : "honeymoon" }}
}
```

## Doc Values 介绍

当你对一个字段进行排序时，Elasticsearch 需要访问每个匹配到的文档得到相关的值。倒排索引的检索性能是非常快的，但是在字段值排序时却不是理想的结构。

在搜索的时候，我们能通过搜索关键词快速得到结果集。
当排序的时候，我们需要倒排索引里面某个字段值的集合。换句话说，我们需要 转置 倒排索引。
转置 结构在其他系统中经常被称作 列存储 。实质上，它将所有单字段的值存储在单数据列中，这使得对其进行操作是十分高效的，例如排序。

在 Elasticsearch 中，`Doc Values` 就是一种列式存储结构，默认情况下每个字段的 `Doc Values` 都是激活的，`Doc Values` 是在索引时创建的，当字段索引时，Elasticsearch 为了能够快速检索，会把字段的值加入倒排索引中，同时它也会存储该字段的 `Doc Values`。

Elasticsearch 中的 Doc Values 常被应用到以下场景：

* 对一个字段进行排序
* 对一个字段进行聚合
* 某些过滤，比如地理位置过滤
* 某些与字段相关的脚本计算

因为文档值被序列化到磁盘，我们可以依靠操作系统的帮助来快速访问。当 working set 远小于节点的可用内存，系统会自动将所有的文档值保存在内存中，使得其读写十分高速； 当其远大于可用内存，操作系统会自动把 Doc Values 加载到系统的页缓存中，从而避免了 jvm 堆内存溢出异常。
