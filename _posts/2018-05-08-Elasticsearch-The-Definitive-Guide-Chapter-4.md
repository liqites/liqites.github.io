---
layout: post
title: Elasticsearch - The Definitive Guide - Chapter 4
author: Tesla Lee
date: 2018-05-08 19:03:50 +0800
categories: [elasticsearch]
---
分布式文档存储

<!--more-->

## 路由一个文档到一个分片中
当索引一个文档的时候，文档会被存储到一个主分片中。

如何决定存储在哪个分片中？

`shard = hash(routing) % number_of_primary_shards`

`routing` 是一个可变值，默认是文档的 _id ，也可以设置成一个自定义的值。 `routing` 通过 `hash` 函数生成一个数字，然后这个数字再除以 `number_of_primary_shards` （主分片的数量）后得到 余数 。

所有的文档 API（ `get` 、 `index` 、 `delete` 、 `bulk` 、 `update` 以及 `mget` ）都接受一个叫做 `routing` 的路由参数 ，通过这个参数我们可以自定义文档到分片的映射。

## 煮粉片和副本分片如何交互
假设有一个三个节点的集群，包含一个叫 `blogs` 的索引。有两个主分片和四个副分片。
则分片的分布可能如图：

![图片]({{ "/assets/images/elas_0401.png" }})

我们假设下面的请求，都发送到 `Node 1` 上。

## 新建、索引和删除文档
新建、索引和删除 请求都是 写 操作， 必须在主分片上面完成之后才能被复制到相关的副本分片。

> 一个文档只能存在于一个分片中，也就是说，如果一个索引有两个主分片，可以认为两个主分片合起来存储了索引的所有文档。

更新步骤：
![图片]({{ "/assets/images/elas_0402.png" }})

1. 客户端向 `Node 1` 发送新建、索引或者删除请求。
2. 节点使用文档的 `_id` 确定文档属于分片 0 。请求会被转发到` Node 3`，因为分片 0 的主分片目前被分配在 `Node 3` 上。
3. `Node 3` 在主分片上面执行请求。如果成功了，它将请求并行转发到 `Node 1` 和 `Node 2` 的副本分片上。一旦所有的副本分片都报告成功, `Node 3` 将向协调节点报告成功，协调节点向客户端报告成功。
