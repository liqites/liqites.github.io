---
layout: post
title: Elasticsearch - The Definitive Guide - Chapter 5
author: Tesla Lee
date: 2018-05-09 16:15:11 +0800
categories: [elasticsearch]
---

搜索 —— 最基本的工具

<!--more-->

基本概念：

* `映射（Mapping）`描述数据在每个字段内如何存储
* `分析（Analysis）`全文是如何处理是指可以被搜索的
* `领域特定查询语言（Query DSL）`Elasticsaerch 中强大灵活的查询语言

## 空搜索

```shell
curl -X GET "localhost:9200/_search"
```

一个简化的返回：
```json
{
   "hits" : {
      "total" :       14,
      "hits" : [
        {
          "_index":   "us",
          "_type":    "tweet",
          "_id":      "7",
          "_score":   1,
          "_source": {
             "date":    "2014-09-17",
             "name":    "John Smith",
             "tweet":   "The Query DSL is really powerful and flexible",
             "user_id": 2
          }
       },
        ... 9 RESULTS REMOVED ...
      ],
      "max_score" :   1
   },
   "took" :           4,
   "_shards" : {
      "failed" :      0,
      "successful" :  10,
      "total" :       10
   },
   "timed_out" :      false
}
```

### hits

* `total`：匹配到的总文档数
* `hits` 数组：前 10 个文档
* `_score`：衡量每个文档的匹配度。
* `max_score`: 所有匹配文档中的 `_score` 的最大值。

### took
整个搜索耗时多少**毫秒**

### shards
查询中参与分片的总数，以及这些分片成功了多少个失败了多少个。

### timeout
`timed_ount` 查询是否超时。
> `timeout` 不是停止执行查询，它仅仅是告知正在协调的节点返回到目前为止收集的结果并且关闭连接。在后台，其他的分片可能仍在执行查询即使是结果已经被发送了。

## 多索引，多类型
我们可以通过在URL中指定特殊的索引和类型

* `/_search`在所有的索引中搜索所有的类型
* `/gb/_search`在 gb 索引中搜索所有的类型
* `/gb,us/_search`在 gb 和 us 索引中搜索所有的文档
* `/g*,u*/_search`在任何以 g 或者 u 开头的索引中搜索所有的类型
* `/gb/user/_search`在 gb 索引中搜索 user 类型
* `/gb,us/user,tweet/_search`在 gb 和 us 索引中搜索 user 和 tweet 类型
* `/_all/user,tweet/_search`在所有的索引中搜索 user 和 tweet 类型

## 分页
`from` 和 `size` 参数

* `size`显示应该返回的结果数量，默认是 10
* `from`显示应该跳过的初始结果数量，默认是 0

## 轻量搜索

* **轻量搜索**，在查询字符串中传递参数
* **完整搜索**，使用 JSON 或更丰富的请求体

### _all 字段
```
GET /_search?q=mary
```

上面的查询是如何执行的？
我们会发现， Elasticsearch 返回的结果中，所有字段中包含 mary 的文档都返回了。这是因为，Elasticsearch 在索引文档时，会将所有的字段拼成一个字段 `_all`，进行索引。就好像多了一个字段 `_all`
