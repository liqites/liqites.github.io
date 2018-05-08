---
layout: post
title: Elasticsearch - The Definitive Guide - Chapter 3
author: Tesla Lee
date: 2018-05-08 15:09:15 +0800
categories: [elasticsearch]
---

数据输入和输出

<!--more-->

一个 对象 是基于特定语言的内存的数据结构。 为了通过网络发送或者存储它，我们需要将它表示成某种标准的格式。 JSON 是一种以人可读的文本表示对象的方法。 它已经变成 NoSQL 世界交换数据的事实标准。当一个对象被序列化成为 JSON，它被称为一个 JSON 文档 。


Elastcisearch 是分布式的 文档 存储。它能存储和检索复杂的数据结构--序列化成为JSON文档--以 实时 的方式。 换句话说，一旦一个文档被存储在 Elasticsearch 中，它就是可以被集群中的任意节点检索到。

在 Elasticsearch 中， 每个字段的所有数据 都是 默认被索引的 。 即每个字段都有为了快速检索设置的专用倒排索引。

## 什么是文档？

我们使用的术语 对象 和 文档 是可以互相替换的。不过，有一个区别： 一个对象仅仅是类似于 hash 、 hashmap 、字典或者关联数组的 JSON 对象，对象中也可以嵌套其他的对象。 对象可能包含了另外一些对象。在 Elasticsearch 中，术语 文档 有着特定的含义。它是指**最顶层**或者**根对象**, 这个根对象被**序列化成 JSON**并存储到 Elasticsearch 中，指定了唯一 ID。

## 文档元数据
* `_index`: 文档存放在那里
* `_type`: 文档表示的对象类型
* `_id`: 文档唯一标识

### _index
`索引`应该是因共同的特性被分组到一起的文档集合。
> 我们的数据是被存储和索引在 分片 中，而一个索引仅仅是逻辑上的命名空间， 这个命名空间由一个或者多个分片组合在一起。

### _type
数据可能在索引中只是松散的组合在一起。Elasticsearch 公开了一个称为 types （类型）的特性，它允许您在索引中对数据进行逻辑分区。

### _id
ID 是一个字符串， 当它和 _index 以及 _type 组合就可以唯一确定 Elasticsearch 中的一个文档。

### 索引文档
通过使用 `index` API ，文档可以被 索引 —— 存储和使文档可被搜索 。
```shell
PUT /{index}/{type}/{id}
{
  "field": "value",
  ...
}
```
### 使用自己的 ID

```shell
curl -X PUT "localhost:9200/website/blog/123"
-H 'Content-Type: application/json' -d'
{
  "title": "My first blog entry",
  "text":  "Just trying this out...",
  "date":  "2014/01/01"
}
'
```
### 自增 ID

```shell
curl -X POST "localhost:9200/website/blog/"
-H 'Content-Type: application/json' -d'
{
  "title": "My second blog entry",
  "text":  "Still trying this out...",
  "date":  "2014/01/01"
}
'
```

## 取回文档
```shell
curl -X GET "localhost:9200/website/blog/123?pretty"
```

返回
```json
{
  "_index" :   "website",
  "_type" :    "blog",
  "_id" :      "123",
  "_version" : 1,
  "found" :    true,
  "_source" :  {
      "title": "My first blog entry",
      "text":  "Just trying this out...",
      "date":  "2014/01/01"
  }
}
```

### 返回文档的一部分
```shell
curl -X GET "localhost:9200/website/blog/123?_source=title,text"
```

## 检查文档是否存在
如果只想检查一个文档是否存在 --根本不想关心内容--那么用 HEAD 方法来代替 GET 方法。 HEAD 请求没有返回体，只返回一个 HTTP 请求报头：

* `200` 存在
* `404` 不存在

## 更新整个文档
在 Elasticsearch 中文档是 不可改变 的，不能修改它们。如果想要更新现有的文档，需要 重建索引 或者进行替换。

使用下面的命令
```shell
curl -X PUT "localhost:9200/website/blog/123"
-H 'Content-Type: application/json' -d'
{
  "title": "My first blog entry",
  "text":  "I am starting to get the hang of this...",
  "date":  "2014/01/02"
}
'
```
我们看到文档的 `_version` 已经变成 2 ，说明文档更新成功了。但实际上是，将就得**文档**标记为删除，同时新建了一个**文档**。
更新一个文档时，Elasticsearch 内部的执行过程大概是

1. 从旧文档构建 JSON
2. 更改该 JSON
3. 删除旧文档
4. 索引一个新文档

## 创建新文档
当我们索引一个文档， 怎么确认我们正在创建一个完全新的文档，而不是覆盖现有的呢？

**请记住， `_index` 、 `_type` 和 `_id` 的组合可以唯一标识一个文档。**

```shell
POST /website/blog/
{ ... }
```
自增 ID

第一种方法使用 op_type 查询 -字符串参数：
```shell
PUT /website/blog/123?op_type=create
{ ... }
```

第二种方法是在 URL 末端使用 /_create :
```shell
PUT /website/blog/123/_create
{ ... }
```
如果创建新文档的请求成功执行，Elasticsearch 会返回元数据和一个 201 Created 的 HTTP 响应码。

另一方面，如果具有相同的 _index 、 _type 和 _id 的文档已经存在，Elasticsearch 将会返回 409 Conflict 响应码。

## 删除文档
删除文档 的语法和我们所知道的规则相同，只是 使用 DELETE 方法：

```shell
curl -X DELETE "localhost:9200/website/blog/123"
```
如果找到该文档，Elasticsearch 将要返回一个 200 ok 的 HTTP 响应码，如果文档没有 找到，我们将得到 404 Not Found 的响应码和类似这样的响应体。

即使文档不存在（ Found 是 false ）， `_version` 值仍然会增加。

## 处理冲突
当我们使用 index API 更新文档 ，可以一次性读取原始文档，做我们的修改，然后重新索引 整个文档 。 最近的索引请求将获胜：无论最后哪一个文档被索引，都将被唯一存储在 Elasticsearch 中。如果其他人同时更改这个文档，他们的更改将丢失。

### 悲观并发控制
这种方法被关系型数据库广泛使用，它假定有变更冲突可能发生，因此阻塞访问资源以防止冲突。 一个典型的例子是读取一行数据之前先将其锁住，确保只有放置锁的线程能够对这行数据进行修改。

### 乐观并发控制
Elasticsearch 中使用的这种方法假定冲突是不可能发生的，并且不会阻塞正在尝试的操作。 然而，如果源数据在读写当中被修改，更新将会失败。应用程序接下来将决定该如何解决冲突。 例如，可以重试更新、使用新的数据、或者将相关情况报告给用户。

## 乐观并发控制
Elasticsearch 是分布式的。当文档创建、更新或删除时， 新版本的文档必须复制到集群中的其他节点。Elasticsearch 也是异步和并发的，这意味着这些复制请求被并行发送，并且到达目的地时也许 顺序是乱的 。 Elasticsearch 需要一种方法确保文档的旧版本不会覆盖新的版本。

Elasticsearch 使用这个 _version 号来确保变更以正确顺序得到执行。如果旧版本的文档在新版本之后到达，它可以被简单的忽略。

所有文档的更新或删除 API，都可以接受 version 参数，这允许你在代码中使用乐观的并发控制，这是一种明智的做法。

### 通过外部系统使用版本控制
一个常见的设置是使用其它数据库作为主要的数据存储，使用 Elasticsearch 做数据检索， 这意味着主数据库的所有更改发生时都需要被复制到 Elasticsearch ，如果多个进程负责这一数据同步，你可能遇到类似于之前描述的并发问题。

如果你的主数据库已经有了版本号 — 或一个能作为版本号的字段值比如 timestamp — 那么你就可以在 Elasticsearch 中通过增加 version_type=external 到查询字符串的方式重用这些相同的版本号， 版本号必须是大于零的整数， 且小于 9.2E+18 — 一个 Java 中 long 类型的正值。

外部版本号的处理方式和我们之前讨论的内部版本号的处理方式有些不同， Elasticsearch 不是检查当前 _version 和请求中指定的版本号是否相同， 而是检查当前 _version 是否 小于 指定的版本号。 如果请求成功，外部的版本号作为文档的新 _version 进行存储。

外部版本号不仅在索引和删除请求是可以指定，而且在 创建 新文档时也可以指定。

## 文档的部分更新
在 更新整个文档 , 我们已经介绍过 更新一个文档的方法是检索并修改它，然后重新索引整个文档，这的确如此。然而，使用 update API 我们还可以部分更新文档，例如在某个请求时对计数器进行累加。

```shell
curl -X POST "localhost:9200/website/blog/1/_update"
-H 'Content-Type: application/json' -d'
{
   "doc" : {
      "tags" : [ "testing" ],
      "views": 0
   }
}
'
```

### 使用脚本部分更新文档那个
脚本可以在 update API中用来改变 _source 的字段内容， 它在更新脚本中称为 ctx._source 。 例如，我们可以使用脚本来增加博客文章中 views 的数量：

```shell
curl -X POST "localhost:9200/website/blog/1/_update"
-H 'Content-Type: application/json' -d'
{
   "script" : "ctx._source.views+=1"
}
'
```

```shell
curl -X POST "localhost:9200/website/blog/1/_update"
-H 'Content-Type: application/json' -d'
{
   "script" : "ctx._source.tags+=new_tag",
   "params" : {
      "new_tag" : "search"
   }
}
'
```

### 更新的文档可能尚不存在
使用 `upsert` 参数

```shell
curl -X POST "localhost:9200/website/pageviews/1/_update"
-H 'Content-Type: application/json' -d'
{
   "script" : "ctx._source.views+=1",
   "upsert": {
       "views": 1
   }
}
'
```

### 更新和冲突
检索 和 重建索引 步骤的间隔越小，变更冲突的机会越小。 但是它并不能完全消除冲突的可能性。 还是有可能在 `update` 设法重新索引之前，来自另一进程的请求修改了文档。

为了避免数据丢失， `update` API 在 检索 步骤时检索得到文档当前的 `_version` 号，并传递版本号到 重建索引 步骤的 `index` 请求。 如果另一个进程修改了处于检索和重新索引步骤之间的文档，那么 `_version` 号将不匹配，更新请求将会失败。

设置参数 `retry_on_conflict` 来在发现冲突时重试更新操作。

## 取回多个文档

* mget API 要求有一个 docs 数组作为参数，每个 元素包含需要检索文档的元数据， 包括 _index 、 _type 和 _id 。
* 如果想检索的数据都在相同的 _index 中（甚至相同的 _type 中），则可以在 URL 中指定默认的 /_index 或者默认的 /_index/_type 。
* 如果所有文档的 _index 和 _type 都是相同的，你可以只传一个 ids 数组，而不是整个 docs 数组。

> 即使有某个文档没有找到，上述请求的 HTTP 状态码仍然是 200 。事实上，即使请求 没有 找到任何文档，它的状态码依然是 200 --因为 mget 请求本身已经成功执行。 为了确定某个文档查找是成功或者失败，你需要检查 found 标记。

## 代价较小的批量操作
与 mget 可以使我们一次取回多个文档同样的方式， bulk API 允许在单个步骤中进行多次 create 、 index 、 update 或 delete 请求。 如果你需要索引一个数据流比如日志事件，它可以排队和索引数百或数千批次。

```json
{ action: { metadata }}\n
{ request body        }\n
{ action: { metadata }}\n
{ request body        }\n
```
* 每行一定要以换行符(\n)结尾， 包括最后一行。
* 这些行不能包含未转义的换行符，因为他们将会对解析造成干扰。

一个完整的 bulk 操作：
```shell
curl -X POST "localhost:9200/_bulk"
-H 'Content-Type: application/json' -d'
{ "delete": { "_index": "website", "_type": "blog", "_id": "123" }}
{ "create": { "_index": "website", "_type": "blog", "_id": "123" }}
{ "title":    "My first blog post" }
{ "index":  { "_index": "website", "_type": "blog" }}
{ "title":    "My second blog post" }
{ "update": { "_index": "website", "_type": "blog", "_id": "123", "_retry_on_conflict" : 3} }
{ "doc" : {"title" : "My updated blog post"} }
'
```

**每个子请求都是独立执行，因此某个子请求的失败不会对其他子请求的成功与否造成影响。**这也意味着 bulk 请求不是原子的： 不能用它来实现事务控制。每个请求是单独处理的，因此一个请求的成功或失败不会影响其他的请求。

### 多大是太大了？
整个批量请求都需要由接收到请求的节点加载到内存中，因此该请求越大，其他请求所能获得的内存就越少。

通过批量索引典型文档，并不断增加批量大小进行尝试。 当性能开始下降，那么你的批量大小就太大了。一个好的办法是开始时将 1,000 到 5,000 个文档作为一个批次, 如果你的文档非常大，那么就减少批量的文档个数。

密切关注你的批量请求的物理大小往往非常有用，一千个 1KB 的文档是完全不同于一千个 1MB 文档所占的物理大小。 一个好的批量大小在开始处理后所占用的物理大小约为 5-15 MB。
