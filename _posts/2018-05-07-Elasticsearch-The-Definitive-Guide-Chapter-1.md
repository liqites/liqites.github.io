---
layout: post
title: Elasticsearch - The Definitive Guide - Chapter 1
author: Tesla Lee
date: 2018-05-07 16:50:10 +0800
categories:
---
你知道的，为了搜索...
<!--more-->

> Elasticsearch 不仅仅是 Lucene，并且也不仅仅只是一个全文搜索引擎。 它可以被下面这样准确的形容：
>
> 一个分布式的实时文档存储，每个字段 可以被索引与搜索
> 一个分布式实时分析搜索引擎
> 能胜任上百个服务节点的扩展，并支持 PB 级别的结构化或者非结构化数据

## 与 Elasticsearch 交互

### JAVA 客户端

* 节点客户端（Node client）
  - 节点客户端作为一个非数据节点加入到本地集群中。换句话说，它本身不保存任何数据，但是它知道数据在集群中的哪个节点中，并且可以把请求转发到正确的节点。

* 传输客户端（Transport client）
  - 轻量级的传输客户端可以将请求发送到远程集群。它本身不加入集群，但是它可以将请求转发到集群中的一个节点上。

两个 Java 客户端都是通过 9300 端口并使用 Elasticsearch 的原生 传输 协议和集群交互。集群中的节点通过端口 9300 彼此通信。

### REST API

**所有其他语言可以使用 RESTful API 通过端口 9200 和 Elasticsearch 进行通信。**

```bash
curl -X<VERB> '<PROTOCOL>://<HOST>:<PORT>/<PATH>?<QUERY_STRING>' -d '<BODY>'
```

* `VERB`: 适当的 HTTP 方法 或 谓词 : `GET`、 `POST`、 `PUT`、 `HEAD` 或者 `DELETE`
* `PROTOCOL`: http 或者 https`（如果你在 Elasticsearch 前面有一个 `https 代理）
* `HOST`: Elasticsearch 集群中任意节点的主机名，或者用 `localhost` 代表本地机器上的节点
* `PORT`: 运行 Elasticsearch HTTP 服务的端口号，默认是 9200
* `PATH`: API 的终端路径（例如 _count 将返回集群中文档数量）。Path 可能包含多个组件，例如：`_cluster/stats` 和 `_nodes/stats/jvm`
* `QUERY_STRING`:
* `BODY`:

## 面向文档
Elasticsearch 使用 JavaScript Object Notation 或者 JSON 作为文档的序列化格式。

## DEMO 数据

* 支持包含多值标签、数值、以及全文本的数据
* 检索任一雇员的完整信息
* 允许结构化搜索，比如查询 30 岁以上的员工
* 允许简单的全文搜索以及较复杂的短语搜索
* 支持在匹配文档内容中高亮显示搜索片段
* 支持基于数据创建和管理分析仪表盘

## 索引（存储）雇员文档
这将会以 雇员文档 的形式存储：一个文档代表一个雇员。

> 你也许已经注意到 索引 这个词在 Elasticsearch 语境中包含多重意思， 所以有必要做一点儿说明：
> 索引（名词）：
>
> 如前所述，一个 索引 类似于传统关系数据库中的一个 数据库 ，是一个存储关系型文档的地方。 索引 (index) 的复数词为 indices 或 indexes 。
>
> 索引（动词）：
>
> 索引一个文档 就是存储一个文档到一个 索引 （名词）中以便它可以被检索和查询到。这非常类似于 SQL 语句中的 INSERT 关键词，除了文档已存在时新文档会替换旧文档情况之外。
>
> 倒排索引：
> 关系型数据库通过增加一个 索引 比如一个 B树（B-tree）索引 到指定的列上，以便提升数据检索速度。Elasticsearch 和 Lucene 使用了一个叫做 倒排索引 的结构来达到相同的目的。
>
> 默认的，一个文档中的每一个属性都是 被索引 的（有一个倒排索引）和可搜索的。一个没有倒排索引的属性是不能被搜索到的。我们将在 倒排索引 讨论倒排索引的更多细节。

```shell
curl -X PUT "localhost:9200/megacorp/employee/1"
-H 'Content-Type: application/json' -d'
{
    "first_name" : "John",
    "last_name" :  "Smith",
    "age" :        25,
    "about" :      "I love to go rock climbing",
    "interests": [ "sports", "music" ]
}
'
```

## 轻量搜索
```shell
curl -X GET "localhost:9200/megacorp/employee/_search"
```

```shell
curl -X GET "localhost:9200/megacorp/employee/_search?q=last_name:Smith"
```

## 查询表达式 Query DSL

```shell
curl -X GET "localhost:9200/megacorp/employee/_search"
-H 'Content-Type: application/json' -d'
{
    "query" : {
        "match" : {
            "last_name" : "Smith"
        }
    }
}
'
```

## 更复杂的搜索
同样搜索姓氏为 Smith 的雇员，但这次我们只需要年龄大于 30 的。
```shell
curl -X GET "localhost:9200/megacorp/employee/_search"
-H 'Content-Type: application/json' -d'
{
    "query" : {
        "bool": {
            "must": {
                "match" : {
                    "last_name" : "smith"
                }
            },
            "filter": {
                "range" : {
                    "age" : { "gt" : 30 }
                }
            }
        }
    }
}
'
```


## 全文搜索
Elasticsearch 默认按照相关性得分排序，即每个文档跟查询的匹配程度。
```shell
curl -X GET "localhost:9200/megacorp/employee/_search"
-H 'Content-Type: application/json' -d'
{
    "query" : {
        "match" : {
            "about" : "rock climbing"
        }
    }
}
'
```

## 短语搜索
找出一个属性中的独立单词是没有问题的，但有时候想要精确匹配一系列单词或者短语 。
```shell
curl -X GET "localhost:9200/megacorp/employee/_search"
-H 'Content-Type: application/json' -d'
{
    "query" : {
        "match_phrase" : {
            "about" : "rock climbing"
        }
    }
}
'
```

## 高亮搜索
许多应用都倾向于在每个搜索结果中 高亮 部分文本片段，以便让用户知道为何该文档符合查询条件。在 Elasticsearch 中检索出高亮片段也很容易。

```shell
curl -X GET "localhost:9200/megacorp/employee/_search"
-H 'Content-Type: application/json' -d'
{
    "query" : {
        "match_phrase" : {
            "about" : "rock climbing"
        }
    },
    "highlight": {
        "fields" : {
            "about" : {}
        }
    }
}
'
```

## 分析
Elasticsearch 有一个功能叫聚合（aggregations），允许我们基于数据生成一些精细的分析结果。聚合与 SQL 中的 GROUP BY 类似但更强大。

```shell
curl -X GET "localhost:9200/megacorp/employee/_search"
-H 'Content-Type: application/json' -d'
{
  "aggs": {
    "all_interests": {
      "terms": { "field": "interests" }
    }
  }
}
'
```

## 分布式特性
Elasticsearch 尽可能地屏蔽了分布式系统的复杂性。这里列举了一些在后台自动执行的操作：

* 分配文档到不同的容器 或 分片 中，文档可以储存在一个或多个节点中
* 按集群节点来均衡分配这些分片，从而对索引和搜索过程进行负载均衡
* 复制每个分片以支持数据冗余，从而防止硬件故障导致的数据丢失
* 将集群中任一节点的请求路由到存有相关数据的节点
* 集群扩容时无缝整合新节点，重新分配分片以便从离群节点恢复
