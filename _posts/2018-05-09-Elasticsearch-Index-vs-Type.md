---
layout: post
title: Elasticsearch - Index vs Type
author: Tesla Lee
date: 2018-05-09 16:43:35 +0800
categories: [elasticsearch]
---

This article is a short and noted versions of elasticsearch's  [Index vs Type](https://www.elastic.co/blog/index-vs-type)

<!--more-->

## What is an index?
An index is stored in a set of shards, which are themselves Lucene indices.

Lucene indices have a small yet fixed overhead in terms of disk space, memory usage and file descriptors used.

**a single large index is more efficient than several small indices.**

While each shard is searched independently, Elasticsearch eventually needs to merge results from all the searched shards.

So, if the request is heavy, the task of merging all these shard results can become very resource-intensive, both in terms of CPU and memory.

## What is a type?

Types are a convenient way to store several types of data in the same index, in order to keep the total number of indices low for the reasons exposed above.

### limitations

* Fields need to be consistent across types. For instance if two fields have the same name in different types of the same index, they need to be of the same field type (string, date, etc.) and have the same configuration.
* Fields that exist in one type will also consume resources for documents of types where this field does not exist. **for speed reasons, doc values often reserve a fixed amount of disk space for every document, so that values can be addressed efficiently.**
* Scores use index-wide statistics, so scores of documents in one type can be impacted by documents from other types.
