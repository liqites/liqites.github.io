---
layout: post
title: Elasticsearch - The Definitive Guide - Chapter 6
author: Tesla Lee
date: 2018-05-10 17:46:51 +0800
categories: [elasticsearch]
---

映射与分析

<!--more-->
在我们的先有数据中，有一条数据的 date 是 2014-09-23。但是我们发现在使用查询

```
1. GET /_search?q=2014    # 13
2. GET /_search?q=date:2014 # 0
```

时，没有得到我们想要的结果，返回的文档数是 0。为什么？

我们知道，第一条查询，是搜索的 `_all` 字段，第二条查询，搜索的 `date`，而 `_all` 字段的类型是 `string`，但是 `date` 字段是什么类型，却不清楚。

可以使用 `GET /gb/_mapping/tweet` 文档的结构与类型。

可以看到 `date` 字段是 `strict_date_optional_time||epoch_millis` 类型。

由此，就引出了两种不同类型的字段
* 精确值字段：类似 `number`, `date` 等。
* 全文字段：`string` 等

Elasticsearch 处理搜索时，不同的字段能够使用的搜索方式是不同的。

## 精确值 vs 全文
对于精确值来说，其实，这里 `string` 类型也可以被看做是 **精确值**，比如一个用户 ID，对于精确值来说 "Foo" 和 "foo" 是不同的。这一点是很好理解的。

精确值很容易查询，查询的结果只有两种，匹配条件或者不匹配条件。例如下面的 SQL：
```sql
WHERE name    = "John Smith"
  AND user_id = 2
  AND date    > "2014-09-15"
```

但是全文查询时，要考虑的情况就要复杂一点。我们得到的结果也不是，”这个文档是不是匹配查询条件？“，而是，”这个文档在多大程度上匹配了这个查询条件？“。同时，我们还希望搜索引擎能够理解我们的意图。例如：
* 搜索 `UK`，时，同时也能匹配包含 `United Kindom` 的文档
* 搜索 `jump` 时，也能够匹配 `jumped`, `jumps`, `jumping` 设置 `leap`。

等等情况。

为了达到上面的目的，Elasticsearch 首先需要对文档进行分析，然后根据分析结果创建 `倒排索引`。

## 倒排索引
Elasticsearch 使用一种称为 倒排索引 的结构，它适用于快速的全文搜索。一个倒排索引由文档中所有不重复词的列表构成，对于其中每个词，有一个包含它的文档列表。

关于`倒排索引` 的两篇文章
* [ES 的原文](https://www.elastic.co/guide/cn/elasticsearch/guide/cn/inverted-index.html)。
* [我自己整理的一篇文章]({{ site.baseurl }}{% post_url 2018-05-09-Elasticsearch-Inverted-Index %})

简单来说，`倒排索引` 记录了词条在哪些文档中出现以及出现的位置。

## 分析与分析器

分析 包含下面的过程：

* 首先，将一块文本分成适合于倒排索引的独立的 **词条** ，
* 之后，将这些词条统一化为**标准格式**以提高它们的“可搜索性”，或者 recall分析器执行上面的工作。

分词器实际上有下面三个独立的功能：

* 字符过滤器：字符串按顺序通过每个`字符过滤器`。在分词前对字符进行整理。比如去掉 HTML 标签，将 `&` 转化为 `and` 等。
* 分词器：字符串被分词器分为单个的词条。
* Token 过滤器：词条按顺序通过每个 Token 过滤器。每个过程都可能会改变词条，比如小写化，删除一些无用词条，或者增加一些词条。

### 内置分析器

Elasticsearch 有一些预装的分析器。

以下面这段话为例：
```
"Set the shape to semi-transparent by calling set_trans(5)"
```

* **标准分析器(standard)**：标准分析器是Elasticsearch默认使用的分析器。它是分析各种语言文本最常用的选择。

```
set, the, shape, to, semi, transparent, by, calling, set_trans, 5
```

* **简单分析器(simple)**：简单分析器在任何不是字母的地方分隔文本，将词条小写。

```
set, the, shape, to, semi, transparent, by, calling, set, trans
```

* **空格分析器(whitespace)**：空格分析器在空格的地方划分文本。

```
Set, the, shape, to, semi-transparent, by, calling, set_trans(5)
```

* **语言分析器**：

这是支持的所有语言分析器：
> arabic, armenian, basque, bengali, brazilian, bulgarian, catalan, cjk, czech, danish, dutch, english, finnish, french, galician, german, greek, hindi, hungarian, indonesian, irish, italian, latvian, lithuanian, norwegian, persian, portuguese, romanian, russian, sorani, spanish, swedish, turkish, thai.

使用 `english` 语言分析器时：

```
set, shape, semi, transpar, call, set_tran, 5
```

### 什么时候使用分析器？

当我们**索引**一个文档时，它的全文域被分析成词条以用来创建**倒排索引**。同时，当我们在全文域中搜索时，同样也要对查询条件应用相同的*分析过程*，来是搜索条件和索引词条一致。

这也就能够解释，为何之前使用简单搜索 `GET /_search?q=date:2014` 时没有办法搜索到结果，而搜索 `GET /_search?q=2014` 时却可以搜索到内容。

### 测试分析器

```shell
 GET /_analyze
{
  "analyzer": "standard",
  "text": "Text to analyze"
}
```

### 指定分析器
Elasticsearch 会自动给字符串分配一个分析器，同时我们也可以自己手动指定分析器。为了能够做到这点，我们需要手动指定映射。

## 映射
为了能够将时间域视为时间，数字域视为数字，字符串域视为全文或精确值字符串， Elasticsearch 需要知道每个域中数据的类型。这个信息包含在映射中。

索引中每个文档都有 类型 ,每种类型都有它自己的 映射 ，或者 模式定义 。映射定义了类型中的域，每个域的数据类型，以及Elasticsearch如何处理这些域。映射也用于配置与类型有关的元数据。

### 核心简单域类型
Elasticsearch 支持 如下简单域类型：
* 字符串: string
* 整数 : byte, short, integer, long
* 浮点数: float, double
* 布尔型: boolean
* 日期: date

当你索引一个包含新域的文档--之前未曾出现-- Elasticsearch 会使用 动态映射 ，通过JSON中基本数据类型，尝试猜测域类型。

域在 es 中的名词是 `properties`

### 自定义域映射
自定义映射允许的操作：
* 全文字符串域和精确值字符串域的区别
* 使用特定语言分析器
* 优化域以适应部分匹配
* 指定自定义数据格式
* 还有更多...

域最重要的属性是 type 。对于不是 string 的域，你一般只需要设置 type：

```json
{
  "number_of_clicks": {
    "type": "integer"
  }
}
```
默认， `string` 类型域会被认为包含全文。

`string` 域映射的两个最重要 属性是 `index` 和 `analyzer` 。

#### index
`index` 属性控制怎样索引字符串。它可以有这几个值：
* `analyzed`： 分析字符串，然后索引它。
* `not_analyzed`：索引这个域，但是作为精确值被搜索，不进行分析。
* `no`：不索引这个域，无法被搜索到。

`string` 域 `index` 属性默认是 `analyzed` 。

#### analyzer
对于 `analyzed` 域，可用 `analyzer` 属性指定在搜索和索引时使用的分析器。默认使用的是 `standard` 分析器。

#### 更新映射
当首次创建索引时，可以指定类型的映射。也可以使用 `/_mapping` API 为新类型增加唉映射。

> 尽管你可以 增加_ 一个存在的映射，你不能 _修改 存在的域映射。如果一个域的映射已经存在，那么该域的数据可能已经被索引。如果你意图修改这个域的映射，索引的数据可能会出错，不能被正常的搜索。

可以更新一个映射来添加一个新域，但不能将一个存在的域从 analyzed 改为 not_analyzed 。

## 复杂核心域类型
Elasticsearch 还支持 `null`，数组和对象。

### 多值域
有可能我们希望 `tag` 域中包含多个标签。也就是说
```json
{ "tag": [ "search", "nosql" ]}
```
数组中所有的值必须是*相同类型*的。如果你通过索引数组来创建新的域，Elasticsearch 会用数组中第一个值的数据类型作为这个域的 `类型` 。

### 空域
```json
"null_value":               null,
"empty_array":              [],
"array_with_null_value":    [ null ]
```
以上三种情况是空域，不会被索引。

### 多层级对象
也就是 JSON 中的对象类型。例如下面的多级对象
```json
{
    "tweet":            "Elasticsearch is very flexible",
    "user": {
        "id":           "@johnsmith",
        "gender":       "male",
        "age":          26,
        "name": {
            "full":     "John Smith",
            "first":    "John",
            "last":     "Smith"
        }
    }
}
```

### 内部对象的映射
```json
{
  "gb": {
    "tweet": {
      "properties": {
        "tweet":            { "type": "string" },
        "user": {
          "type":             "object",
          "properties": {
            "id":           { "type": "string" },
            "gender":       { "type": "string" },
            "age":          { "type": "long"   },
            "name":   {
              "type":         "object",
              "properties": {
                "full":     { "type": "string" },
                "first":    { "type": "string" },
                "last":     { "type": "string" }
              }
            }
          }
        }
      }
    }
  }
}
```
* `tweet` 是根对象
* `user` `name` 是内部对象

### 内部对象是如何索引的
Lucene 不理解内部对象。所以 Elasticsearch 会先转化文档。例如：
```json
{
    "tweet":            [elasticsearch, flexible, very],
    "user.id":          [@johnsmith],
    "user.gender":      [male],
    "user.age":         [26],
    "user.name.full":   [john, smith],
    "user.name.first":  [john],
    "user.name.last":   [smith]
}
```

内部域 可以通过名称引用（例如， first ）。为了区分同名的两个域，我们可以使用全 路径 （例如， user.name.first ） 或 type 名加路径（ tweet.user.name.first ）。

### 内部对象数组
假设有这样一个对象。
```json
{
    "followers": [
        { "age": 35, "name": "Mary White"},
        { "age": 26, "name": "Alex Jones"},
        { "age": 19, "name": "Lisa Smith"}
    ]
}
```
这个文档会被处理成：
```json 
{
    "followers.age":    [19, 26, 35],
    "followers.name":   [alex, jones, lisa, smith, mary, white]
}
```
> `{age: 35}` 和 `{name: Mary White}` 之间的相关性已经丢失了，因为每个多值域只是一包无序的值，而不是有序数组。**这足以让我们问，“有一个26岁的追随者？”**
> **但是我们不能得到一个准确的答案**：“是否有一个26岁 名字叫 Alex Jones 的追随者？”
> 相关内部对象被称为 nested 对象，可以回答上面的查询，我们稍后会在嵌套对象中介绍它。
