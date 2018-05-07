---
layout: post
title: Basic Concept of Elasticsearch
author: Tesla Lee
date: 2018-05-03 00:00:00 +0800
categories: [elasticsearch]
---

Elasticsearch 中的几个基本概念

<!--more-->

## 基本概念

* **Near Realtime(NRT)**：接近实时，意味着，当你将内容存储到 Elasticsearch 后，大概最多一秒钟后就可以搜索了。
* **Cluster**：集群是一个或多个 `Node`，并且在此基础上提供索引与搜索等功能。
* **Node**：一个 `Node` 就是一个集群中的单台服务器，它存储数据，参与整个集群的数据索引和搜索功能。一个 `Node` 在启动时会加入到指定的集群中去。
* **Index**：`Index` 是一组有特定属性的 `Documents`。比如，你可以有个 `Index` 是存放客户数据的，一个 `Index` 是存放产品目录。
* **Type**：对于一个 `Index`，你可以指定一个或多个 `Type`，对于 `Type`，你自己可以赋予它任何意义。一般来说，比如多个 `Document` 有相同的几个 `Field`，那么它们可以认为是一个 `Type`。
* **Document**：`Document` 是能够被索引的基本单元。比如，一个客户有一个 `Document`。
* **Shards & Replicas**：一个 `Index` 存储的数据可能会非常庞大， 以至于单台机器并没有办法存放这些数据。
  - **Shards**：为了解决这个问题，所以引入了 `Shard` 来将 `Index` 分成多个 `Shard`，每个 `Shard` 可以认为是一个独立的 `Index`。我们在创建 `Index` 时，可以指定 `Shard` 的数量。`Shard` 提供了以下两个主要功能：
    - 可以将你的内容平行分割扩展
    - 可以提供分布式并行操作
  - `Shard` 的管理完全由 Elasticsearch 接手。
  - **Replica**：任何系统都需要有失败恢复机制。而 **Replica** 或者 **Replica Shard** 就提供这样的功能，它是 `Shard` 的备份。它提供两个主要功能。
    - 当一个 `Shard/Node` 出错时，依然可以保持功能完整。所以，`Replica` 与 原 `Shard` 永远不会存放在同一个 `Node` 上面。
    - 它可以帮助扩展你的搜索数据量，因为所有的 `Shard` 都会被搜索到。
