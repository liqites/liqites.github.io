---
layout: post
title: Elasticsearch - The Definitive Guide - Chapter 6
author: Tesla Lee
date: 2018-05-09 17:46:51 +0800
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

当我们**索引**一个文档时，它的全文字段被分析成词条以用来创建**倒排索引**。同时，当我们在全文字段中搜索时，同样也要对查询条件应用相同的*分析过程*，来是搜索条件和索引词条一致。

这也就能够解释，为何之前使用简单搜索 `GET /_search?q=date:2014` 时没有办法搜索到结果，而搜索 `GET /_search?q=2014` 时却可以搜索到内容。

### 测试分析器
```shell GET /_analyze
{
  "analyzer": "standard",
  "text": "Text to analyze"
}
```

### 指定分析器
Elasticsearch 会自动给字符串分配一个分析器，同时我们也可以自己手动指定分析器。为了能够做到这点，我们需要手动指定映射。