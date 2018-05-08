---
layout: post
title: Elasticsearch - The Definitive Guide - Chapter 3
author: Tesla Lee
date: 2018-05-08 15:09:15 +0800
categories:
---

数据输入和输出

<!--more-->

一个 对象 是基于特定语言的内存的数据结构。 为了通过网络发送或者存储它，我们需要将它表示成某种标准的格式。 JSON 是一种以人可读的文本表示对象的方法。 它已经变成 NoSQL 世界交换数据的事实标准。当一个对象被序列化成为 JSON，它被称为一个 JSON 文档 。


Elastcisearch 是分布式的 文档 存储。它能存储和检索复杂的数据结构--序列化成为JSON文档--以 实时 的方式。 换句话说，一旦一个文档被存储在 Elasticsearch 中，它就是可以被集群中的任意节点检索到。

在 Elasticsearch 中， 每个字段的所有数据 都是 默认被索引的 。 即每个字段都有为了快速检索设置的专用倒排索引。

## 什么是文档？

我们使用的术语 对象 和 文档 是可以互相替换的。不过，有一个区别： 一个对象仅仅是类似于 hash 、 hashmap 、字典或者关联数组的 JSON 对象，对象中也可以嵌套其他的对象。 对象可能包含了另外一些对象。在 Elasticsearch 中，术语 文档 有着特定的含义。它是指**最顶层**或者**根对象**, 这个根对象被**序列化成 JSON**并存储到 Elasticsearch 中，指定了唯一 ID。
